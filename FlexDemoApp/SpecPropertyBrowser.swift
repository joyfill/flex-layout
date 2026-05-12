// SpecPropertyBrowser — sidebar-driven playground over every property
// sample shipped in the `JoyDOMSampleSpecs` target. Picking a row in
// the sidebar loads the sample JSON into an editable `TextEditor`;
// every keystroke re-decodes the text and live-updates the preview.
// On decode failure the last valid spec keeps rendering and an error
// banner surfaces the parse error so the preview never flashes empty
// between edits.
//
// Mirrors the visual style of `JoyDOMPasteDemo` for the viewport
// slider so the two modes feel familiar.

import SwiftUI
import JoyDOM
import JoyDOMSampleSpecs

#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

struct SpecPropertyBrowser: View {

    // MARK: - Owned state

    @State private var selectedSampleID: String =
        SpecPropertySamples.all.first?.id ?? ""
    @State private var simulatedWidth: CGFloat = 800

    /// Editable JSON the preview re-decodes on every change.
    @State private var jsonText: String =
        SpecPropertySamples.all.first?.json ?? ""

    /// Last successfully-decoded `Spec`. Holds the preview steady while
    /// the editor contains a transient parse error mid-keystroke.
    @State private var lastValidSpec: Spec? = {
        guard let json = SpecPropertySamples.all.first?.json,
              let spec = try? JSONDecoder().decode(Spec.self, from: Data(json.utf8))
        else { return nil }
        return spec
    }()

    /// `nil` when `jsonText` parses cleanly; otherwise the most recent
    /// decoder error's `localizedDescription`.
    @State private var decodeError: String? = nil

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
            VStack(alignment: .leading, spacing: 16) {
                header(for: sample)
                Divider()
                widthSlider
                Divider()
                preview(for: sample)
                    .frame(maxHeight: .infinity)
                editor(for: sample)
                    .frame(maxHeight: .infinity)
                if let decodeError {
                    errorBanner(decodeError)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .onChange(of: selectedSampleID) { _ in
                // Reset the editor whenever the user navigates to a
                // different template — the previous edits stay scoped
                // to the previous sample.
                jsonText = sample.json
                decodeOrSurfaceError(jsonText)
            }
            .onChange(of: jsonText) { newValue in
                decodeOrSurfaceError(newValue)
            }
            .onAppear {
                // Bootstrap `lastValidSpec` for samples loaded after
                // first render (e.g. when the app launches with a
                // selection that differs from the initial state).
                if lastValidSpec == nil {
                    decodeOrSurfaceError(jsonText)
                }
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
            ScrollView {
                if let spec = lastValidSpec {
                    JoyDOMView(spec: spec)
                        .viewport(viewport)
                        .onEvent("*") { _ in }
                        .frame(maxWidth: max(40, viewport.width), alignment: .topLeading)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                } else {
                    Text("(failed to decode \(sample.id))")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, minHeight: 80)
                }
            }
            .background(Color(white: 0.96))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.gray.opacity(0.25))
            )
        }
    }

    @ViewBuilder
    private func editor(for sample: SpecPropertySample) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Text("JSON")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Button("Reset to template") {
                    jsonText = sample.json
                    decodeOrSurfaceError(jsonText)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                Button("Copy") {
                    copyToPasteboard(jsonText)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                Spacer()
                if decodeError == nil {
                    Text("valid")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.green)
                } else {
                    Text("invalid")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.red)
                }
            }

            JSONCodeEditor(text: $jsonText)
                .frame(minHeight: 240, maxHeight: .infinity)
                .padding(6)
                .background(Color(white: 0.97))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            decodeError == nil
                                ? Color.gray.opacity(0.25)
                                : Color.red.opacity(0.55)
                        )
                )
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("Decode error:")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.red)
            Text(message)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.red.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .padding(10)
        .background(Color.red.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.red.opacity(0.35))
        )
    }

    // MARK: - Helpers

    /// Try to decode `text` as a `Spec`. On success refresh
    /// `lastValidSpec` and clear any banner; on failure keep the
    /// previously rendered spec and surface the error.
    private func decodeOrSurfaceError(_ text: String) {
        do {
            let spec = try JSONDecoder().decode(Spec.self, from: Data(text.utf8))
            lastValidSpec = spec
            decodeError = nil
        } catch {
            decodeError = error.localizedDescription
        }
    }

    private func copyToPasteboard(_ s: String) {
        #if canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(s, forType: .string)
        #elseif canImport(UIKit)
        UIPasteboard.general.string = s
        #endif
    }
}

private struct BrowserRow: View {
    let sample: SpecPropertySample
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            // Overview rows render flush; variant rows shift right and
            // show a small leader so multiple test cases under the same
            // property group visually instead of looking like duplicates.
            if sample.variantLabel != nil {
                Text("↳")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(isSelected ? .white.opacity(0.6) : .secondary)
                    .padding(.leading, 12)
                    .padding(.top, 2)
            }
            VStack(alignment: .leading, spacing: 1) {
                if let variant = sample.variantLabel {
                    Text(variant)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(isSelected ? .white : .primary)
                } else {
                    Text(sample.property)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(isSelected ? .white : .primary)
                }
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

// MARK: - JSON code editor (smart-substitutions-off)
//
// SwiftUI's `TextEditor` inherits NSTextView (macOS) and UITextView
// (iOS) defaults that auto-replace straight quotes with curly quotes
// (`"` → `"` `"`), straight dashes with em-dashes, and apply other
// "smart" substitutions that break JSON the moment a user edits it.
//
// `JSONCodeEditor` is a platform-thin wrapper around the native text
// view with every auto-substitution turned off, autocorrect / spell-
// check disabled, and a monospaced font set. Used in place of
// `TextEditor` for the JSON pane.

private struct JSONCodeEditor: View {
    @Binding var text: String

    var body: some View {
        #if canImport(AppKit)
        NSTextViewRepresentable(text: $text)
        #elseif canImport(UIKit)
        UITextViewRepresentable(text: $text)
        #else
        // Fallback for platforms without AppKit/UIKit — we accept the
        // smart-substitution risk because there's no native text view
        // to configure.
        TextEditor(text: $text)
            .font(.system(.caption, design: .monospaced))
            .autocorrectionDisabled(true)
        #endif
    }
}

#if canImport(AppKit)
private struct NSTextViewRepresentable: NSViewRepresentable {
    @Binding var text: String

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        // The whole point of this wrapper — disable every auto
        // substitution that could mangle JSON.
        textView.isAutomaticQuoteSubstitutionEnabled  = false
        textView.isAutomaticDashSubstitutionEnabled   = false
        textView.isAutomaticTextReplacementEnabled    = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticDataDetectionEnabled      = false
        textView.isAutomaticLinkDetectionEnabled      = false
        textView.smartInsertDeleteEnabled             = false
        textView.isRichText                           = false
        textView.allowsUndo                           = true
        textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.delegate = context.coordinator
        textView.string = text
        textView.textContainerInset = NSSize(width: 4, height: 4)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if textView.string != text {
            // Programmatic update from the Reset button — replace
            // contents preserving the user's caret position only if
            // valid; otherwise reset to start.
            textView.string = text
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NSTextViewRepresentable
        init(_ parent: NSTextViewRepresentable) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}
#endif

#if canImport(UIKit)
private struct UITextViewRepresentable: UIViewRepresentable {
    @Binding var text: String

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        // Disable iOS keyboard's smart substitutions + autocorrect.
        textView.autocapitalizationType   = .none
        textView.autocorrectionType       = .no
        textView.smartQuotesType          = .no
        textView.smartDashesType          = .no
        textView.smartInsertDeleteType    = .no
        textView.spellCheckingType        = .no
        textView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.delegate = context.coordinator
        textView.text = text
        textView.isEditable = true
        textView.isScrollEnabled = true
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        if textView.text != text {
            textView.text = text
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: UITextViewRepresentable
        init(_ parent: UITextViewRepresentable) { self.parent = parent }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
    }
}
#endif
