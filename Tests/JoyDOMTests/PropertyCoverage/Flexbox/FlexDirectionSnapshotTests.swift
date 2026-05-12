// FlexDirectionSnapshotTests — Layer 3 of the flexDirection coverage
// cycle described in docs/Property-Test-Workflow.md.
//
// Each test renders one sample from JoyDOMSampleSpecs at a thoughtful
// viewport + height, then diffs against a committed PNG baseline. The
// baselines live in `__Snapshots__/FlexDirectionSnapshotTests/` next
// to this file (swift-snapshot-testing's default location).
//
// The responsive sample (`flexbox-flex-direction-responsive`)
// contributes two methods — one at a narrow viewport (column) and
// one at a wide viewport (row) — to prove the breakpoint flip across
// both states.
//
// Viewport choices: each sample's intrinsic shape drives the picked
// width/height so the rendered output fills its frame without obvious
// gaps. Wider for rows, taller for columns, default-ish for the
// overview / edge / cascade samples.
//
// First run records baselines (tests fail with "No reference was
// found on disk"); second run diff-checks against them.

import XCTest
import SnapshotTesting
@testable import JoyDOM
import JoyDOMSampleSpecs

final class FlexDirectionSnapshotTests: XCTestCase {

    private func sample(_ id: String) throws -> SpecPropertySample {
        try XCTUnwrap(SpecPropertySamples.sample(withID: id),
                      "Sample \(id) not in JoyDOMSampleSpecs bundle")
    }

    // MARK: - Value sweep + overview

    func test_flexDirection_overview_rendersAllFourDirections() throws {
        let s = try sample("flexbox-flex-direction")
        assertJoyDOMSnapshot(json: s.json, viewportWidth: 600, height: 240)
    }

    func test_flexDirection_row_rendersLeftToRight() throws {
        let s = try sample("flexbox-flex-direction-row")
        assertJoyDOMSnapshot(json: s.json, viewportWidth: 400, height: 120)
    }

    func test_flexDirection_column_rendersTopToBottom() throws {
        let s = try sample("flexbox-flex-direction-column")
        assertJoyDOMSnapshot(json: s.json, viewportWidth: 120, height: 360)
    }

    func test_flexDirection_rowReverse_rendersRightToLeft() throws {
        let s = try sample("flexbox-flex-direction-row-reverse")
        assertJoyDOMSnapshot(json: s.json, viewportWidth: 400, height: 120)
    }

    func test_flexDirection_columnReverse_rendersBottomToTop() throws {
        let s = try sample("flexbox-flex-direction-column-reverse")
        assertJoyDOMSnapshot(json: s.json, viewportWidth: 120, height: 360)
    }

    // MARK: - Default / edge

    func test_flexDirection_default_rendersContainerDefault() throws {
        let s = try sample("flexbox-flex-direction-default")
        assertJoyDOMSnapshot(json: s.json, viewportWidth: 400, height: 360)
    }

    func test_flexDirection_empty_rendersBareContainer() throws {
        let s = try sample("flexbox-flex-direction-empty")
        assertJoyDOMSnapshot(json: s.json, viewportWidth: 320, height: 100)
    }

    func test_flexDirection_singleChild_rendersAtLeadingEdge() throws {
        let s = try sample("flexbox-flex-direction-single-child")
        assertJoyDOMSnapshot(json: s.json, viewportWidth: 240, height: 120)
    }

    // MARK: - Interactions

    func test_flexDirection_withWrap_wrapsToSecondLine() throws {
        let s = try sample("flexbox-flex-direction-with-wrap")
        assertJoyDOMSnapshot(json: s.json, viewportWidth: 400, height: 220)
    }

    func test_flexDirection_withJustifyEnd_stacksFromBottom() throws {
        let s = try sample("flexbox-flex-direction-with-justify-end")
        assertJoyDOMSnapshot(json: s.json, viewportWidth: 200, height: 280)
    }

    func test_flexDirection_withAlignItems_centersOnCrossAxis() throws {
        let s = try sample("flexbox-flex-direction-with-align-items")
        assertJoyDOMSnapshot(json: s.json, viewportWidth: 320, height: 160)
    }

    func test_flexDirection_withAlignSelf_dropsOneChild() throws {
        let s = try sample("flexbox-flex-direction-with-align-self")
        assertJoyDOMSnapshot(json: s.json, viewportWidth: 320, height: 160)
    }

    func test_flexDirection_withGap_showsSpacingBetweenChildren() throws {
        let s = try sample("flexbox-flex-direction-with-gap")
        assertJoyDOMSnapshot(json: s.json, viewportWidth: 320, height: 120)
    }

    func test_flexDirection_withOrder_reordersVisualSequence() throws {
        let s = try sample("flexbox-flex-direction-with-order")
        assertJoyDOMSnapshot(json: s.json, viewportWidth: 320, height: 120)
    }

    func test_flexDirection_withGrow_distributesRemainingSpace() throws {
        let s = try sample("flexbox-flex-direction-with-grow")
        assertJoyDOMSnapshot(json: s.json, viewportWidth: 440, height: 120)
    }

    func test_flexDirection_withBasis_appliesInitialSizes() throws {
        let s = try sample("flexbox-flex-direction-with-basis")
        assertJoyDOMSnapshot(json: s.json, viewportWidth: 440, height: 120)
    }

    func test_flexDirection_columnWithWrap_wrapsToSecondColumn() throws {
        let s = try sample("flexbox-flex-direction-column-with-wrap")
        assertJoyDOMSnapshot(json: s.json, viewportWidth: 260, height: 240)
    }

    // MARK: - Real-world patterns

    /// Responsive sample at NARROW viewport → renders as column.
    /// Pair with `test_flexDirection_responsive_atWide_rendersRow` to
    /// prove the breakpoint flip across both states.
    func test_flexDirection_responsive_atNarrow_rendersColumn() throws {
        let s = try sample("flexbox-flex-direction-responsive")
        assertJoyDOMSnapshot(json: s.json, viewportWidth: 400, height: 260)
    }

    /// Responsive sample at WIDE viewport (>= 768px) → renders as row
    /// per the breakpoint override.
    func test_flexDirection_responsive_atWide_rendersRow() throws {
        let s = try sample("flexbox-flex-direction-responsive")
        assertJoyDOMSnapshot(json: s.json, viewportWidth: 900, height: 140)
    }

    func test_flexDirection_nested_rendersRowOfColumns() throws {
        let s = try sample("flexbox-flex-direction-nested")
        assertJoyDOMSnapshot(json: s.json, viewportWidth: 360, height: 160)
    }

    func test_flexDirection_inAbsolute_pinsToInset() throws {
        let s = try sample("flexbox-flex-direction-in-absolute")
        assertJoyDOMSnapshot(json: s.json, viewportWidth: 360, height: 200)
    }

    func test_flexDirection_inFixedWidth_shrinksChildren() throws {
        let s = try sample("flexbox-flex-direction-in-fixed-width")
        assertJoyDOMSnapshot(json: s.json, viewportWidth: 280, height: 120)
    }

    // MARK: - Cascade scoping

    func test_flexDirection_classSelector_appliesToBothSiblings() throws {
        let s = try sample("flexbox-flex-direction-class-selector")
        assertJoyDOMSnapshot(json: s.json, viewportWidth: 400, height: 220)
    }

    func test_flexDirection_inline_honoursPropsStyle() throws {
        let s = try sample("flexbox-flex-direction-inline")
        assertJoyDOMSnapshot(json: s.json, viewportWidth: 320, height: 120)
    }
}
