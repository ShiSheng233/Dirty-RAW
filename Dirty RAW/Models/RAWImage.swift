//
//  RAWImage.swift
//  Dirty RAW
//

import SwiftUI
import AppKit

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

            let wrapper = NikonSDKWrapper(filePath: url.path)
            guard let wrapper = wrapper else {
                await MainActor.run {
                    self.error = "Failed to open file"
                    self.isLoading = false
                }
                return
            }

            nonisolated(unsafe) let image = wrapper.decodeToImage()
            nonisolated(unsafe) let exif = wrapper.getEXIFData()
            nonisolated(unsafe) let info = wrapper.getImageInfo()

            // Generate thumbnail
            var thumb: NSImage?
            if let img = image {
                let thumbSize: CGFloat = 80
                let ratio = min(thumbSize / img.size.width, thumbSize / img.size.height)
                let newSize = NSSize(width: img.size.width * ratio, height: img.size.height * ratio)
                thumb = NSImage(size: newSize)
                thumb?.lockFocus()
                img.draw(in: NSRect(origin: .zero, size: newSize))
                thumb?.unlockFocus()
            }

            await MainActor.run {
                self.sdkWrapper = wrapper
                self.image = image
                self.processedImage = image
                self.thumbnail = thumb
                self.exifData = exif
                self.imageInfo = info
                self.isLoading = false
            }
        }
    }

    func applyAdjustments() {
        guard let image = image else { return }

        // Cancel previous processing
        processingTask?.cancel()

        isProcessing = true

        processingTask = Task.detached { [weak self, adjustments] in
            let processed = ImageProcessor.shared.process(image: image, adjustments: adjustments)

            await MainActor.run {
                guard let self = self else { return }
                self.processedImage = processed
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
