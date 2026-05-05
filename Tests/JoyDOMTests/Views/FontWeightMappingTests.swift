import XCTest
import SwiftUI
@testable import JoyDOM

/// Pin every CSS Fonts Module Level 4 weight band boundary so a future
/// refactor can't quietly shift a numeric `font-weight` into the wrong
/// SwiftUI `Font.Weight`. Boundaries sit at the band midpoints — e.g. 449
/// is still `.regular`, 450 promotes to `.medium`.
final class FontWeightMappingTests: XCTestCase {

    // MARK: - Lower-band boundaries

    func testWeightAtAndBelow149IsUltraLight() {
        XCTAssertEqual(JoyDOMView.swiftFontWeight(forCSSWeight: 1),   .ultraLight)
        XCTAssertEqual(JoyDOMView.swiftFontWeight(forCSSWeight: 100), .ultraLight)
        XCTAssertEqual(JoyDOMView.swiftFontWeight(forCSSWeight: 149), .ultraLight)
    }

    func testWeight150To249IsThin() {
        XCTAssertEqual(JoyDOMView.swiftFontWeight(forCSSWeight: 150), .thin)
        XCTAssertEqual(JoyDOMView.swiftFontWeight(forCSSWeight: 200), .thin)
        XCTAssertEqual(JoyDOMView.swiftFontWeight(forCSSWeight: 249), .thin)
    }

    func testWeight250To349IsLight() {
        XCTAssertEqual(JoyDOMView.swiftFontWeight(forCSSWeight: 250), .light)
        XCTAssertEqual(JoyDOMView.swiftFontWeight(forCSSWeight: 300), .light)
        XCTAssertEqual(JoyDOMView.swiftFontWeight(forCSSWeight: 349), .light)
    }

    func testWeight350To449IsRegular() {
        XCTAssertEqual(JoyDOMView.swiftFontWeight(forCSSWeight: 350), .regular)
        XCTAssertEqual(JoyDOMView.swiftFontWeight(forCSSWeight: 400), .regular)
        XCTAssertEqual(JoyDOMView.swiftFontWeight(forCSSWeight: 449), .regular)
    }

    func testWeight450To549IsMedium() {
        XCTAssertEqual(JoyDOMView.swiftFontWeight(forCSSWeight: 450), .medium)
        XCTAssertEqual(JoyDOMView.swiftFontWeight(forCSSWeight: 500), .medium)
        XCTAssertEqual(JoyDOMView.swiftFontWeight(forCSSWeight: 549), .medium)
    }

    func testWeight550To649IsSemibold() {
        XCTAssertEqual(JoyDOMView.swiftFontWeight(forCSSWeight: 550), .semibold)
        XCTAssertEqual(JoyDOMView.swiftFontWeight(forCSSWeight: 600), .semibold)
        XCTAssertEqual(JoyDOMView.swiftFontWeight(forCSSWeight: 649), .semibold)
    }

    func testWeight650To749IsBold() {
        XCTAssertEqual(JoyDOMView.swiftFontWeight(forCSSWeight: 650), .bold)
        XCTAssertEqual(JoyDOMView.swiftFontWeight(forCSSWeight: 700), .bold)
        XCTAssertEqual(JoyDOMView.swiftFontWeight(forCSSWeight: 749), .bold)
    }

    func testWeight750To849IsHeavy() {
        XCTAssertEqual(JoyDOMView.swiftFontWeight(forCSSWeight: 750), .heavy)
        XCTAssertEqual(JoyDOMView.swiftFontWeight(forCSSWeight: 800), .heavy)
        XCTAssertEqual(JoyDOMView.swiftFontWeight(forCSSWeight: 849), .heavy)
    }

    func testWeight850AndAboveIsBlack() {
        XCTAssertEqual(JoyDOMView.swiftFontWeight(forCSSWeight: 850), .black)
        XCTAssertEqual(JoyDOMView.swiftFontWeight(forCSSWeight: 900), .black)
        XCTAssertEqual(JoyDOMView.swiftFontWeight(forCSSWeight: 1000), .black)
    }
}
