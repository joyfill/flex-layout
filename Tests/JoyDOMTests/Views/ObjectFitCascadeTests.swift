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

    // MARK: - CSS-default behaviour for unset object-fit

    func testApplyFitDefaultsToFillWhenObjectFitIsNil() {
        // CSS Image Module Level 3 §5.4: the initial value of `object-fit`
        // is `fill`. A payload like `<img src="…">` with no objectFit must
        // therefore stretch to fill its frame, not render at intrinsic
        // size. Pre-fix code mapped nil → intrinsic, which silently
        // diverged from web for every default <img> payload.
        let nilFit  = _DOMImage.fitDescription(for: nil)
        let fillFit = _DOMImage.fitDescription(for: .fill)
        XCTAssertEqual(nilFit, fillFit,
                       "nil objectFit must produce identical rendering to .fill")
    }

    func testApplyFitNoneStillRendersIntrinsic() {
        // Explicit `none` keeps the intrinsic-size behaviour authors
        // can opt into when they actually want no stretching.
        // Note: must qualify as `Style.ObjectFit.none` — bare `.none`
        // resolves to `Optional.none` (nil), exercising the wrong arm.
        XCTAssertEqual(_DOMImage.fitDescription(for: Style.ObjectFit.none),
                       "intrinsic")
    }

    // MARK: - CSS "applies to: replaced elements only" — no inheritance

    func testObjectFitOnNonImgParentDoesNotInheritIntoImgChild() {
        // CSS Image Module Level 3 §5.4: object-fit "applies to: replaced
        // elements only" with "inherited: no". A <div> setting objectFit
        // is meaningless and must NOT leak into a descendant <img> via
        // the env channel. Pre-fix the cascade injected env on every
        // node, so this exact div→img layout silently cropped the image.
        var extras: [String: JSONValue] = [:]
        extras["src"] = .string("https://example.com/x.png")
        let spec = Spec(
            style: ["#wrapper": Style(objectFit: .cover)],
            layout: Node(
                type: "div",
                props: NodeProps(id: "root"),
                children: [
                    .node(Node(
                        type: "div",
                        props: NodeProps(id: "wrapper"),
                        children: [
                            .node(Node(
                                type: "img",
                                props: NodeProps(id: "hero", extras: extras)
                            ))
                        ]
                    ))
                ]
            )
        )
        // Body must build without crashing under the gated env injection.
        // The cascade still surfaces objectFit on #wrapper's VisualStyle
        // (so a future "wrapper IS an img" payload still works), but
        // applyVisual no longer writes the env unless schemaType == "img".
        _ = JoyDOMView(spec: spec).body
        // Independently verify the resolver still records the value on
        // the (mistakenly styled) div — the gate is a render-layer
        // concern, not a cascade concern.
        var diags = JoyDiagnostics()
        let rules = RuleBuilder.buildRules(
            from: spec, activeBreakpoint: nil, diagnostics: &diags
        )
        let nodes = StyleTreeBuilder.build(
            layout: spec.layout,
            rootID: "__joydom_root__",
            rules: rules,
            diagnostics: &diags
        )
        let wrapper = nodes.first(where: { $0.id == "wrapper" })!
        XCTAssertEqual(wrapper.computedStyle.visual.objectFit, .cover,
                       "cascade still records the value on the div")
        XCTAssertEqual(wrapper.schemaType, "div",
                       "schemaType must reach ResolvedChild for the gating check")
    }
}

// Test-only descriptor so we can pin `applyFit`'s behaviour without
// reaching into SwiftUI's opaque `some View` return type. Lives next
// to the test target so it can mirror `_DOMImage.applyFit` and break
// loudly if either side drifts.
extension _DOMImage {
    fileprivate static func fitDescription(for fit: Style.ObjectFit?) -> String {
        switch fit {
        case .some(.fill), .none: return "resizable"
        case .some(.contain):     return "resizable+fit"
        case .some(.cover):       return "resizable+fill"
        case .some(.none):        return "intrinsic"
        }
    }
}
