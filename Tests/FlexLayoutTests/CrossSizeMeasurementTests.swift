import XCTest
import SwiftUI
@testable import FlexLayout

/// Regression tests for the cross-axis measurement pass in `FlexEngine`.
///
/// Bug: when a flex container measured a child's cross size to determine
/// the line's cross extent, it passed `nil` for the cross-axis dimension
/// of the proposal. SwiftUI views that wrap their content (Text, nested
/// flex containers, ScrollView…) returned their single-line natural size
/// — often much wider than the container — and that natural size became
/// the line's cross size, propagating up and overflowing the
/// constrained container.
///
/// Symptom in `FlexDemoApp`: the visualCSS sample's hero body paragraph
/// and stat-card row rendered wider than the simulated viewport,
/// clipping at the preview-card border instead of wrapping.
///
/// Fix: the cross-axis measurement now proposes the container's
/// cross constraint (minus the item's cross-axis margins) so wrapping
/// content sizes itself to fit, matching the CSS flexbox spec.
final class CrossSizeMeasurementTests: XCTestCase {

    private let ε: CGFloat = 0.5

    /// Models a SwiftUI Text-style wrap behavior: the natural width is
    /// 1000pt at single line; pass an explicit width and the text wraps.
    private func wrappingText(naturalWidth: CGFloat = 1000, lineHeight: CGFloat = 20)
        -> FlexItemInput
    {
        FlexItemInput(
            measure: { proposal in
                if let w = proposal.width {
                    let lines = ceil(naturalWidth / max(1, w))
                    return CGSize(width: w, height: lines * lineHeight)
                } else {
                    return CGSize(width: naturalWidth, height: lineHeight)
                }
            },
            grow:   0,
            shrink: 1,
            basis:  .auto
        )
    }

    /// Mirrors the visualCSS sample's hero-body paragraph: a long Text
    /// inside a column flex container with a fixed cross-axis width.
    func testColumnContainerWrapsLongTextToCrossConstraint() {
        let frames = FlexEngine.solve(
            config:   FlexContainerConfig(direction: .column, alignItems: .stretch),
            inputs:   [wrappingText()],
            proposal: ProposedViewSize(width: 300, height: nil)
        ).frames

        XCTAssertLessThanOrEqual(
            frames[0].width, 300 + ε,
            "text frame width \(frames[0].width) overflows the 300pt cross constraint"
        )
    }

    /// Same scenario in a row container: the wrapping content's HEIGHT
    /// (cross axis) should fit within the cross constraint when the row
    /// is height-bounded.
    func testRowContainerWrapsTallContentToCrossConstraint() {
        // Row container constrained to 80pt tall. Text is 1000×20 single
        // line; with width 300 it wraps to 4 lines = 80pt. The row's
        // cross constraint of 80 must be propagated to the text's
        // cross-size measurement.
        let txt = wrappingText(naturalWidth: 1000, lineHeight: 20)
        let frames = FlexEngine.solve(
            config:   FlexContainerConfig(direction: .row, alignItems: .stretch),
            inputs:   [txt],
            proposal: ProposedViewSize(width: 300, height: 80)
        ).frames

        // The frame's height (cross axis for row) must fit within the
        // 80pt cross constraint, not return some single-line natural.
        XCTAssertLessThanOrEqual(
            frames[0].height, 80 + ε,
            "text frame height \(frames[0].height) overflows the 80pt cross constraint"
        )
    }

    /// Items with explicit cross sizes must continue to use them — the
    /// new measurement path only affects the otherwise-unconstrained
    /// `auto` cross case.
    func testExplicitCrossSizeStillRespected() {
        let item = FlexItemInput(
            measure:        { _ in CGSize(width: 0, height: 0) },
            basis:          .points(0),
            explicitWidth:  .points(80)   // explicit cross size for column
        )
        let frames = FlexEngine.solve(
            config:   FlexContainerConfig(direction: .column),
            inputs:   [item],
            proposal: ProposedViewSize(width: 300, height: nil)
        ).frames

        XCTAssertEqual(frames[0].width, 80, accuracy: ε,
                       "explicit cross size must win over the new constraint propagation")
    }

    /// Cross-axis margins must be subtracted from the proposed cross
    /// space so the item is sized as a content box, not an outer box.
    func testCrossAxisMarginsReduceMeasureProposal() {
        let lineHeight: CGFloat = 20
        // Capture the proposal handed to the measure function so we can
        // assert the engine subtracted the cross-axis margin.
        var observedCrossWidth: CGFloat?
        let item = FlexItemInput(
            measure: { proposal in
                observedCrossWidth = proposal.width
                let w = proposal.width ?? 1000
                let lines = ceil(1000.0 / max(1, w))
                return CGSize(width: w, height: lines * lineHeight)
            },
            grow:   0,
            shrink: 1,
            basis:  .auto,
            margin: EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 5)
        )
        _ = FlexEngine.solve(
            config:   FlexContainerConfig(direction: .column, alignItems: .stretch),
            inputs:   [item],
            proposal: ProposedViewSize(width: 300, height: nil)
        )
        // Container 300, leading margin 10 + trailing 5 = 15 → 285pt cross
        // space proposed to the item.
        XCTAssertEqual(observedCrossWidth ?? -1, 285, accuracy: ε,
                       "expected 300 − (leading 10 + trailing 5) = 285pt cross proposal")
    }

    /// Unconstrained containers must still propose nil so children can
    /// expand to their natural size — important for hugging-content
    /// container patterns.
    func testUnconstrainedColumnPropagatesNilCrossProposal() {
        var observedCrossWidth: CGFloat? = -1   // sentinel: never called yet
        let item = FlexItemInput(
            measure: { proposal in
                observedCrossWidth = proposal.width
                return CGSize(width: 100, height: 20)
            },
            basis: .auto
        )
        _ = FlexEngine.solve(
            config:   FlexContainerConfig(direction: .column, alignItems: .stretch),
            inputs:   [item],
            proposal: ProposedViewSize(width: nil, height: nil)
        )
        XCTAssertNil(observedCrossWidth,
                     "with nil container width the cross proposal must remain nil")
    }
}
