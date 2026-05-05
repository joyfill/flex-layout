import XCTest
import SwiftUI
@testable import FlexLayout

/// Tests for CSS `min-width` / `max-width` / `min-height` / `max-height`
/// clamping in the FlexLayout engine. CSS 2.1 §10.4 specifies that
/// `max-*` is applied first, then `min-*`, and that `min-*` always wins
/// on direct conflict (`min > max` clamps to `min`).
final class MinMaxConstraintTests: XCTestCase {

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

    private func assertSize(
        _ frame: CGRect,
        width:  CGFloat? = nil,
        height: CGFloat? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        if let w = width  { XCTAssertEqual(frame.width,  w, accuracy: ε, "width",  file: file, line: line) }
        if let h = height { XCTAssertEqual(frame.height, h, accuracy: ε, "height", file: file, line: line) }
    }

    // MARK: - max-width clamps an explicit width

    func testMaxWidthClampsExplicitWidth() {
        // width: 100, maxWidth: 50 → width is clamped to 50.
        let item = FlexItemInput(
            measure:        { _ in .zero },
            shrink:         0,
            explicitWidth:  .points(100),
            explicitHeight: .points(20),
            maxWidth:       .points(50)
        )
        let frames = solve([item], in: CGSize(width: 400, height: 200))
        assertSize(frames[0], width: 50, height: 20)
    }

    // MARK: - min-width raises an explicit width

    func testMinWidthRaisesExplicitWidth() {
        // width: 100, minWidth: 200 → width clamps up to 200.
        let item = FlexItemInput(
            measure:        { _ in .zero },
            shrink:         0,
            explicitWidth:  .points(100),
            explicitHeight: .points(20),
            minWidth:       .points(200)
        )
        let frames = solve([item], in: CGSize(width: 400, height: 200))
        assertSize(frames[0], width: 200, height: 20)
    }

    // MARK: - min beats max on conflict (CSS 2.1 §10.4)

    func testMinBeatsMaxOnConflict() {
        // width: 100, minWidth: 50, maxWidth: 80 → 80 (max applied, min already <= max).
        let item = FlexItemInput(
            measure:        { _ in .zero },
            shrink:         0,
            explicitWidth:  .points(100),
            explicitHeight: .points(20),
            minWidth:       .points(50),
            maxWidth:       .points(80)
        )
        let frames = solve([item], in: CGSize(width: 400, height: 200))
        assertSize(frames[0], width: 80, height: 20)
    }

    func testMinAboveMaxClampsToMin() {
        // width: 100, minWidth: 200, maxWidth: 80 → max applied first (80),
        // then min applied (200). Spec says min wins on conflict → 200.
        let item = FlexItemInput(
            measure:        { _ in .zero },
            shrink:         0,
            explicitWidth:  .points(100),
            explicitHeight: .points(20),
            minWidth:       .points(200),
            maxWidth:       .points(80)
        )
        let frames = solve([item], in: CGSize(width: 400, height: 200))
        assertSize(frames[0], width: 200, height: 20)
    }

    // MARK: - intrinsic-only item with min-width raises width

    func testIntrinsicWithMinWidthClampsUp() {
        // No explicit width; intrinsic 100; minWidth 200 → 200.
        let item = FlexItemInput(
            measure: { _ in CGSize(width: 100, height: 20) },
            shrink:  0,
            minWidth: .points(200)
        )
        let frames = solve([item], in: CGSize(width: 600, height: 200))
        assertSize(frames[0], width: 200, height: 20)
    }

    // MARK: - max-height clamps an explicit height

    func testMaxHeightClampsExplicitHeight() {
        // direction: column → height is on the main axis.
        let item = FlexItemInput(
            measure:        { _ in .zero },
            shrink:         0,
            explicitWidth:  .points(40),
            explicitHeight: .points(100),
            maxHeight:      .points(50)
        )
        let frames = solve(
            [item],
            in: CGSize(width: 200, height: 400),
            config: .init(direction: .column, alignItems: .flexStart)
        )
        assertSize(frames[0], width: 40, height: 50)
    }

    func testMinHeightRaisesExplicitHeight() {
        let item = FlexItemInput(
            measure:        { _ in .zero },
            shrink:         0,
            explicitWidth:  .points(40),
            explicitHeight: .points(100),
            minHeight:      .points(200)
        )
        let frames = solve(
            [item],
            in: CGSize(width: 200, height: 400),
            config: .init(direction: .column, alignItems: .flexStart)
        )
        assertSize(frames[0], width: 40, height: 200)
    }

    func testMinHeightBeatsMaxHeightOnConflict() {
        // height: 100, minHeight: 200, maxHeight: 80 → 200 (min wins).
        let item = FlexItemInput(
            measure:        { _ in .zero },
            shrink:         0,
            explicitWidth:  .points(40),
            explicitHeight: .points(100),
            minHeight:      .points(200),
            maxHeight:      .points(80)
        )
        let frames = solve(
            [item],
            in: CGSize(width: 200, height: 400),
            config: .init(direction: .column, alignItems: .flexStart)
        )
        assertSize(frames[0], width: 40, height: 200)
    }

    func testIntrinsicWithMinHeightClampsUp() {
        let item = FlexItemInput(
            measure:        { _ in CGSize(width: 40, height: 100) },
            shrink:         0,
            minHeight:      .points(200)
        )
        let frames = solve(
            [item],
            in: CGSize(width: 200, height: 600),
            config: .init(direction: .column, alignItems: .flexStart)
        )
        assertSize(frames[0], width: 40, height: 200)
    }

    // MARK: - max-width caps a grow item

    func testMaxWidthCapsGrowItem() {
        // grow: 1 with maxWidth: 100 in a 400-wide container next to a 50-px
        // sibling — the grow item should stop at 100 px instead of consuming
        // the full 350 px of free space.
        let grower = FlexItemInput(
            measure:       { _ in CGSize(width: 0, height: 20) },
            grow:          1,
            shrink:        0,
            basis:         .points(0),
            explicitHeight: .points(20),
            maxWidth:      .points(100)
        )
        let sibling = FlexItemInput.fixed(width: 50, height: 20)
        let frames = solve([grower, sibling], in: CGSize(width: 400, height: 50))
        XCTAssertEqual(frames[0].width, 100, accuracy: ε)
        XCTAssertEqual(frames[1].width,  50, accuracy: ε)
    }

    // MARK: - §9.7 freeze-and-redistribute

    func testMaxWidthOnGrowerRedistributesLeftoverToSiblings() {
        // 3 grow:1 items in a 300-wide row, basis 0. A is capped at 50;
        // CSS §9.7 prescribes freezing A at its max and redistributing the
        // leftover 50pt across B and C (browsers give 50/125/125, not
        // 50/100/100 as the prior single-pass implementation produced).
        let make: (CGFloat?) -> FlexItemInput = { max in
            FlexItemInput(
                measure:        { _ in CGSize(width: 0, height: 20) },
                grow:           1,
                shrink:         0,
                basis:          .points(0),
                explicitHeight: .points(20),
                maxWidth:       max.map { .points($0) }
            )
        }
        let frames = solve(
            [make(50), make(nil), make(nil)],
            in: CGSize(width: 300, height: 50)
        )
        XCTAssertEqual(frames[0].width,  50, accuracy: ε)
        XCTAssertEqual(frames[1].width, 125, accuracy: ε,
                       "B should absorb half of A's stranded 50pt leftover")
        XCTAssertEqual(frames[2].width, 125, accuracy: ε,
                       "C should absorb the other half")
    }

    func testMinWidthOnShrinkingItemRedistributesShortfall() {
        // 3 items basis=100, grow=0, shrink=1, container=200, overflow=100.
        // A has minWidth=80 — it can only absorb 20 of the overflow before
        // hitting its floor; the remaining 80 must be split between B and C.
        // Expected: A=80, B=60, C=60 (sums to 200).
        let make: (CGFloat?) -> FlexItemInput = { min in
            FlexItemInput(
                measure:        { _ in CGSize(width: 100, height: 20) },
                grow:           0,
                shrink:         1,
                basis:          .points(100),
                explicitHeight: .points(20),
                minWidth:       min.map { .points($0) }
            )
        }
        let frames = solve(
            [make(80), make(nil), make(nil)],
            in: CGSize(width: 200, height: 50)
        )
        XCTAssertEqual(frames[0].width, 80, accuracy: ε)
        XCTAssertEqual(frames[1].width, 60, accuracy: ε,
                       "B must absorb half of A's unabsorbed 80pt overflow")
        XCTAssertEqual(frames[2].width, 60, accuracy: ε)
    }
}
