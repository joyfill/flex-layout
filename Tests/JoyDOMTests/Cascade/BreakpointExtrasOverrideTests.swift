import XCTest
@testable import JoyDOM

/// Phase 4 backfill: pin the "active breakpoint's `nodes[id].extras`
/// override the base node extras" contract end-to-end.
///
/// `JoyDOMView.renderSnapshot()` flattens
/// `Breakpoint.nodes[id].extras` into the `extrasOverrides` map that
/// `StyleTreeBuilder` merges over each node's base extras while
/// preserving non-overridden keys. This suite drives the merge
/// directly through `StyleTreeBuilder.build` so the contract is pinned
/// independently of the SwiftUI render path.
final class BreakpointExtrasOverrideTests: XCTestCase {

    /// Helper: resolve a single node's flattened props bag through the
    /// tree builder with an explicit `extrasOverrides` dictionary.
    private func resolvedProps(
        baseExtras: [String: JSONValue],
        overrides: [String: JSONValue]
    ) -> [String: JSONValue] {
        var diags = JoyDiagnostics()
        let layout = Node(
            type: "img",
            props: NodeProps(id: "x", extras: baseExtras)
        )
        let nodes = StyleTreeBuilder.build(
            layout: layout,
            rootID: "__joydom_root__",
            rules: [],
            classNameOverrides: [:],
            extrasOverrides: ["x": overrides],
            diagnostics: &diags
        )
        return nodes.first(where: { $0.id == "x" })!.props
    }

    func testActiveBreakpointExtrasReplaceMatchingKey() {
        let resolved = resolvedProps(
            baseExtras: ["src": .string("base.png")],
            overrides:  ["src": .string("retina.png")]
        )
        XCTAssertEqual(resolved["src"], .string("retina.png"),
                       "breakpoint override must win over base extras for the same key")
    }

    func testNonOverriddenBaseExtrasSurviveMerge() {
        let resolved = resolvedProps(
            baseExtras: [
                "src":  .string("base.png"),
                "alt":  .string("logo")
            ],
            overrides: ["src": .string("retina.png")]
        )
        XCTAssertEqual(resolved["src"], .string("retina.png"))
        XCTAssertEqual(resolved["alt"], .string("logo"),
                       "keys not present in the override map must pass through unchanged")
    }

    func testOverrideAddsNewKeyWithoutDroppingBase() {
        let resolved = resolvedProps(
            baseExtras: ["src": .string("base.png")],
            overrides:  ["alt": .string("retina-aware logo")]
        )
        XCTAssertEqual(resolved["src"], .string("base.png"))
        XCTAssertEqual(resolved["alt"], .string("retina-aware logo"))
    }

    /// End-to-end: a Spec with a base node + a breakpoint that overrides
    /// `extras` resolves through the same path JoyDOMView uses
    /// internally, confirming the wiring outside of just StyleTreeBuilder.
    func testEndToEndSpecResolvesActiveBreakpointExtrasOverride() {
        var diags = JoyDiagnostics()
        let spec = Spec(
            style: [:],
            breakpoints: [
                Breakpoint(
                    conditions: [],   // always active
                    nodes: ["x": NodeProps(extras: ["src": .string("retina.png")])]
                )
            ],
            layout: Node(
                type: "img",
                props: NodeProps(id: "x", extras: [
                    "src": .string("base.png"),
                    "alt": .string("logo")
                ])
            )
        )

        let active = BreakpointResolver.active(
            in: Viewport(width: 0),
            breakpoints: spec.breakpoints
        )
        XCTAssertNotNil(active, "empty-conditions breakpoint should activate")

        var extrasOverrides: [String: [String: JSONValue]] = [:]
        if let bp = active {
            for (id, props) in bp.nodes where !props.extras.isEmpty {
                extrasOverrides[id] = props.extras
            }
        }

        let rules = RuleBuilder.buildRules(from: spec, activeBreakpoint: active, diagnostics: &diags)
        let nodes = StyleTreeBuilder.build(
            layout: spec.layout,
            rootID: "__joydom_root__",
            rules: rules,
            classNameOverrides: [:],
            extrasOverrides: extrasOverrides,
            diagnostics: &diags
        )

        let x = nodes.first(where: { $0.id == "x" })!
        // Confirm the values reach what `ComponentResolver` would later
        // package into `ComponentProps.values` — same dictionary shape.
        let props = ComponentProps(x.props, id: x.id)
        XCTAssertEqual(props.values["src"], .string("retina.png"),
                       "active-breakpoint extras must override base for matching key")
        XCTAssertEqual(props.values["alt"], .string("logo"),
                       "non-overridden base extras must survive the merge")
    }
}
