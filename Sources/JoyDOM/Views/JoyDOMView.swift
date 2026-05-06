// JoyDOMView — the top-level SwiftUI view that renders a `Spec`.
//
// Data flow per `body` evaluation:
//
//   1. `BreakpointResolver.active` ──────► active Breakpoint (or nil)
//   2. `RuleBuilder.buildRules`    ──────► [StyleResolver.Rule]
//   3. `StyleTreeBuilder.build`    ──────► [StyleNode]
//   4. `ComponentResolver.resolve` ──────► ComponentResolver.Resolved
//        • one AnyView per child
//        • a per-child ComponentEvents that fans events into the root sink
//   5. Root sink                   ──────► dispatches to `onEvent` handlers
//   6. Diagnostics                 ──────► forwarded to `onDiagnostic`
//   7. `FlexLayout`                ──────► lays out children using `ItemStyle`
//
// Caller-facing knobs: `.onEvent`, `.placeholder`, `.onDiagnostic`,
// `.viewport`, `.formState`, `.bindings`. Each returns a new
// `JoyDOMView` so chains compose like any SwiftUI modifier.

import Foundation
import SwiftUI
import FlexLayout
import CoreGraphics
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Renders a `Spec` as a live SwiftUI view tree backed by `FlexLayout`.
///
/// ```swift
/// JoyDOMView(spec: spec)
///     .joyViewport(.init(width: 1024))
///     .onEvent("submit") { event in print("submitted:", event.payload) }
/// ```
///
/// Pass a `Viewport` via `.joyViewport(_:)` so breakpoint resolution can
/// pick the active breakpoint. Without one, only the document-level styles
/// apply.
public struct JoyDOMView: View {

    // MARK: - Stored state

    private let spec: Spec
    private let registry: ComponentRegistry
    private let locals: [Component]

    private var eventHandlers: [String: (JoyEvent) -> Void] = [:]
    private var placeholderFactory: (String) -> AnyView = { AnyView(PlaceholderBox(id: $0)) }
    private var diagnosticHandler: ((JoyWarning) -> Void)?
    private var formStateRef: FormState?
    /// Viewport supplied via `.viewport(_:)`. Drives breakpoint
    /// resolution. Demos typically wire this to `GeometryReader`'s
    /// width; tests construct viewports directly.
    private var storedViewport: Viewport?
    /// Sidecar binding map declared via `.bindings(_:)`. Keys are
    /// `Node.props.id` values; values are FormState dotted paths.
    /// Empty by default — joy-dom payloads stay pure (no iOS-specific
    /// binding tokens leak into the wire format).
    private var bindingsByID: [String: String] = [:]
    /// Whether the built-in User Agent stylesheet (browser-like
    /// defaults for `h1`–`h6`) prepends to the cascade. Default
    /// `true` matches authoring expectations on payloads written
    /// against a web reference renderer. Disable with
    /// `.userAgentDefaults(false)` for spec-strict rendering.
    private var applyUserAgentDefaults: Bool = true

    // MARK: - Initialisers

    /// Render a `Spec`.
    ///
    /// - Parameters:
    ///   - spec: The joy-dom document to render.
    ///   - registry: Component factory registry. Defaults to ``ComponentRegistry/shared``.
    ///   - locals: Inline `Component("id") { … }` overrides (optional).
    public init(
        spec: Spec,
        registry: ComponentRegistry = .shared,
        @JoyDOMComponentBuilder locals: () -> [Component] = { [] }
    ) {
        self.spec = spec
        self.registry = registry
        self.locals = locals()
    }

    // MARK: - Modifiers

    /// Register a handler for events named `name`. Returns a new view — chain
    /// multiple calls to register for different names.
    ///
    /// Pass `"*"` to register a catch-all that fires for every propagating
    /// event after the named handler (if any). Later calls with the same name
    /// overwrite the earlier handler. Non-propagating events (emitted with
    /// `propagates: false`) bypass both named and wildcard handlers.
    public func onEvent(_ name: String, _ handler: @escaping (JoyEvent) -> Void) -> JoyDOMView {
        var copy = self
        copy.eventHandlers[name] = handler
        return copy
    }

    /// Override the default placeholder factory. `id` is the node id that
    /// couldn't be resolved.
    public func placeholder(_ build: @escaping (String) -> AnyView) -> JoyDOMView {
        var copy = self
        copy.placeholderFactory = build
        return copy
    }

    /// Register a diagnostic handler. Called once per `JoyWarning` emitted
    /// during parse/cascade/resolve. Useful for surfacing parse errors in
    /// debug builds; intentionally silent by default.
    public func onDiagnostic(_ handler: @escaping (JoyWarning) -> Void) -> JoyDOMView {
        var copy = self
        copy.diagnosticHandler = handler
        return copy
    }

    /// Override the viewport used for breakpoint resolution. When unset
    /// (or set to `nil`), no breakpoint applies and the document-level
    /// styles render unchanged. Demos typically wrap JoyDOMView in a
    /// `GeometryReader` and feed `proxy.size.width` here.
    public func viewport(_ viewport: Viewport?) -> JoyDOMView {
        var copy = self
        copy.storedViewport = viewport
        return copy
    }

    /// Declare the FormState path each node id binds to.
    ///
    /// Joy-dom payloads carry no iOS-specific binding tokens — that's
    /// the spec's "pre-resolved values" stance. iOS hosts that want
    /// live two-way binding wire it up here, declaratively, at the
    /// SwiftUI surface:
    ///
    /// ```swift
    /// JoyDOMView(spec: spec)
    ///     .formState(form)
    ///     .bindings([
    ///         "name-field":  "user.name",
    ///         "email-field": "user.email",
    ///     ])
    /// ```
    ///
    /// Calling `.bindings(_:)` more than once merges the maps — later
    /// calls win on conflicting keys.
    public func bindings(_ map: [String: String]) -> JoyDOMView {
        var copy = self
        for (id, path) in map {
            copy.bindingsByID[id] = path
        }
        return copy
    }

    /// Toggle the built-in User Agent stylesheet. Default `true` —
    /// `h1`–`h6` resolve to bold and progressively-sized defaults
    /// (matching browser UA stylesheets), so payloads authored
    /// against a web reference renderer don't lose their heading
    /// hierarchy on iOS.
    ///
    /// Pass `false` for spec-strict rendering. The joy-dom spec at
    /// `joyfill/.joy DOM/spec.ts` does not define UA defaults, so
    /// payloads validated against pure spec shouldn't depend on
    /// them.
    public func userAgentDefaults(_ enabled: Bool) -> JoyDOMView {
        var copy = self
        copy.applyUserAgentDefaults = enabled
        return copy
    }

    /// Attach a `FormState` so every factory in the tree that declares a
    /// schema `binding` (or `binding.<field>`) prop can read and write its
    /// value live. The caller owns the `FormState` — state survives payload
    /// hot-swaps and is pruned to the paths the current schema declares on
    /// every render, so stale values don't accumulate across fetches.
    public func formState(_ form: FormState) -> JoyDOMView {
        var copy = self
        copy.formStateRef = form
        return copy
    }

    // MARK: - Body

    /// Identifiable pair used by `ForEach` so the child index provides stable
    /// identity without requiring `ResolvedChild` itself to be `Identifiable`
    /// (child ids are non-unique across subtrees during Phase 2 development).
    private struct IndexedChild: Identifiable {
        let offset: Int
        let child: ResolvedChild
        var id: Int { offset }
    }

    public var body: some View {
        let snapshot = renderSnapshot()
        return FlexLayout(snapshot.rootStyle.container) {
            childrenView(snapshot.children)
        }
        .flexOverflow(snapshot.rootStyle.container.overflow)
    }

    /// Build the `ForEach` over one level of resolved children. Separated so
    /// the recursive case in `render(_:)` doesn't have to reason about the
    /// `@ViewBuilder` closure types.
    private func childrenView(_ children: [ResolvedChild]) -> some View {
        let pairs = Array(children.enumerated()).map { IndexedChild(offset: $0.offset, child: $0.element) }
        return ForEach(pairs) { pair in
            self.render(pair.child)
        }
    }

    /// Render a single resolved child. Leaves use the factory's view; nodes
    /// with schema descendants wrap their children in a nested `FlexLayout`
    /// so container geometry (direction, gap, padding, justify/align) takes
    /// effect exactly where the schema declares it.
    private func render(_ child: ResolvedChild) -> AnyView {
        let rawView: AnyView
        if child.isContainer {
            let nested = child.nested
            let inner = FlexLayout(child.containerStyle) {
                self.childrenView(nested)
            }
            .flexOverflow(child.containerStyle.overflow)
            rawView = AnyView(inner)
        } else {
            rawView = child.view
        }
        // Apply non-layout visual CSS (background, border, typography, etc.)
        // before the flex-item wrapper so the decorations sit inside the
        // item's allocated slot.
        let withVisual = applyVisual(rawView, visual: child.visualStyle)
        // `visibility: hidden` keeps the flex slot and only suppresses the
        // paint — apply `.hidden()` *before* `.flexItem(...)` so layout
        // still sees the natural size of the underlying view.
        let maybeHidden: AnyView = child.isVisibilityHidden
            ? AnyView(withVisual.hidden())
            : withVisual
        return AnyView(applyItem(maybeHidden, style: child.itemStyle))
    }

    /// Map a numeric CSS `font-weight` (per CSS Fonts Module Level 4) to a
    /// SwiftUI `Font.Weight`. Each named weight covers a 100-unit band
    /// centered on its canonical numeric value — the boundary sits at the
    /// midpoint, so `449` still resolves to `.regular` while `450`
    /// promotes to `.medium`. Exposed `internal` so tests can pin every
    /// boundary value directly.
    ///
    /// CSS Fonts Module Level 4 restricts `font-weight` to `[1, 1000]`.
    /// Out-of-range inputs clamp silently in release builds (the bands
    /// extend to ±∞), and trip an `assert` in debug builds so authoring
    /// mistakes surface during development.
    internal static func swiftFontWeight(forCSSWeight n: Int) -> Font.Weight {
        assert((1...1000).contains(n), "CSS font-weight must be in [1, 1000], got \(n)")
        switch n {
        case ..<150:  return .ultraLight
        case ..<250:  return .thin
        case ..<350:  return .light
        case ..<450:  return .regular
        case ..<550:  return .medium
        case ..<650:  return .semibold
        case ..<750:  return .bold
        case ..<850:  return .heavy
        default:      return .black
        }
    }

    /// Compute the SwiftUI `lineSpacing` value for a given CSS
    /// `line-height` multiplier and font size, matching the formula used
    /// inside `applyVisual`. Exposed `internal` for tests.
    internal static func lineSpacing(forLineHeight lh: Double, fontSize: CGFloat) -> CGFloat {
        let target = fontSize * CGFloat(lh)
        #if canImport(UIKit)
        // UIFont.lineHeight = ascender + |descender| + leading.
        let systemLineHeight = UIFont.systemFont(ofSize: fontSize).lineHeight
        #elseif canImport(AppKit)
        // boundingRectForFont.height is the largest-possible-glyph bound and
        // overstates the typographic line height by ~15–20%, leaving too
        // little lineSpacing on macOS. The UIKit equivalent is the sum of
        // the typographic metrics (descender is negative on AppKit).
        let f = NSFont.systemFont(ofSize: fontSize)
        let systemLineHeight = f.ascender - f.descender + f.leading
        #else
        let systemLineHeight = fontSize * 1.2
        #endif
        return max(0, target - systemLineHeight)
    }

    /// Apply non-layout CSS to a view using SwiftUI view modifiers.
    ///
    /// Typography modifiers propagate through SwiftUI's environment, so they
    /// automatically cascade to `Text` descendants (including those produced
    /// by `primitive_string` factories in child nodes).
    private func applyVisual(_ view: AnyView, visual: VisualStyle) -> AnyView {
        var v: AnyView = view

        // --- Typography (propagates via SwiftUI environment) ---

        if visual.fontFamily != nil || visual.fontSize != nil || visual.fontWeight != nil || visual.fontStyle != nil {
            let size     = visual.fontSize ?? 17
            var font: Font = visual.fontFamily.map { .custom($0, size: size) } ?? .system(size: size)
            if let w = visual.fontWeight {
                switch w {
                case .normal:      font = font.weight(.regular)
                case .bold:        font = font.weight(.bold)
                case .numeric(let n):
                    font = font.weight(JoyDOMView.swiftFontWeight(forCSSWeight: n))
                }
            }
            if visual.fontStyle == .italic { font = font.italic() }
            v = AnyView(v.font(font))
        }

        if let hex = visual.color { v = AnyView(v.foregroundColor(Color(hex: hex))) }

        if let align = visual.textAlign {
            let ta: TextAlignment
            switch align {
            case .left:   ta = .leading
            case .center: ta = .center
            case .right:  ta = .trailing
            }
            v = AnyView(v.multilineTextAlignment(ta))
        }

        if let ls = visual.letterSpacing { v = AnyView(v.tracking(ls)) }

        if let lh = visual.lineHeight {
            // CSS line-height is a multiplier of font size; SwiftUI's
            // lineSpacing is the *extra* space added between lines, not the
            // total line height. `lineSpacing(forLineHeight:fontSize:)`
            // subtracts the platform font's natural line height (which
            // already includes default leading) from the target so the
            // visual gap matches CSS expectations.
            let fontSizePt = visual.fontSize ?? 17
            v = AnyView(v.lineSpacing(JoyDOMView.lineSpacing(forLineHeight: lh, fontSize: fontSizePt)))
        }

        if let tt = visual.textTransform {
            switch tt {
            case .uppercase: v = AnyView(v.environment(\.textCase, .uppercase))
            case .lowercase: v = AnyView(v.environment(\.textCase, .lowercase))
            case .none: break
            }
        }

        if let td = visual.textDecoration {
            // SwiftUI's `.underline()` / `.strikethrough()` only paint on
            // `Text` itself, not on container `View`s, so the value has to
            // ride down through the environment and be re-applied at the
            // text leaf. `_DecoratedText` (the `primitive_string` /
            // `primitive_number` renderer) reads `inheritedTextDecoration`
            // and applies the matching modifier to its `Text`.
            let inherited: InheritedTextDecoration
            switch td {
            case .underline:   inherited = .underline
            case .lineThrough: inherited = .lineThrough
            case .none:        inherited = .none
            }
            v = AnyView(v.environment(\.inheritedTextDecoration, inherited))
        }

        if let to = visual.textOverflow, to == .ellipsis {
            v = AnyView(v.truncationMode(.tail).lineLimit(1))
        }

        if let ws = visual.whiteSpace, ws == .nowrap {
            v = AnyView(v.lineLimit(1))
        }

        // --- Background & opacity ---

        if let hex = visual.backgroundColor { v = AnyView(v.background(Color(hex: hex))) }
        if let op  = visual.opacity          { v = AnyView(v.opacity(op)) }

        // --- Border + border-radius ---

        // `strokedOverlay` is the single enforcement point for `.none` —
        // it returns an EmptyView, suppressing the stroke.
        let hasBorder = visual.borderWidth != nil && visual.borderColor != nil
        v = applyBorderRadius(v, radius: visual.borderRadius,
                              borderColor: hasBorder ? visual.borderColor : nil,
                              borderWidth: hasBorder ? visual.borderWidth : nil,
                              borderStyle: hasBorder ? (visual.borderStyle ?? .solid) : nil)

        // Phase 3: `margin` is no longer applied here. FlexLayout's item
        // pipeline now consumes it as a true flex-item margin, so the
        // adapter in `applyItem` passes it through `.flexItem(margin:)`.

        return v
    }

    /// Apply border and/or border-radius to `view`.
    ///
    /// Handles all four combinations:
    ///   - radius + border  → clip to shape, overlay stroke
    ///   - radius only      → clip to shape
    ///   - border only      → overlay plain Rectangle stroke
    ///   - neither          → no change
    ///
    /// Per-corner radii use `UnevenRoundedRectangle` (iOS 16+).
    private func applyBorderRadius(
        _ view: AnyView,
        radius: BorderRadius?,
        borderColor: String?,
        borderWidth: CGFloat?,
        borderStyle: Style.BorderStyleProp? = nil
    ) -> AnyView {
        let strokeColor = borderColor.map { Color(hex: $0) }
        guard let radius else {
            if let sc = strokeColor, let bw = borderWidth {
                return AnyView(view.overlay(
                    strokedOverlay(shape: AnyShape(Rectangle()),
                                   color: sc,
                                   width: bw,
                                   style: borderStyle ?? .solid)
                ))
            }
            return view
        }
        let shape: AnyShape
        switch radius {
        case .uniform(let l):
            shape = AnyShape(RoundedRectangle(cornerRadius: CGFloat(l.value)))
        case .corners(let tl, let tr, let br, let bl):
            shape = AnyShape(UnevenRoundedRectangle(
                topLeadingRadius:     CGFloat(tl?.value ?? 0),
                bottomLeadingRadius:  CGFloat(bl?.value ?? 0),
                bottomTrailingRadius: CGFloat(br?.value ?? 0),
                topTrailingRadius:    CGFloat(tr?.value ?? 0)
            ))
        }
        var v = AnyView(view.clipShape(shape))
        if let sc = strokeColor, let bw = borderWidth {
            v = AnyView(v.overlay(
                strokedOverlay(shape: shape,
                               color: sc,
                               width: bw,
                               style: borderStyle ?? .solid)
            ))
        }
        return v
    }

    /// Build the overlay view that draws a stroke around `shape` using the
    /// requested CSS `border-style`. `solid` uses the default StrokeStyle;
    /// `dashed` / `dotted` use a `StrokeStyle` with a dash array; `double`
    /// stacks two concentric strokes (inner shrunk by 2× line-width) to
    /// approximate the CSS double-line look.
    @ViewBuilder
    private func strokedOverlay(
        shape: AnyShape,
        color: Color,
        width bw: CGFloat,
        style: Style.BorderStyleProp
    ) -> some View {
        switch style {
        case .none:
            EmptyView()
        case .solid:
            shape.stroke(color, lineWidth: bw)
        case .dashed:
            shape.stroke(color, style: StrokeStyle(lineWidth: bw, dash: [bw * 3, bw * 2]))
        case .dotted:
            shape.stroke(color, style: StrokeStyle(lineWidth: bw, lineCap: .round, dash: [0.01, bw * 2]))
        case .double:
            // CSS `double` = two lines each `bw/3` wide with a `bw/3` gap
            // between them. Outer stroke sits on the shape edge; inner
            // stroke is inset by `bw*2/3` (padding reduces the offered
            // frame, causing the shape to draw smaller).
            ZStack {
                shape.stroke(color, lineWidth: bw / 3)
                shape.stroke(color, lineWidth: bw / 3).padding(bw * 2 / 3)
            }
        }
    }

    // MARK: - Rendering helpers

    /// Runs the full parse → cascade → resolve pipeline once.
    ///
    /// Separated from `body` so test helpers can exercise the full flow by
    /// simply reading `body`, yet the resolver's factories only run once per
    /// evaluation.
    internal func renderSnapshot() -> ComponentResolver.Resolved {
        var diagnostics = JoyDiagnostics()

        // Pick the active breakpoint for the current viewport (if any).
        let activeBreakpoint = storedViewport.flatMap {
            BreakpointResolver.active(in: $0, breakpoints: spec.breakpoints)
        }

        // Build the cascade rule list and the per-node className overrides
        // the active breakpoint declares.
        let rules = RuleBuilder.buildRules(
            from: spec,
            activeBreakpoint: activeBreakpoint,
            diagnostics: &diagnostics,
            applyUserAgentDefaults: applyUserAgentDefaults
        )
        var classNameOverrides: [String: [String]] = [:]
        var extrasOverrides: [String: [String: JSONValue]] = [:]
        if let bp = activeBreakpoint {
            for (id, props) in bp.nodes {
                if let classes = props.className {
                    classNameOverrides[id] = classes
                }
                if !props.extras.isEmpty {
                    extrasOverrides[id] = props.extras
                }
            }
        }

        // Walk the tree.
        let nodes = StyleTreeBuilder.build(
            layout: spec.layout,
            rootID: "__joydom_root__",
            rules: rules,
            classNameOverrides: classNameOverrides,
            extrasOverrides: extrasOverrides,
            bindingsByID: bindingsByID,
            diagnostics: &diagnostics
        )

        // Capture the handler map locally so the event sink closure doesn't
        // need to retain `self`.
        let handlers = eventHandlers
        // Bubble-path plumbing: look up each node's parent to walk ancestors,
        // and every local's handlers so `.onJoyEvent` can fire during bubble.
        // Both dictionaries use a tolerant init (`[key] = value` in a loop)
        // so adversarial payloads with duplicate ids never hard-crash.
        var parentByID: [String: String?] = [:]
        parentByID.reserveCapacity(nodes.count)
        for n in nodes where parentByID[n.id] == nil {
            parentByID[n.id] = n.parentID
        }
        var localsByID: [String: Component] = [:]
        localsByID.reserveCapacity(locals.count)
        for l in locals { localsByID[l.id] = l }
        let rootID = "__joydom_root__"
        // Prune FormState to the binding paths the current schema
        // declares *before* handing it to the resolver. Done up front so
        // a factory that reads its binding during its initial render
        // can't observe a stale value from a previous payload that
        // happened to reuse a now-dropped path key.
        if let form = formStateRef {
            var keep: Set<String> = []
            for n in nodes {
                for (key, val) in n.props where key == "binding" || key.hasPrefix("binding.") {
                    if case .string(let path) = val { keep.insert(path) }
                }
            }
            form.prune(keeping: keep)
        }
        let resolved = ComponentResolver.resolve(
            nodes: nodes,
            locals: locals,
            registry: registry,
            placeholder: placeholderFactory,
            eventSink: { sourceID, name, payload, propagates in
                let event = JoyEvent(
                    name: name,
                    sourceID: sourceID,
                    payload: payload,
                    propagates: propagates
                )
                // Bubble phase: visit source first, then each ancestor up to
                // (but excluding) the root. Each local along the way may
                // carry a matching `.onJoyEvent` handler. A non-propagating
                // event only fires at the target.
                var cursor: String? = sourceID
                var visited: Set<String> = []
                while let id = cursor, id != rootID, visited.insert(id).inserted {
                    if let local = localsByID[id],
                       let handler = local.handlers[name] {
                        handler(event)
                    }
                    if !propagates { break }
                    cursor = parentByID[id] ?? nil
                }
                // Root handlers are the terminal stop of the bubble phase.
                if propagates {
                    handlers[name]?(event)
                    // Wildcard fires after the named handler so specific
                    // logic (which may modify state) runs before the sniffer.
                    if name != "*" { handlers["*"]?(event) }
                }
            },
            formState: formStateRef,
            diagnostics: &diagnostics
        )

        if let sink = diagnosticHandler {
            for warning in diagnostics.warnings { sink(warning) }
        }
        return resolved
    }

    /// Wraps one resolved child with the `.flexItem(...)` modifier carrying
    /// every CSS item property.
    ///
    /// Phase 3: min/max width/height and margin are now resolved by the
    /// FlexLayout engine itself (see `FlexEngine.computeRawLayout`). The
    /// adapter passes them through; the previous SwiftUI `.frame()` shim
    /// for min/max constraints has been removed.
    ///
    /// TODO: box-sizing: border-box is not yet enforced here. The
    /// `width`/`height` values pass through as content-box sizes per CSS
    /// `box-sizing: content-box` (the initial value).
    private func applyItem(_ view: AnyView, style: ItemStyle) -> some View {
        view.flexItem(
            grow:      style.grow,
            shrink:    style.shrink,
            basis:     style.basis,
            alignSelf: style.alignSelf,
            order:     style.order,
            width:     style.width,
            height:    style.height,
            minWidth:  style.minWidth.map  { .points($0) },
            maxWidth:  style.maxWidth.map  { .points($0) },
            minHeight: style.minHeight.map { .points($0) },
            maxHeight: style.maxHeight.map { .points($0) },
            margin:    Self.edgeInsets(from: style.margin),
            overflow:  style.overflow,
            zIndex:    style.zIndex,
            position:  style.position,
            top:       style.top,
            bottom:    style.bottom,
            leading:   style.leading,
            trailing:  style.trailing
        )
    }

    /// Translate JoyDOM's `Padding` shape (uniform / per-side) into the
    /// SwiftUI `EdgeInsets` value FlexLayout's `ItemStyle.margin` expects.
    /// Returns `EdgeInsets()` (zero on all sides) when no margin is set.
    ///
    /// Only `px` units feed the layout engine. Percentage / em / other
    /// units are not yet supported on margin and resolve to zero — the
    /// engine has no notion of "margin: 5%" today, so silently dropping
    /// such values is preferable to mis-scaling them as raw points.
    private static func edgeInsets(from padding: Padding?) -> EdgeInsets {
        guard let padding else { return EdgeInsets() }
        func px(_ l: Length) -> CGFloat { l.unit == "px" ? CGFloat(l.value) : 0 }
        switch padding {
        case .uniform(let l):
            let n = px(l)
            return EdgeInsets(top: n, leading: n, bottom: n, trailing: n)
        case .sides(let t, let r, let b, let l):
            return EdgeInsets(top: px(t), leading: px(l), bottom: px(b), trailing: px(r))
        }
    }
}
