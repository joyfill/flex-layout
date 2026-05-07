// SpecPropertyBrowser — sidebar-driven browser over every property
// sample shipped in the `JoyDOMSampleSpecs` target. Picking a row in
// the sidebar decodes the sample JSON, renders it through
// `JoyDOMView` at the simulated viewport width, and exposes the raw
// JSON in a collapsible disclosure for copy / inspection.
//
// Mirrors the visual style of `JoyDOMPasteDemo` for the viewport
// slider so the two modes feel familiar.

import SwiftUI
import JoyDOM
import JoyDOMSampleSpecs

struct SpecPropertyBrowser: View {

    // MARK: - Owned state

    @State private var selectedSampleID: String =
        SpecPropertySamples.all.first?.id ?? ""
    @State private var simulatedWidth: CGFloat = 600
    @State private var showJSON: Bool = false

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 260)
                .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            detail
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(Color(nsColor: .windowBackgroundColor))
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Spec Properties")
                .font(.title3.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.top, 16)
                .padding(.bottom, 6)
            Text("\(SpecPropertySamples.all.count) samples · \(SpecPropertySamples.byCategory.count) categories")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.bottom, 10)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(SpecPropertySamples.byCategory, id: \.category) { bucket in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(bucket.category.uppercased())
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.top, 4)
                            ForEach(bucket.samples) { sample in
                                BrowserRow(
                                    sample: sample,
                                    isSelected: selectedSampleID == sample.id
                                )
                                .onTapGesture { selectedSampleID = sample.id }
                            }
                        }
                    }
                }
                .padding(8)
            }
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detail: some View {
        if let sample = SpecPropertySamples.sample(withID: selectedSampleID) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header(for: sample)
                    Divider()
                    widthSlider
                    Divider()
                    preview(for: sample)
                    jsonDisclosure(for: sample)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            Text("Pick a sample from the sidebar.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func header(for sample: SpecPropertySample) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(sample.property)
                .font(.title2.weight(.semibold))
            HStack(spacing: 6) {
                Text(sample.category)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Text("·")
                    .foregroundStyle(.secondary)
                Text(sample.id)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
            Text(sample.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var widthSlider: some View {
        HStack(spacing: 12) {
            Text("Viewport width")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 110, alignment: .leading)
            Slider(value: $simulatedWidth, in: 200...1400, step: 1)
            Text("\(Int(simulatedWidth))px")
                .font(.system(.caption, design: .monospaced))
                .frame(width: 70, alignment: .trailing)
        }
    }

    @ViewBuilder
    private func preview(for sample: SpecPropertySample) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Preview")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            let viewport = Viewport(width: simulatedWidth)
            if let spec = decode(sample.json) {
                JoyDOMView(spec: spec)
                    .viewport(viewport)
                    .onEvent("*") { _ in }
                    .frame(maxWidth: max(40, viewport.width), alignment: .topLeading)
                    .padding(12)
                    .background(Color(white: 0.96))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.gray.opacity(0.25))
                    )
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            } else {
                Text("(failed to decode \(sample.id))")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .background(Color(white: 0.96))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private func jsonDisclosure(for sample: SpecPropertySample) -> some View {
        DisclosureGroup(isExpanded: $showJSON) {
            ScrollView(.horizontal) {
                Text(sample.json)
                    .font(.system(.caption, design: .monospaced))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(white: 0.97))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.gray.opacity(0.25))
            )
        } label: {
            Text("Show JSON")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private func decode(_ json: String) -> Spec? {
        try? JSONDecoder().decode(Spec.self, from: Data(json.utf8))
    }
}

private struct BrowserRow: View {
    let sample: SpecPropertySample
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(sample.property)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(isSelected ? .white : .primary)
                Text(sample.summary)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .white.opacity(0.85) : .secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
    }
}
