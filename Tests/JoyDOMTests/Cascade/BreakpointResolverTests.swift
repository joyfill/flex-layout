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

    // MARK: - Display-none breakpoint visibility (Breakpoints.md "Custom Breakpoint Node Visibility")

    /// Spec ref: `DOM/guides/Breakpoints.md` "Custom Breakpoint Node
    /// Visibility". A `width >= 768px` breakpoint applies
    /// `display: none` to the middle node. At narrow viewports all
    /// three nodes render; at wide viewports the middle is removed.
    func testBreakpointDisplayNoneOverrideHidesNode() {
        let wide = Breakpoint(
            conditions: [.width(operator: .greaterThanOrEqual, value: 768, unit: .px)],
            nodes: [:],
            style: ["#middle": Style(display: Display.none)]
        )
        let spec = Spec(
            version: 1,
            style: [:],
            breakpoints: [wide],
            layout: Node(type: "div", props: NodeProps(id: "root"), children: [
                .node(Node(type: "div", props: NodeProps(id: "left"))),
                .node(Node(type: "div", props: NodeProps(id: "middle"))),
                .node(Node(type: "div", props: NodeProps(id: "right")))
            ])
        )

        // Narrow viewport — breakpoint inactive, middle is visible.
        var diags = JoyDiagnostics()
        let narrowRules = RuleBuilder.buildRules(
            from: spec, activeBreakpoint: nil, diagnostics: &diags
        )
        let narrow = StyleTreeBuilder.build(
            layout: spec.layout,
            rootID: "__joydom_root__",
            rules: narrowRules,
            diagnostics: &diags
        )
        XCTAssertEqual(narrow.first(where: { $0.id == "middle" })?.computedStyle.isDisplayNone, false)

        // Wide viewport — breakpoint active, middle is display:none.
        let active = BreakpointResolver.active(
            in: Viewport(width: 1024),
            breakpoints: spec.breakpoints
        )
        XCTAssertEqual(active, wide)
        let wideRules = RuleBuilder.buildRules(
            from: spec, activeBreakpoint: active, diagnostics: &diags
        )
        let wideNodes = StyleTreeBuilder.build(
            layout: spec.layout,
            rootID: "__joydom_root__",
            rules: wideRules,
            diagnostics: &diags
        )
        XCTAssertEqual(wideNodes.first(where: { $0.id == "middle" })?.computedStyle.isDisplayNone, true)
        // Siblings stay visible.
        XCTAssertEqual(wideNodes.first(where: { $0.id == "left"   })?.computedStyle.isDisplayNone, false)
        XCTAssertEqual(wideNodes.first(where: { $0.id == "right"  })?.computedStyle.isDisplayNone, false)
    }

    // MARK: - Deep merge spec example (Breakpoints.md "Merging View Properties")

    /// Spec ref: `DOM/guides/Breakpoints.md` "Merging View Properties
    /// and Precedence of Resolution With Primary".
    ///
    ///   Primary:    `{ color: "red", padding: 8 }`
    ///   Breakpoint: `{ color: "blue" }`
    ///   Merged:     `{ color: "blue", padding: 8 }`
    ///
    /// Our cascade does this naturally — the breakpoint Style only
    /// overwrites fields it sets, leaving the primary `padding` intact.
    func testBreakpointDeepMergePreservesNonOverriddenFields() {
        let bp = Breakpoint(
            conditions: [.width(operator: .greaterThanOrEqual, value: 768, unit: .px)],
            nodes: [:],
            style: ["#hero": Style(color: "blue")]
        )
        let spec = Spec(
            version: 1,
            style: ["#hero": Style(padding: .uniform(.px(8)), color: "red")],
            breakpoints: [bp],
            layout: Node(type: "div", props: NodeProps(id: "hero"))
        )

        var diags = JoyDiagnostics()
        let active = BreakpointResolver.active(
            in: Viewport(width: 1024),
            breakpoints: spec.breakpoints
        )
        let rules = RuleBuilder.buildRules(
            from: spec, activeBreakpoint: active, diagnostics: &diags
        )
        let nodes = StyleTreeBuilder.build(
            layout: spec.layout,
            rootID: "__joydom_root__",
            rules: rules,
            diagnostics: &diags
        )
        let hero = nodes.first(where: { $0.id == "hero" })!
        XCTAssertEqual(hero.computedStyle.visual.color, "blue", "breakpoint override wins for color")
        XCTAssertEqual(hero.computedStyle.container.padding.leading, 8,
                       "primary's padding survives because the breakpoint didn't set it")
        XCTAssertEqual(hero.computedStyle.container.padding.trailing, 8)
        XCTAssertEqual(hero.computedStyle.container.padding.top, 8)
        XCTAssertEqual(hero.computedStyle.container.padding.bottom, 8)
    }

    // MARK: - Restore-original (Breakpoints.md "Restore the original …")

    /// Spec ref: `DOM/guides/Breakpoints.md` "Restore the original node
    /// ordering". When two breakpoints can match, the lower-specificity
    /// one omits the override entirely so the primary's `order: 5`
    /// reasserts itself. Our cascade picks the active breakpoint by
    /// specificity — set up so only `B` (no order override) matches.
    func testRemovingOrderFromBreakpointRestoresPrimaryOrder() {
        // Only B matches at the test viewport (portrait + width).
        // A would only match at landscape, so the cascade picks B.
        let bpA = Breakpoint(
            conditions: [
                .width(operator: .greaterThanOrEqual, value: 768, unit: .px),
                .orientation(.landscape)
            ],
            nodes: [:],
            style: ["#hero": Style(order: 1)]
        )
        let bpB = Breakpoint(
            conditions: [.width(operator: .greaterThanOrEqual, value: 768, unit: .px)],
            nodes: [:],
            style: ["#hero": Style(color: "red")]
        )
        let spec = Spec(
            version: 1,
            style: ["#hero": Style(order: 5)],
            breakpoints: [bpA, bpB],
            layout: Node(type: "div", props: NodeProps(id: "hero"))
        )

        var diags = JoyDiagnostics()
        let active = BreakpointResolver.active(
            in: Viewport(width: 1024, orientation: .portrait),
            breakpoints: spec.breakpoints
        )
        XCTAssertEqual(active, bpB, "B is the only breakpoint that matches a portrait wide viewport")
        let rules = RuleBuilder.buildRules(
            from: spec, activeBreakpoint: active, diagnostics: &diags
        )
        let nodes = StyleTreeBuilder.build(
            layout: spec.layout,
            rootID: "__joydom_root__",
            rules: rules,
            diagnostics: &diags
        )
        let hero = nodes.first(where: { $0.id == "hero" })!
        XCTAssertEqual(hero.computedStyle.item.order, 5,
                       "B doesn't set order — primary's order: 5 must survive")
        XCTAssertEqual(hero.computedStyle.visual.color, "red",
                       "B's color: red still applies on top of primary")
    }

    /// Spec ref: `DOM/guides/Breakpoints.md` "Restore the original node
    /// visibility". Same shape as the order test but for `display:
    /// none` — when the active breakpoint omits the field, the primary
    /// (which doesn't set it either) leaves the node visible.
    func testRemovingDisplayNoneFromBreakpointRestoresVisibility() {
        let bpA = Breakpoint(
            conditions: [
                .width(operator: .greaterThanOrEqual, value: 768, unit: .px),
                .orientation(.landscape)
            ],
            nodes: [:],
            style: ["#hero": Style(display: Display.none)]
        )
        let bpB = Breakpoint(
            conditions: [.width(operator: .greaterThanOrEqual, value: 768, unit: .px)],
            nodes: [:],
            style: ["#hero": Style(color: "red")]
        )
        let spec = Spec(
            version: 1,
            style: [:],
            breakpoints: [bpA, bpB],
            layout: Node(type: "div", props: NodeProps(id: "hero"))
        )

        var diags = JoyDiagnostics()
        let active = BreakpointResolver.active(
            in: Viewport(width: 1024, orientation: .portrait),
            breakpoints: spec.breakpoints
        )
        XCTAssertEqual(active, bpB)
        let rules = RuleBuilder.buildRules(
            from: spec, activeBreakpoint: active, diagnostics: &diags
        )
        let nodes = StyleTreeBuilder.build(
            layout: spec.layout,
            rootID: "__joydom_root__",
            rules: rules,
            diagnostics: &diags
        )
        let hero = nodes.first(where: { $0.id == "hero" })!
        XCTAssertEqual(hero.computedStyle.isDisplayNone, false,
                       "B doesn't set display — node must be visible")
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
