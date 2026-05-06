import XCTest
@testable import JoyDOM

/// Pin the built-in User Agent stylesheet behavior:
///   • unstyled `h1`–`h6` resolve to the canonical browser defaults
///     (bold, progressively-sized) so iOS matches what payload
///     authors saw on the web reference renderer;
///   • author rules with equal-or-greater specificity beat UA
///     defaults per standard CSS cascade semantics;
///   • `.userAgentDefaults(false)` returns to spec-strict behavior
///     (empty visual on unstyled headings) for consumers that want
///     pure spec rendering.
final class UserAgentStylesTests: XCTestCase {

    // MARK: - Helpers

    /// Resolve every node in a `Spec` through the same pipeline
    /// `JoyDOMView.renderSnapshot()` uses — but without going through
    /// SwiftUI — so tests can inspect `ComputedStyle` per id.
    private func resolveCollectingDiagnostics(
        spec: Spec,
        applyUserAgentDefaults: Bool = true
    ) -> (byID: [String: ComputedStyle], diagnostics: JoyDiagnostics) {
        var diags = JoyDiagnostics()
        let rules = RuleBuilder.buildRules(
            from: spec,
            activeBreakpoint: nil,
            diagnostics: &diags,
            applyUserAgentDefaults: applyUserAgentDefaults
        )
        let nodes = StyleTreeBuilder.build(
            layout: spec.layout,
            rootID: "__joydom_root__",
            rules: rules,
            diagnostics: &diags
        )
        var byID: [String: ComputedStyle] = [:]
        for n in nodes { byID[n.id] = n.computedStyle }
        return (byID, diags)
    }

    /// Walk `Resolved.children` recursively to find a child whose
    /// node-tree id matches `id`. Used by the public-API test below
    /// since headings live deeper than the top level.
    private func find(
        id: String,
        in children: [ResolvedChild]
    ) -> ResolvedChild? {
        for child in children {
            if child.id == id { return child }
            if let nested = find(id: id, in: child.nested) {
                return nested
            }
        }
        return nil
    }

    private func headingSpec(type: String, id: String) -> Spec {
        Spec(
            style: [:],
            layout: Node(
                type: "div",
                props: NodeProps(id: "root"),
                children: [
                    .node(Node(
                        type: type,
                        props: NodeProps(id: id),
                        children: [.primitive(.string("Heading"))]
                    ))
                ]
            )
        )
    }

    // MARK: - 1. Unstyled h4 → bold, 16 px

    func testUnstyledH4ResolvesToBoldAt16px() {
        let (byID, _) = resolveCollectingDiagnostics(
            spec: headingSpec(type: "h4", id: "h")
        )
        let visual = byID["h"]?.visual
        XCTAssertEqual(visual?.fontWeight, .bold,
                       "unstyled h4 should pick up the UA bold default")
        XCTAssertEqual(visual?.fontSize, 16,
                       "unstyled h4 should pick up the UA 16 px default")
    }

    // MARK: - 2. Each heading → expected default

    func testEachHeadingResolvesToExpectedDefault() {
        let expected: [(type: String, size: CGFloat)] = [
            ("h1", 32),
            ("h2", 24),
            ("h3", 19),
            ("h4", 16),
            ("h5", 13),
            ("h6", 11),
        ]
        for (type, size) in expected {
            let (byID, _) = resolveCollectingDiagnostics(
                spec: headingSpec(type: type, id: "h")
            )
            XCTAssertEqual(byID["h"]?.visual.fontWeight, .bold,
                           "\(type) should be bold by default")
            XCTAssertEqual(byID["h"]?.visual.fontSize, size,
                           "\(type) should default to \(size) px")
        }
    }

    // MARK: - 3. Author type-selector beats UA on source order

    func testAuthorTypeSelectorBeatsUAOnSourceOrder() {
        // Author rule: `h1 { fontSize: 40 }` — same specificity
        // (0,0,0,1) as the UA `h1` rule, but later sourceOrder, so
        // it wins on the size while UA still contributes the
        // bold weight (the author rule didn't set fontWeight).
        let spec = Spec(
            style: ["h1": Style(fontSize: .px(40))],
            layout: Node(
                type: "div",
                props: NodeProps(id: "root"),
                children: [
                    .node(Node(
                        type: "h1",
                        props: NodeProps(id: "h"),
                        children: [.primitive(.string("Heading"))]
                    ))
                ]
            )
        )
        let (byID, _) = resolveCollectingDiagnostics(spec: spec)
        XCTAssertEqual(byID["h"]?.visual.fontSize, 40,
                       "author h1 fontSize should beat UA on source order")
        XCTAssertEqual(byID["h"]?.visual.fontWeight, .bold,
                       "UA bold weight should survive — author didn't set fontWeight")
    }

    // MARK: - 4. Author class-selector beats UA on specificity

    func testAuthorClassSelectorBeatsUAOnSpecificity() {
        // `.muted` is specificity (0,0,1,0) vs UA's (0,0,0,1) — class
        // wins regardless of source order. The numeric weight 300
        // overrides UA's `bold`.
        let spec = Spec(
            style: [".muted": Style(fontWeight: .numeric(300))],
            layout: Node(
                type: "div",
                props: NodeProps(id: "root"),
                children: [
                    .node(Node(
                        type: "h1",
                        props: NodeProps(id: "h", className: ["muted"]),
                        children: [.primitive(.string("Heading"))]
                    ))
                ]
            )
        )
        let (byID, _) = resolveCollectingDiagnostics(spec: spec)
        XCTAssertEqual(byID["h"]?.visual.fontWeight, .numeric(300),
                       "class selector should beat UA bold via specificity")
        // Size still inherits from UA (no author rule for fontSize).
        XCTAssertEqual(byID["h"]?.visual.fontSize, 32,
                       "UA h1 fontSize should still apply when class doesn't override it")
    }

    // MARK: - 5. .userAgentDefaults(false) disables the layer

    func testUserAgentDefaultsCanBeDisabled() {
        // Drive through the public render path so the modifier's
        // wire-up to RuleBuilder is exercised end-to-end.
        let spec = Spec(
            style: [:],
            layout: Node(
                type: "div",
                props: NodeProps(id: "root"),
                children: [
                    .node(Node(
                        type: "h4",
                        props: NodeProps(id: "h"),
                        children: [.primitive(.string("Heading"))]
                    ))
                ]
            )
        )
        let view = JoyDOMView(spec: spec).userAgentDefaults(false)
        let snapshot = view.renderSnapshot()
        guard let child = find(id: "h", in: snapshot.children) else {
            XCTFail("expected to find h4 child in resolved snapshot")
            return
        }
        XCTAssertNil(child.visualStyle.fontWeight,
                     "with UA disabled, unstyled h4 should have no fontWeight")
        XCTAssertNil(child.visualStyle.fontSize,
                     "with UA disabled, unstyled h4 should have no fontSize")

        // Sanity: with UA enabled (the default), the same payload
        // resolves to the bold/16 px UA defaults — proving the
        // modifier is the only thing toggling behavior.
        let defaultView = JoyDOMView(spec: spec)
        guard let defaultChild = find(id: "h", in: defaultView.renderSnapshot().children) else {
            XCTFail("expected to find h4 child in default-snapshot")
            return
        }
        XCTAssertEqual(defaultChild.visualStyle.fontWeight, .bold)
        XCTAssertEqual(defaultChild.visualStyle.fontSize, 16)
    }
}
