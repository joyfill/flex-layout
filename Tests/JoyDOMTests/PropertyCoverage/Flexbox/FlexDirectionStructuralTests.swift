// FlexDirectionStructuralTests — Layer 2 coverage for the 23 flexDirection
// samples shipped in PR #32 (`feat/flex-direction-coverage-samples`).
//
// Per sample we load the bundled JSON via `SpecPropertySamples.sample(withID:)`,
// decode it as a JoyDOM `Spec`, build cascade rules + a style tree, and
// assert the post-cascade `ComputedStyle` matches the sample's summary
// claim. No rendering — these are the cheapest possible regression
// catchers for "the cascade dropped my property" bugs.
//
// API notes (verified against current source):
//   • Container fields live on `ComputedStyle.container` (a
//     `FlexContainerConfig`): `direction`, `wrap`, `justifyContent`,
//     `alignItems`, `gap` (CGFloat), etc.
//   • Item fields live on `ComputedStyle.item` (an `ItemStyle`): `grow`,
//     `basis`, `order`, `alignSelf`, `position`, `width`/`height`, etc.
//   • `FlexContainerConfig.gap` is `CGFloat` (not a `FlexGap` enum), so the
//     gap assertion compares against `16` directly.
//   • Internal types (`StyleTreeBuilder`, `RuleBuilder`,
//     `StyleResolver.Rule`) are reachable via `@testable import JoyDOM`.

import XCTest
import FlexLayout
@testable import JoyDOM
import JoyDOMSampleSpecs

final class FlexDirectionStructuralTests: XCTestCase {

    // MARK: - Helpers

    /// Resolve a bundled sample through the full cascade and return the
    /// decoded spec, the style tree (root + descendants), and any
    /// diagnostics raised.
    private func resolved(
        _ sampleID: String,
        activeBreakpoint: Breakpoint? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> (spec: Spec, nodes: [StyleNode], diagnostics: JoyDiagnostics) {
        let sample = try XCTUnwrap(
            SpecPropertySamples.sample(withID: sampleID),
            "Sample \(sampleID) not in bundle",
            file: file, line: line
        )
        let spec = try JSONDecoder().decode(Spec.self, from: Data(sample.json.utf8))
        var diags = JoyDiagnostics()
        let rules = RuleBuilder.buildRules(
            from: spec,
            activeBreakpoint: activeBreakpoint,
            diagnostics: &diags
        )
        let nodes = StyleTreeBuilder.build(
            layout: spec.layout,
            rootID: "__joydom_root__",
            rules: rules,
            diagnostics: &diags
        )
        return (spec, nodes, diags)
    }

    /// The author-supplied root node (`#root`, `#wrap`, …). We accept any
    /// id since some samples (`flex-direction-in-absolute`) wrap their
    /// content under `#wrap` instead of `#root`.
    private func node(
        _ id: String,
        in nodes: [StyleNode],
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> StyleNode {
        try XCTUnwrap(
            nodes.first(where: { $0.id == id }),
            "node #\(id) not in style tree",
            file: file, line: line
        )
    }

    // MARK: - 1. Direct flex-direction values

    func test_flexDirection_row_resolvesToRowDirection() throws {
        let (_, nodes, _) = try resolved("flexbox-flex-direction-row")
        XCTAssertEqual(try node("root", in: nodes).computedStyle.container.direction, .row)
    }

    func test_flexDirection_column_resolvesToColumnDirection() throws {
        let (_, nodes, _) = try resolved("flexbox-flex-direction-column")
        XCTAssertEqual(try node("root", in: nodes).computedStyle.container.direction, .column)
    }

    func test_flexDirection_rowReverse_resolvesToRowReverseDirection() throws {
        let (_, nodes, _) = try resolved("flexbox-flex-direction-row-reverse")
        XCTAssertEqual(try node("root", in: nodes).computedStyle.container.direction, .rowReverse)
    }

    func test_flexDirection_columnReverse_resolvesToColumnReverseDirection() throws {
        let (_, nodes, _) = try resolved("flexbox-flex-direction-column-reverse")
        XCTAssertEqual(try node("root", in: nodes).computedStyle.container.direction, .columnReverse)
    }

    func test_flexDirection_default_matchesFlexContainerConfigDefault() throws {
        let (_, nodes, _) = try resolved("flexbox-flex-direction-default")
        // Sample omits `flexDirection`, so the resolver should fall back
        // to the FlexLayout-compiled default (currently `.row`).
        XCTAssertEqual(
            try node("root", in: nodes).computedStyle.container.direction,
            FlexContainerConfig().direction,
            "unset flexDirection should resolve to FlexContainerConfig's compiled-in default"
        )
    }

    // MARK: - 2. Composition with other container properties

    func test_flexDirection_withWrap_alsoSetsWrap() throws {
        let (_, nodes, _) = try resolved("flexbox-flex-direction-with-wrap")
        let root = try node("root", in: nodes).computedStyle.container
        XCTAssertEqual(root.direction, .row)
        XCTAssertEqual(root.wrap, .wrap)
    }

    func test_flexDirection_withJustifyEnd_columnReverseAndJustifyFlexEnd() throws {
        let (_, nodes, _) = try resolved("flexbox-flex-direction-with-justify-end")
        let root = try node("root", in: nodes).computedStyle.container
        XCTAssertEqual(root.direction, .columnReverse)
        XCTAssertEqual(root.justifyContent, .flexEnd)
    }

    func test_flexDirection_columnWithWrap_columnAndWrap() throws {
        let (_, nodes, _) = try resolved("flexbox-flex-direction-column-with-wrap")
        let root = try node("root", in: nodes).computedStyle.container
        XCTAssertEqual(root.direction, .column)
        XCTAssertEqual(root.wrap, .wrap)
    }

    func test_flexDirection_withGap_rowAndGapApplied() throws {
        let (_, nodes, _) = try resolved("flexbox-flex-direction-with-gap")
        let root = try node("root", in: nodes).computedStyle.container
        XCTAssertEqual(root.direction, .row)
        // `FlexContainerConfig.gap` is a plain `CGFloat` (not an enum), so
        // we assert the resolved point value directly.
        XCTAssertEqual(root.gap, 16)
    }

    // MARK: - 3. Tree-shape edge cases

    func test_flexDirection_empty_rootHasNoChildren() throws {
        let (_, nodes, _) = try resolved("flexbox-flex-direction-empty")
        let authorNodes = nodes.filter { $0.id != "__joydom_root__" && $0.id != "root" }
        XCTAssertTrue(
            authorNodes.isEmpty,
            "empty sample should register only the implicit + author root; got \(authorNodes.map(\.id))"
        )
    }

    func test_flexDirection_singleChild_hasExactlyOneAuthoredDescendant() throws {
        let (_, nodes, _) = try resolved("flexbox-flex-direction-single-child")
        let descendants = nodes.filter { $0.parentID == "root" }
        XCTAssertEqual(descendants.count, 1, "expected exactly one child under #root")
        XCTAssertEqual(descendants.first?.id, "only")
    }

    // MARK: - 4. Cross-axis + per-item properties

    func test_flexDirection_withAlignItems_rootCentersChildrenAndChildHeightsTake() throws {
        let (_, nodes, _) = try resolved("flexbox-flex-direction-with-align-items")
        let root = try node("root", in: nodes).computedStyle.container
        XCTAssertEqual(root.direction, .row)
        XCTAssertEqual(root.alignItems, .center)
        XCTAssertEqual(try node("a", in: nodes).computedStyle.item.height, .points(30))
        XCTAssertEqual(try node("b", in: nodes).computedStyle.item.height, .points(60))
        XCTAssertEqual(try node("c", in: nodes).computedStyle.item.height, .points(90))
    }

    func test_flexDirection_withAlignSelf_bDropsToFlexEnd() throws {
        let (_, nodes, _) = try resolved("flexbox-flex-direction-with-align-self")
        XCTAssertEqual(try node("b", in: nodes).computedStyle.item.alignSelf, .flexEnd)
        XCTAssertEqual(try node("a", in: nodes).computedStyle.item.alignSelf, .auto)
        XCTAssertEqual(try node("c", in: nodes).computedStyle.item.alignSelf, .auto)
    }

    func test_flexDirection_withOrder_abcOrderingIs312() throws {
        let (_, nodes, _) = try resolved("flexbox-flex-direction-with-order")
        XCTAssertEqual(try node("a", in: nodes).computedStyle.item.order, 3)
        XCTAssertEqual(try node("b", in: nodes).computedStyle.item.order, 1)
        XCTAssertEqual(try node("c", in: nodes).computedStyle.item.order, 2)
    }

    func test_flexDirection_withGrow_abcGrowIs112() throws {
        let (_, nodes, _) = try resolved("flexbox-flex-direction-with-grow")
        XCTAssertEqual(try node("a", in: nodes).computedStyle.item.grow, 1)
        XCTAssertEqual(try node("b", in: nodes).computedStyle.item.grow, 1)
        XCTAssertEqual(try node("c", in: nodes).computedStyle.item.grow, 2)
    }

    func test_flexDirection_withBasis_abcBasisCasesAreAutoPointsFraction() throws {
        let (_, nodes, _) = try resolved("flexbox-flex-direction-with-basis")
        XCTAssertEqual(try node("a", in: nodes).computedStyle.item.basis, .auto)
        XCTAssertEqual(try node("b", in: nodes).computedStyle.item.basis, .points(80))
        // 30% → fraction(0.30). Use exact equality since the resolver
        // normalises percent to a 0…1 fraction without rounding.
        XCTAssertEqual(try node("c", in: nodes).computedStyle.item.basis, .fraction(0.30))
    }

    // MARK: - 5. Responsive — breakpoint flip

    func test_flexDirection_responsive_isColumnBelowBreakpoint() throws {
        let (_, nodes, _) = try resolved("flexbox-flex-direction-responsive")
        XCTAssertEqual(try node("root", in: nodes).computedStyle.container.direction, .column,
                       "no active breakpoint → base rule (column) applies")
    }

    func test_flexDirection_responsive_flipsToRowAtBreakpoint() throws {
        // Look up the >=768px breakpoint from the spec rather than
        // hard-coding a Breakpoint literal, so this stays in sync with
        // any future tweak to the sample JSON.
        let sample = try XCTUnwrap(
            SpecPropertySamples.sample(withID: "flexbox-flex-direction-responsive")
        )
        let spec = try JSONDecoder().decode(Spec.self, from: Data(sample.json.utf8))
        let bp = try XCTUnwrap(spec.breakpoints.first, "sample must define at least one breakpoint")
        let (_, nodes, _) = try resolved("flexbox-flex-direction-responsive", activeBreakpoint: bp)
        XCTAssertEqual(try node("root", in: nodes).computedStyle.container.direction, .row,
                       "active >=768px breakpoint should flip flexDirection to row")
    }

    // MARK: - 6. Nesting / position / fixed width

    func test_flexDirection_nested_outerRowInnerColumns() throws {
        let (_, nodes, _) = try resolved("flexbox-flex-direction-nested")
        XCTAssertEqual(try node("root", in: nodes).computedStyle.container.direction, .row)
        XCTAssertEqual(try node("left", in: nodes).computedStyle.container.direction, .column)
        XCTAssertEqual(try node("right", in: nodes).computedStyle.container.direction, .column)
    }

    func test_flexDirection_inAbsolute_overlayIsAbsoluteAndRow() throws {
        let (_, nodes, _) = try resolved("flexbox-flex-direction-in-absolute")
        let overlay = try node("overlay", in: nodes).computedStyle
        XCTAssertEqual(overlay.item.position, .absolute)
        XCTAssertEqual(overlay.container.direction, .row)
    }

    func test_flexDirection_inFixedWidth_rootIs250pxAndRow() throws {
        let (_, nodes, _) = try resolved("flexbox-flex-direction-in-fixed-width")
        let root = try node("root", in: nodes).computedStyle
        XCTAssertEqual(root.item.width, .points(250))
        XCTAssertEqual(root.container.direction, .row)
    }

    // MARK: - 7. Selector / inline plumbing proofs

    func test_flexDirection_classSelector_bothStacksGetColumn() throws {
        let (_, nodes, _) = try resolved("flexbox-flex-direction-class-selector")
        XCTAssertEqual(try node("a", in: nodes).computedStyle.container.direction, .column,
                       ".stack rule should set #a's direction")
        XCTAssertEqual(try node("b", in: nodes).computedStyle.container.direction, .column,
                       ".stack rule should also reach #b")
    }

    func test_flexDirection_inline_rootDirectionFromPropsStyle() throws {
        let (_, nodes, _) = try resolved("flexbox-flex-direction-inline")
        XCTAssertEqual(try node("root", in: nodes).computedStyle.container.direction, .row,
                       "inline props.style should set flexDirection")
    }
}
