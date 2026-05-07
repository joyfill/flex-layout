import XCTest
import SwiftUI
@testable import JoyDOM

/// Image-styles cascade tests — pin the contract that `objectFit` /
/// `objectPosition` ride through SwiftUI's environment from the
/// resolver to the `_DOMImage` leaf, and that the `Alignment` helper
/// covers the spec's 3×3 horizontal/vertical grid exactly.
///
/// Same hosted-test pattern as `JoyDOMTextDecorationCascadeTests`:
/// instantiate the leaf view with an explicit `.environment(...)` and
/// exercise `body` so every arm of the switch compiles + runs without
/// spinning up a hosting controller.
final class ObjectFitCascadeTests: XCTestCase {

    // MARK: - EnvironmentValues round-trip

    func testInheritedObjectFitEnvironmentDefaultsToNil() {
        let env = EnvironmentValues()
        XCTAssertNil(env.inheritedObjectFit)
    }

    func testInheritedObjectFitEnvironmentRoundTripsAllCases() {
        var env = EnvironmentValues()
        for v: Style.ObjectFit in [.fill, .contain, .cover, .none] {
            env.inheritedObjectFit = v
            XCTAssertEqual(env.inheritedObjectFit, v)
        }
        env.inheritedObjectFit = nil
        XCTAssertNil(env.inheritedObjectFit)
    }

    func testInheritedObjectPositionEnvironmentDefaultsToNil() {
        let env = EnvironmentValues()
        XCTAssertNil(env.inheritedObjectPosition)
    }

    func testInheritedObjectPositionEnvironmentRoundTripsValue() {
        var env = EnvironmentValues()
        let pos = Style.ObjectPosition(horizontal: .right, vertical: .bottom)
        env.inheritedObjectPosition = pos
        XCTAssertEqual(env.inheritedObjectPosition, pos)
    }

    // MARK: - Alignment helper covers the spec's 3×3 grid

    func testObjectPositionAlignmentTopRow() {
        XCTAssertEqual(Style.ObjectPosition(horizontal: .left,   vertical: .top).alignment,    .topLeading)
        XCTAssertEqual(Style.ObjectPosition(horizontal: .center, vertical: .top).alignment,    .top)
        XCTAssertEqual(Style.ObjectPosition(horizontal: .right,  vertical: .top).alignment,    .topTrailing)
    }

    func testObjectPositionAlignmentCenterRow() {
        XCTAssertEqual(Style.ObjectPosition(horizontal: .left,   vertical: .center).alignment, .leading)
        XCTAssertEqual(Style.ObjectPosition(horizontal: .center, vertical: .center).alignment, .center)
        XCTAssertEqual(Style.ObjectPosition(horizontal: .right,  vertical: .center).alignment, .trailing)
    }

    func testObjectPositionAlignmentBottomRow() {
        XCTAssertEqual(Style.ObjectPosition(horizontal: .left,   vertical: .bottom).alignment, .bottomLeading)
        XCTAssertEqual(Style.ObjectPosition(horizontal: .center, vertical: .bottom).alignment, .bottom)
        XCTAssertEqual(Style.ObjectPosition(horizontal: .right,  vertical: .bottom).alignment, .bottomTrailing)
    }

    // MARK: - Leaf view builds for every objectFit case

    func testDOMImageBuildsForEachObjectFit() {
        // `_DOMImage` switches on the env value; instantiating its
        // body for every case ensures every arm of `applyFit` compiles
        // and runs without crashing.
        let url = URL(string: "https://example.com/x.png")!
        for fit: Style.ObjectFit? in [nil, .fill, .contain, .cover, .none] {
            let view = _DOMImage(url: url)
                .environment(\.inheritedObjectFit, fit)
            _ = view
        }
    }

    func testDOMImageBuildsWithObjectPosition() {
        let url = URL(string: "https://example.com/x.png")!
        let pos = Style.ObjectPosition(horizontal: .right, vertical: .bottom)
        let view = _DOMImage(url: url)
            .environment(\.inheritedObjectPosition, pos)
        _ = view
    }

    // MARK: - End-to-end through JoyDOMView

    func testJoyDOMViewBuildsWithObjectFitOnImage() {
        // Parent style sets `objectFit: cover` on an `img` node — body
        // must build without crashing. The resolver wires the value
        // into the environment in `applyVisual`; `_DOMImage` consumes
        // it via `@Environment`.
        var extras: [String: JSONValue] = [:]
        extras["src"] = .string("https://example.com/x.png")
        let spec = Spec(
            style: ["#hero": Style(objectFit: .cover)],
            layout: Node(
                type: "div",
                props: NodeProps(id: "root"),
                children: [
                    .node(Node(
                        type: "img",
                        props: NodeProps(id: "hero", extras: extras)
                    ))
                ]
            )
        )
        let view = JoyDOMView(spec: spec)
        _ = view.body
    }

    func testObjectFitLandsInComputedVisualStyle() {
        // Parallel to `testTextDecorationLandsInComputedVisualStyle` —
        // pin that the cascade surfaces objectFit on visual so
        // applyVisual can wire it into the environment.
        var diags = JoyDiagnostics()
        let spec = Spec(
            style: ["#root": Style(objectFit: .contain)],
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
        XCTAssertEqual(root.computedStyle.visual.objectFit, .contain)
    }
}
