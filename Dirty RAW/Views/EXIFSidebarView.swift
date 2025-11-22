//
//  EXIFSidebarView.swift
//  Dirty RAW
//

import SwiftUI

struct EXIFSidebarView: View {
    @ObservedObject var rawImage: RAWImage
    @State private var expandedSections: Set<String> = ["Camera", "Exposure", "Image", "Metadata", "Advanced", "Shooting Data"]

    init(rawImage: RAWImage?) {
        self._rawImage = ObservedObject(wrappedValue: rawImage ?? RAWImage(url: URL(fileURLWithPath: "/")))
    }

    var body: some View {
        if rawImage.url.path != "/" {
            ScrollView {
                VStack(spacing: 12) {
                    // File Name Card
                    VStack(alignment: .leading, spacing: 8) {
                        Label("File", systemImage: "doc.text")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(rawImage.fileName)
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                            .lineLimit(2)
                            .truncationMode(.middle)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // Camera & Exposure Info
                    if !rawImage.formattedEXIF.isEmpty {
                        let cameraInfo = groupedEXIFData.camera
                        let exposureInfo = groupedEXIFData.exposure
                        let imageInfo = groupedEXIFData.image
                        let metaInfo = groupedEXIFData.meta
                        let advancedInfo = groupedEXIFData.advanced

                        if !cameraInfo.isEmpty {
                            CollapsibleEXIFCard(
                                title: "Camera",
                                icon: "camera",
                                items: cameraInfo,
                                isExpanded: expandedSections.contains("Camera"),
                                onToggle: { toggleSection("Camera") }
                            )
                        }

                        if !exposureInfo.isEmpty {
                            CollapsibleEXIFCard(
                                title: "Exposure",
                                icon: "circle.lefthalf.filled",
                                items: exposureInfo,
                                isExpanded: expandedSections.contains("Exposure"),
                                onToggle: { toggleSection("Exposure") }
                            )
                        }

                        if !imageInfo.isEmpty {
                            CollapsibleEXIFCard(
                                title: "Image",
                                icon: "photo",
                                items: imageInfo,
                                isExpanded: expandedSections.contains("Image"),
                                onToggle: { toggleSection("Image") }
                            )
                        }

                        if !advancedInfo.isEmpty {
                            CollapsibleEXIFCard(
                                title: "Advanced",
                                icon: "gearshape",
                                items: advancedInfo,
                                isExpanded: expandedSections.contains("Advanced"),
                                onToggle: { toggleSection("Advanced") }
                            )
                        }

                        if !metaInfo.isEmpty {
                            CollapsibleEXIFCard(
                                title: "Metadata",
                                icon: "info.circle",
                                items: metaInfo,
                                isExpanded: expandedSections.contains("Metadata"),
                                onToggle: { toggleSection("Metadata") }
                            )
                        }
                    }

                    // Shooting Data Section
                    if !rawImage.shootingDataStrings.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            Button(action: { toggleSection("Shooting Data") }) {
                                HStack {
                                    Label("Shooting Data", systemImage: "list.bullet.rectangle")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Image(systemName: expandedSections.contains("Shooting Data") ? "chevron.down" : "chevron.right")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            if expandedSections.contains("Shooting Data") {
                                Divider()

                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(rawImage.shootingDataStrings, id: \.self) { line in
                                        Text(line)
                                            .font(.system(.caption2, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(12)
                            }
                        }
                        .background(Color(.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(12)
            }
        } else {
            VStack(spacing: 12) {
                Image(systemName: "info.circle")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("No Image Loaded")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text("Open a file to view EXIF data")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private func toggleSection(_ section: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedSections.contains(section) {
                expandedSections.remove(section)
            } else {
                expandedSections.insert(section)
            }
        }
    }

    private var groupedEXIFData: (camera: [EXIFInfo], exposure: [EXIFInfo], image: [EXIFInfo], meta: [EXIFInfo], advanced: [EXIFInfo]) {
        let cameraKeys = ["Make", "Model", "Lens"]
        let exposureKeys = ["Shutter Speed", "Aperture", "ISO", "Focal Length", "Exposure Bias", "Metering", "Program", "White Balance", "Flash"]
        let imageKeys = ["Dimensions", "Bit Depth", "Orientation", "Resolution", "Color Type"]
        let advancedKeys = ["File Format", "Picture Control", "Active D-Lighting", "Noise Reduction"]

        var camera: [EXIFInfo] = []
        var exposure: [EXIFInfo] = []
        var image: [EXIFInfo] = []
        var meta: [EXIFInfo] = []
        var advanced: [EXIFInfo] = []

        for item in rawImage.formattedEXIF {
            if cameraKeys.contains(item.label) {
                camera.append(item)
            } else if exposureKeys.contains(item.label) {
                exposure.append(item)
            } else if imageKeys.contains(item.label) {
                image.append(item)
            } else if advancedKeys.contains(item.label) {
                advanced.append(item)
            } else {
                meta.append(item)
            }
        }

        return (camera, exposure, image, meta, advanced)
    }
}

struct CollapsibleEXIFCard: View {
    let title: String
    let icon: String
    let items: [EXIFInfo]
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onToggle) {
                HStack {
                    Label(title, systemImage: icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()

                VStack(spacing: 8) {
                    ForEach(items) { item in
                        EXIFRow(label: item.label, value: item.value)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            }
        }
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct EXIFRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

#Preview {
    EXIFSidebarView(rawImage: nil)
        .frame(width: 250)
}
