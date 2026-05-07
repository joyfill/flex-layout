import XCTest
@testable import JoyDOM

/// Unit 7 — `BreakpointResolver.active(in:_:)` picks the single
/// breakpoint that applies to the current viewport, per Josh's
/// "cascade approach" documented in `DOM/guides/Breakpoints.md`.
///
/// Selection rule under test:
///   1. A breakpoint matches when ALL its conditions match.
///   2. Among matches, highest specificity wins.
///      Specificity = count of conditions.
///   3. Specificity tie → later source order wins (CSS-like).
final class BreakpointResolverTests: XCTestCase {

    // MARK: - Empty / no-match cases

    func testEmptyBreakpointsArrayReturnsNil() {
        let bp = BreakpointResolver.active(
            in: Viewport(width: 800),
            breakpoints: []
        )
        XCTAssertNil(bp)
        XCTAssertNil(BreakpointResolver.activeIndex(
            in: Viewport(width: 800),
            breakpoints: []
        ))
    }

    func testNonMatchingBreakpointReturnsNil() {
        let bp = Breakpoint(
            conditions: [.width(operator: .lessThan, value: 600, unit: .px)]
        )
        XCTAssertNil(BreakpointResolver.active(
            in: Viewport(width: 1200),
            breakpoints: [bp]
        ))
    }

    // MARK: - Single match

    func testSingleMatchingBreakpointReturned() {
        let bp = Breakpoint(
            conditions: [.width(operator: .lessThan, value: 600, unit: .px)]
        )
        let active = BreakpointResolver.active(
            in: Viewport(width: 320),
            breakpoints: [bp]
        )
        XCTAssertEqual(active, bp)
        XCTAssertEqual(BreakpointResolver.activeIndex(
            in: Viewport(width: 320),
            breakpoints: [bp]
        ), 0)
    }

    func testBreakpointWithNoConditionsMatchesAnyViewport() {
        // Empty conditions = vacuously true. This is the "default"
        // breakpoint slot — useful as a catch-all at low specificity.
        let bp = Breakpoint(conditions: [])
        XCTAssertEqual(
            BreakpointResolver.active(in: Viewport(width: 0), breakpoints: [bp]),
            bp
        )
        XCTAssertEqual(
            BreakpointResolver.active(in: Viewport(width: 9999), breakpoints: [bp]),
            bp
        )
    }

    // MARK: - Specificity

    func testHigherSpecificityWinsOverLowerWhenBothMatch() {
        let lowSpec = Breakpoint(
            conditions: [.width(operator: .lessThan, value: 9999, unit: .px)]
        )
        let highSpec = Breakpoint(
            conditions: [
                .width(operator: .lessThan, value: 9999, unit: .px),
                .orientation(.portrait),
            ]
        )
        let viewport = Viewport(width: 320, orientation: .portrait)
        let active = BreakpointResolver.active(
            in: viewport,
            breakpoints: [lowSpec, highSpec]
        )
        XCTAssertEqual(active, highSpec)
        XCTAssertEqual(BreakpointResolver.activeIndex(
            in: viewport,
            breakpoints: [lowSpec, highSpec]
        ), 1)
    }

    func testHigherSpecificityWinsRegardlessOfArrayOrder() {
        // Same as above but with array order reversed — proves the
        // resolver doesn't fall back to "first match wins".
        let highSpec = Breakpoint(
            conditions: [
                .width(operator: .lessThan, value: 9999, unit: .px),
                .orientation(.portrait),
            ]
        )
        let lowSpec = Breakpoint(
            conditions: [.width(operator: .lessThan, value: 9999, unit: .px)]
        )
        let active = BreakpointResolver.active(
            in: Viewport(width: 320, orientation: .portrait),
            breakpoints: [highSpec, lowSpec]
        )
        XCTAssertEqual(active, highSpec)
    }

    func testLowerSpecificityWinsWhenHigherDoesNotMatch() {
        let lowSpec = Breakpoint(
            conditions: [.width(operator: .lessThan, value: 9999, unit: .px)]
        )
        let highSpec = Breakpoint(
            conditions: [
                .width(operator: .lessThan, value: 9999, unit: .px),
                .orientation(.landscape),
            ]
        )
        // Portrait viewport — high-spec breakpoint fails its second
        // condition, so the low-spec catch-all wins.
        let active = BreakpointResolver.active(
            in: Viewport(width: 320, orientation: .portrait),
            breakpoints: [lowSpec, highSpec]
        )
        XCTAssertEqual(active, lowSpec)
    }

    // MARK: - Specificity ties → later source order wins

    func testSpecificityTieBreaksByLaterSourceOrder() {
        let earlier = Breakpoint(
            conditions: [.width(operator: .lessThan, value: 9999, unit: .px)]
        )
        let later = Breakpoint(
            conditions: [.orientation(.portrait)]
        )
        let active = BreakpointResolver.active(
            in: Viewport(width: 320, orientation: .portrait),
            breakpoints: [earlier, later]
        )
        XCTAssertEqual(active, later, "later source order must win the tie")
        XCTAssertEqual(BreakpointResolver.activeIndex(
            in: Viewport(width: 320, orientation: .portrait),
            breakpoints: [earlier, later]
        ), 1)
    }

    func testThreeWayTieReturnsLastMatching() {
        let a = Breakpoint(conditions: [.width(operator: .lessThan, value: 9999, unit: .px)])
        let b = Breakpoint(conditions: [.orientation(.portrait)])
        let c = Breakpoint(conditions: [.not(.type(.print))])
        let active = BreakpointResolver.active(
            in: Viewport(width: 320, orientation: .portrait),
            breakpoints: [a, b, c]
        )
        XCTAssertEqual(active, c)
    }

    // MARK: - Distinguishable breakpoints (sanity)

    // MARK: - End-to-end order override (Phase B of SPEC_COMPLIANCE_PLAN)

    /// Spec: `DOM/guides/Breakpoints.md` "Custom Breakpoint Node Ordering".
    /// Three siblings carry document-level `order: 1, 2, 3`. A `width >=
    /// 768px` breakpoint flips them to `order: 3, 2, 1`. The same payload
    /// resolves differently depending on which breakpoint is active —
    /// proves the cascade hand-off plus the Phase 1 `order` plumbing.
    func testBreakpointOrderOverrideAppliesAtMatchingViewport() {
        let wideOnly = Breakpoint(
            conditions: [.width(operator: .greaterThanOrEqual, value: 768, unit: .px)],
            nodes: [:],
            style: [
                "#a": Style(order: 3),
                "#b": Style(order: 2),
                "#c": Style(order: 1)
            ]
        )
        let spec = Spec(
            version: 1,
            style: [
                "#a": Style(order: 1),
                "#b": Style(order: 2),
                "#c": Style(order: 3)
            ],
            breakpoints: [wideOnly],
            layout: Node(type: "div", props: NodeProps(id: "root"), children: [
                .node(Node(type: "div", props: NodeProps(id: "a"))),
                .node(Node(type: "div", props: NodeProps(id: "b"))),
                .node(Node(type: "div", props: NodeProps(id: "c")))
            ])
        )

        // Narrow viewport — declared order applies.
        var diags = JoyDiagnostics()
        let narrowRules = RuleBuilder.buildRules(
            from: spec,
            activeBreakpoint: nil,
            diagnostics: &diags
        )
        let narrowNodes = StyleTreeBuilder.build(
            layout: spec.layout,
            rootID: "__joydom_root__",
            rules: narrowRules,
            diagnostics: &diags
        )
        XCTAssertEqual(narrowNodes.first(where: { $0.id == "a" })?.computedStyle.item.order, 1)
        XCTAssertEqual(narrowNodes.first(where: { $0.id == "b" })?.computedStyle.item.order, 2)
        XCTAssertEqual(narrowNodes.first(where: { $0.id == "c" })?.computedStyle.item.order, 3)

        // Wide viewport — breakpoint override flips the order.
        let active = BreakpointResolver.active(
            in: Viewport(width: 1024),
            breakpoints: spec.breakpoints
        )
        XCTAssertEqual(active, wideOnly, "the >=768px breakpoint must match a 1024px viewport")
        let wideRules = RuleBuilder.buildRules(
            from: spec,
            activeBreakpoint: active,
            diagnostics: &diags
        )
        let wideNodes = StyleTreeBuilder.build(
            layout: spec.layout,
            rootID: "__joydom_root__",
            rules: wideRules,
            diagnostics: &diags
        )
        XCTAssertEqual(wideNodes.first(where: { $0.id == "a" })?.computedStyle.item.order, 3)
        XCTAssertEqual(wideNodes.first(where: { $0.id == "b" })?.computedStyle.item.order, 2)
        XCTAssertEqual(wideNodes.first(where: { $0.id == "c" })?.computedStyle.item.order, 1)
    }

    // MARK: - Active-breakpoint content sanity

    func testActiveBreakpointHasItsContent() {
        // The resolver returns the breakpoint object itself — make sure
        // its `nodes` and `style` make it through (Unit 8 reads them).
        let bp = Breakpoint(
            conditions: [.width(operator: .lessThan, value: 600, unit: .px)],
            nodes:      ["panel": NodeProps(style: Style(display: .flex))],
            style:      ["#root": Style(flexDirection: .column)]
        )
        let active = BreakpointResolver.active(
            in: Viewport(width: 320),
            breakpoints: [bp]
        )
        XCTAssertEqual(active?.nodes["panel"]?.style?.display, .flex)
        XCTAssertEqual(active?.style["#root"]?.flexDirection, .column)
    }
}
