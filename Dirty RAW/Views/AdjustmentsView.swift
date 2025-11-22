//
//  AdjustmentsView.swift
//  Dirty RAW
//

import SwiftUI
import Combine

struct AdjustmentsView: View {
    @Binding var adjustments: ImageAdjustments
    var imageSize: NSSize?
    var onReset: () -> Void

    @State private var localAdjustments: ImageAdjustments = ImageAdjustments()
    @State private var debounceTask: Task<Void, Never>?
    @State private var expandedSections: Set<String> = ["Light", "Color", "Tone Curve", "Detail", "Noise Reduction", "Upscaling"]

    private var availableScales: (canScale1_5x: Bool, canScale2x: Bool, canScale3x: Bool) {
        guard let size = imageSize else {
            return (true, true, true)
        }
        return ImageProcessor.shared.availableUpscaleFactors(for: size)
    }

    private func updateAdjustment() {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            if !Task.isCancelled {
                await MainActor.run {
                    adjustments = localAdjustments
                }
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Reset Card
                VStack(alignment: .leading, spacing: 8) {
                    Label("Adjustments", systemImage: "slider.horizontal.3")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack {
                        Text(localAdjustments.isDefault ? "No changes" : "Modified")
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                        Spacer()
                        Button("Reset") {
                            localAdjustments.reset()
                            onReset()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(localAdjustments.isDefault)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color(.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Light Section
                CollapsibleAdjustmentCard(
                    title: "Light",
                    icon: "sun.max",
                    isExpanded: expandedSections.contains("Light"),
                    onToggle: { toggleSection("Light") }
                ) {
                    VStack(spacing: 8) {
                        AdjustmentRow(
                            label: "Exposure",
                            value: $localAdjustments.exposure,
                            range: -2.0...2.0,
                            onChange: updateAdjustment
                        )
                        AdjustmentRow(
                            label: "Contrast",
                            value: $localAdjustments.contrast,
                            range: 0.5...2.0,
                            centerValue: 1.0,
                            onChange: updateAdjustment
                        )
                        AdjustmentRow(
                            label: "Highlights",
                            value: $localAdjustments.highlights,
                            range: 0.0...2.0,
                            centerValue: 1.0,
                            onChange: updateAdjustment
                        )
                        AdjustmentRow(
                            label: "Shadows",
                            value: $localAdjustments.shadows,
                            range: -1.0...1.0,
                            onChange: updateAdjustment
                        )
                        AdjustmentRow(
                            label: "Brightness",
                            value: $localAdjustments.brightness,
                            range: -1.0...1.0,
                            onChange: updateAdjustment
                        )
                    }
                }

                // Color Section
                CollapsibleAdjustmentCard(
                    title: "Color",
                    icon: "drop.fill",
                    isExpanded: expandedSections.contains("Color"),
                    onToggle: { toggleSection("Color") }
                ) {
                    VStack(spacing: 8) {
                        AdjustmentRow(
                            label: "Temperature",
                            value: $localAdjustments.temperature,
                            range: 2000...10000,
                            centerValue: 6500,
                            onChange: updateAdjustment
                        )
                        AdjustmentRow(
                            label: "Tint",
                            value: $localAdjustments.tint,
                            range: -100...100,
                            onChange: updateAdjustment
                        )
                        AdjustmentRow(
                            label: "Hue",
                            value: $localAdjustments.hue,
                            range: -180...180,
                            onChange: updateAdjustment
                        )
                        AdjustmentRow(
                            label: "Vibrance",
                            value: $localAdjustments.vibrance,
                            range: -1.0...1.0,
                            onChange: updateAdjustment
                        )
                        AdjustmentRow(
                            label: "Saturation",
                            value: $localAdjustments.saturation,
                            range: 0.0...2.0,
                            centerValue: 1.0,
                            onChange: updateAdjustment
                        )
                    }
                }

                // Tone Curve Section
                CollapsibleAdjustmentCard(
                    title: "Tone Curve",
                    icon: "point.topleft.down.to.point.bottomright.curvepath",
                    isExpanded: expandedSections.contains("Tone Curve"),
                    onToggle: { toggleSection("Tone Curve") }
                ) {
                    VStack(spacing: 8) {
                        AdjustmentRow(
                            label: "Blacks",
                            value: $localAdjustments.toneCurveBlacks,
                            range: 0.0...0.5,
                            onChange: updateAdjustment
                        )
                        AdjustmentRow(
                            label: "Shadows",
                            value: $localAdjustments.toneCurveShadows,
                            range: 0.0...0.5,
                            centerValue: 0.25,
                            onChange: updateAdjustment
                        )
                        AdjustmentRow(
                            label: "Midtones",
                            value: $localAdjustments.toneCurveMids,
                            range: 0.25...0.75,
                            centerValue: 0.5,
                            onChange: updateAdjustment
                        )
                        AdjustmentRow(
                            label: "Highlights",
                            value: $localAdjustments.toneCurveHighlights,
                            range: 0.5...1.0,
                            centerValue: 0.75,
                            onChange: updateAdjustment
                        )
                        AdjustmentRow(
                            label: "Whites",
                            value: $localAdjustments.toneCurveWhites,
                            range: 0.5...1.0,
                            centerValue: 1.0,
                            onChange: updateAdjustment
                        )
                    }
                }

                // Detail Section
                CollapsibleAdjustmentCard(
                    title: "Detail",
                    icon: "triangle",
                    isExpanded: expandedSections.contains("Detail"),
                    onToggle: { toggleSection("Detail") }
                ) {
                    VStack(spacing: 8) {
                        AdjustmentRow(
                            label: "Sharpness",
                            value: $localAdjustments.sharpness,
                            range: 0.0...2.0,
                            onChange: updateAdjustment
                        )
                    }
                }

                // Noise Reduction Section
                CollapsibleAdjustmentCard(
                    title: "Noise Reduction",
                    icon: "circle.dotted",
                    isExpanded: expandedSections.contains("Noise Reduction"),
                    onToggle: { toggleSection("Noise Reduction") }
                ) {
                    VStack(spacing: 8) {
                        // Enable toggle
                        HStack {
                            Text("Enable")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                            Toggle("", isOn: $localAdjustments.noiseReductionEnabled)
                                .toggleStyle(.checkbox)
                                .onChange(of: localAdjustments.noiseReductionEnabled) { _, _ in
                                    updateAdjustment()
                                }
                        }

                        if localAdjustments.noiseReductionEnabled {
                            AdjustmentRow(
                                label: "Luminance",
                                value: $localAdjustments.noiseLevel,
                                range: 0.0...0.1,
                                onChange: updateAdjustment
                            )
                            AdjustmentRow(
                                label: "Detail",
                                value: $localAdjustments.noiseSharpness,
                                range: 0.0...2.0,
                                centerValue: 0.4,
                                onChange: updateAdjustment
                            )
                        }
                    }
                }

                // MetalFX Upscaling Section
                if #available(macOS 13.0, *) {
                    CollapsibleAdjustmentCard(
                        title: "Upscaling",
                        icon: "arrow.up.left.and.arrow.down.right",
                        isExpanded: expandedSections.contains("Upscaling"),
                        onToggle: { toggleSection("Upscaling") }
                    ) {
                        VStack(spacing: 8) {
                            // Enable toggle
                            HStack {
                                Text("Enable")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Toggle("", isOn: $localAdjustments.upscalingEnabled)
                                    .toggleStyle(.checkbox)
                                    .onChange(of: localAdjustments.upscalingEnabled) { _, _ in
                                        updateAdjustment()
                                    }
                            }

                            if localAdjustments.upscalingEnabled {
                                // Scale factor buttons
                                HStack {
                                    Text("Scale")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    HStack(spacing: 4) {
                                        ScaleButton(label: "1.5x", tag: 0, selection: $localAdjustments.upscaleMode, enabled: availableScales.canScale1_5x, onChange: updateAdjustment)
                                        ScaleButton(label: "2x", tag: 1, selection: $localAdjustments.upscaleMode, enabled: availableScales.canScale2x, onChange: updateAdjustment)
                                        ScaleButton(label: "3x", tag: 2, selection: $localAdjustments.upscaleMode, enabled: availableScales.canScale3x, onChange: updateAdjustment)
                                    }
                                }

                                // Warning text if options disabled
                                if !availableScales.canScale3x || !availableScales.canScale2x {
                                    Text("Some options disabled (image too large)")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            
                            // MetalFX badge
                            HStack(spacing: 4) {
                                Image(systemName: "apple.logo")
                                    .font(.caption2)
                                Text("MetalFX")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .padding(12)
        }
        .onAppear {
            localAdjustments = adjustments
        }
        .onChange(of: adjustments.isDefault) { _, isDefault in
            if isDefault {
                localAdjustments = adjustments
            }
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
}

// MARK: - Collapsible Card

struct CollapsibleAdjustmentCard<Content: View>: View {
    let title: String
    let icon: String
    let isExpanded: Bool
    let onToggle: () -> Void
    @ViewBuilder let content: Content

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

                content
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
            }
        }
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Adjustment Row

struct AdjustmentRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var centerValue: Double = 0.0
    var onChange: (() -> Void)?

    private var displayValue: String {
        if range.upperBound > 100 {
            return String(format: "%.0f", value)
        } else if range.upperBound <= 2 {
            let normalized = (value - centerValue) * 100 / max(range.upperBound - centerValue, 0.001)
            return String(format: "%+.0f", normalized)
        } else {
            return String(format: "%+.0f", value)
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(displayValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            Slider(value: $value, in: range)
                .controlSize(.small)
                .onChange(of: value) { _, _ in
                    onChange?()
                }
        }
        .onTapGesture(count: 2) {
            value = centerValue
            onChange?()
        }
    }
}

// MARK: - Scale Button

struct ScaleButton: View {
    let label: String
    let tag: Int
    @Binding var selection: Int
    let enabled: Bool
    var onChange: (() -> Void)?

    var body: some View {
        Button(action: {
            selection = tag
            onChange?()
        }) {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(selection == tag ? Color.accentColor : Color.secondary.opacity(0.2))
                .foregroundColor(selection == tag ? .white : (enabled ? .primary : .secondary))
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1.0 : 0.4)
    }
}

#Preview {
    AdjustmentsView(adjustments: .constant(ImageAdjustments()), imageSize: NSSize(width: 8256, height: 5504), onReset: {})
        .frame(width: 280, height: 600)
}
