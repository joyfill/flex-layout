import XCTest
import SwiftUI
@testable import FlexLayout

/// Tests for true CSS flex-item margin in the FlexLayout engine.
/// Margin reduces the space available to the item's content box and
/// offsets the rendered frame by the start margin (no `.padding()`
/// shim on the SwiftUI side anymore).
final class FlexMarginTests: XCTestCase {

    private let ε: CGFloat = 0.5

    private func solve(
        _ inputs: [FlexItemInput],
        in containerSize: CGSize,
        config: FlexContainerConfig = .init(direction: .row, alignItems: .flexStart)
    ) -> [CGRect] {
        FlexEngine.solve(
            config:   config,
            inputs:   inputs,
            proposal: ProposedViewSize(width: containerSize.width, height: containerSize.height)
        ).frames
    }

    // MARK: - uniform margin in a row container

    func testUniformMarginShrinksRowAndShiftsOrigin() {
        // 100-wide container with one grow item that has uniform margin 10.
        // Effective frame width = 100 - 20 = 80; x offset = 10.
        let item = FlexItemInput(
            measure:        { _ in CGSize(width: 0, height: 20) },
            grow:           1,
            shrink:         1,
            basis:          .points(0),
            explicitHeight: .points(20),
            margin:         EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        )
        let frames = solve([item], in: CGSize(width: 100, height: 100))
        XCTAssertEqual(frames[0].minX,   10, accuracy: ε)
        XCTAssertEqual(frames[0].minY,   10, accuracy: ε)
        XCTAssertEqual(frames[0].width,  80, accuracy: ε)
        XCTAssertEqual(frames[0].height, 20, accuracy: ε)
    }

    // MARK: - per-side asymmetric margin

    func testAsymmetricMarginShiftsOnlySpecifiedSides() {
        // margin: { top: 4, leading: 12, bottom: 8, trailing: 16 }
        // in a 200-wide row container with a fixed-size 50×20 item.
        // The free main-axis space goes after the item (justify: flex-start).
        // Item x = leading margin = 12; width remains 50; y = top margin = 4.
        let item = FlexItemInput(
            measure: { _ in CGSize(width: 50, height: 20) },
            shrink:  0,
            margin:  EdgeInsets(top: 4, leading: 12, bottom: 8, trailing: 16)
        )
        let frames = solve(
            [item],
            in: CGSize(width: 200, height: 100),
            config: .init(direction: .row, alignItems: .flexStart)
        )
        XCTAssertEqual(frames[0].minX,  12, accuracy: ε)
        XCTAssertEqual(frames[0].minY,   4, accuracy: ε)
        XCTAssertEqual(frames[0].width, 50, accuracy: ε)
    }

    // MARK: - margin between two items

    func testMarginBetweenSiblingsAccumulates() {
        // Two 50-wide items in a row. The first has trailing margin 10;
        // the second has leading margin 20. Expected gap between them = 30.
        let a = FlexItemInput(
            measure: { _ in CGSize(width: 50, height: 20) },
            shrink:  0,
            margin:  EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10)
        )
        let b = FlexItemInput(
            measure: { _ in CGSize(width: 50, height: 20) },
            shrink:  0,
            margin:  EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 0)
        )
        let frames = solve([a, b], in: CGSize(width: 400, height: 50))
        XCTAssertEqual(frames[0].minX,   0, accuracy: ε)
        XCTAssertEqual(frames[0].width, 50, accuracy: ε)
        // a ends at 50; trailing 10 + leading 20 = 30 gap before b.
        XCTAssertEqual(frames[1].minX,  80, accuracy: ε)
        XCTAssertEqual(frames[1].width, 50, accuracy: ε)
    }

    // MARK: - margin + container padding compose correctly

    func testMarginPlusContainerPaddingCompose() {
        // 100×60 container with padding 10 on every side and a single grow
        // item with margin 5 on every side. Inner area = 80×40; the item's
        // outer box fills the inner area, so its content frame starts at
        // padding(10) + margin(5) = 15 and is sized 80 - 10 = 70 wide.
        let item = FlexItemInput(
            measure:        { _ in CGSize(width: 0, height: 0) },
            grow:           1,
            shrink:         1,
            basis:          .points(0),
            margin:         EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
        )
        let frames = solve(
            [item],
            in: CGSize(width: 100, height: 60),
            config: .init(
                direction:  .row,
                alignItems: .stretch,
                padding:    EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
            )
        )
        XCTAssertEqual(frames[0].minX,  15, accuracy: ε)
        XCTAssertEqual(frames[0].minY,  15, accuracy: ε)
        XCTAssertEqual(frames[0].width, 70, accuracy: ε)
        // Cross-axis: stretch fills line cross size (40) minus margin (10) = 30.
        XCTAssertEqual(frames[0].height, 30, accuracy: ε)
    }

    // MARK: - margin in a column container

    func testColumnMarginShiftsOriginVertically() {
        // direction: column. margin top:10, bottom:10 → effective height
        // of a stretching item in a 100-tall container = 80; y offset = 10.
        let item = FlexItemInput(
            measure: { _ in .zero },
            grow:    1,
            shrink:  1,
            basis:   .points(0),
            margin:  EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0)
        )
        let frames = solve(
            [item],
            in: CGSize(width: 50, height: 100),
            config: .init(direction: .column, alignItems: .stretch)
        )
        XCTAssertEqual(frames[0].minX,    0, accuracy: ε)
        XCTAssertEqual(frames[0].minY,   10, accuracy: ε)
        XCTAssertEqual(frames[0].height, 80, accuracy: ε)
    }
}
