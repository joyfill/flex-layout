import XCTest
@testable import JoyDOM

/// Sibling-combinator support — `+` (adjacent sibling) and `~` (general
/// sibling). Three coverage zones:
///
///   1. **Parser** — `SelectorParser` recognizes `+` / `~` between
///      compounds and emits the right `Combinator` case.
///   2. **Matcher** — given a stylesheet with sibling-combinator rules
///      and a node's preceding siblings, the matcher selects the right
///      rules.
///   3. **End-to-end** — `StyleTreeBuilder` plumbs preceding-sibling
///      info into the resolver so a real layout (root with a few
///      children) cascades sibling rules correctly.
final class SiblingCombinatorTests: XCTestCase {

    // MARK: - Parser

    func testParserRecognizesAdjacentSibling() {
        var diags = JoyDiagnostics()
        let s = SelectorParser.parse("#a + #b", diagnostics: &diags)
        XCTAssertNotNil(s)
        XCTAssertEqual(s?.combinators, [.adjacentSibling])
        XCTAssertEqual(s?.parts.count, 2)
        XCTAssertTrue(diags.warnings.isEmpty)
    }

    func testParserRecognizesGeneralSibling() {
        var diags = JoyDiagnostics()
        let s = SelectorParser.parse("#a ~ #b", diagnostics: &diags)
        XCTAssertNotNil(s)
        XCTAssertEqual(s?.combinators, [.generalSibling])
        XCTAssertEqual(s?.parts.count, 2)
        XCTAssertTrue(diags.warnings.isEmpty)
    }

    func testParserMixesSiblingAndAncestorCombinators() {
        var diags = JoyDiagnostics()
        let s = SelectorParser.parse("#root > #a + .b", diagnostics: &diags)
        XCTAssertNotNil(s)
        XCTAssertEqual(s?.combinators, [.child, .adjacentSibling])
    }

    func testParserHandlesSiblingWithoutSpaces() {
        var diags = JoyDiagnostics()
        let s = SelectorParser.parse("#a+#b", diagnostics: &diags)
        XCTAssertNotNil(s, "no whitespace around `+` should still parse")
        XCTAssertEqual(s?.combinators, [.adjacentSibling])
    }

    func testParserDanglingSiblingFails() {
        var diags = JoyDiagnostics()
        XCTAssertNil(SelectorParser.parse("#a +", diagnostics: &diags))
        XCTAssertNil(SelectorParser.parse("+ #b", diagnostics: &diags))
    }

    // MARK: - Matcher (via StyleResolver)

    private func node(_ id: String, classes: [String] = []) -> StyleResolver.NodeRef {
        StyleResolver.NodeRef(id: id, schemaType: nil, classes: classes)
    }

    private func resolveSubject(
        css: String,
        subjectID: String,
        classes: [String] = [],
        precedingSiblings: [StyleResolver.NodeRef] = []
    ) -> ComputedStyle {
        var diags = JoyDiagnostics()
        let stylesheet = CSSParser.parse(css, diagnostics: &diags)
        return StyleResolver.resolve(
            id: subjectID,
            schemaType: nil,
            classes: classes,
            ancestors: [],
            precedingSiblings: precedingSiblings,
            stylesheet: stylesheet,
            diagnostics: &diags
        )
    }

    func testAdjacentSiblingMatchesImmediatelyPrecedingSibling() {
        // `.lead + .body { flex-grow: 1 }` should fire when the immediately
        // previous sibling has class `lead`.
        let style = resolveSubject(
            css: ".lead + .body { flex-grow: 1; }",
            subjectID: "x",
            classes: ["body"],
            precedingSiblings: [node("a", classes: ["lead"])]
        )
        XCTAssertEqual(style.item.grow, 1)
    }

    func testAdjacentSiblingDoesNotMatchNonAdjacent() {
        // `.lead + .body` must NOT fire when `.lead` isn't the IMMEDIATE
        // preceding sibling (something else sits between).
        let style = resolveSubject(
            css: ".lead + .body { flex-grow: 7; }",
            subjectID: "x",
            classes: ["body"],
            precedingSiblings: [
                node("a", classes: ["lead"]),
                node("b", classes: ["other"]),
            ]
        )
        XCTAssertNil(style.item.grow, "non-adjacent sibling shouldn't fire `+`")
    }

    func testGeneralSiblingMatchesAnyEarlierSibling() {
        // `.lead ~ .body` fires for any earlier sibling with .lead.
        let style = resolveSubject(
            css: ".lead ~ .body { flex-grow: 3; }",
            subjectID: "x",
            classes: ["body"],
            precedingSiblings: [
                node("a", classes: ["lead"]),
                node("b", classes: ["other"]),
            ]
        )
        XCTAssertEqual(style.item.grow, 3, "later sibling counts for `~`")
    }

    func testGeneralSiblingDoesNotMatchWhenNoEarlierMatches() {
        let style = resolveSubject(
            css: ".lead ~ .body { flex-grow: 5; }",
            subjectID: "x",
            classes: ["body"],
            precedingSiblings: [node("a", classes: ["other"])]
        )
        XCTAssertNil(style.item.grow)
    }

    func testNoPrecedingSiblingsMeansSiblingSelectorsNeverMatch() {
        let style = resolveSubject(
            css: ".x + .y { flex-grow: 9; } .x ~ .y { flex-shrink: 9; }",
            subjectID: "y",
            classes: ["y"],
            precedingSiblings: []
        )
        XCTAssertNil(style.item.grow)
        XCTAssertNil(style.item.shrink)
    }

    func testChainedSiblingCombinators() {
        // `.a + .b + .c` — subject is .c, prev is .b, prev-of-prev is .a.
        let style = resolveSubject(
            css: ".a + .b + .c { flex-grow: 4; }",
            subjectID: "x",
            classes: ["c"],
            precedingSiblings: [
                node("a", classes: ["a"]),
                node("b", classes: ["b"]),
            ]
        )
        XCTAssertEqual(style.item.grow, 4)
    }

    // MARK: - End-to-end (StyleTreeBuilder threads preceding siblings)

    func testStyleTreeBuilderAppliesAdjacentSiblingRule() {
        let css = ".first + .second { flex-grow: 2; }"
        var diags = JoyDiagnostics()
        let stylesheet = CSSParser.parse(css, diagnostics: &diags)
        let schema: [SchemaEntry] = [
            SchemaEntry(id: "first",  type: nil, classes: ["first"],  parentID: nil),
            SchemaEntry(id: "second", type: nil, classes: ["second"], parentID: nil),
        ]
        let nodes = StyleTreeBuilder.build(
            rootID: "root",
            schema: schema,
            stylesheet: stylesheet,
            diagnostics: &diags
        )
        let secondNode = nodes.first { $0.id == "second" }
        XCTAssertEqual(secondNode?.computedStyle.item.grow, 2,
                       "second's preceding sibling (first) carries .first → adjacent rule fires")
    }

    func testStyleTreeBuilderAppliesGeneralSiblingRule() {
        let css = ".alpha ~ .target { flex-grow: 6; }"
        var diags = JoyDiagnostics()
        let stylesheet = CSSParser.parse(css, diagnostics: &diags)
        let schema: [SchemaEntry] = [
            SchemaEntry(id: "alpha",  type: nil, classes: ["alpha"],  parentID: nil),
            SchemaEntry(id: "middle", type: nil, classes: ["filler"], parentID: nil),
            SchemaEntry(id: "target", type: nil, classes: ["target"], parentID: nil),
        ]
        let nodes = StyleTreeBuilder.build(
            rootID: "root",
            schema: schema,
            stylesheet: stylesheet,
            diagnostics: &diags
        )
        let target = nodes.first { $0.id == "target" }
        XCTAssertEqual(target?.computedStyle.item.grow, 6)
    }

    func testStyleTreeBuilderSiblingRuleScopesToParent() {
        // `.alpha ~ .target` should NOT fire across different parents.
        // `outer.alpha` and `inner.target` are not actual siblings.
        let css = ".alpha ~ .target { flex-grow: 8; }"
        var diags = JoyDiagnostics()
        let stylesheet = CSSParser.parse(css, diagnostics: &diags)
        let schema: [SchemaEntry] = [
            SchemaEntry(id: "outer",  type: nil, classes: ["alpha"],  parentID: nil),
            SchemaEntry(id: "wrap",   type: nil, classes: ["wrap"],   parentID: nil),
            SchemaEntry(id: "target", type: nil, classes: ["target"], parentID: "wrap"),
        ]
        let nodes = StyleTreeBuilder.build(
            rootID: "root",
            schema: schema,
            stylesheet: stylesheet,
            diagnostics: &diags
        )
        let target = nodes.first { $0.id == "target" }
        XCTAssertNil(target?.computedStyle.item.grow,
                     "cross-parent siblings should not match")
    }
}
