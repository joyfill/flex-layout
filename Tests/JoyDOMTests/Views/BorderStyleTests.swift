import XCTest
import SwiftUI
@testable import JoyDOM

/// Phase 1 added the non-solid CSS `border-style` cases (`dashed`,
/// `dotted`, `double`). The actual stroke-array path in SwiftUI is not
/// inspectable from outside the framework, so this suite exercises the
/// resolver mapping (Style → VisualStyle) and the JoyDOMView body
/// construction so a regression that crashed the render path (e.g. a
/// divide-by-zero in a custom dash array) would surface.
final class BorderStyleTests: XCTestCase {

    private func resolvedVisual(for style: Style) -> VisualStyle {
        var diags = JoyDiagnostics()
        let spec = Spec(
            style: ["#x": style],
            breakpoints: [],
            layout: Node(type: "div", props: NodeProps(id: "x"))
        )
        let rules = RuleBuilder.buildRules(from: spec, activeBreakpoint: nil, diagnostics: &diags)
        let nodes = StyleTreeBuilder.build(
            layout: spec.layout,
            rootID: "__joydom_root__",
            rules: rules,
            diagnostics: &diags
        )
        return nodes.first(where: { $0.id == "x" })!.computedStyle.visual
    }

    private func renderable(borderStyle: Style.BorderStyleProp) -> Spec {
        Spec(
            style: ["#x": Style(
                borderWidth: .px(2),
                borderColor: "#3B4FE0",
                borderStyle: borderStyle
            )],
            breakpoints: [],
            layout: Node(type: "div", props: NodeProps(id: "x"))
        )
    }

    func testDashedRoundTripsToVisualStyle() {
        XCTAssertEqual(resolvedVisual(for: Style(borderStyle: .dashed)).borderStyle, .dashed)
    }

    func testDottedRoundTripsToVisualStyle() {
        XCTAssertEqual(resolvedVisual(for: Style(borderStyle: .dotted)).borderStyle, .dotted)
    }

    func testDoubleRoundTripsToVisualStyle() {
        XCTAssertEqual(resolvedVisual(for: Style(borderStyle: .double)).borderStyle, .double)
    }

    func testSolidRoundTripsToVisualStyle() {
        XCTAssertEqual(resolvedVisual(for: Style(borderStyle: .solid)).borderStyle, .solid)
    }

    func testNoneRoundTripsToVisualStyle() {
        XCTAssertEqual(resolvedVisual(for: Style(borderStyle: Style.BorderStyleProp.none)).borderStyle, Style.BorderStyleProp.none)
    }

    // MARK: - View body construction smoke tests
    //
    // Touching `body` exercises `applyVisual` → `applyBorderRadius` and
    // the per-style stroke path, which is where any regression in the
    // dashed/dotted/double drawing code would surface.

    func testJoyDOMViewBuildsBodyForDashedBorder() {
        _ = JoyDOMView(spec: renderable(borderStyle: .dashed)).body
    }

    func testJoyDOMViewBuildsBodyForDottedBorder() {
        _ = JoyDOMView(spec: renderable(borderStyle: .dotted)).body
    }

    func testJoyDOMViewBuildsBodyForDoubleBorder() {
        _ = JoyDOMView(spec: renderable(borderStyle: .double)).body
    }
}
