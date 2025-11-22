//
//  RAWImage.swift
//  Dirty RAW
//

import SwiftUI
import AppKit
import ImageIO

struct EXIFInfo: Identifiable {
    let id = UUID()
    let label: String
    let value: String
}

@MainActor
class RAWImage: ObservableObject, Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let fileName: String

    nonisolated static func == (lhs: RAWImage, rhs: RAWImage) -> Bool {
        lhs.id == rhs.id
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    @Published var image: NSImage?
    @Published var processedImage: NSImage?
    @Published var thumbnail: NSImage?
    @Published var exifData: NKEXIFData?
    @Published var imageInfo: NKImageInfo?
    @Published var isLoading = false
    @Published var isProcessing = false
    @Published var error: String?
    @Published var adjustments = ImageAdjustments()

    private var sdkWrapper: NikonSDKWrapper?
    private var processingTask: Task<Void, Never>?

    init(url: URL) {
        self.url = url
        self.fileName = url.lastPathComponent
    }

    func load() {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        Task.detached { [weak self, url] in
            guard let self = self else { return }

            let isAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if isAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let ext = url.pathExtension.lowercased()
            let isNikonRAW = ext == "nef" || ext == "nrw"

            var image: NSImage?
            var exif: NKEXIFData?
            var info: NKImageInfo?
            var wrapper: NikonSDKWrapper?

            // Try NikonSDKWrapper for NEF/NRW files
            if isNikonRAW {
                wrapper = NikonSDKWrapper(filePath: url.path)
                if let w = wrapper {
                    nonisolated(unsafe) let wrapperImage = w.decodeToImage()
                    nonisolated(unsafe) let wrapperExif = w.getEXIFData()
                    nonisolated(unsafe) let wrapperInfo = w.getImageInfo()
                    image = wrapperImage
                    exif = wrapperExif
                    info = wrapperInfo
                }
            }

            // Fallback to macOS native methods for JPG or if NEF failed
            if image == nil {
                image = self.loadImageNative(url: url)
                if image != nil {
                    exif = self.loadEXIFNative(url: url)
                    info = self.loadImageInfoNative(url: url, image: image!)
                }
            }

            guard let loadedImage = image else {
                await MainActor.run {
                    self.error = "Failed to open file"
                    self.isLoading = false
                }
                return
            }

            // Generate thumbnail
            let thumbSize: CGFloat = 80
            let ratio = min(thumbSize / loadedImage.size.width, thumbSize / loadedImage.size.height)
            let newSize = NSSize(width: loadedImage.size.width * ratio, height: loadedImage.size.height * ratio)
            let thumb = NSImage(size: newSize)
            thumb.lockFocus()
            loadedImage.draw(in: NSRect(origin: .zero, size: newSize))
            thumb.unlockFocus()

            // Capture values for sendable closure
            nonisolated(unsafe) let finalWrapper = wrapper
            nonisolated(unsafe) let finalImage = loadedImage
            nonisolated(unsafe) let finalThumb = thumb
            nonisolated(unsafe) let finalExif = exif
            nonisolated(unsafe) let finalInfo = info

            await MainActor.run {
                self.sdkWrapper = finalWrapper
                self.image = finalImage
                self.processedImage = finalImage
                self.thumbnail = finalThumb
                self.exifData = finalExif
                self.imageInfo = finalInfo
                self.isLoading = false
            }
        }
    }

    // MARK: - Native macOS Loading Methods

    private nonisolated func loadImageNative(url: URL) -> NSImage? {
        // Use NSImage's native loading which handles memory more efficiently
        guard let image = NSImage(contentsOf: url) else {
            return nil
        }

        // Get actual pixel dimensions from the image representation
        if let rep = image.representations.first {
            let pixelWidth = rep.pixelsWide
            let pixelHeight = rep.pixelsHigh
            if pixelWidth > 0 && pixelHeight > 0 {
                image.size = NSSize(width: pixelWidth, height: pixelHeight)
            }
        }

        return image
    }

    private nonisolated func loadEXIFNative(url: URL) -> NKEXIFData? {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] else {
            return nil
        }

        let exifData = NKEXIFData()

        // TIFF properties
        if let tiff = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any] {
            exifData.make = tiff[kCGImagePropertyTIFFMake as String] as? String
            exifData.model = tiff[kCGImagePropertyTIFFModel as String] as? String
            exifData.software = tiff[kCGImagePropertyTIFFSoftware as String] as? String
            exifData.artist = tiff[kCGImagePropertyTIFFArtist as String] as? String
            exifData.copyright = tiff[kCGImagePropertyTIFFCopyright as String] as? String

            if let dateString = tiff[kCGImagePropertyTIFFDateTime as String] as? String {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
                exifData.dateTime = formatter.date(from: dateString)
            }
        }

        // EXIF properties
        if let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any] {
            if let exposure = exif[kCGImagePropertyExifExposureTime as String] as? Double {
                exifData.exposureTime = exposure
            }
            if let fNumber = exif[kCGImagePropertyExifFNumber as String] as? Double {
                exifData.fNumber = fNumber
            }
            if let isoArray = exif[kCGImagePropertyExifISOSpeedRatings as String] as? [Int], let iso = isoArray.first {
                exifData.iso = UInt(iso)
            }
            if let focal = exif[kCGImagePropertyExifFocalLength as String] as? Double {
                exifData.focalLength = focal
            }
            if let bias = exif[kCGImagePropertyExifExposureBiasValue as String] as? Double {
                exifData.exposureBias = bias
            }
            if let metering = exif[kCGImagePropertyExifMeteringMode as String] as? Int {
                exifData.meteringMode = UInt(metering)
            }
            if let program = exif[kCGImagePropertyExifExposureProgram as String] as? Int {
                exifData.exposureProgram = UInt(program)
            }
            if let flash = exif[kCGImagePropertyExifFlash as String] as? Int {
                exifData.flash = UInt(flash)
            }
            if let lens = exif[kCGImagePropertyExifLensModel as String] as? String {
                exifData.lensInfo = lens
            }
        }

        // File format for JPEG
        exifData.fileFormat = 3 // JPEG

        return exifData
    }

    private nonisolated func loadImageInfoNative(url: URL, image: NSImage) -> NKImageInfo? {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] else {
            return nil
        }

        let info = NKImageInfo()
        info.width = UInt(image.size.width)
        info.height = UInt(image.size.height)
        info.byteDepth = 1 // 8-bit for JPEG
        info.colorType = 2 // RGB

        if let orientation = properties[kCGImagePropertyOrientation as String] as? Int {
            info.orientation = UInt(orientation)
        }

        if let dpi = properties[kCGImagePropertyDPIWidth as String] as? Double {
            info.resolution = dpi
        }

        return info
    }

    func applyAdjustments() {
        guard let image = image else { return }

        // Cancel previous processing
        processingTask?.cancel()

        isProcessing = true

        processingTask = Task.detached { [weak self, adjustments, image] in
            let processed = ImageProcessor.shared.process(image: image, adjustments: adjustments)

            nonisolated(unsafe) let finalProcessed = processed

            await MainActor.run {
                guard let self = self else { return }
                self.processedImage = finalProcessed
                self.isProcessing = false
            }
        }
    }

    func resetAdjustments() {
        adjustments.reset()
        processedImage = image
    }

    func close() {
        sdkWrapper?.closeSession()
        sdkWrapper = nil
        image = nil
        exifData = nil
        imageInfo = nil
    }

    var formattedEXIF: [EXIFInfo] {
        guard let exif = exifData else { return [] }

        var items: [EXIFInfo] = []

        // Camera Info
        if let make = exif.make {
            items.append(EXIFInfo(label: "Make", value: make))
        }
        if let model = exif.model {
            items.append(EXIFInfo(label: "Model", value: model))
        }

        // Lens Info
        if let lens = exif.lensInfo, !lens.isEmpty {
            items.append(EXIFInfo(label: "Lens", value: lens))
        }

        // Image Info
        if let info = imageInfo {
            items.append(EXIFInfo(label: "Dimensions", value: "\(info.width) × \(info.height)"))
            items.append(EXIFInfo(label: "Bit Depth", value: "\(info.byteDepth * 8) bit"))

            // Orientation
            let orientations = ["Unknown", "Normal", "Flip Horizontal", "Rotate 180°", "Flip Vertical", "Transpose", "Rotate 90° CW", "Transverse", "Rotate 90° CCW"]
            if info.orientation < orientations.count {
                items.append(EXIFInfo(label: "Orientation", value: orientations[Int(info.orientation)]))
            }

            // Resolution
            if info.resolution > 0 {
                items.append(EXIFInfo(label: "Resolution", value: String(format: "%.0f DPI", info.resolution)))
            }

            // Color Type
            let colorTypes = ["Unknown", "Grayscale", "RGB", "CMYK"]
            if info.colorType < colorTypes.count {
                items.append(EXIFInfo(label: "Color Type", value: colorTypes[Int(info.colorType)]))
            }
        }

        // Exposure
        if exif.exposureTime > 0 {
            let exposure = exif.exposureTime >= 1 ? String(format: "%.1f s", exif.exposureTime) :
                          String(format: "1/%.0f s", 1.0 / exif.exposureTime)
            items.append(EXIFInfo(label: "Shutter Speed", value: exposure))
        }

        if exif.fNumber > 0 {
            items.append(EXIFInfo(label: "Aperture", value: String(format: "f/%.1f", exif.fNumber)))
        }

        if exif.iso > 0 {
            items.append(EXIFInfo(label: "ISO", value: "\(exif.iso)"))
        }

        if exif.focalLength > 0 {
            items.append(EXIFInfo(label: "Focal Length", value: String(format: "%.0f mm", exif.focalLength)))
        }

        if exif.exposureBias != 0 {
            items.append(EXIFInfo(label: "Exposure Bias", value: String(format: "%+.1f EV", exif.exposureBias)))
        }

        // Metering Mode
        let meteringModes = ["Unknown", "Average", "Center-weighted", "Spot", "Multi-spot", "Pattern", "Partial"]
        if exif.meteringMode < meteringModes.count {
            items.append(EXIFInfo(label: "Metering", value: meteringModes[Int(exif.meteringMode)]))
        }

        // Exposure Program
        let programs = ["Unknown", "Manual", "Program", "Aperture Priority", "Shutter Priority", "Creative", "Action", "Portrait", "Landscape"]
        if exif.exposureProgram < programs.count {
            items.append(EXIFInfo(label: "Program", value: programs[Int(exif.exposureProgram)]))
        }

        // White Balance
        let wbModes = ["Auto", "Incandescent", "Fluorescent", "Sunlight", "Flash", "Shade", "Cloudy", "Preset"]
        if exif.whiteBalance < wbModes.count {
            items.append(EXIFInfo(label: "White Balance", value: wbModes[Int(exif.whiteBalance)]))
        }

        // Flash
        let flashValue = exif.flash
        var flashStatus = "Unknown"
        if flashValue == 0 {
            flashStatus = "Did not fire"
        } else if flashValue & 0x1 != 0 {
            flashStatus = "Fired"
            if flashValue & 0x8 != 0 {
                flashStatus += ", Auto"
            }
            if flashValue & 0x40 != 0 {
                flashStatus += ", Red-eye"
            }
        }
        items.append(EXIFInfo(label: "Flash", value: flashStatus))

        // Advanced Settings
        // File Format
        let fileFormats = ["Unknown", "NEF", "TIFF", "JPEG", "NRW"]
        if exif.fileFormat < fileFormats.count && exif.fileFormat > 0 {
            items.append(EXIFInfo(label: "File Format", value: fileFormats[Int(exif.fileFormat)]))
        }

        // Picture Control
        let pictureControls = ["Standard", "Neutral", "Vivid", "Monochrome", "Portrait", "Landscape", "Flat"]
        if exif.pictureControl < pictureControls.count {
            items.append(EXIFInfo(label: "Picture Control", value: pictureControls[Int(exif.pictureControl)]))
        }

        // Active D-Lighting
        let dLightingModes = ["Off", "Low", "Normal", "High", "Extra High", "Auto"]
        if exif.activeDLighting < dLightingModes.count {
            items.append(EXIFInfo(label: "Active D-Lighting", value: dLightingModes[Int(exif.activeDLighting)]))
        }

        // Noise Reduction
        let nrModes = ["Off", "Low", "Normal", "High"]
        if exif.noiseReduction < nrModes.count {
            items.append(EXIFInfo(label: "Noise Reduction", value: nrModes[Int(exif.noiseReduction)]))
        }

        // Date
        if let date = exif.dateTime {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            items.append(EXIFInfo(label: "Date", value: formatter.string(from: date)))
        }

        // Software
        if let software = exif.software, !software.isEmpty {
            items.append(EXIFInfo(label: "Software", value: software))
        }

        // Artist
        if let artist = exif.artist, !artist.isEmpty {
            items.append(EXIFInfo(label: "Artist", value: artist))
        }

        // Copyright
        if let copyright = exif.copyright, !copyright.isEmpty {
            items.append(EXIFInfo(label: "Copyright", value: copyright))
        }

        return items
    }

    var shootingDataStrings: [String] {
        return exifData?.shootingData as? [String] ?? []
    }
}
