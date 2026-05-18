// FontRegistry — registers the JoyDOM bundled fonts (Geist, Geist Mono,
// Libre Baskerville) with CoreText so SwiftUI's `Font.custom(...)` can
// resolve them by family name.
//
// JoyDOM ships these fonts in `Resources/fonts/` for cross-runtime
// visual parity with the joy-dom JS runtime, which renders fontFamily
// samples against the same fixture fonts. Without registration, macOS
// + iOS would fall back to the host system font and JoyDOM snapshots
// would diverge from joy-dom's reference renders.
//
// Registration is idempotent (a guard `registered` flag + an `NSLock`
// for thread safety) — snapshot test suites can call `registerIfNeeded()`
// from `setUp()` on every test without paying repeated CoreText cost.
//
// FontRegistry lives in the `JoyDOMSampleSpecs` target rather than
// `JoyDOM` because that's where the font binaries ship — JoyDOM itself
// has no test fixture awareness — and because SwiftPM forbids the
// reverse dependency (`JoyDOMSampleSpecs` already depends on `JoyDOM`).

import Foundation
import CoreText

/// Registers bundled fonts with CoreText on first call. Safe to invoke
/// repeatedly: subsequent calls are no-ops.
public enum FontRegistry {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var registered = false

    /// Variable-font files shipped in `Resources/fonts/`. The `[wght]`
    /// suffix is the OpenType axis tag — kept intact in the filename
    /// because that's how the upstream Geist + Libre Baskerville releases
    /// distribute their variable fonts.
    private static let fontFiles: [(name: String, ext: String)] = [
        ("Geist[wght]", "woff2"),
        ("Geist-Italic[wght]", "woff2"),
        ("GeistMono[wght]", "woff2"),
        ("GeistMono-Italic[wght]", "woff2"),
        ("LibreBaskerville-VariableFont_wght", "ttf"),
        ("LibreBaskerville-Italic-VariableFont_wght", "ttf"),
    ]

    /// Registers all bundled fonts on first invocation. Subsequent
    /// invocations short-circuit on the `registered` guard. Failures are
    /// logged but non-fatal — tests that depend on a specific family
    /// will show the regression via baseline diffs.
    public static func registerIfNeeded() {
        lock.lock()
        defer { lock.unlock() }
        guard !registered else { return }

        let bundle = JoyDOMSampleSpecsBundle.bundle
        for entry in fontFiles {
            // `.copy("Resources")` preserves the subdirectory layout in
            // Bundle.module, so we must pass `subdirectory: "fonts"` to
            // resolve the URL — a top-level lookup would miss.
            guard let url = bundle.url(
                forResource: entry.name,
                withExtension: entry.ext,
                subdirectory: "fonts"
            ) else {
                print("[FontRegistry] missing bundled font: \(entry.name).\(entry.ext)")
                continue
            }
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                let message = (error?.takeRetainedValue() as Error?)?.localizedDescription
                    ?? "unknown CoreText error"
                print("[FontRegistry] failed to register \(entry.name): \(message)")
            }
        }
        registered = true
    }
}
