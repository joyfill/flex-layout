import XCTest
@testable import JoyDOM

/// Unit 1 — `Spec` and its child types are the Swift mirror of the
/// `joy-dom` JSON spec defined in `joyfill/.joy#33` (`DOM/spec.ts`).
///
/// These tests assert that every shape in `Sources/JoyDOMView/Spec/JoyDOM.swift`
/// round-trips through JSON with the exact wire format Josh's TypeScript
/// types declare. Synthesized `Codable` covers the pure-struct types; the
/// union-shape enums (`PrimitiveValue`, `ChildNode`, `Gap`, `Padding`,
/// `MediaQuery`) need custom `Codable` because Swift's default synthesis
/// emits a discriminator key that doesn't match the spec.
final class JoyDOMTests: XCTestCase {

    // MARK: - Helpers

    private func roundTrip<T: Codable & Equatable>(_ value: T, file: StaticString = #file, line: UInt = #line) throws {
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(T.self, from: data)
        XCTAssertEqual(decoded, value, file: file, line: line)
    }

    private func encodeJSON<T: Encodable>(_ value: T) throws -> Any {
        let data = try JSONEncoder().encode(value)
        return try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
    }

    private func decode<T: Decodable>(_ type: T.Type, from json: String) throws -> T {
        try JSONDecoder().decode(T.self, from: Data(json.utf8))
    }

    // MARK: - Length (synthesized — should pass in RED)

    func testLengthRoundTripPx() throws {
        try roundTrip(Length(value: 100, unit: "px"))
    }

    func testLengthRoundTripPercent() throws {
        try roundTrip(Length.percent(50))
    }

    func testLengthDecodesFromCanonicalJSON() throws {
        let l = try decode(Length.self, from: #"{"value":100,"unit":"px"}"#)
        XCTAssertEqual(l, .px(100))
    }

    // MARK: - String-raw enums

    func testPositionEnumRoundTrip() throws {
        try roundTrip(Position.absolute)
        try roundTrip(Position.relative)
    }

    func testDisplayInlineBlockSerializesWithDash() throws {
        let json = try encodeJSON(Display.inlineBlock) as? String
        XCTAssertEqual(json, "inline-block")
        let decoded = try decode(Display.self, from: #""inline-block""#)
        XCTAssertEqual(decoded, .inlineBlock)
    }

    func testJustifyContentValuesRoundTrip() throws {
        let values: [Style.JustifyContent] = [.flexStart, .flexEnd, .center, .spaceBetween, .spaceAround]
        for value in values {
            try roundTrip(value)
        }
    }

    func testWidthOperatorRoundTripsAllFour() throws {
        for op: WidthOperator in [.greaterThan, .lessThan, .greaterThanOrEqual, .lessThanOrEqual] {
            try roundTrip(op)
        }
    }

    // MARK: - PrimitiveValue (custom Codable — RED FAILS, GREEN PASSES)

    func testPrimitiveValueStringEncodesAsBareString() throws {
        let json = try encodeJSON(PrimitiveValue.string("hello"))
        XCTAssertEqual(json as? String, "hello")
    }

    func testPrimitiveValueNumberEncodesAsBareNumber() throws {
        let json = try encodeJSON(PrimitiveValue.number(42))
        XCTAssertEqual(json as? Double, 42)
    }

    func testPrimitiveValueNullEncodesAsNull() throws {
        let data = try JSONEncoder().encode(PrimitiveValue.null)
        XCTAssertEqual(String(data: data, encoding: .utf8), "null")
    }

    func testPrimitiveValueRoundTrips() throws {
        try roundTrip(PrimitiveValue.string("hi"))
        try roundTrip(PrimitiveValue.number(3.14))
        try roundTrip(PrimitiveValue.null)
    }

    func testPrimitiveValueDecodesFromCanonicalJSON() throws {
        XCTAssertEqual(try decode(PrimitiveValue.self, from: #""x""#), .string("x"))
        XCTAssertEqual(try decode(PrimitiveValue.self, from: "12.5"), .number(12.5))
        XCTAssertEqual(try decode(PrimitiveValue.self, from: "null"), .null)
    }

    // MARK: - ChildNode (custom Codable — RED FAILS)

    func testChildNodePrimitiveEncodesTransparently() throws {
        let json = try encodeJSON(ChildNode.primitive(.string("text")))
        XCTAssertEqual(json as? String, "text")
    }

    func testChildNodeNodeEncodesAsObject() throws {
        let node = Node(type: "div", props: NodeProps(id: "root"))
        let json = try encodeJSON(ChildNode.node(node)) as? [String: Any]
        XCTAssertEqual(json?["type"] as? String, "div")
    }

    func testChildNodeRoundTrips() throws {
        try roundTrip(ChildNode.primitive(.string("hello")))
        try roundTrip(ChildNode.primitive(.null))
        try roundTrip(ChildNode.node(Node(type: "p")))
    }

    // MARK: - Gap (custom Codable — RED FAILS)

    func testGapUniformEncodesAsLength() throws {
        let json = try encodeJSON(Gap.uniform(.px(8))) as? [String: Any]
        XCTAssertEqual(json?["value"] as? Double, 8)
        XCTAssertEqual(json?["unit"] as? String, "px")
    }

    func testGapAxesEncodesWithCAndR() throws {
        let g = Gap.axes(column: .px(4), row: .px(8))
        let json = try encodeJSON(g) as? [String: Any]
        let c = json?["c"] as? [String: Any]
        let r = json?["r"] as? [String: Any]
        XCTAssertEqual(c?["value"] as? Double, 4)
        XCTAssertEqual(r?["value"] as? Double, 8)
    }

    func testGapRoundTrips() throws {
        try roundTrip(Gap.uniform(.px(12)))
        try roundTrip(Gap.axes(column: .px(4), row: .px(8)))
    }

    // MARK: - Padding (custom Codable — RED FAILS)

    func testPaddingUniformEncodesAsLength() throws {
        let json = try encodeJSON(Padding.uniform(.px(16))) as? [String: Any]
        XCTAssertEqual(json?["value"] as? Double, 16)
    }

    func testPaddingSidesEncodesWithFourKeys() throws {
        let p = Padding.sides(top: .px(1), right: .px(2), bottom: .px(3), left: .px(4))
        let json = try encodeJSON(p) as? [String: Any]
        XCTAssertEqual((json?["top"] as? [String: Any])?["value"] as? Double, 1)
        XCTAssertEqual((json?["right"] as? [String: Any])?["value"] as? Double, 2)
        XCTAssertEqual((json?["bottom"] as? [String: Any])?["value"] as? Double, 3)
        XCTAssertEqual((json?["left"] as? [String: Any])?["value"] as? Double, 4)
    }

    func testPaddingRoundTrips() throws {
        try roundTrip(Padding.uniform(.px(10)))
        try roundTrip(Padding.sides(top: .px(1), right: .px(2), bottom: .px(3), left: .px(4)))
    }

    // MARK: - MediaQuery (custom Codable — RED FAILS)

    func testMediaQueryWidthFeatureRoundTrip() throws {
        try roundTrip(MediaQuery.width(operator: .lessThan, value: 768, unit: .px))
    }

    func testMediaQueryWidthFeatureWireFormat() throws {
        let json = try encodeJSON(MediaQuery.width(operator: .lessThan, value: 768, unit: .px)) as? [String: Any]
        XCTAssertEqual(json?["type"] as? String, "feature")
        XCTAssertEqual(json?["name"] as? String, "width")
        XCTAssertEqual(json?["operator"] as? String, "<")
        XCTAssertEqual(json?["value"] as? Double, 768)
        XCTAssertEqual(json?["unit"] as? String, "px")
    }

    func testMediaQueryOrientationRoundTrip() throws {
        try roundTrip(MediaQuery.orientation(.landscape))
        try roundTrip(MediaQuery.orientation(.portrait))
    }

    func testMediaQueryOrientationWireFormat() throws {
        let json = try encodeJSON(MediaQuery.orientation(.portrait)) as? [String: Any]
        XCTAssertEqual(json?["type"] as? String, "feature")
        XCTAssertEqual(json?["name"] as? String, "orientation")
        XCTAssertEqual(json?["value"] as? String, "portrait")
    }

    func testMediaQueryTypePrintRoundTrip() throws {
        try roundTrip(MediaQuery.type(.print))
    }

    func testMediaQueryTypeWireFormat() throws {
        let json = try encodeJSON(MediaQuery.type(.print)) as? [String: Any]
        XCTAssertEqual(json?["type"] as? String, "type")
        XCTAssertEqual(json?["value"] as? String, "print")
    }

    func testMediaQueryLogicalAndRoundTrip() throws {
        let q = MediaQuery.logical(op: .and, conditions: [
            .width(operator: .greaterThanOrEqual, value: 768, unit: .px),
            .orientation(.landscape),
        ])
        try roundTrip(q)
    }

    func testMediaQueryLogicalAndWireFormat() throws {
        let q = MediaQuery.logical(op: .and, conditions: [.type(.print)])
        let json = try encodeJSON(q) as? [String: Any]
        XCTAssertEqual(json?["op"] as? String, "and")
        XCTAssertNotNil(json?["conditions"])
    }

    func testMediaQueryNotRoundTrip() throws {
        try roundTrip(MediaQuery.not(.type(.print)))
    }

    func testMediaQueryNotWireFormat() throws {
        let json = try encodeJSON(MediaQuery.not(.type(.print))) as? [String: Any]
        XCTAssertEqual(json?["op"] as? String, "not")
        XCTAssertNotNil(json?["condition"])
    }

    func testMediaQueryDecodesFromCanonicalJSON() throws {
        let json = #"{"op":"or","conditions":[{"type":"feature","name":"width","operator":"<","value":600,"unit":"px"},{"type":"type","value":"print"}]}"#
        let q = try decode(MediaQuery.self, from: json)
        if case .logical(let op, let conditions) = q {
            XCTAssertEqual(op, .or)
            XCTAssertEqual(conditions.count, 2)
        } else {
            XCTFail("expected logical OR, got \(q)")
        }
    }

    // MARK: - Style (synthesized for the simple case; nested fields exercise unions)

    func testEmptyStyleRoundTrip() throws {
        try roundTrip(Style())
    }

    func testStyleSingleFieldRoundTrip() throws {
        try roundTrip(Style(flexDirection: .row))
    }

    func testStyleWithGapRoundTrip() throws {
        try roundTrip(Style(gap: .axes(column: .px(4), row: .px(8))))
    }

    func testStyleWithPaddingRoundTrip() throws {
        try roundTrip(Style(padding: .sides(top: .px(8), right: .px(8), bottom: .px(8), left: .px(8))))
    }

    func testStyleWithMostFieldsRoundTrip() throws {
        try roundTrip(Style(
            position: .relative,
            display: .flex,
            zIndex: 5,
            overflow: .hidden,
            top: .px(10),
            flexDirection: .column,
            flexGrow: 1,
            flexShrink: 0,
            flexBasis: .length(.percent(50)),
            justifyContent: .spaceBetween,
            alignItems: .center,
            flexWrap: .wrap,
            gap: .uniform(.px(8)),
            order: 2,
            width: .percent(100),
            height: .px(120),
            padding: .uniform(.px(12))
        ))
    }

    // MARK: - Node tree

    func testEmptyNodeRoundTrip() throws {
        try roundTrip(Node(type: "div"))
    }

    func testNodeWithPropsRoundTrip() throws {
        try roundTrip(Node(
            type: "div",
            props: NodeProps(
                id: "root",
                className: ["container", "primary"],
                style: Style(flexDirection: .row)
            )
        ))
    }

    func testNodeWithChildrenRoundTrip() throws {
        let n = Node(
            type: "div",
            children: [
                .node(Node(type: "p", children: [.primitive(.string("hello"))])),
                .primitive(.null),
            ]
        )
        try roundTrip(n)
    }

    // MARK: - Breakpoint

    func testBreakpointEmptyRoundTrip() throws {
        try roundTrip(Breakpoint())
    }

    func testBreakpointWithEverythingRoundTrip() throws {
        let bp = Breakpoint(
            conditions: [.width(operator: .lessThan, value: 768, unit: .px)],
            nodes: [
                "footer": NodeProps(style: Style(display: .block)),
            ],
            style: [
                "#header": Style(flexDirection: .column),
                ".panel":  Style(padding: .uniform(.px(8))),
            ]
        )
        try roundTrip(bp)
    }

    // MARK: - Full document

    func testFullSpecRoundTrip() throws {
        let spec = Spec(
            version: 1,
            style: ["#root": Style(flexDirection: .column)],
            breakpoints: [
                Breakpoint(
                    conditions: [.width(operator: .lessThan, value: 768, unit: .px)],
                    nodes: ["sidebar": NodeProps(style: Style(display: .block))],
                    style: ["#root": Style(flexDirection: .column)]
                ),
            ],
            layout: Node(
                type: "div",
                props: NodeProps(id: "root", className: ["page"]),
                children: [
                    .node(Node(type: "p", children: [.primitive(.string("Hello, joy-dom"))])),
                ]
            )
        )
        try roundTrip(spec)
    }

    // MARK: - Malformed payloads must throw

    func testMalformedJSONThrows() {
        let bad = #"{"version":1,"style":{},"breakpoints":[],"layout":"oops"}"#
        XCTAssertThrowsError(try decode(Spec.self, from: bad))
    }

    func testMissingRequiredLayoutThrows() {
        let bad = #"{"version":1,"style":{},"breakpoints":[]}"#
        XCTAssertThrowsError(try decode(Spec.self, from: bad))
    }

    func testInvalidEnumValueThrows() {
        XCTAssertThrowsError(try decode(Position.self, from: #""sideways""#))
    }

    // MARK: - Phase 1 — spec-enum extensions

    // 1.1 — flex-direction reverses
    func testFlexDirectionRowReverseSerializesWithDash() throws {
        let json = try encodeJSON(Style.FlexDirection.rowReverse) as? String
        XCTAssertEqual(json, "row-reverse")
        try roundTrip(Style.FlexDirection.rowReverse)
    }
    func testFlexDirectionColumnReverseSerializesWithDash() throws {
        let json = try encodeJSON(Style.FlexDirection.columnReverse) as? String
        XCTAssertEqual(json, "column-reverse")
        try roundTrip(Style.FlexDirection.columnReverse)
    }

    // 1.2 — flex-wrap: wrap-reverse
    func testFlexWrapWrapReverseSerializesWithDash() throws {
        let json = try encodeJSON(Style.FlexWrap.wrapReverse) as? String
        XCTAssertEqual(json, "wrap-reverse")
        try roundTrip(Style.FlexWrap.wrapReverse)
    }

    // 1.3 — align-items / align-self: baseline
    func testAlignItemsBaselineRoundTrip() throws {
        let json = try encodeJSON(Style.AlignItems.baseline) as? String
        XCTAssertEqual(json, "baseline")
        try roundTrip(Style.AlignItems.baseline)
    }
    func testAlignSelfBaselineRoundTrip() throws {
        let json = try encodeJSON(Style.AlignSelf.baseline) as? String
        XCTAssertEqual(json, "baseline")
        try roundTrip(Style.AlignSelf.baseline)
    }

    // 1.4 — align-content
    func testAlignContentEachValueRoundTrip() throws {
        let cases: [(Style.AlignContent, String)] = [
            (.flexStart,    "flex-start"),
            (.flexEnd,      "flex-end"),
            (.center,       "center"),
            (.spaceBetween, "space-between"),
            (.spaceAround,  "space-around"),
            (.spaceEvenly,  "space-evenly"),
            (.stretch,      "stretch"),
        ]
        for (value, wire) in cases {
            let json = try encodeJSON(value) as? String
            XCTAssertEqual(json, wire)
            try roundTrip(value)
        }
    }
    func testAlignContentRoundTripsThroughStyle() throws {
        try roundTrip(Style(alignContent: .spaceBetween))
    }

    // 1.5 — border-style: dashed / dotted / double
    func testBorderStyleDashedRoundTrip() throws {
        let json = try encodeJSON(Style.BorderStyleProp.dashed) as? String
        XCTAssertEqual(json, "dashed")
        try roundTrip(Style.BorderStyleProp.dashed)
    }
    func testBorderStyleDottedRoundTrip() throws {
        let json = try encodeJSON(Style.BorderStyleProp.dotted) as? String
        XCTAssertEqual(json, "dotted")
        try roundTrip(Style.BorderStyleProp.dotted)
    }
    func testBorderStyleDoubleRoundTrip() throws {
        let json = try encodeJSON(Style.BorderStyleProp.double) as? String
        XCTAssertEqual(json, "double")
        try roundTrip(Style.BorderStyleProp.double)
    }

    // 1.6 — position: fixed / sticky
    func testPositionFixedRoundTrip() throws {
        let json = try encodeJSON(Position.fixed) as? String
        XCTAssertEqual(json, "fixed")
        try roundTrip(Position.fixed)
    }
    func testPositionStickyRoundTrip() throws {
        let json = try encodeJSON(Position.sticky) as? String
        XCTAssertEqual(json, "sticky")
        try roundTrip(Position.sticky)
    }

    // 1.7 — display: inline / inline-flex
    func testDisplayInlineRoundTrip() throws {
        let json = try encodeJSON(Display.inline) as? String
        XCTAssertEqual(json, "inline")
        try roundTrip(Display.inline)
    }
    func testDisplayInlineFlexSerializesWithDash() throws {
        let json = try encodeJSON(Display.inlineFlex) as? String
        XCTAssertEqual(json, "inline-flex")
        try roundTrip(Display.inlineFlex)
    }

    // MARK: - object-fit (spec.ts:69)

    func testObjectFitFillRoundTrip() throws {
        let json = try encodeJSON(Style.ObjectFit.fill) as? String
        XCTAssertEqual(json, "fill")
        try roundTrip(Style.ObjectFit.fill)
    }
    func testObjectFitContainRoundTrip() throws {
        let json = try encodeJSON(Style.ObjectFit.contain) as? String
        XCTAssertEqual(json, "contain")
        try roundTrip(Style.ObjectFit.contain)
    }
    func testObjectFitCoverRoundTrip() throws {
        let json = try encodeJSON(Style.ObjectFit.cover) as? String
        XCTAssertEqual(json, "cover")
        try roundTrip(Style.ObjectFit.cover)
    }
    func testObjectFitNoneRoundTrip() throws {
        let json = try encodeJSON(Style.ObjectFit.none) as? String
        XCTAssertEqual(json, "none")
        try roundTrip(Style.ObjectFit.none)
    }

    func testStyleObjectFitRoundTripsThroughStyleField() throws {
        // The cascade reads `Style.objectFit` directly off a decoded
        // payload, so the field has to survive a Style round-trip
        // independently of the bare enum.
        try roundTrip(Style(objectFit: .cover))
    }

    // MARK: - object-position (spec.ts:70-73)

    func testObjectPositionCenterCenterRoundTripJSONShape() throws {
        let v = Style.ObjectPosition(horizontal: .center, vertical: .center)
        let dict = try encodeJSON(v) as? [String: String]
        XCTAssertEqual(dict?["horizontal"], "center")
        XCTAssertEqual(dict?["vertical"], "center")
        try roundTrip(v)
    }

    func testObjectPositionLeftTopRoundTrip() throws {
        let v = Style.ObjectPosition(horizontal: .left, vertical: .top)
        try roundTrip(v)
    }

    func testObjectPositionRightBottomRoundTrip() throws {
        let v = Style.ObjectPosition(horizontal: .right, vertical: .bottom)
        try roundTrip(v)
    }

    func testObjectPositionRightCenterRoundTrip() throws {
        let v = Style.ObjectPosition(horizontal: .right, vertical: .center)
        try roundTrip(v)
    }

    func testObjectPositionDecodesFromCanonicalJSON() throws {
        let json = #"{"horizontal":"left","vertical":"bottom"}"#
        let v = try decode(Style.ObjectPosition.self, from: json)
        XCTAssertEqual(v.horizontal, .left)
        XCTAssertEqual(v.vertical,   .bottom)
    }

    func testStyleObjectPositionRoundTripsThroughStyleField() throws {
        let s = Style(objectPosition: .init(horizontal: .right, vertical: .top))
        try roundTrip(s)
    }
}
