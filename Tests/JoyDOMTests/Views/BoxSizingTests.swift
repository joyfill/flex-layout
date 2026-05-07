import XCTest
import SwiftUI
@testable import JoyDOM
import FlexLayout

/// `box-sizing: border-box` enforcement (Approach A — Phase A of
/// `SPEC_COMPLIANCE_PLAN.md`).
///
/// JoyDOM's adapter (`JoyDOMView.adjustForBoxSizing`) deducts the node's
/// own border + padding from explicit `width` / `height` before handing
/// the value to FlexLayout, so the engine itself stays unaware of
/// box-sizing. These tests pin the arithmetic at the helper level
/// (no SwiftUI rendering required) plus an end-to-end pipeline check
/// that exercises the same path through `StyleResolver`.
///
/// Spec: `DOM/spec.ts:17` (`boxSizing?: 'border-box'`),
/// CSS Box Sizing Module Level 3 §3.
final class BoxSizingTests: XCTestCase {

    // MARK: - Pure adapter helper

    func testContentBoxIsPassThroughEvenWithBorderAndPadding() {
        // Default (nil) box-sizing must not deduct anything — content-box
        // is the CSS default and matches today's behavior bit-for-bit.
        let result = JoyDOMView.adjustForBoxSizing(
            .points(100),
            boxSizing: nil,
            borderWidth: 2,
            paddingTotal: 20
        )
        XCTAssertEqual(result, .points(100))
    }

    func testBorderBoxDeductsBorderAndPaddingOnMainAxis() {
        // 100 − (2 × 2 border) − (10 + 10 padding) = 76.
        let result = JoyDOMView.adjustForBoxSizing(
            .points(100),
            boxSizing: .borderBox,
            borderWidth: 2,
            paddingTotal: 20
        )
        XCTAssertEqual(result, .points(76))
    }

    func testBorderBoxDeductsAsymmetricCrossAxisPadding() {
        // top: 5 + bottom: 5 = 10 padding, plus 1×2 border = 12 deduction.
        let result = JoyDOMView.adjustForBoxSizing(
            .points(80),
            boxSizing: .borderBox,
            borderWidth: 1,
            paddingTotal: 10
        )
        XCTAssertEqual(result, .points(68))
    }

    func testBorderBoxWithoutBorderJustDeductsPadding() {
        let result = JoyDOMView.adjustForBoxSizing(
            .points(50),
            boxSizing: .borderBox,
            borderWidth: nil,
            paddingTotal: 16
        )
        XCTAssertEqual(result, .points(34))
    }

    func testBorderBoxWithoutPaddingJustDeductsBorder() {
        let result = JoyDOMView.adjustForBoxSizing(
            .points(50),
            boxSizing: .borderBox,
            borderWidth: 4,
            paddingTotal: 0
        )
        XCTAssertEqual(result, .points(42))
    }

    func testBorderBoxClampsAtZeroWhenDeductionExceedsValue() {
        // 10 − (4 × 2 border) − (20 padding) would go negative — clamp to 0.
        let result = JoyDOMView.adjustForBoxSizing(
            .points(10),
            boxSizing: .borderBox,
            borderWidth: 4,
            paddingTotal: 20
        )
        XCTAssertEqual(result, .points(0))
    }

    func testBorderBoxLeavesAutoUntouched() {
        // No explicit dimension → nothing to deduct from.
        let result = JoyDOMView.adjustForBoxSizing(
            .auto,
            boxSizing: .borderBox,
            borderWidth: 2,
            paddingTotal: 20
        )
        XCTAssertEqual(result, .auto)
    }

    func testBorderBoxLeavesPercentageUntouched() {
        // % cannot be deducted without knowing the container's resolved
        // size; documented limitation. Pass-through.
        let result = JoyDOMView.adjustForBoxSizing(
            .fraction(0.5),
            boxSizing: .borderBox,
            borderWidth: 2,
            paddingTotal: 20
        )
        XCTAssertEqual(result, .fraction(0.5))
    }

    func testBorderBoxLeavesMinContentUntouched() {
        let result = JoyDOMView.adjustForBoxSizing(
            .minContent,
            boxSizing: .borderBox,
            borderWidth: 2,
            paddingTotal: 20
        )
        XCTAssertEqual(result, .minContent)
    }

    func testBorderBoxWithNoBorderOrPaddingIsPassThrough() {
        // Nothing to deduct → return the value unchanged (skip the switch).
        let result = JoyDOMView.adjustForBoxSizing(
            .points(100),
            boxSizing: .borderBox,
            borderWidth: nil,
            paddingTotal: 0
        )
        XCTAssertEqual(result, .points(100))
    }

    // MARK: - End-to-end pipeline

    /// Drives the full Spec → ComputedStyle → adapter path so a regression
    /// in either the resolver wiring or the deduction surfaces here.
    private func resolve(style: Style) -> ComputedStyle {
        var diags = JoyDiagnostics()
        let rules = RuleBuilder.buildRules(
            from: Spec(
                style: ["#x": style],
                breakpoints: [],
                layout: Node(type: "div", props: NodeProps(id: "x"))
            ),
            activeBreakpoint: nil,
            diagnostics: &diags
        )
        let nodes = StyleTreeBuilder.build(
            layout: Node(type: "div", props: NodeProps(id: "x")),
            rootID: "__joydom_root__",
            rules: rules,
            diagnostics: &diags
        )
        return nodes.first(where: { $0.id == "x" })!.computedStyle
    }

    func testBoxSizingFlagSurvivesCascadeOntoItemStyle() {
        let c = resolve(style: Style(boxSizing: .borderBox))
        XCTAssertEqual(c.item.boxSizing, .borderBox)
    }

    func testBoxSizingAbsentMeansContentBoxImplicitDefault() {
        // No `boxSizing` field → `item.boxSizing == nil` → adapter does
        // not deduct.
        let c = resolve(style: Style(width: .px(100)))
        XCTAssertNil(c.item.boxSizing)
    }

    func testBorderBoxPipelineProducesEffectiveSeventySixPxFromHundred() {
        // The headline assertion from `SPEC_COMPLIANCE_PLAN.md`:
        // width: 100, padding: 10 (uniform), borderWidth: 2,
        // boxSizing: border-box → effective FlexLayout width = 76.
        let c = resolve(style: Style(
            boxSizing:   .borderBox,
            width:       .px(100),
            padding:     .uniform(.px(10)),
            borderWidth: .px(2)
        ))
        let effectiveWidth = JoyDOMView.adjustForBoxSizing(
            c.item.width,
            boxSizing: c.item.boxSizing,
            borderWidth: c.visual.borderWidth,
            paddingTotal: c.container.padding.leading + c.container.padding.trailing
        )
        XCTAssertEqual(effectiveWidth, .points(76))
    }

    func testBorderBoxPipelineDeductsAsymmetricPaddingOnHeight() {
        // top: 5, bottom: 5 (other sides arbitrary) + border: 1 → 80 − 12 = 68.
        let c = resolve(style: Style(
            boxSizing: .borderBox,
            height: .px(80),
            padding: .sides(top: .px(5), right: .px(20), bottom: .px(5), left: .px(20)),
            borderWidth: .px(1)
        ))
        let effectiveHeight = JoyDOMView.adjustForBoxSizing(
            c.item.height,
            boxSizing: c.item.boxSizing,
            borderWidth: c.visual.borderWidth,
            paddingTotal: c.container.padding.top + c.container.padding.bottom
        )
        XCTAssertEqual(effectiveHeight, .points(68))
    }

    func testBorderBoxPipelineLeavesContentBoxPayloadAlone() {
        // Without `boxSizing`, the same {width: 100, padding: 10, border: 2}
        // payload feeds 100 to FlexLayout — content-box passthrough.
        let c = resolve(style: Style(
            width:       .px(100),
            padding:     .uniform(.px(10)),
            borderWidth: .px(2)
        ))
        let effectiveWidth = JoyDOMView.adjustForBoxSizing(
            c.item.width,
            boxSizing: c.item.boxSizing,
            borderWidth: c.visual.borderWidth,
            paddingTotal: c.container.padding.leading + c.container.padding.trailing
        )
        XCTAssertEqual(effectiveWidth, .points(100))
    }

    func testBorderBoxPipelineLeavesUnsetWidthAlone() {
        // No explicit width → nothing to deduct from; result stays `.auto`.
        let c = resolve(style: Style(
            boxSizing:   .borderBox,
            padding:     .uniform(.px(10)),
            borderWidth: .px(2)
        ))
        let effectiveWidth = JoyDOMView.adjustForBoxSizing(
            c.item.width,
            boxSizing: c.item.boxSizing,
            borderWidth: c.visual.borderWidth,
            paddingTotal: c.container.padding.leading + c.container.padding.trailing
        )
        XCTAssertEqual(effectiveWidth, .auto)
    }

    func testBorderBoxPipelineLeavesPercentageWidthUntouched() {
        // % can't be deducted at the adapter layer (requires container
        // resolution) — documented pass-through.
        let c = resolve(style: Style(
            boxSizing:   .borderBox,
            width:       Length(value: 50, unit: "%"),
            padding:     .uniform(.px(10)),
            borderWidth: .px(2)
        ))
        let effectiveWidth = JoyDOMView.adjustForBoxSizing(
            c.item.width,
            boxSizing: c.item.boxSizing,
            borderWidth: c.visual.borderWidth,
            paddingTotal: c.container.padding.leading + c.container.padding.trailing
        )
        XCTAssertEqual(effectiveWidth, .fraction(0.5))
    }
}
