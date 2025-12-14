//
//  ImageProcessor.swift
//  Dirty RAW
//

import Foundation
import CoreImage
import Metal
import MetalFX
import AppKit

struct ImageAdjustments {
    var exposure: Double = 0.0        // -2.0 to 2.0 EV
    var brightness: Double = 0.0      // -1.0 to 1.0
    var contrast: Double = 1.0        // 0.5 to 2.0
    var saturation: Double = 1.0      // 0.0 to 2.0
    var highlights: Double = 1.0      // 0.0 to 2.0
    var shadows: Double = 0.0         // -1.0 to 1.0
    /// Reference white balance for the decoded image.
    /// For Nikon RAW, this can be initialized from camera metadata when available.
    var referenceTemperature: Double = 6500
    var referenceTint: Double = 0.0

    /// Target white balance selected by the user.
    /// When `temperature/tint` match `referenceTemperature/referenceTint`, white balance is effectively a no-op.
    var temperature: Double = 6500    // 2000 to 10000 Kelvin
    var tint: Double = 0.0            // -100 to 100
    var sharpness: Double = 0.0       // 0.0 to 2.0
    var vibrance: Double = 0.0        // -1.0 to 1.0
    var hue: Double = 0.0             // -180 to 180 degrees

    // Tone Curve (5 points: black, shadows, mids, highlights, white)
    var toneCurveBlacks: Double = 0.0      // 0.0 to 0.5
    var toneCurveShadows: Double = 0.25    // 0.0 to 0.5
    var toneCurveMids: Double = 0.5        // 0.25 to 0.75
    var toneCurveHighlights: Double = 0.75 // 0.5 to 1.0
    var toneCurveWhites: Double = 1.0      // 0.5 to 1.0

    // Noise Reduction
    var noiseReductionEnabled: Bool = false
    var noiseLevel: Double = 0.02     // 0.0 to 0.1
    var noiseSharpness: Double = 0.4  // 0.0 to 2.0

    // MetalFX Upscaling
    var upscalingEnabled: Bool = false
    var upscaleMode: Int = 0          // 0 = 1.5x, 1 = 2x, 2 = 3x

    // LUT (3D .cube)
    var lutEnabled: Bool = false
    var lutID: String = "none"        // "none" | "bundle:<name>" | "import:<uuid>"
    var lutIntensity: Double = 1.0    // 0.0 to 1.0

    var upscaleFactor: Double {
        switch upscaleMode {
        case 0: return 1.5
        case 1: return 2.0
        case 2: return 3.0
        default: return 2.0
        }
    }

    var isDefault: Bool {
        exposure == 0.0 &&
        brightness == 0.0 &&
        contrast == 1.0 &&
        saturation == 1.0 &&
        highlights == 1.0 &&
        shadows == 0.0 &&
        referenceTemperature == 6500 &&
        referenceTint == 0.0 &&
        temperature == referenceTemperature &&
        tint == referenceTint &&
        sharpness == 0.0 &&
        vibrance == 0.0 &&
        hue == 0.0 &&
        toneCurveBlacks == 0.0 &&
        toneCurveShadows == 0.25 &&
        toneCurveMids == 0.5 &&
        toneCurveHighlights == 0.75 &&
        toneCurveWhites == 1.0 &&
        noiseReductionEnabled == false &&
        upscalingEnabled == false &&
        lutEnabled == false &&
        lutID == "none" &&
        lutIntensity == 1.0
    }

    mutating func reset() {
        self = ImageAdjustments()
    }
}

class ImageProcessor {
    static let shared = ImageProcessor()

    private let context: CIContext
    private let device: MTLDevice?
    private let commandQueue: MTLCommandQueue?

    private lazy var metalLUTKernel: MetalLUTKernel? = {
        guard let device else { return nil }
        return MetalLUTKernel(device: device)
    }()

    private init() {
        // Create Metal device for GPU acceleration
        device = MTLCreateSystemDefaultDevice()
        commandQueue = device?.makeCommandQueue()

        if let device = device {
            // Metal-backed context for best performance
            context = CIContext(mtlDevice: device, options: [
                .workingColorSpace: CGColorSpace(name: CGColorSpace.extendedLinearSRGB)!,
                .outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                .useSoftwareRenderer: false,
                .priorityRequestLow: false,
                .cacheIntermediates: true
            ])
            print("ImageProcessor: Using Metal device: \(device.name)")
        } else {
            // Fallback to CPU
            context = CIContext(options: [
                .useSoftwareRenderer: true
            ])
            print("ImageProcessor: Metal not available, using CPU")
        }
    }

    var isMetalFXAvailable: Bool {
        guard let device = device else { return false }
        if #available(macOS 13.0, *) {
            let descriptor = MTLFXSpatialScalerDescriptor()
            descriptor.inputWidth = 100
            descriptor.inputHeight = 100
            descriptor.outputWidth = 200
            descriptor.outputHeight = 200
            descriptor.colorTextureFormat = .rgba16Float
            descriptor.outputTextureFormat = .rgba16Float
            return MTLFXSpatialScalerDescriptor.supportsDevice(device)
        }
        return false
    }

    func process(image: NSImage, adjustments: ImageAdjustments) -> NSImage? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        var ciImage = CIImage(cgImage: cgImage)

        // Apply adjustments only if not default (excluding upscaling check)
        let hasAdjustments = adjustments.exposure != 0.0 ||
            adjustments.brightness != 0.0 ||
            adjustments.contrast != 1.0 ||
            adjustments.saturation != 1.0 ||
            adjustments.highlights != 1.0 ||
            adjustments.shadows != 0.0 ||
            adjustments.temperature != adjustments.referenceTemperature ||
            adjustments.tint != adjustments.referenceTint ||
            adjustments.sharpness != 0.0 ||
            adjustments.vibrance != 0.0 ||
            adjustments.hue != 0.0 ||
            adjustments.toneCurveBlacks != 0.0 ||
            adjustments.toneCurveShadows != 0.25 ||
            adjustments.toneCurveMids != 0.5 ||
            adjustments.toneCurveHighlights != 0.75 ||
            adjustments.toneCurveWhites != 1.0 ||
            adjustments.noiseReductionEnabled ||
            (adjustments.lutEnabled && adjustments.lutID != "none" && adjustments.lutIntensity > 0.0001)

        if hasAdjustments {
            ciImage = applyAdjustments(to: ciImage, adjustments: adjustments)
        }

        // Render with Metal context
        guard let outputCGImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }

        var resultImage = NSImage(cgImage: outputCGImage, size: image.size)

        // Apply MetalFX upscaling if enabled
        if adjustments.upscalingEnabled {
            if let upscaled = applyMetalFXUpscaling(to: resultImage, factor: adjustments.upscaleFactor) {
                resultImage = upscaled
            }
        }

        return resultImage
    }

    /// Returns max upscale factors available for given image size (1.5x, 2x, 3x)
    func availableUpscaleFactors(for imageSize: NSSize) -> (canScale1_5x: Bool, canScale2x: Bool, canScale3x: Bool) {
        let maxTextureSize = 16384.0
        let maxFactor = min(maxTextureSize / imageSize.width, maxTextureSize / imageSize.height)
        return (
            canScale1_5x: maxFactor >= 1.5,
            canScale2x: maxFactor >= 2.0,
            canScale3x: maxFactor >= 3.0
        )
    }

    @available(macOS 13.0, *)
    private func applyMetalFXUpscaling(to image: NSImage, factor: Double) -> NSImage? {
        guard let device = device,
              let commandQueue = commandQueue,
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        let inputWidth = cgImage.width
        let inputHeight = cgImage.height
        let outputWidth = Int(Double(inputWidth) * factor)
        let outputHeight = Int(Double(inputHeight) * factor)

        // Create spatial scaler descriptor
        let descriptor = MTLFXSpatialScalerDescriptor()
        descriptor.inputWidth = inputWidth
        descriptor.inputHeight = inputHeight
        descriptor.outputWidth = outputWidth
        descriptor.outputHeight = outputHeight
        descriptor.colorTextureFormat = .rgba16Float
        descriptor.outputTextureFormat = .rgba16Float
        descriptor.colorProcessingMode = .perceptual

        guard let scaler = descriptor.makeSpatialScaler(device: device) else {
            print("MetalFX: Failed to create spatial scaler")
            return nil
        }

        // Create input texture
        let inputDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba16Float,
            width: inputWidth,
            height: inputHeight,
            mipmapped: false
        )
        inputDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
        inputDescriptor.storageMode = .private

        guard let inputTexture = device.makeTexture(descriptor: inputDescriptor) else {
            return nil
        }

        // Create output texture
        let outputDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba16Float,
            width: outputWidth,
            height: outputHeight,
            mipmapped: false
        )
        outputDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
        outputDescriptor.storageMode = .private

        guard let outputTexture = device.makeTexture(descriptor: outputDescriptor) else {
            return nil
        }

        // Convert CGImage to CIImage and render to input texture
        let ciImage = CIImage(cgImage: cgImage)
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            return nil
        }

        context.render(ciImage, to: inputTexture, commandBuffer: commandBuffer, bounds: ciImage.extent, colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!)

        // Apply MetalFX upscaling
        scaler.colorTexture = inputTexture
        scaler.outputTexture = outputTexture
        scaler.encode(commandBuffer: commandBuffer)

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        // Read back from output texture
        let readDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba16Float,
            width: outputWidth,
            height: outputHeight,
            mipmapped: false
        )
        readDescriptor.usage = .shaderRead
        readDescriptor.storageMode = .managed

        guard let readTexture = device.makeTexture(descriptor: readDescriptor),
              let blitBuffer = commandQueue.makeCommandBuffer(),
              let blitEncoder = blitBuffer.makeBlitCommandEncoder() else {
            return nil
        }

        blitEncoder.copy(from: outputTexture, to: readTexture)
        blitEncoder.endEncoding()
        blitBuffer.commit()
        blitBuffer.waitUntilCompleted()

        // Convert texture to CGImage
        let outputCIImage = CIImage(mtlTexture: readTexture, options: [.colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!])
        guard let outputCIImage = outputCIImage,
              let outputCGImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) else {
            return nil
        }

        return NSImage(cgImage: outputCGImage, size: NSSize(width: outputWidth, height: outputHeight))
    }

    private func applyAdjustments(to image: CIImage, adjustments: ImageAdjustments) -> CIImage {
        var result = image

        // Exposure adjustment
        if adjustments.exposure != 0.0 {
            if let filter = CIFilter(name: "CIExposureAdjust") {
                filter.setValue(result, forKey: kCIInputImageKey)
                filter.setValue(adjustments.exposure, forKey: kCIInputEVKey)
                if let output = filter.outputImage {
                    result = output
                }
            }
        }

        // Highlights and Shadows
        if adjustments.highlights != 1.0 || adjustments.shadows != 0.0 {
            if let filter = CIFilter(name: "CIHighlightShadowAdjust") {
                filter.setValue(result, forKey: kCIInputImageKey)
                filter.setValue(adjustments.highlights, forKey: "inputHighlightAmount")
                filter.setValue(adjustments.shadows, forKey: "inputShadowAmount")
                if let output = filter.outputImage {
                    result = output
                }
            }
        }

        // Temperature and Tint (White Balance)
        if adjustments.temperature != adjustments.referenceTemperature || adjustments.tint != adjustments.referenceTint {
            if let filter = CIFilter(name: "CITemperatureAndTint") {
                filter.setValue(result, forKey: kCIInputImageKey)
                // Map from reference (decoded image) white point to user-selected target white point.
                let neutral = CIVector(x: adjustments.referenceTemperature, y: adjustments.referenceTint)
                let targetNeutral = CIVector(x: adjustments.temperature, y: adjustments.tint)
                filter.setValue(neutral, forKey: "inputNeutral")
                filter.setValue(targetNeutral, forKey: "inputTargetNeutral")
                if let output = filter.outputImage {
                    result = output
                }
            }
        }

        // Vibrance
        if adjustments.vibrance != 0.0 {
            if let filter = CIFilter(name: "CIVibrance") {
                filter.setValue(result, forKey: kCIInputImageKey)
                filter.setValue(adjustments.vibrance, forKey: "inputAmount")
                if let output = filter.outputImage {
                    result = output
                }
            }
        }

        // Hue
        if adjustments.hue != 0.0 {
            if let filter = CIFilter(name: "CIHueAdjust") {
                filter.setValue(result, forKey: kCIInputImageKey)
                // Convert degrees to radians
                let radians = adjustments.hue * .pi / 180.0
                filter.setValue(radians, forKey: kCIInputAngleKey)
                if let output = filter.outputImage {
                    result = output
                }
            }
        }

        // Tone Curve
        let hasToneCurveChanges = adjustments.toneCurveBlacks != 0.0 ||
            adjustments.toneCurveShadows != 0.25 ||
            adjustments.toneCurveMids != 0.5 ||
            adjustments.toneCurveHighlights != 0.75 ||
            adjustments.toneCurveWhites != 1.0

        if hasToneCurveChanges {
            if let filter = CIFilter(name: "CIToneCurve") {
                filter.setValue(result, forKey: kCIInputImageKey)
                filter.setValue(CIVector(x: 0.0, y: CGFloat(adjustments.toneCurveBlacks)), forKey: "inputPoint0")
                filter.setValue(CIVector(x: 0.25, y: CGFloat(adjustments.toneCurveShadows)), forKey: "inputPoint1")
                filter.setValue(CIVector(x: 0.5, y: CGFloat(adjustments.toneCurveMids)), forKey: "inputPoint2")
                filter.setValue(CIVector(x: 0.75, y: CGFloat(adjustments.toneCurveHighlights)), forKey: "inputPoint3")
                filter.setValue(CIVector(x: 1.0, y: CGFloat(adjustments.toneCurveWhites)), forKey: "inputPoint4")
                if let output = filter.outputImage {
                    result = output
                }
            }
        }

        // Color Controls (brightness, contrast, saturation)
        if adjustments.brightness != 0.0 || adjustments.contrast != 1.0 || adjustments.saturation != 1.0 {
            if let filter = CIFilter(name: "CIColorControls") {
                filter.setValue(result, forKey: kCIInputImageKey)
                filter.setValue(adjustments.brightness, forKey: kCIInputBrightnessKey)
                filter.setValue(adjustments.contrast, forKey: kCIInputContrastKey)
                filter.setValue(adjustments.saturation, forKey: kCIInputSaturationKey)
                if let output = filter.outputImage {
                    result = output
                }
            }
        }

        // Sharpness
        if adjustments.sharpness > 0.0 {
            if let filter = CIFilter(name: "CISharpenLuminance") {
                filter.setValue(result, forKey: kCIInputImageKey)
                filter.setValue(adjustments.sharpness, forKey: kCIInputSharpnessKey)
                if let output = filter.outputImage {
                    result = output
                }
            }
        }

        // Noise Reduction
        if adjustments.noiseReductionEnabled {
            if let filter = CIFilter(name: "CINoiseReduction") {
                filter.setValue(result, forKey: kCIInputImageKey)
                filter.setValue(adjustments.noiseLevel, forKey: "inputNoiseLevel")
                filter.setValue(adjustments.noiseSharpness, forKey: "inputSharpness")
                if let output = filter.outputImage {
                    result = output
                }
            }
        }

        // LUT (apply at the end of the color pipeline)
        if adjustments.lutEnabled,
           adjustments.lutID != "none",
           adjustments.lutIntensity > 0.0001,
           let lut = LUTStore.shared.resolveLUT(id: adjustments.lutID) {
            let intensity = min(max(adjustments.lutIntensity, 0.0), 1.0)

            // Prefer Metal compute path (supports 65³ and is GPU accelerated).
            if let metalOut = applyLUTWithMetal(to: result, lut: lut, intensity: Float(intensity)) {
                result = metalOut
            } else {
                // Fallback: Core Image color cube
                if let cubeFilter = CIFilter(name: "CIColorCubeWithColorSpace") ?? CIFilter(name: "CIColorCube") {
                    cubeFilter.setValue(result, forKey: kCIInputImageKey)
                    cubeFilter.setValue(lut.dimension, forKey: "inputCubeDimension")
                    cubeFilter.setValue(lut.cubeData, forKey: "inputCubeData")

                    if cubeFilter.inputKeys.contains("inputColorSpace") {
                        cubeFilter.setValue(CGColorSpace(name: CGColorSpace.sRGB), forKey: "inputColorSpace")
                    }

                    if let lutOutput = cubeFilter.outputImage {
                        if intensity >= 0.999 {
                            result = lutOutput
                        } else {
                            if let dissolve = CIFilter(name: "CIDissolveTransition") {
                                dissolve.setValue(result, forKey: kCIInputImageKey)
                                dissolve.setValue(lutOutput, forKey: kCIInputTargetImageKey)
                                dissolve.setValue(intensity, forKey: kCIInputTimeKey)
                                if let mixed = dissolve.outputImage {
                                    result = mixed
                                } else {
                                    result = lutOutput
                                }
                            } else {
                                result = lutOutput
                            }
                        }
                    }
                }
            }
        }

        return result
    }

    private func applyLUTWithMetal(to image: CIImage, lut: LUT3D, intensity: Float) -> CIImage? {
        guard let device,
              let commandQueue,
              let kernel = metalLUTKernel,
              let commandBuffer = commandQueue.makeCommandBuffer() else {
            return nil
        }

        let extent = image.extent.integral
        let width = max(Int(extent.width), 1)
        let height = max(Int(extent.height), 1)

        // Input / output textures
        let inDesc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba16Float,
            width: width,
            height: height,
            mipmapped: false
        )
        inDesc.usage = [.shaderRead, .shaderWrite]
        inDesc.storageMode = .private

        let outDesc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba16Float,
            width: width,
            height: height,
            mipmapped: false
        )
        outDesc.usage = [.shaderRead, .shaderWrite]
        outDesc.storageMode = .private

        guard let inputTexture = device.makeTexture(descriptor: inDesc),
              let outputTexture = device.makeTexture(descriptor: outDesc) else {
            return nil
        }

        // Render CIImage -> inputTexture
        context.render(
            image,
            to: inputTexture,
            commandBuffer: commandBuffer,
            bounds: extent,
            colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!
        )

        // LUT 3D texture
        guard let lutTexture = kernel.makeLUTTexture(cacheKey: lut.id, dimension: lut.dimension, cubeData: lut.cubeData) else {
            return nil
        }

        // Encode compute
        if let encoder = commandBuffer.makeComputeCommandEncoder() {
            kernel.encode(
                encoder: encoder,
                input: inputTexture,
                output: outputTexture,
                lut: lutTexture,
                lutDimension: UInt32(lut.dimension),
                intensity: intensity
            )
            encoder.endEncoding()
        } else {
            return nil
        }

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        // Wrap output texture back into CIImage
        guard let outCI = CIImage(mtlTexture: outputTexture, options: [.colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!]) else {
            return nil
        }
        return outCI.cropped(to: extent)
    }

    // Process with completion for async updates
    func processAsync(image: NSImage, adjustments: ImageAdjustments, completion: @escaping (NSImage?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.process(image: image, adjustments: adjustments)
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
}

// MARK: - Metal LUT Kernel (runtime compiled)

private final class MetalLUTKernel {
    private let device: MTLDevice
    private let pipeline: MTLComputePipelineState
    private let sampler: MTLSamplerState
    private var lutCache: [String: MTLTexture] = [:]
    private let lock = NSLock()

    init?(device: MTLDevice) {
        self.device = device

        let source = """
        #include <metal_stdlib>
        using namespace metal;

        struct LUTParams {
            uint  lutDim;
            float intensity;
        };

        kernel void lut3dApply(
            texture2d<half, access::read>  inTex  [[texture(0)]],
            texture2d<half, access::write> outTex [[texture(1)]],
            texture3d<float, access::sample> lutTex [[texture(2)]],
            constant LUTParams& params [[buffer(0)]],
            sampler s [[sampler(0)]],
            uint2 gid [[thread_position_in_grid]]
        ) {
            if (gid.x >= outTex.get_width() || gid.y >= outTex.get_height()) return;

            half4 inH = inTex.read(gid);
            float4 inF = float4(inH);
            float3 rgb = clamp(inF.rgb, 0.0f, 1.0f);

            float dim = max(float(params.lutDim), 2.0f);
            float invDim = 1.0f / dim;

            // Map [0,1] into normalized LUT coords with half-texel offset
            float3 uvw = rgb * ((dim - 1.0f) * invDim) + (0.5f * invDim);
            float4 mapped = lutTex.sample(s, uvw);

            float t = clamp(params.intensity, 0.0f, 1.0f);
            float3 outRgb = mix(inF.rgb, mapped.rgb, t);
            outTex.write(half4(outRgb, inF.a), gid);
        }
        """

        do {
            let options = MTLCompileOptions()
            let library = try device.makeLibrary(source: source, options: options)
            guard let fn = library.makeFunction(name: "lut3dApply") else { return nil }
            pipeline = try device.makeComputePipelineState(function: fn)
        } catch {
            return nil
        }

        let sDesc = MTLSamplerDescriptor()
        sDesc.minFilter = .linear
        sDesc.magFilter = .linear
        sDesc.mipFilter = .notMipmapped
        sDesc.normalizedCoordinates = true
        sDesc.sAddressMode = .clampToEdge
        sDesc.tAddressMode = .clampToEdge
        sDesc.rAddressMode = .clampToEdge
        guard let s = device.makeSamplerState(descriptor: sDesc) else { return nil }
        sampler = s
    }

    func makeLUTTexture(cacheKey: String, dimension: Int, cubeData: Data) -> MTLTexture? {
        lock.lock()
        if let cached = lutCache[cacheKey] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        let desc = MTLTextureDescriptor()
        desc.textureType = .type3D
        desc.pixelFormat = .rgba32Float
        desc.width = dimension
        desc.height = dimension
        desc.depth = dimension
        desc.mipmapLevelCount = 1
        desc.usage = [.shaderRead]
        desc.storageMode = .shared

        guard let tex = device.makeTexture(descriptor: desc) else { return nil }

        let bytesPerRow = dimension * 4 * MemoryLayout<Float>.size
        let bytesPerImage = bytesPerRow * dimension
        cubeData.withUnsafeBytes { raw in
            guard let base = raw.baseAddress else { return }
            tex.replace(
                region: MTLRegionMake3D(0, 0, 0, dimension, dimension, dimension),
                mipmapLevel: 0,
                slice: 0,
                withBytes: base,
                bytesPerRow: bytesPerRow,
                bytesPerImage: bytesPerImage
            )
        }

        lock.lock()
        lutCache[cacheKey] = tex
        lock.unlock()
        return tex
    }

    func encode(
        encoder: MTLComputeCommandEncoder,
        input: MTLTexture,
        output: MTLTexture,
        lut: MTLTexture,
        lutDimension: UInt32,
        intensity: Float
    ) {
        encoder.setComputePipelineState(pipeline)
        encoder.setTexture(input, index: 0)
        encoder.setTexture(output, index: 1)
        encoder.setTexture(lut, index: 2)

        var params = LUTParams(lutDim: lutDimension, intensity: intensity)
        encoder.setBytes(&params, length: MemoryLayout<LUTParams>.size, index: 0)
        encoder.setSamplerState(sampler, index: 0)

        let w = pipeline.threadExecutionWidth
        let h = max(pipeline.maxTotalThreadsPerThreadgroup / w, 1)
        let tg = MTLSize(width: w, height: h, depth: 1)
        let grid = MTLSize(width: output.width, height: output.height, depth: 1)
        encoder.dispatchThreads(grid, threadsPerThreadgroup: tg)
    }

    private struct LUTParams {
        var lutDim: UInt32
        var intensity: Float
    }
}

// MARK: - LUT Support (.cube)

fileprivate struct LUT3D {
    let id: String
    let displayName: String
    let dimension: Int
    let cubeData: Data
}

/// Thread-safe LUT registry + cache.
/// - Built-in LUTs are generated programmatically.
/// - Imported LUTs are copied into Application Support, so we don't rely on security-scoped bookmarks.
final class LUTStore {
    static let shared = LUTStore()
    static let didChangeNotification = Notification.Name("DirtyRAW.LUTStoreDidChange")

    struct Option: Identifiable, Hashable {
        let id: String
        let displayName: String
        let isBuiltIn: Bool
    }

    private let lock = NSLock()
    private var cache: [String: LUT3D] = [:]
    private var imported: [String: ImportedLUT] = [:] // id -> meta

    private struct ImportedLUT: Codable {
        let id: String
        let displayName: String
        let fileName: String
    }

    private let defaultsKey = "DirtyRAW.ImportedLUTs.v1"

    private init() {
        restoreImportedIndex()
    }

    func listOptions() -> [Option] {
        lock.lock()
        let importedValues = imported.values
        lock.unlock()

        var options: [Option] = [
            .init(id: "none", displayName: "None", isBuiltIn: true),
        ]

        // Bundle presets (Resources/LUTs/*.cube)
        if let urls = Bundle.main.urls(forResourcesWithExtension: "cube", subdirectory: "LUTs") {
            let bundleItems: [Option] = urls
                .sorted { $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending }
                .map { url in
                    let name = url.deletingPathExtension().lastPathComponent
                    return Option(id: "bundle:\(name)", displayName: name, isBuiltIn: true)
                }
            options.append(contentsOf: bundleItems)
        }

        let sortedImported = importedValues.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
        options.append(contentsOf: sortedImported.map { .init(id: "import:\($0.id)", displayName: $0.displayName, isBuiltIn: false) })
        return options
    }

    func importCubeFile(from url: URL) throws -> String {
        let displayName = url.deletingPathExtension().lastPathComponent
        let uuid = UUID().uuidString
        let storedFileName = "\(uuid)-\(displayName).cube"

        let destinationURL = try applicationSupportLUTsDirectory().appendingPathComponent(storedFileName)
        try FileManager.default.createDirectory(at: destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true)

        // Copy (overwrite if a previous import used the same filename, though UUID should avoid this)
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        try FileManager.default.copyItem(at: url, to: destinationURL)

        // Validate by parsing once (and warm the cache)
        let lut = try CubeLUTParser.parse(fileURL: destinationURL, id: "import:\(uuid)", displayName: displayName)

        lock.lock()
        cache[lut.id] = lut
        imported[uuid] = ImportedLUT(id: uuid, displayName: displayName, fileName: storedFileName)
        persistImportedIndexLocked()
        lock.unlock()

        NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
        return lut.id
    }

    fileprivate func resolveLUT(id: String) -> LUT3D? {
        if id == "none" { return nil }

        lock.lock()
        if let cached = cache[id] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        // Bundle LUTs
        if id.hasPrefix("bundle:") {
            let name = String(id.dropFirst("bundle:".count))
            guard let fileURL = Bundle.main.url(forResource: name, withExtension: "cube", subdirectory: "LUTs") else {
                return nil
            }
            do {
                let parsed = try CubeLUTParser.parse(fileURL: fileURL, id: id, displayName: name)
                lock.lock()
                cache[id] = parsed
                lock.unlock()
                return parsed
            } catch {
                return nil
            }
        }

        // Imported LUTs
        if id.hasPrefix("import:") {
            let uuid = String(id.dropFirst("import:".count))
            lock.lock()
            let meta = imported[uuid]
            lock.unlock()
            guard let meta else { return nil }

            do {
                let fileURL = try applicationSupportLUTsDirectory().appendingPathComponent(meta.fileName)
                let parsed = try CubeLUTParser.parse(fileURL: fileURL, id: id, displayName: meta.displayName)
                lock.lock()
                cache[id] = parsed
                lock.unlock()
                return parsed
            } catch {
                return nil
            }
        }

        return nil
    }

    // MARK: - Private

    private func restoreImportedIndex() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else { return }
        do {
            let decoded = try JSONDecoder().decode([ImportedLUT].self, from: data)
            lock.lock()
            imported = Dictionary(uniqueKeysWithValues: decoded.map { ($0.id, $0) })
            lock.unlock()
        } catch {
            // Ignore corrupted index
        }
    }

    private func persistImportedIndexLocked() {
        let list = imported.values.sorted { $0.displayName < $1.displayName }
        guard let data = try? JSONEncoder().encode(Array(list)) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    private func applicationSupportLUTsDirectory() throws -> URL {
        let appSupport = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return appSupport.appendingPathComponent("DirtyRAW", isDirectory: true)
            .appendingPathComponent("LUTs", isDirectory: true)
    }
}

fileprivate enum CubeLUTParser {
    static let maxSupportedDimension = 65

    enum ParseError: LocalizedError {
        case invalidSize
        case unsupportedSize(Int)
        case unsupported1DLUT
        case dataMismatch(expected: Int, actual: Int)
        case fileReadFailed

        var errorDescription: String? {
            switch self {
            case .invalidSize:
                return "Invalid LUT size"
            case .unsupportedSize(let size):
                return "Unsupported LUT size: \(size) (max \(maxSupportedDimension))"
            case .unsupported1DLUT:
                return "1D LUT is not supported"
            case .dataMismatch(let expected, let actual):
                return "LUT data mismatch (expected \(expected) lines, got \(actual))"
            case .fileReadFailed:
                return "Failed to read LUT file"
            }
        }
    }

    static func parse(fileURL: URL, id: String, displayName: String) throws -> LUT3D {
        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
            throw ParseError.fileReadFailed
        }

        var size: Int?
        var rgb: [Float] = []
        rgb.reserveCapacity(maxSupportedDimension * maxSupportedDimension * maxSupportedDimension * 3)

        for rawLine in content.split(whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty || line.hasPrefix("#") { continue }

            if line.hasPrefix("LUT_1D_SIZE") {
                throw ParseError.unsupported1DLUT
            }

            if line.hasPrefix("LUT_3D_SIZE") {
                let parts = line.split(whereSeparator: { $0.isWhitespace })
                if let last = parts.last, let parsed = Int(last) {
                    if parsed < 2 {
                        throw ParseError.invalidSize
                    }
                    if parsed > maxSupportedDimension {
                        throw ParseError.unsupportedSize(parsed)
                    }
                    size = parsed
                    rgb.reserveCapacity(parsed * parsed * parsed * 3)
                }
                continue
            }

            if line.hasPrefix("TITLE") ||
                line.hasPrefix("DOMAIN_MIN") ||
                line.hasPrefix("DOMAIN_MAX") {
                continue
            }

            let parts = line.split(whereSeparator: { $0.isWhitespace })
            guard parts.count >= 3,
                  let r = Float(parts[0]),
                  let g = Float(parts[1]),
                  let b = Float(parts[2]) else {
                continue
            }

            rgb.append(min(max(r, 0), 1))
            rgb.append(min(max(g, 0), 1))
            rgb.append(min(max(b, 0), 1))
        }

        guard let dimension = size, dimension > 1 else {
            throw ParseError.invalidSize
        }

        let expectedLines = dimension * dimension * dimension
        let actualLines = rgb.count / 3
        guard actualLines == expectedLines else {
            throw ParseError.dataMismatch(expected: expectedLines, actual: actualLines)
        }

        // Core Image expects cube data in nested order: B (outer) -> G -> R (inner).
        // Standard .cube files are typically written in that same order with R changing fastest,
        // so the file line order can be used directly.
        var rgba: [Float] = []
        rgba.reserveCapacity(expectedLines * 4)
        for i in stride(from: 0, to: rgb.count, by: 3) {
            rgba.append(rgb[i])
            rgba.append(rgb[i + 1])
            rgba.append(rgb[i + 2])
            rgba.append(1.0)
        }

        return LUT3D(id: id, displayName: displayName, dimension: dimension, cubeData: floatsToData(rgba))
    }

    static func generateCubeData(
        dimension: Int,
        transform: (_ r: Float, _ g: Float, _ b: Float) -> (Float, Float, Float)
    ) -> Data {
        var rgba: [Float] = []
        rgba.reserveCapacity(dimension * dimension * dimension * 4)

        let maxIndex = Float(dimension - 1)
        for b in 0..<dimension {
            let bf = Float(b) / maxIndex
            for g in 0..<dimension {
                let gf = Float(g) / maxIndex
                for r in 0..<dimension {
                    let rf = Float(r) / maxIndex
                    let (or, og, ob) = transform(rf, gf, bf)
                    rgba.append(min(max(or, 0), 1))
                    rgba.append(min(max(og, 0), 1))
                    rgba.append(min(max(ob, 0), 1))
                    rgba.append(1.0)
                }
            }
        }

        return floatsToData(rgba)
    }

    private static func floatsToData(_ floats: [Float]) -> Data {
        floats.withUnsafeBytes { Data($0) }
    }
}
