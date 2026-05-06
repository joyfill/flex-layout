import XCTest
import SwiftUI
@testable import JoyDOM

/// Pins the contract that `VisualStyle.fontFamily` produces a SwiftUI
/// `Font.custom(...)` rather than `Font.system(...)`, and that the
/// absence of a fontFamily falls back to system. The actual `applyVisual`
/// path runs the same construction via `JoyDOMView.font(for:)` so testing
/// the helper is equivalent to testing the modifier branch.
///
/// Font is opaque from outside SwiftUI — there's no public API to ask
/// "which descriptor does this font hold?" — so we lean on the textual
/// description, which differs between `.custom` and `.system`. This is
/// brittle by SwiftUI standards but stable within an SDK release.
final class FontFamilyTests: XCTestCase {

    func testCustomFontFamilyProducesNonNilFont() {
        var v = VisualStyle()
        v.fontFamily = "Helvetica Neue"
        v.fontSize   = 16
        let font = JoyDOMView.font(for: v)
        XCTAssertNotNil(font, "non-empty typography should produce a Font")
    }

    func testCustomFontFamilyDiffersFromSystemFont() {
        // Font is opaque from outside SwiftUI — there's no public API to
        // ask "which descriptor does this hold?" — so we lean on Font's
        // own Equatable: a `.custom(...)` font and a `.system(...)` font
        // at the same size MUST not compare equal. That's a stable signal
        // and doesn't depend on SwiftUI's stringification format (which
        // can shift between Xcode releases without an actual regression).
        var custom = VisualStyle()
        custom.fontFamily = "Helvetica Neue"
        custom.fontSize   = 16

        var system = VisualStyle()
        system.fontSize = 16

        XCTAssertNotEqual(JoyDOMView.font(for: custom),
                          JoyDOMView.font(for: system),
                          "custom and system fonts must produce different Font values")
    }

    func testSystemFallbackWhenFontFamilyAbsent() {
        // No fontFamily set → helper falls through to .system(size:). Pin
        // the contract via Font Equatable: the result must equal the
        // explicit Font.system(size:) we'd construct ourselves.
        var v = VisualStyle()
        v.fontSize = 14
        XCTAssertEqual(JoyDOMView.font(for: v), .system(size: 14),
                       "absent fontFamily must yield Font.system(size:)")
    }

    func testEmptyVisualStyleProducesNoFont() {
        // No typography fields set → helper returns nil so applyVisual
        // skips the .font(...) modifier entirely.
        let v = VisualStyle()
        XCTAssertNil(JoyDOMView.font(for: v))
    }

    func testFontStyleItalicCarriesThrough() {
        // The helper should embed italic when fontStyle == .italic. The
        // Font value is opaque, so we just assert non-nil + that the
        // helper doesn't crash for the italic + custom-family combo.
        var v = VisualStyle()
        v.fontFamily = "Helvetica Neue"
        v.fontSize   = 18
        v.fontStyle  = .italic
        XCTAssertNotNil(JoyDOMView.font(for: v))
    }

    func testNumericFontWeightCarriesThrough() {
        // Pin the integration with swiftFontWeight: a numeric weight
        // does not crash and produces a non-nil Font.
        var v = VisualStyle()
        v.fontSize   = 16
        v.fontWeight = .numeric(700)
        XCTAssertNotNil(JoyDOMView.font(for: v))
    }
}
