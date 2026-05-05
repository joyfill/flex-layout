import XCTest
import SwiftUI
import CoreGraphics
@testable import JoyDOM

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Cover the Phase 2.3 line-height refinement — `lineSpacing` is now the
/// extra leading on top of the platform font's natural line height, not
/// just `fontSize × (lh − 1)`. Tests verify the formula stays
/// non-negative and matches the platform-specific system font metrics so
/// a refactor can't silently regress to the old approximation.
final class LineHeightTests: XCTestCase {

    func testLineSpacingIsNonNegative() {
        // Even when the requested line-height is below the system's
        // natural leading the formula must clamp to zero — never feed
        // SwiftUI a negative `lineSpacing`.
        let spacing = JoyDOMView.lineSpacing(forLineHeight: 0.5, fontSize: 16)
        XCTAssertGreaterThanOrEqual(spacing, 0)
    }

    func testLineSpacingMatchesTargetMinusSystem() {
        // Compute the expected system metric here directly — duplicating
        // the production formula in a helper would mask drift if it
        // regressed (e.g. back to NSFont.boundingRectForFont.height).
        let fontSize: CGFloat = 16
        let lh: Double = 1.5
        #if canImport(UIKit)
        let systemMetric = UIFont.systemFont(ofSize: fontSize).lineHeight
        #elseif canImport(AppKit)
        let f = NSFont.systemFont(ofSize: fontSize)
        let systemMetric = f.ascender - f.descender + f.leading
        #else
        let systemMetric: CGFloat = fontSize * 1.2
        #endif
        let expected = max(0, fontSize * CGFloat(lh) - systemMetric)
        let actual = JoyDOMView.lineSpacing(forLineHeight: lh, fontSize: fontSize)
        XCTAssertEqual(actual, expected, accuracy: 0.0001)
    }

    func testLineSpacingScalesWithFontSize() {
        // A taller font with the same multiplier should yield a larger
        // (or equal) lineSpacing — the system natural line height grows
        // proportionally with size on both UIKit and AppKit.
        let small = JoyDOMView.lineSpacing(forLineHeight: 1.5, fontSize: 12)
        let large = JoyDOMView.lineSpacing(forLineHeight: 1.5, fontSize: 24)
        XCTAssertGreaterThan(large, small)
    }

    func testLineSpacingZeroForUnitMultiplier() {
        // CSS `line-height: 1` means "tight to the font's natural
        // height" — once we subtract the system leading, lineSpacing
        // should land at zero (or near it, accounting for whatever extra
        // the system font already bakes in).
        let spacing = JoyDOMView.lineSpacing(forLineHeight: 1.0, fontSize: 16)
        XCTAssertEqual(spacing, 0, accuracy: 0.0001)
    }
}
