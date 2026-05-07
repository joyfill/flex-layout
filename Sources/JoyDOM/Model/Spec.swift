// JoyDOM — Swift mirror of `joy-dom` (joyfill/.joy spec, PR #33).
//
// This file defines the data types that match `DOM/spec.ts` from the
// joyfill `.joy` repository, so an iOS host can decode a server-sent
// `joy-dom` document and feed it into JoyDOMView's render pipeline.
//
// The shapes below are pure data — no behavior, no rendering. Subsequent
// units add:
//   • Unit 2 — `Style` → CSS string serializer
//   • Unit 3 — tree → flat `[SchemaEntry]` converter
//   • Unit 5 — `MediaQuery` evaluator against a `Viewport`
//   • Unit 7 — Breakpoint cascade resolver
//   • Unit 8 — applying an active breakpoint to the render pipeline
//
// Every type round-trips through JSON via Codable, with field names that
// match Josh's TS spec verbatim (camelCase, e.g. `flexDirection`).
//
// Scope notes for Unit 1:
//   • `NodeProps` covers the named fields (`id`, `className`, `style`).
//     The `[key: string]: unknown` escape hatch from the TS spec is not
//     yet mirrored — it lands in Unit 10 alongside `UiAction` descriptors.
//   • `Length<'px' | '%'>` from TS collapses to a single `Length` struct
//     with a `String` unit field; unit validity is a serializer concern
//     (Unit 2), not a type-system concern.

import Foundation

// MARK: - Document root (`Spec`)

/// The top-level joy-dom document. Mirrors `Spec` in `DOM/spec.ts`.
public struct Spec: Equatable {
    /// Schema version. Always `1` in the current spec.
    public var version: Int
    /// Document-level style rules, keyed by selector (`#id`, `.class`, `type`).
    public var style: [String: Style]
    /// Responsive breakpoints in source order. Cascade resolution picks the
    /// active breakpoint by specificity then source order at render time.
    public var breakpoints: [Breakpoint]
    /// The root node of the document.
    public var layout: Node

    public init(
        version: Int = 1,
        style: [String: Style] = [:],
        breakpoints: [Breakpoint] = [],
        layout: Node
    ) {
        self.version = version
        self.style = style
        self.breakpoints = breakpoints
        self.layout = layout
    }
}

// MARK: - Node tree

/// A renderable element. Mirrors `Node` in `DOM/spec.ts`.
public struct Node: Equatable {
    /// Element type — `"div"`, `"p"`, or a custom string for registry
    /// components (`"button"`, `"text-field"`, etc.).
    public var type: String
    /// Optional element-level props (id, className, inline style).
    public var props: NodeProps?
    /// Optional children. A child may be another `Node` or a primitive
    /// value (string / number / null) representing text content.
    public var children: [ChildNode]?

    public init(
        type: String,
        props: NodeProps? = nil,
        children: [ChildNode]? = nil
    ) {
        self.type = type
        self.props = props
        self.children = children
    }
}

/// Element-level props. Mirrors `NodeProps` in `DOM/spec.ts`.
public struct NodeProps: Equatable {
    /// Element id — used as both the graph identity and the CSS `#id`
    /// selector target. Nodes without an `id` cannot be addressed in
    /// `Breakpoint.nodes` overrides.
    public var id: String?
    /// CSS class names — matched by `.class` selectors.
    public var className: [String]?
    /// Inline style applied directly to this node. Wins over selector-based
    /// rules per the cascade order documented in `DOM/guides/Styles.md`.
    public var style: Style?
    /// Open bag for component-specific props (`[key: string]: unknown` from
    /// the TS spec). Preserves structured JSON values — arrays, objects,
    /// numbers, booleans, and null — without coercing them to strings.
    public var extras: [String: JSONValue]

    public init(
        id: String? = nil,
        className: [String]? = nil,
        style: Style? = nil,
        extras: [String: JSONValue] = [:]
    ) {
        self.id = id
        self.className = className
        self.style = style
        self.extras = extras
    }
}

/// A child of a `Node`. Either a nested element or a primitive value.
public enum ChildNode: Equatable {
    case node(Node)
    case primitive(PrimitiveValue)
}

/// Primitive value used as text content. Mirrors `PrimitiveValue` in
/// `DOM/spec.ts`.
public enum PrimitiveValue: Equatable {
    case string(String)
    case number(Double)
    case null
}

// MARK: - Style

/// JSON-safe length (`{ value, unit }`). Mirrors `Length` in `DOM/spec.ts`.
///
/// Josh's TS spec uses `Length<'px'>` and `Length<'px' | '%'>` — Swift's
/// type system can't express string-literal unit constraints cleanly, so
/// we collapse both into one struct and validate the unit in the
/// serializer (Unit 2) where the context is known.
public struct Length: Equatable {
    public var value: Double
    public var unit: String

    public init(value: Double, unit: String) {
        self.value = value
        self.unit = unit
    }

    /// Convenience for the common `{ value: N, unit: "px" }` case.
    public static func px(_ value: Double) -> Length {
        Length(value: value, unit: "px")
    }

    /// Convenience for the common `{ value: N, unit: "%" }` case.
    public static func percent(_ value: Double) -> Length {
        Length(value: value, unit: "%")
    }
}

/// `flexBasis` is either the keyword `"auto"` or a concrete `Length`.
///
/// Swift's type system can't encode this union as a `RawRepresentable` enum
/// because `Length` isn't a raw value, so we use a custom enum with a manual
/// `Codable` implementation that tries the string path first.
public enum FlexBasisValue: Equatable {
    case auto
    case length(Length)

    /// Flatten to a string suitable for component-factory `props` dicts.
    public var stringValue: String {
        switch self {
        case .auto: return "auto"
        case .length(let l): return l.unit == "px" ? "\(l.value)px" : "\(l.value)\(l.unit)"
        }
    }
}

/// Subset of CSS that joy-dom supports. Mirrors `Style` in `DOM/spec.ts`.
///
/// Every field is optional — `Style()` represents "no overrides". The
/// cascade in Unit 8 deep-merges Style values, so partial overrides keep
/// sibling fields intact.
public struct Style: Equatable {
    // MARK: Layout & positioning
    public var position: Position?
    public var display: Display?
    public var boxSizing: Style.BoxSizing?
    public var zIndex: Int?
    public var overflow: Overflow?

    public var top: Length?
    public var left: Length?
    public var bottom: Length?
    public var right: Length?

    // MARK: Flexbox
    public var flexDirection: Style.FlexDirection?
    public var flexGrow: Double?
    public var flexShrink: Double?
    public var flexBasis: FlexBasisValue?
    public var justifyContent: Style.JustifyContent?
    public var alignItems: Style.AlignItems?
    public var alignSelf: Style.AlignSelf?
    public var alignContent: Style.AlignContent?
    public var flexWrap: Style.FlexWrap?
    public var gap: Gap?
    public var rowGap: Length?
    public var columnGap: Length?
    public var order: Int?

    // MARK: Sizing
    public var width: Length?
    public var height: Length?
    public var minWidth: Length?
    public var maxWidth: Length?
    public var minHeight: Length?
    public var maxHeight: Length?

    // MARK: Box model & visuals
    public var padding: Padding?
    public var margin: Padding?
    public var backgroundColor: String?
    public var opacity: Double?
    public var borderWidth: Length?
    public var borderColor: String?
    public var borderStyle: Style.BorderStyleProp?
    public var borderRadius: BorderRadius?

    // MARK: Typography
    public var fontFamily: String?
    public var fontSize: Length?
    public var fontWeight: Style.FontWeight?
    public var fontStyle: Style.FontStyleProp?
    public var color: String?
    public var textDecoration: Style.TextDecoration?
    public var textAlign: Style.TextAlign?
    public var textTransform: Style.TextTransform?
    public var lineHeight: Double?
    public var letterSpacing: Length?
    public var textOverflow: Style.TextOverflow?
    public var whiteSpace: Style.WhiteSpace?

    // MARK: Image
    /// `object-fit` — how a replaced element (e.g. `<img>`) scales to its
    /// content box. Mirrors `Style.objectFit` in `DOM/spec.ts:69`.
    public var objectFit: Style.ObjectFit?
    /// `object-position` — alignment of a replaced element within its
    /// content box. Mirrors `Style.objectPosition` in `DOM/spec.ts:70-73`.
    public var objectPosition: Style.ObjectPosition?

    public init(
        position: Position? = nil,
        display: Display? = nil,
        boxSizing: Style.BoxSizing? = nil,
        zIndex: Int? = nil,
        overflow: Overflow? = nil,
        top: Length? = nil,
        left: Length? = nil,
        bottom: Length? = nil,
        right: Length? = nil,
        flexDirection: Style.FlexDirection? = nil,
        flexGrow: Double? = nil,
        flexShrink: Double? = nil,
        flexBasis: FlexBasisValue? = nil,
        justifyContent: Style.JustifyContent? = nil,
        alignItems: Style.AlignItems? = nil,
        alignSelf: Style.AlignSelf? = nil,
        alignContent: Style.AlignContent? = nil,
        flexWrap: Style.FlexWrap? = nil,
        gap: Gap? = nil,
        rowGap: Length? = nil,
        columnGap: Length? = nil,
        order: Int? = nil,
        width: Length? = nil,
        height: Length? = nil,
        minWidth: Length? = nil,
        maxWidth: Length? = nil,
        minHeight: Length? = nil,
        maxHeight: Length? = nil,
        padding: Padding? = nil,
        margin: Padding? = nil,
        backgroundColor: String? = nil,
        opacity: Double? = nil,
        borderWidth: Length? = nil,
        borderColor: String? = nil,
        borderStyle: Style.BorderStyleProp? = nil,
        borderRadius: BorderRadius? = nil,
        fontFamily: String? = nil,
        fontSize: Length? = nil,
        fontWeight: Style.FontWeight? = nil,
        fontStyle: Style.FontStyleProp? = nil,
        color: String? = nil,
        textDecoration: Style.TextDecoration? = nil,
        textAlign: Style.TextAlign? = nil,
        textTransform: Style.TextTransform? = nil,
        lineHeight: Double? = nil,
        letterSpacing: Length? = nil,
        textOverflow: Style.TextOverflow? = nil,
        whiteSpace: Style.WhiteSpace? = nil,
        objectFit: Style.ObjectFit? = nil,
        objectPosition: Style.ObjectPosition? = nil
    ) {
        self.position = position
        self.display = display
        self.boxSizing = boxSizing
        self.zIndex = zIndex
        self.overflow = overflow
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
        self.flexDirection = flexDirection
        self.flexGrow = flexGrow
        self.flexShrink = flexShrink
        self.flexBasis = flexBasis
        self.justifyContent = justifyContent
        self.alignItems = alignItems
        self.alignSelf = alignSelf
        self.alignContent = alignContent
        self.flexWrap = flexWrap
        self.gap = gap
        self.rowGap = rowGap
        self.columnGap = columnGap
        self.order = order
        self.width = width
        self.height = height
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.padding = padding
        self.margin = margin
        self.backgroundColor = backgroundColor
        self.opacity = opacity
        self.borderWidth = borderWidth
        self.borderColor = borderColor
        self.borderStyle = borderStyle
        self.borderRadius = borderRadius
        self.fontFamily = fontFamily
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.fontStyle = fontStyle
        self.color = color
        self.textDecoration = textDecoration
        self.textAlign = textAlign
        self.textTransform = textTransform
        self.lineHeight = lineHeight
        self.letterSpacing = letterSpacing
        self.textOverflow = textOverflow
        self.whiteSpace = whiteSpace
        self.objectFit = objectFit
        self.objectPosition = objectPosition
    }
}

// MARK: - Style enums (string-keyed, raw values match the TS literal types)

public enum Position: String, Equatable, Codable {
    case absolute
    case relative
    case fixed
    case sticky
}

public enum Display: String, Equatable, Codable {
    case block
    case inlineBlock = "inline-block"
    case flex
    case none
    case inline
    case inlineFlex = "inline-flex"
}

public enum Overflow: String, Equatable, Codable {
    case visible
    case hidden
    case clip
    case scroll
    case auto
}

// `FlexDirection` / `JustifyContent` / `AlignItems` / `FlexWrap` / `AlignSelf`
// are nested inside `Style` because the surrounding `FlexLayout` package
// exports types with the same top-level names. Nesting keeps the API honest
// (`Style.FlexDirection.row`) while avoiding ambiguity at every call site
// in the resolver and serializer.
extension Style {
    public enum FlexDirection: String, Equatable, Codable {
        case row
        case column
        case rowReverse    = "row-reverse"
        case columnReverse = "column-reverse"
    }

    public enum JustifyContent: String, Equatable, Codable {
        case flexStart    = "flex-start"
        case flexEnd      = "flex-end"
        case center
        case spaceBetween = "space-between"
        case spaceAround  = "space-around"
        case spaceEvenly  = "space-evenly"
    }

    public enum AlignItems: String, Equatable, Codable {
        case flexStart = "flex-start"
        case flexEnd   = "flex-end"
        case center
        case stretch
        case baseline
    }

    public enum AlignSelf: String, Equatable, Codable {
        case auto
        case flexStart = "flex-start"
        case flexEnd   = "flex-end"
        case center
        case stretch
        case baseline
    }

    public enum FlexWrap: String, Equatable, Codable {
        case nowrap
        case wrap
        case wrapReverse = "wrap-reverse"
    }

    public enum AlignContent: String, Equatable, Codable {
        case flexStart    = "flex-start"
        case flexEnd      = "flex-end"
        case center
        case spaceBetween = "space-between"
        case spaceAround  = "space-around"
        case spaceEvenly  = "space-evenly"
        case stretch
    }

    public enum BoxSizing: String, Equatable, Codable {
        case borderBox = "border-box"
    }

    public enum BorderStyleProp: String, Equatable, Codable {
        case solid
        case none
        case dashed
        case dotted
        case double
    }

    /// `fontWeight` is either a named keyword ("normal", "bold") or a
    /// numeric value (100–900). Swift's enum doesn't natively mix String
    /// raw values with Int raw values, so we model it as a custom enum
    /// with a manual Codable implementation.
    public enum FontWeight: Equatable {
        case normal
        case bold
        case numeric(Int)
    }

    public enum FontStyleProp: String, Equatable, Codable {
        case normal
        case italic
    }

    public enum TextDecoration: String, Equatable, Codable {
        case none
        case underline
        case lineThrough = "line-through"
    }

    public enum TextAlign: String, Equatable, Codable {
        case left
        case center
        case right
    }

    public enum TextTransform: String, Equatable, Codable {
        case none
        case uppercase
        case lowercase
    }

    public enum TextOverflow: String, Equatable, Codable {
        case clip
        case ellipsis
    }

    public enum WhiteSpace: String, Equatable, Codable {
        case normal
        case nowrap
    }

    /// `object-fit` — how a replaced element (e.g. `<img>`) is resized to
    /// fit its content box. Mirrors `Style.objectFit` in `DOM/spec.ts:69`.
    public enum ObjectFit: String, Equatable, Codable {
        case fill
        case contain
        case cover
        case none
    }

    /// `object-position` — alignment of a replaced element within its
    /// content box. Mirrors `Style.objectPosition` in `DOM/spec.ts:70-73`:
    /// ```ts
    /// objectPosition?: {
    ///   horizontal: 'left' | 'center' | 'right';
    ///   vertical: 'top' | 'center' | 'bottom';
    /// };
    /// ```
    public struct ObjectPosition: Equatable, Codable {
        public enum Horizontal: String, Equatable, Codable {
            case left
            case center
            case right
        }
        public enum Vertical: String, Equatable, Codable {
            case top
            case center
            case bottom
        }
        public var horizontal: Horizontal
        public var vertical: Vertical
        public init(horizontal: Horizontal, vertical: Vertical) {
            self.horizontal = horizontal
            self.vertical = vertical
        }
    }
}

/// `gap` is either a uniform length (single value applied to row + column)
/// or a per-axis pair `{ c, r }`.
public enum Gap: Equatable {
    case uniform(Length)
    case axes(column: Length, row: Length)
}

/// `padding` / `margin` — either a uniform length or per-side `{ top, right, bottom, left }`.
/// `margin` reuses this shape (same JSON structure, same cascade semantics).
public enum Padding: Equatable {
    case uniform(Length)
    case sides(top: Length, right: Length, bottom: Length, left: Length)
}

/// `borderRadius` is either a uniform length or a per-corner object.
public enum BorderRadius: Equatable {
    case uniform(Length)
    case corners(topLeft: Length?, topRight: Length?, bottomRight: Length?, bottomLeft: Length?)
}

// MARK: - Breakpoints

/// A responsive breakpoint. Mirrors `Breakpoint` in `DOM/spec.ts`.
///
/// At render time, `BreakpointResolver` (Unit 7) picks the highest-
/// specificity matching breakpoint for the current viewport. Per Josh's
/// `Breakpoints.md`: "Only one breakpoint can be applied at a time."
public struct Breakpoint: Equatable {
    /// Conditions ANDed together — all must match for the breakpoint to
    /// activate.
    public var conditions: [MediaQuery]
    /// Per-node overrides keyed by `props.id`. Restyle / re-prop only —
    /// structural fields (`type`, `children`) are deliberately not in
    /// `NodeProps`, so re-parenting is impossible. This is the deliberate
    /// "no tree mutation" guarantee the spec inherits from web `@media`.
    public var nodes: [String: NodeProps]
    /// Selector-keyed style overrides applied while this breakpoint is
    /// active. Cascade between this and `nodes[id].style` is documented
    /// in the cascade order: `Document.style → Breakpoint.style →
    /// node.props.style → Breakpoint.nodes[id].style`.
    public var style: [String: Style]

    public init(
        conditions: [MediaQuery] = [],
        nodes: [String: NodeProps] = [:],
        style: [String: Style] = [:]
    ) {
        self.conditions = conditions
        self.nodes = nodes
        self.style = style
    }
}

/// A media-query condition. Mirrors the discriminated union of
/// `MediaQueryLogical | MediaQueryNot | MediaWidthFeature |
/// MediaOrientationFeature | MediaType` in `DOM/spec.ts`.
public indirect enum MediaQuery: Equatable {
    case logical(op: LogicalOp, conditions: [MediaQuery])
    case not(MediaQuery)
    case type(MediaTypeKind)
    case width(operator: WidthOperator? = nil, value: Double? = nil, unit: WidthUnit? = nil)
    case orientation(Orientation)
}

public enum LogicalOp: String, Equatable {
    case and
    case or
}

public enum MediaTypeKind: String, Equatable {
    case print
}

public enum WidthOperator: String, Equatable {
    case greaterThan       = ">"
    case lessThan          = "<"
    case greaterThanOrEqual = ">="
    case lessThanOrEqual    = "<="
}

public enum WidthUnit: String, Equatable {
    case px
}

public enum Orientation: String, Equatable {
    case landscape
    case portrait
}

// MARK: - Codable

// Swift can synthesize `Codable` for types whose fields are all themselves
// `Codable`. For pure structs (`Spec`, `Node`, `NodeProps`, `Style`,
// `Length`, `Breakpoint`) and `String`-raw enums (`Position`, `Display`,
// `Overflow`, `FlexDirection`, `JustifyContent`, `AlignItems`, `FlexWrap`,
// `LogicalOp`, `MediaTypeKind`, `WidthOperator`, `WidthUnit`,
// `Orientation`) the synthesized implementation matches Josh's JSON shape
// exactly.
//
// The union-shape enums (`PrimitiveValue`, `ChildNode`, `Gap`, `Padding`,
// `MediaQuery`) need custom Codable because Swift's default synthesis
// emits `{"uniform": …}` / `{"node": …}` discriminators that don't match
// the spec. Unit 1's RED stubs below produce empty / null output so
// round-trip tests fail observably; Unit 1's GREEN replaces them with
// implementations matching `DOM/spec.ts`.

extension Spec: Codable {}
extension Node: Codable {}
extension Style: Codable {}
extension Length: Codable {}
extension Breakpoint: Codable {}

extension LogicalOp: Codable {}
extension MediaTypeKind: Codable {}
extension WidthOperator: Codable {}
extension WidthUnit: Codable {}
extension Orientation: Codable {}

// MARK: - Custom Codable for union-shape enums

/// `PrimitiveValue` rides a single JSON value — `"hi"`, `42`, or `null` —
/// not a wrapper object. Swift's default synthesis would emit a
/// discriminator key (`{"string":"hi"}`); we override it.
extension PrimitiveValue: Codable {
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() {
            self = .null
        } else if let s = try? c.decode(String.self) {
            self = .string(s)
        } else if let n = try? c.decode(Double.self) {
            self = .number(n)
        } else {
            throw DecodingError.dataCorruptedError(
                in: c,
                debugDescription: "PrimitiveValue must be string, number, or null"
            )
        }
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .string(let s): try c.encode(s)
        case .number(let n): try c.encode(n)
        case .null:          try c.encodeNil()
        }
    }
}

/// `ChildNode` is either a primitive (string / number / null) or an
/// object that is a `Node`. We try primitive first; if the value looks
/// like an object we decode it as `Node`.
extension ChildNode: Codable {
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() {
            self = .primitive(.null)
        } else if let s = try? c.decode(String.self) {
            self = .primitive(.string(s))
        } else if let n = try? c.decode(Double.self) {
            self = .primitive(.number(n))
        } else {
            // Fall through to Node — must be an object.
            let node = try Node(from: decoder)
            self = .node(node)
        }
    }
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .primitive(let p): try p.encode(to: encoder)
        case .node(let n):      try n.encode(to: encoder)
        }
    }
}

/// `Gap` is `Length<'px'>` (uniform) or `{ c: Length, r: Length }` (axes).
/// We try the axes form first because its keys (`c`, `r`) are disjoint
/// from `Length`'s (`value`, `unit`).
extension Gap: Codable {
    private struct Axes: Codable {
        let c: Length
        let r: Length
    }
    public init(from decoder: Decoder) throws {
        if let axes = try? Axes(from: decoder) {
            self = .axes(column: axes.c, row: axes.r)
            return
        }
        let l = try Length(from: decoder)
        self = .uniform(l)
    }
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .uniform(let l):
            try l.encode(to: encoder)
        case .axes(let c, let r):
            try Axes(c: c, r: r).encode(to: encoder)
        }
    }
}

/// `Padding` is `Length<'px'>` (uniform) or
/// `{ top, right, bottom, left }` (per-side). Same disjoint-keys
/// discrimination as `Gap`.
extension Padding: Codable {
    private struct Sides: Codable {
        let top: Length
        let right: Length
        let bottom: Length
        let left: Length
    }
    public init(from decoder: Decoder) throws {
        if let sides = try? Sides(from: decoder) {
            self = .sides(top: sides.top, right: sides.right,
                          bottom: sides.bottom, left: sides.left)
            return
        }
        let l = try Length(from: decoder)
        self = .uniform(l)
    }
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .uniform(let l):
            try l.encode(to: encoder)
        case .sides(let t, let r, let b, let lf):
            try Sides(top: t, right: r, bottom: b, left: lf).encode(to: encoder)
        }
    }
}

/// `MediaQuery` is a discriminated union. Logical / `not` carry an `op`
/// key; everything else carries a `type` key (`"type"` for media-type,
/// `"feature"` for width / orientation). Mirrors `MediaQuery` in
/// `DOM/spec.ts`.
extension MediaQuery: Codable {
    private enum Key: String, CodingKey {
        case op, conditions, condition
        case type, name, value
        case `operator`, unit
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Key.self)

        // Logical / not — discriminated by the `op` key.
        if let op = try c.decodeIfPresent(String.self, forKey: .op) {
            switch op {
            case "and", "or":
                let logicalOp = LogicalOp(rawValue: op)!
                let conditions = try c.decode([MediaQuery].self, forKey: .conditions)
                self = .logical(op: logicalOp, conditions: conditions)
            case "not":
                let inner = try c.decode(MediaQuery.self, forKey: .condition)
                self = .not(inner)
            default:
                throw DecodingError.dataCorruptedError(
                    forKey: .op, in: c,
                    debugDescription: "unknown op '\(op)'"
                )
            }
            return
        }

        // type / feature — discriminated by the `type` key.
        let kind = try c.decode(String.self, forKey: .type)
        switch kind {
        case "type":
            let value = try c.decode(MediaTypeKind.self, forKey: .value)
            self = .type(value)
        case "feature":
            let name = try c.decode(String.self, forKey: .name)
            switch name {
            case "width":
                let op   = try c.decodeIfPresent(WidthOperator.self, forKey: .operator)
                let val  = try c.decodeIfPresent(Double.self,        forKey: .value)
                let unit = try c.decodeIfPresent(WidthUnit.self,     forKey: .unit)
                self = .width(operator: op, value: val, unit: unit)
            case "orientation":
                let value = try c.decode(Orientation.self, forKey: .value)
                self = .orientation(value)
            default:
                throw DecodingError.dataCorruptedError(
                    forKey: .name, in: c,
                    debugDescription: "unknown feature name '\(name)'"
                )
            }
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type, in: c,
                debugDescription: "unknown query kind '\(kind)'"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: Key.self)
        switch self {
        case .logical(let op, let conditions):
            try c.encode(op.rawValue, forKey: .op)
            try c.encode(conditions,  forKey: .conditions)
        case .not(let inner):
            try c.encode("not", forKey: .op)
            try c.encode(inner, forKey: .condition)
        case .type(let kind):
            try c.encode("type", forKey: .type)
            try c.encode(kind,   forKey: .value)
        case .width(let op, let val, let unit):
            try c.encode("feature", forKey: .type)
            try c.encode("width",   forKey: .name)
            try c.encodeIfPresent(op,   forKey: .operator)
            try c.encodeIfPresent(val,  forKey: .value)
            try c.encodeIfPresent(unit, forKey: .unit)
        case .orientation(let o):
            try c.encode("feature",     forKey: .type)
            try c.encode("orientation", forKey: .name)
            try c.encode(o,             forKey: .value)
        }
    }
}

/// `BorderRadius` is `Length<'px'>` (uniform) or
/// `{ topLeft?, topRight?, bottomRight?, bottomLeft? }` (per-corner).
extension BorderRadius: Codable {
    private struct Corners: Codable {
        let topLeft:     Length?
        let topRight:    Length?
        let bottomRight: Length?
        let bottomLeft:  Length?
    }
    public init(from decoder: Decoder) throws {
        // Try Length FIRST — `{"value":N,"unit":"px"}` is uniform.
        // Corners must come second because all its fields are optional,
        // so it would silently decode a Length object with all-nil corners.
        if let l = try? Length(from: decoder) {
            self = .uniform(l)
            return
        }
        let corners = try Corners(from: decoder)
        self = .corners(
            topLeft:     corners.topLeft,
            topRight:    corners.topRight,
            bottomRight: corners.bottomRight,
            bottomLeft:  corners.bottomLeft
        )
    }
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .uniform(let l):
            try l.encode(to: encoder)
        case .corners(let tl, let tr, let br, let bl):
            try Corners(topLeft: tl, topRight: tr,
                        bottomRight: br, bottomLeft: bl).encode(to: encoder)
        }
    }
}

/// `FontWeight` is either a named string ("normal", "bold") or a number
/// (100–900). Swift enums can't mix raw value types, so we implement
/// Codable manually.
extension Style.FontWeight: Codable {
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let s = try? c.decode(String.self) {
            switch s {
            case "normal": self = .normal
            case "bold":   self = .bold
            default:
                throw DecodingError.dataCorruptedError(
                    in: c,
                    debugDescription: "unknown fontWeight string '\(s)'"
                )
            }
        } else if let n = try? c.decode(Int.self) {
            self = .numeric(n)
        } else {
            throw DecodingError.dataCorruptedError(
                in: c,
                debugDescription: "fontWeight must be a named string or numeric value"
            )
        }
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .normal:      try c.encode("normal")
        case .bold:        try c.encode("bold")
        case .numeric(let n): try c.encode(n)
        }
    }
}

/// Lossless JSON value type for `NodeProps.extras`. Mirrors the
/// `[key: string]: unknown` escape hatch in the TS spec — preserves
/// arrays, objects, and null without coercing them to strings.
public indirect enum JSONValue: Equatable, Codable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case null
    case array([JSONValue])
    case object([String: JSONValue])

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        // Bool must precede Double — Swift's JSON decoder decodes `true`
        // as 1.0 if Bool is not tried first.
        if let b = try? c.decode(Bool.self)               { self = .bool(b);   return }
        if let s = try? c.decode(String.self)             { self = .string(s); return }
        if let n = try? c.decode(Double.self)             { self = .number(n); return }
        if c.decodeNil()                                  { self = .null;      return }
        if let a = try? c.decode([JSONValue].self)        { self = .array(a);  return }
        if let o = try? c.decode([String: JSONValue].self){ self = .object(o); return }
        throw DecodingError.typeMismatch(
            JSONValue.self,
            .init(codingPath: decoder.codingPath,
                  debugDescription: "unexpected JSON type for JSONValue")
        )
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .string(let s): try c.encode(s)
        case .number(let n): try c.encode(n)
        case .bool(let b):   try c.encode(b)
        case .null:          try c.encodeNil()
        case .array(let a):  try c.encode(a)
        case .object(let o): try c.encode(o)
        }
    }

    /// Flatten to a `String` for component-factory props dicts that expect
    /// `[String: String]`. Returns `nil` for arrays and objects since they
    /// can't be meaningfully collapsed to a single string.
    public var stringValue: String? {
        switch self {
        case .string(let s): return s
        case .number(let n): return n.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(n)) : String(n)
        case .bool(let b):   return b ? "true" : "false"
        case .null, .array, .object: return nil
        }
    }
}

/// `NodeProps` requires a custom Codable to capture unknown keys as
/// `extras` (the `[key: string]: unknown` escape hatch from the TS spec)
/// while still synthesizing the known fields normally.
extension NodeProps: Codable {
    private enum KnownKey: String, CodingKey {
        case id, className, style
    }

    public init(from decoder: Decoder) throws {
        let known = try decoder.container(keyedBy: KnownKey.self)
        id        = try known.decodeIfPresent(String.self,   forKey: .id)
        className = try known.decodeIfPresent([String].self, forKey: .className)
        style     = try known.decodeIfPresent(Style.self,    forKey: .style)

        let any = try decoder.container(keyedBy: AnyCodingKey.self)
        let reserved: Set<String> = ["id", "className", "style"]
        var bag: [String: JSONValue] = [:]
        for key in any.allKeys where !reserved.contains(key.stringValue) {
            if let v = try? any.decode(JSONValue.self, forKey: key) {
                bag[key.stringValue] = v
            }
        }
        extras = bag
    }

    public func encode(to encoder: Encoder) throws {
        var known = encoder.container(keyedBy: KnownKey.self)
        try known.encodeIfPresent(id,        forKey: .id)
        try known.encodeIfPresent(className, forKey: .className)
        try known.encodeIfPresent(style,     forKey: .style)
        var any = encoder.container(keyedBy: AnyCodingKey.self)
        for (k, v) in extras {
            try any.encode(v, forKey: AnyCodingKey(k))
        }
    }
}

/// `FlexBasisValue` is either the string `"auto"` or a `Length` object.
/// We try the string path first so a bare `"auto"` decodes correctly without
/// accidentally matching the `Length` struct.
extension FlexBasisValue: Codable {
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let s = try? c.decode(String.self), s == "auto" { self = .auto; return }
        self = .length(try Length(from: decoder))
    }
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .auto:
            var c = encoder.singleValueContainer()
            try c.encode("auto")
        case .length(let l):
            try l.encode(to: encoder)
        }
    }
}

/// Generic `CodingKey` that accepts any string. Used by `NodeProps` to
/// capture the `[key: string]: unknown` extras bag.
struct AnyCodingKey: CodingKey {
    let stringValue: String
    var intValue: Int? { nil }
    init(_ string: String) { self.stringValue = string }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { return nil }
}
