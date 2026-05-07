// ComputedStyle / ItemStyle — the post-cascade style value produced by
// `StyleResolver`.
//
// We deliberately keep container and item style separate inside
// `ComputedStyle` because FlexLayout also separates them: a view becomes a
// `FlexBox(config:)` using `container`, then every child applies `item` via
// `.flexItem(...)`. Storing a single flat struct here means the resolver
// doesn't need to know which properties target which axis — it just writes
// into the right nested field.

import Foundation
import FlexLayout
import CoreGraphics

/// Per-item flex-item properties, mirroring the CSS item-level subset.
///
/// Initial values match the CSS spec defaults exactly (`flex-grow:0`,
/// `flex-shrink:1`, `flex-basis:auto`, etc.) so an unstyled node still
/// renders correctly.
///
/// Phase 3 moved `margin` from `VisualStyle` into `ItemStyle` because the
/// FlexLayout engine now resolves it as a true flex-item margin (affecting
/// available space and item offset). The visual layer no longer wraps the
/// item in a SwiftUI `.padding()` to fake margin.
///
/// `box-sizing` controls whether explicit `width`/`height` cover the
/// content box (CSS default) or the border box (`border-box`). The spec
/// only allows `'border-box'` as an explicit value; absent the field,
/// content-box semantics apply and JoyDOM's adapter passes `width` /
/// `height` straight through to FlexLayout. When `boxSizing == .borderBox`
/// the adapter deducts the node's own `borderWidth × 2 + paddingMain × 2`
/// (or cross equivalent) before forwarding the explicit dimension —
/// FlexLayout itself stays unaware of the property.
public struct ItemStyle: Equatable {
    public var grow:      CGFloat       = 0
    public var shrink:    CGFloat       = 1
    public var basis:     FlexBasis     = .auto
    public var alignSelf: AlignSelf     = .auto
    public var order:     Int           = 0
    public var width:     FlexSize      = .auto
    public var height:    FlexSize      = .auto
    public var minWidth:  CGFloat?      = nil
    public var maxWidth:  CGFloat?      = nil
    public var minHeight: CGFloat?      = nil
    public var maxHeight: CGFloat?      = nil
    public var margin:    Padding?      = nil
    public var overflow:  FlexOverflow  = .visible
    public var zIndex:    Int           = 0
    public var position:  FlexPosition  = .relative
    public var top:       CGFloat?      = nil
    public var bottom:    CGFloat?      = nil
    public var leading:   CGFloat?      = nil
    public var trailing:  CGFloat?      = nil
    /// Whether explicit `width` / `height` include border + padding
    /// (`border-box`) or just the content area (the CSS-default
    /// `content-box`). The spec only allows `'border-box'` as a value;
    /// `nil` means "use the default" (content-box).
    public var boxSizing: Style.BoxSizing? = nil

    public init() {}
}

/// Non-layout visual properties carried through the cascade.
///
/// These are applied by the render layer as SwiftUI view modifiers rather
/// than by the flex engine, so they live separately from `ItemStyle` and
/// `FlexContainerConfig`. Typography modifiers (font, color, etc.) are
/// applied as SwiftUI environment values, propagating automatically to
/// `Text` descendants.
public struct VisualStyle: Equatable {
    // Box model & visuals
    public var backgroundColor: String?           = nil
    public var opacity:         Double?           = nil
    public var borderWidth:     CGFloat?          = nil
    public var borderColor:     String?           = nil
    public var borderStyle:     Style.BorderStyleProp? = nil
    public var borderRadius:    BorderRadius?     = nil

    // Typography
    public var fontFamily:      String?           = nil
    public var fontSize:        CGFloat?          = nil
    public var fontWeight:      Style.FontWeight? = nil
    public var fontStyle:       Style.FontStyleProp? = nil
    public var color:           String?           = nil
    public var textDecoration:  Style.TextDecoration? = nil
    public var textAlign:       Style.TextAlign?  = nil
    public var textTransform:   Style.TextTransform? = nil
    public var lineHeight:      Double?           = nil
    public var letterSpacing:   CGFloat?          = nil
    public var textOverflow:    Style.TextOverflow? = nil
    public var whiteSpace:      Style.WhiteSpace? = nil

    public init() {}
}

/// A fully resolved style for a single CSS node.
///
/// `container` is consumed when the node renders as a flex container (`display:
/// flex` or simply because it has children). `item` is consumed by the parent
/// flex container when laying out this node as one of its items. Both are
/// always populated — using them correctly is the resolver's job.
public struct ComputedStyle: Equatable {
    public var container: FlexContainerConfig = FlexContainerConfig()
    public var item:      ItemStyle           = ItemStyle()
    public var visual:    VisualStyle         = VisualStyle()
    public var display:   FlexDisplay         = .flex

    /// `display: none` removes the element (and its whole subtree) from the
    /// formatting tree. We track it as a flag — rather than a `FlexDisplay`
    /// case — so the FlexLayout enum stays untouched; the resolver filters
    /// flagged nodes out before any view is produced.
    public var isDisplayNone: Bool = false

    /// `visibility: hidden` keeps the element in layout (it still reserves
    /// space) but suppresses its paint. Carried as a flag on ComputedStyle
    /// so the resolver can forward it to `ResolvedChild`, which in turn
    /// lets the render layer apply SwiftUI's `.hidden()` without touching
    /// the flex tree.
    public var isVisibilityHidden: Bool = false

    public init() {}
}
