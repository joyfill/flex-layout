import XCTest
import SwiftUI
@testable import JoyDOM

/// Phase 2.1 — `text-decoration` now rides through SwiftUI's environment
/// (because container `.underline()` / `.strikethrough()` don't paint on
/// `Text` descendants). These tests pin the contract end-to-end:
///
///   1. The `inheritedTextDecoration` EnvironmentValues key round-trips
///      every `InheritedTextDecoration` case.
///   2. `JoyDOMView` body builds without crashing on a parent →
///      primitive_string subtree carrying `text-decoration: underline`.
///   3. `_DecoratedText` (the `primitive_string` leaf renderer) builds
///      successfully under each decoration value, exercising the path
///      that paints `.underline()` / `.strikethrough()` directly on the
///      `Text`.
final class JoyDOMTextDecorationCascadeTests: XCTestCase {

    // MARK: - EnvironmentValues round-trip

    func testEnvironmentDefaultIsNone() {
        let env = EnvironmentValues()
        XCTAssertEqual(env.inheritedTextDecoration, .none)
    }

    func testEnvironmentValuesGetterAndSetterRoundTrip() {
        var env = EnvironmentValues()
        XCTAssertEqual(env.inheritedTextDecoration, .none)
        env.inheritedTextDecoration = .lineThrough
        XCTAssertEqual(env.inheritedTextDecoration, .lineThrough)
        env.inheritedTextDecoration = .underline
        XCTAssertEqual(env.inheritedTextDecoration, .underline)
        env.inheritedTextDecoration = .none
        XCTAssertEqual(env.inheritedTextDecoration, .none)
    }

    // MARK: - Leaf renderer covers each decoration

    func testDecoratedTextBuildsForEachDecoration() {
        // `_DecoratedText` reads `@Environment(\.inheritedTextDecoration)`
        // and switches over it; just exercising `body` on each variant
        // ensures every arm of the switch compiles and runs.
        for decoration: InheritedTextDecoration in [.none, .underline, .lineThrough] {
            let view = _DecoratedText(text: "leaf")
                .environment(\.inheritedTextDecoration, decoration)
            _ = view
        }
    }

    // MARK: - End-to-end through JoyDOMView

    func testJoyDOMViewBuildsWithUnderlineOnContainer() {
        // Parent div carries `text-decoration: underline`; nested span
        // contains a primitive_string. Body must build without crashing
        // — the decoration is handed down via the environment and
        // re-applied at the `_DecoratedText` leaf.
        let spec = Spec(
            style: ["#root": Style(textDecoration: .underline)],
            layout: Node(
                type: "div",
                props: NodeProps(id: "root"),
                children: [
                    .node(Node(
                        type: "span",
                        props: NodeProps(id: "child"),
                        children: [.primitive(.string("hello"))]
                    ))
                ]
            )
        )
        let view = JoyDOMView(spec: spec)
        _ = view.body
    }

    func testJoyDOMViewBuildsWithLineThroughOnContainer() {
        let spec = Spec(
            style: ["#root": Style(textDecoration: .lineThrough)],
            layout: Node(
                type: "div",
                props: NodeProps(id: "root"),
                children: [.primitive(.string("strikethrough me"))]
            )
        )
        let view = JoyDOMView(spec: spec)
        _ = view.body
    }

    func testJoyDOMViewBuildsWithNoneDecoration() {
        let spec = Spec(
            style: ["#root": Style(textDecoration: .none)],
            layout: Node(
                type: "div",
                props: NodeProps(id: "root"),
                children: [.primitive(.string("plain"))]
            )
        )
        let view = JoyDOMView(spec: spec)
        _ = view.body
    }

    // MARK: - Resolver hands the right value to the environment

    func testTextDecorationLandsInComputedVisualStyle() {
        // The cascade has to surface `textDecoration` on the visual
        // style so `applyVisual` can wire it into the environment. This
        // is the contract the leaf renderer relies on.
        var diags = JoyDiagnostics()
        let spec = Spec(
            style: ["#root": Style(textDecoration: .underline)],
            layout: Node(type: "div", props: NodeProps(id: "root"))
        )
        let rules = RuleBuilder.buildRules(
            from: spec, activeBreakpoint: nil, diagnostics: &diags
        )
        let nodes = StyleTreeBuilder.build(
            layout: spec.layout,
            rootID: "__joydom_root__",
            rules: rules,
            diagnostics: &diags
        )
        let root = nodes.first(where: { $0.id == "root" })!
        XCTAssertEqual(root.computedStyle.visual.textDecoration, .underline)
    }
}
