import XCTest
@testable import JoyDOM
import FlexLayout

/// Tests for the CSS properties and element types added in the spec-gaps
/// branch (joyfill/.joy PR #33 full conformance).
///
/// Coverage:
///   • JSON round-trip for every new Style field and associated enum
///   • `NodeProps.extras` open bag encode/decode
///   • StyleResolver.apply() maps new fields to ComputedStyle correctly
///   • New element types register and resolve in DefaultPrimitives
final class SpecGapTests: XCTestCase {

    // MARK: - Helpers

    private func roundTrip<T: Codable & Equatable>(
        _ value: T,
        file: StaticString = #file, line: UInt = #line
    ) throws {
        let data    = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(T.self, from: data)
        XCTAssertEqual(decoded, value, file: file, line: line)
    }

    private func decode<T: Decodable>(_ type: T.Type, from json: String) throws -> T {
        try JSONDecoder().decode(T.self, from: Data(json.utf8))
    }

    private func resolve(style: Style) -> ComputedStyle {
        var diags = JoyDiagnostics()
        let spec = Spec(
            style: ["#x": style],
            layout: Node(type: "div", props: NodeProps(id: "x"))
        )
        let rules = RuleBuilder.buildRules(from: spec, activeBreakpoint: nil, diagnostics: &diags)
        let nodes = StyleTreeBuilder.build(
            layout: spec.layout,
            rootID: "__joydom_root__",
            rules: rules,
            diagnostics: &diags
        )
        return nodes.first(where: { $0.id == "x" })!.computedStyle
    }

    // MARK: - alignSelf

    func testAlignSelfRoundTrip() throws {
        try roundTrip(Style.AlignSelf.auto)
        try roundTrip(Style.AlignSelf.flexStart)
        try roundTrip(Style.AlignSelf.flexEnd)
        try roundTrip(Style.AlignSelf.center)
        try roundTrip(Style.AlignSelf.stretch)
    }

    func testAlignSelfDecodesRawValues() throws {
        XCTAssertEqual(try decode(Style.AlignSelf.self, from: #""auto""#),      .auto)
        XCTAssertEqual(try decode(Style.AlignSelf.self, from: #""flex-start""#),.flexStart)
        XCTAssertEqual(try decode(Style.AlignSelf.self, from: #""flex-end""#),  .flexEnd)
        XCTAssertEqual(try decode(Style.AlignSelf.self, from: #""center""#),    .center)
        XCTAssertEqual(try decode(Style.AlignSelf.self, from: #""stretch""#),   .stretch)
    }

    func testAlignSelfMapsToItemStyle() {
        XCTAssertEqual(resolve(style: Style(alignSelf: .flexStart)).item.alignSelf, .flexStart)
        XCTAssertEqual(resolve(style: Style(alignSelf: .flexEnd)).item.alignSelf,   .flexEnd)
        XCTAssertEqual(resolve(style: Style(alignSelf: .center)).item.alignSelf,    .center)
        XCTAssertEqual(resolve(style: Style(alignSelf: .stretch)).item.alignSelf,   .stretch)
        XCTAssertEqual(resolve(style: Style(alignSelf: .auto)).item.alignSelf,      .auto)
    }

    // MARK: - rowGap / columnGap

    func testRowGapAndColumnGapRoundTrip() throws {
        try roundTrip(Style(rowGap: .px(8), columnGap: .px(16)))
    }

    func testRowGapMapsToContainer() {
        XCTAssertEqual(resolve(style: Style(rowGap: .px(12))).container.rowGap, 12)
    }

    func testColumnGapMapsToContainer() {
        XCTAssertEqual(resolve(style: Style(columnGap: .px(8))).container.columnGap, 8)
    }

    func testRowColumnGapOverrideUniformGap() {
        let s = Style(gap: .uniform(.px(20)), rowGap: .px(5))
        let c = resolve(style: s)
        XCTAssertEqual(c.container.gap, 20, "uniform gap applied first")
        XCTAssertEqual(c.container.rowGap, 5,  "rowGap overrides uniform gap's row component")
    }

    // MARK: - min/max sizing

    func testMinMaxSizingRoundTrip() throws {
        try roundTrip(Style(minWidth: .px(100), maxWidth: .px(400),
                            minHeight: .px(50),  maxHeight: .px(200)))
    }

    func testMinMaxMapsToItemStyle() {
        let c = resolve(style: Style(minWidth: .px(50), maxWidth: .px(300),
                                     minHeight: .px(20), maxHeight: .px(100)))
        XCTAssertEqual(c.item.minWidth,  50)
        XCTAssertEqual(c.item.maxWidth,  300)
        XCTAssertEqual(c.item.minHeight, 20)
        XCTAssertEqual(c.item.maxHeight, 100)
    }

    // MARK: - display: none

    func testDisplayNoneRoundTrip() throws {
        try roundTrip(Style(display: Display.none))
    }

    func testDisplayNoneSetsIsDisplayNone() {
        XCTAssertTrue(resolve(style: Style(display: Display.none)).isDisplayNone)
    }

    func testDisplayFlexClearsDisplayNone() {
        // none first, then flex — last rule wins.
        var diags = JoyDiagnostics()
        let spec = Spec(
            style: [".hide": Style(display: Display.none), "#x": Style(display: .flex)],
            layout: Node(type: "div", props: NodeProps(id: "x", className: ["hide"]))
        )
        let rules = RuleBuilder.buildRules(from: spec, activeBreakpoint: nil, diagnostics: &diags)
        let nodes = StyleTreeBuilder.build(layout: spec.layout, rootID: "__joydom_root__",
                                           rules: rules, diagnostics: &diags)
        let computed = nodes.first(where: { $0.id == "x" })!.computedStyle
        XCTAssertFalse(computed.isDisplayNone)
    }

    // MARK: - justifyContent: spaceEvenly

    func testJustifyContentSpaceEvenlyRoundTrip() throws {
        try roundTrip(Style(justifyContent: .spaceEvenly))
    }

    func testJustifyContentSpaceEvenlyMapsToContainer() {
        XCTAssertEqual(
            resolve(style: Style(justifyContent: .spaceEvenly)).container.justifyContent,
            .spaceEvenly
        )
    }

    // MARK: - alignItems: stretch

    func testAlignItemsStretchRoundTrip() throws {
        try roundTrip(Style(alignItems: .stretch))
    }

    func testAlignItemsStretchMapsToContainer() {
        XCTAssertEqual(
            resolve(style: Style(alignItems: .stretch)).container.alignItems,
            .stretch
        )
    }

    // MARK: - backgroundColor / opacity

    func testBackgroundColorRoundTrip() throws {
        try roundTrip(Style(backgroundColor: "#FF0000"))
    }

    func testBackgroundColorMapsToVisual() {
        XCTAssertEqual(resolve(style: Style(backgroundColor: "#0099FF")).visual.backgroundColor, "#0099FF")
    }

    func testOpacityRoundTrip() throws {
        try roundTrip(Style(opacity: 0.5))
    }

    func testOpacityMapsToVisual() {
        XCTAssertEqual(resolve(style: Style(opacity: 0.75)).visual.opacity, 0.75)
    }

    // MARK: - border

    func testBorderPropertiesRoundTrip() throws {
        try roundTrip(Style(
            borderWidth: .px(2),
            borderColor: "#000000",
            borderStyle: .solid
        ))
    }

    func testBorderStyleNoneRoundTrip() throws {
        let s = try decode(Style.self, from: #"{"borderStyle":"none"}"#)
        XCTAssertEqual(s.borderStyle, Style.BorderStyleProp.none)
    }

    func testBorderMapsToVisual() {
        let c = resolve(style: Style(borderWidth: .px(1), borderColor: "#333333", borderStyle: .solid))
        XCTAssertEqual(c.visual.borderWidth, 1)
        XCTAssertEqual(c.visual.borderColor, "#333333")
        XCTAssertEqual(c.visual.borderStyle, .solid)
    }

    // MARK: - borderRadius

    func testBorderRadiusUniformRoundTrip() throws {
        try roundTrip(Style(borderRadius: .uniform(.px(8))))
    }

    func testBorderRadiusCornersRoundTrip() throws {
        try roundTrip(Style(borderRadius: .corners(
            topLeft:     .px(4),
            topRight:    .px(8),
            bottomRight: .px(4),
            bottomLeft:  .px(8)
        )))
    }

    func testBorderRadiusPartialCornersRoundTrip() throws {
        try roundTrip(Style(borderRadius: .corners(
            topLeft: .px(12), topRight: nil, bottomRight: nil, bottomLeft: nil
        )))
    }

    func testBorderRadiusMapsToVisual() {
        let c = resolve(style: Style(borderRadius: .uniform(.px(12))))
        guard case .uniform(let l) = c.visual.borderRadius else {
            XCTFail("expected .uniform"); return
        }
        XCTAssertEqual(l, .px(12))
    }

    // MARK: - margin

    func testMarginUniformRoundTrip() throws {
        try roundTrip(Style(margin: .uniform(.px(16))))
    }

    func testMarginSidesRoundTrip() throws {
        try roundTrip(Style(margin: .sides(top: .px(8), right: .px(4),
                                           bottom: .px(8), left: .px(4))))
    }

    func testMarginMapsToVisual() {
        let c = resolve(style: Style(margin: .uniform(.px(10))))
        guard case .uniform(let l) = c.visual.margin else {
            XCTFail("expected .uniform"); return
        }
        XCTAssertEqual(l, .px(10))
    }

    // MARK: - Typography

    func testFontWeightNamedRoundTrip() throws {
        try roundTrip(Style(fontWeight: .normal))
        try roundTrip(Style(fontWeight: .bold))
    }

    func testFontWeightNumericRoundTrip() throws {
        for n in [100, 200, 300, 400, 500, 600, 700, 800, 900] {
            try roundTrip(Style(fontWeight: .numeric(n)))
        }
    }

    func testFontWeightDecodesNamedStrings() throws {
        XCTAssertEqual(try decode(Style.FontWeight.self, from: #""normal""#), .normal)
        XCTAssertEqual(try decode(Style.FontWeight.self, from: #""bold""#),   .bold)
    }

    func testFontWeightDecodesNumbers() throws {
        XCTAssertEqual(try decode(Style.FontWeight.self, from: "700"), .numeric(700))
    }

    func testFontWeightEncodesNormally() throws {
        let data = try JSONEncoder().encode(Style.FontWeight.normal)
        XCTAssertEqual(String(data: data, encoding: .utf8), "\"normal\"")
    }

    func testFontWeightEncodesNumeric() throws {
        let data = try JSONEncoder().encode(Style.FontWeight.numeric(600))
        XCTAssertEqual(String(data: data, encoding: .utf8), "600")
    }

    func testTypographyRoundTrip() throws {
        try roundTrip(Style(
            fontFamily: "Inter",
            fontSize:   .px(16),
            fontWeight: .numeric(600),
            fontStyle:  .italic,
            color:      "#1A1A1A",
            textDecoration: .underline,
            textAlign:  .center,
            textTransform: .uppercase,
            lineHeight: 1.5,
            letterSpacing: .px(0.5),
            textOverflow: .ellipsis,
            whiteSpace: .nowrap
        ))
    }

    func testTypographyMapsToVisual() {
        let c = resolve(style: Style(
            fontFamily: "Helvetica",
            fontSize:   .px(14),
            fontWeight: .bold,
            color:      "#FF0000",
            textAlign:  .right,
            lineHeight: 1.4,
            letterSpacing: .px(1.0),
            textOverflow: .ellipsis,
            whiteSpace: .nowrap
        ))
        XCTAssertEqual(c.visual.fontFamily,    "Helvetica")
        XCTAssertEqual(c.visual.fontSize,      14)
        XCTAssertEqual(c.visual.fontWeight,    .bold)
        XCTAssertEqual(c.visual.color,         "#FF0000")
        XCTAssertEqual(c.visual.textAlign,     .right)
        XCTAssertEqual(c.visual.lineHeight,    1.4)
        XCTAssertEqual(c.visual.letterSpacing, 1.0)
        XCTAssertEqual(c.visual.textOverflow,  .ellipsis)
        XCTAssertEqual(c.visual.whiteSpace,    .nowrap)
    }

    func testTextDecorationRoundTrip() throws {
        XCTAssertEqual(try decode(Style.TextDecoration.self, from: #""line-through""#), .lineThrough)
        try roundTrip(Style(textDecoration: .lineThrough))
    }

    // MARK: - NodeProps extras (JSONValue)

    func testNodePropsExtrasRoundTrip() throws {
        let json = #"{"id":"btn","label":"Click me","count":3,"active":true}"#
        let props = try decode(NodeProps.self, from: json)
        XCTAssertEqual(props.id, "btn")
        XCTAssertEqual(props.extras["label"],  .string("Click me"))
        XCTAssertEqual(props.extras["count"],  .number(3))
        XCTAssertEqual(props.extras["active"], .bool(true))
    }

    func testNodePropsExtrasDoNotContainKnownKeys() throws {
        let json = #"{"id":"x","className":["a"],"style":{},"custom":"yes"}"#
        let props = try decode(NodeProps.self, from: json)
        XCTAssertNil(props.extras["id"])
        XCTAssertNil(props.extras["className"])
        XCTAssertNil(props.extras["style"])
        XCTAssertEqual(props.extras["custom"], .string("yes"))
    }

    func testNodePropsExtrasEncodeToJSON() throws {
        let props = NodeProps(id: "x", extras: ["src": .string("https://example.com/img.png")])
        let data = try JSONEncoder().encode(props)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(json?["src"] as? String, "https://example.com/img.png")
    }

    func testNodePropsExtrasNestedObjectAndArray() throws {
        let json = #"{"nested":{"key":1},"list":[1,2,3],"nothing":null}"#
        let props = try decode(NodeProps.self, from: json)
        XCTAssertEqual(props.extras["nested"], .object(["key": .number(1)]))
        XCTAssertEqual(props.extras["list"],   .array([.number(1), .number(2), .number(3)]))
        XCTAssertEqual(props.extras["nothing"], .null)
        // Round-trip the full NodeProps.
        try roundTrip(props)
    }

    func testJSONValueStringValueFlattening() {
        XCTAssertEqual(JSONValue.string("hello").stringValue, "hello")
        XCTAssertEqual(JSONValue.number(42).stringValue,      "42")
        XCTAssertEqual(JSONValue.number(3.14).stringValue,    "3.14")
        XCTAssertEqual(JSONValue.bool(true).stringValue,      "true")
        XCTAssertEqual(JSONValue.bool(false).stringValue,     "false")
        XCTAssertNil(JSONValue.null.stringValue)
        XCTAssertNil(JSONValue.array([]).stringValue)
        XCTAssertNil(JSONValue.object([:]).stringValue)
    }

    func testNodePropsExtrasFlowThroughToStyleNode() {
        var diags = JoyDiagnostics()
        let spec = Spec(
            layout: Node(type: "img",
                         props: NodeProps(id: "hero", extras: [
                             "src":    .string("https://example.com/img.png"),
                             "config": .object(["mode": .string("compact")])
                         ]))
        )
        let nodes = StyleTreeBuilder.build(
            layout: spec.layout,
            rootID: "__joydom_root__",
            rules: [],
            diagnostics: &diags
        )
        let hero = nodes.first(where: { $0.id == "hero" })!
        // Scalar string is preserved.
        XCTAssertEqual(hero.props["src"], .string("https://example.com/img.png"))
        // Structured object is preserved losslessly (not dropped).
        XCTAssertEqual(hero.props["config"], .object(["mode": .string("compact")]))
    }

    // MARK: - FlexBasisValue

    func testFlexBasisAutoDecodes() throws {
        let s = try decode(Style.self, from: #"{"flexBasis":"auto"}"#)
        XCTAssertEqual(s.flexBasis, .auto)
    }

    func testFlexBasisLengthDecodes() throws {
        let s = try decode(Style.self, from: #"{"flexBasis":{"value":100,"unit":"px"}}"#)
        XCTAssertEqual(s.flexBasis, .length(.px(100)))
    }

    func testFlexBasisAutoRoundTrip() throws {
        try roundTrip(Style(flexBasis: .auto))
    }

    func testFlexBasisLengthRoundTrip() throws {
        try roundTrip(Style(flexBasis: .length(.px(200))))
    }

    func testFlexBasisAutoMapsToFlexAuto() {
        let c = resolve(style: Style(flexBasis: .auto))
        XCTAssertEqual(c.item.basis, .auto)
    }

    func testFlexBasisLengthMapsToPoints() {
        let c = resolve(style: Style(flexBasis: .length(.px(120))))
        XCTAssertEqual(c.item.basis, .points(120))
    }

    // MARK: - New element types in DefaultPrimitives

    func testHeadingElementsRegister() {
        let registry = ComponentRegistry().withDefaultPrimitives()
        for type_ in ["h1", "h2", "h3", "h4", "h5", "h6"] {
            XCTAssertNotNil(registry.factory(for: type_), "\(type_) should be registered")
        }
    }

    func testSpanRegisters() {
        let registry = ComponentRegistry().withDefaultPrimitives()
        XCTAssertNotNil(registry.factory(for: "span"))
    }

    func testImgRegisters() {
        let registry = ComponentRegistry().withDefaultPrimitives()
        XCTAssertNotNil(registry.factory(for: "img"))
    }

    func testBoxSizingRoundTrip() throws {
        try roundTrip(Style(boxSizing: .borderBox))
        let s = try decode(Style.self, from: #"{"boxSizing":"border-box"}"#)
        XCTAssertEqual(s.boxSizing, .borderBox)
    }

    // MARK: - Full Spec round-trip with new fields

    func testSpecWithAllNewFieldsRoundTrips() throws {
        let spec = Spec(
            style: [
                "#container": Style(
                    padding: .uniform(.px(16)),
                    margin: .uniform(.px(8)),
                    backgroundColor: "#FFFFFF",
                    borderWidth: .px(1),
                    borderColor: "#CCCCCC",
                    borderStyle: .solid,
                    borderRadius: .uniform(.px(8))
                ),
                "h1": Style(
                    fontFamily: "Inter",
                    fontSize: .px(24),
                    fontWeight: .numeric(700),
                    color: "#1A1A1A",
                    lineHeight: 1.2
                ),
                "p": Style(
                    fontSize: .px(14),
                    color: "#666666",
                    textAlign: .left,
                    lineHeight: 1.6
                )
            ],
            layout: Node(
                type: "div",
                props: NodeProps(id: "container"),
                children: [
                    .node(Node(type: "h1", children: [.primitive(.string("Title"))])),
                    .node(Node(type: "p",  children: [.primitive(.string("Body text"))]))
                ]
            )
        )
        try roundTrip(spec)
    }

    // MARK: - Phase 1.6 — position: fixed / sticky emit a diagnostic

    /// Helper that runs the cascade with diagnostics so callers can inspect
    /// the warnings emitted while resolving a specific style.
    private func resolveCollectingDiagnostics(
        style: Style
    ) -> (computed: ComputedStyle, diagnostics: JoyDiagnostics) {
        var diags = JoyDiagnostics()
        let spec = Spec(
            style: ["#x": style],
            layout: Node(type: "div", props: NodeProps(id: "x"))
        )
        let rules = RuleBuilder.buildRules(from: spec, activeBreakpoint: nil, diagnostics: &diags)
        let nodes = StyleTreeBuilder.build(
            layout: spec.layout,
            rootID: "__joydom_root__",
            rules: rules,
            diagnostics: &diags
        )
        let computed = nodes.first(where: { $0.id == "x" })!.computedStyle
        return (computed, diags)
    }

    func testPositionFixedEmitsDiagnostic() {
        let (_, diags) = resolveCollectingDiagnostics(style: Style(position: .fixed))
        XCTAssertTrue(
            diags.warnings.contains { $0.detail.contains("fixed") },
            "expected a diagnostic mentioning position: fixed"
        )
    }

    func testPositionStickyEmitsDiagnostic() {
        let (_, diags) = resolveCollectingDiagnostics(style: Style(position: .sticky))
        XCTAssertTrue(
            diags.warnings.contains { $0.detail.contains("sticky") },
            "expected a diagnostic mentioning position: sticky"
        )
    }

    func testPositionRelativeDoesNotEmitDiagnostic() {
        let (_, diags) = resolveCollectingDiagnostics(style: Style(position: .relative))
        XCTAssertFalse(
            diags.warnings.contains { $0.detail.contains("fixed") || $0.detail.contains("sticky") },
            "position: relative must not emit a fixed/sticky fallback warning"
        )
    }

    func testDisplayInlineDoesNotEmitDiagnostic() {
        let (_, diags) = resolveCollectingDiagnostics(style: Style(display: .inline))
        XCTAssertEqual(diags.warnings.count, 0,
                       "display: inline is a benign block-level fallback; no warning expected")
    }
}
