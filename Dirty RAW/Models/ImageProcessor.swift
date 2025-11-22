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
        temperature == 6500 &&
        tint == 0.0 &&
        sharpness == 0.0 &&
        vibrance == 0.0 &&
        hue == 0.0 &&
        toneCurveBlacks == 0.0 &&
        toneCurveShadows == 0.25 &&
        toneCurveMids == 0.5 &&
        toneCurveHighlights == 0.75 &&
        toneCurveWhites == 1.0 &&
        noiseReductionEnabled == false &&
        upscalingEnabled == false
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
            adjustments.temperature != 6500 ||
            adjustments.tint != 0.0 ||
            adjustments.sharpness != 0.0 ||
            adjustments.vibrance != 0.0 ||
            adjustments.hue != 0.0 ||
            adjustments.toneCurveBlacks != 0.0 ||
            adjustments.toneCurveShadows != 0.25 ||
            adjustments.toneCurveMids != 0.5 ||
            adjustments.toneCurveHighlights != 0.75 ||
            adjustments.toneCurveWhites != 1.0 ||
            adjustments.noiseReductionEnabled

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
        if adjustments.temperature != 6500 || adjustments.tint != 0.0 {
            if let filter = CIFilter(name: "CITemperatureAndTint") {
                filter.setValue(result, forKey: kCIInputImageKey)
                // Convert Kelvin to CIVector (neutral is 6500K)
                let neutral = CIVector(x: adjustments.temperature, y: adjustments.tint)
                let targetNeutral = CIVector(x: 6500, y: 0)
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

        return result
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
