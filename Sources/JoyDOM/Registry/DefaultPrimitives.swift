// DefaultPrimitives — `ComponentRegistry.withDefaultPrimitives()` adds
// factories for the joy-dom HTML element types and internal primitives.
//
// Container elements (div, span, p, h1–h6): render as passthrough — the
// FlexLayout subtree handles their content; they contribute no chrome.
// Typography styling on these elements is applied by the render layer as
// SwiftUI environment modifiers that cascade to Text descendants.
//
// Void elements:
//   • `img`             — AsyncImage driven by a `src` extra prop.
//
// Internal primitives (produced by StyleTreeBuilder for primitive children):
//   • `primitive_string` — `Text(value)`
//   • `primitive_number` — `Text(value)` (number serialised to string)
//   • `primitive_null`   — `EmptyView()`
//
// Apps can override any of these by registering a custom factory BEFORE
// or AFTER calling `withDefaultPrimitives()` (last-wins per registry
// contract; the helper skips already-registered slots when called last).

import Foundation
import SwiftUI

extension ComponentRegistry {

    /// Register joy-dom primitive factories for all built-in element types.
    ///
    /// Existing registrations for any type are preserved — the helper only
    /// fills empty slots — so callers can register custom overrides in any order.
    ///
    /// Returns `self` for fluent chaining:
    /// ```swift
    /// let registry = ComponentRegistry()
    ///     .withDefaultPrimitives()
    ///     .register("button") { props, events in .custom { … } }
    /// ```
    @discardableResult
    public func withDefaultPrimitives() -> ComponentRegistry {
        // Block containers — when a node has children, the resolver
        // replaces the factory output with a nested FlexLayout. When a
        // node has NO children (e.g. an empty `<div>` styled as a
        // colored rectangle via `backgroundColor`), the factory output
        // IS what renders. We need a primitive that:
        //
        //   1. Has zero ideal/intrinsic size so an empty `<div>` with no
        //      explicit width and `flex-basis: auto` resolves to 0 wide
        //      (CSS-correct — content size of an empty element is 0).
        //      Naked `Color.clear` reports `intrinsicContentSize: (10, 10)`,
        //      so a row of empty divs would each render as a 10×10 sliver
        //      (caught visually in `flex-direction/with-basis.json` — box
        //      `a` was rendering at 10px wide instead of 0).
        //   2. Still expands to fill when a parent proposes a finite size
        //      (flex-grow, explicit width on the element, or cross-axis
        //      stretch).
        //   3. Respects every `applyVisual` / `applyItem` modifier on top
        //      (background, borders, frame, clipShape) — rules out
        //      `EmptyView()` which takes zero space *and* ignores modifiers.
        //
        // `Color.clear.frame(idealWidth: 0, idealHeight: 0)` satisfies all
        // three: the explicit ideal of 0 overrides Color's intrinsic
        // contribution to the unconstrained-axis fallback, and the
        // surrounding `.frame` still accepts background/clipShape/etc.
        // applied after.
        for type_ in ["div", "span", "section", "article", "header", "footer",
                      "main", "nav", "ul", "ol", "li", "form", "label"] {
            let t = type_
            registerIfAbsent(t) { _, _ in
                .custom { Color.clear.frame(idealWidth: 0, idealHeight: 0) }
            }
        }

        // Text containers — semantic block elements; same passthrough
        // rendering; typography styling cascades via SwiftUI environment.
        for type_ in ["p", "h1", "h2", "h3", "h4", "h5", "h6"] {
            let t = type_
            registerIfAbsent(t) { _, _ in
                .custom { Color.clear.frame(idealWidth: 0, idealHeight: 0) }
            }
        }

        // Inline text container
        registerIfAbsent("span") { _, _ in
            .custom { Color.clear.frame(idealWidth: 0, idealHeight: 0) }
        }

        // Image — `src` extra prop drives the URL. The leaf view is
        // `_DOMImage`, which reads `object-fit` / `object-position` from
        // the SwiftUI environment (handed down by `JoyDOMView.applyVisual`)
        // and applies the matching `.resizable() + .aspectRatio(...)` and
        // `.frame(alignment:)` modifiers.
        registerIfAbsent("img") { props, _ in
            let src = props.string("src") ?? ""
            if let url = URL(string: src) {
                return .custom { _DOMImage(url: url) }
            }
            return .custom { Color.gray.opacity(0.1) }
        }

        // Internal primitives produced by StyleTreeBuilder for text children.
        // Both string and number leaves render through `_DecoratedText` so
        // they can pick up the `inheritedTextDecoration` environment value
        // an ancestor declared and apply `.underline()` / `.strikethrough()`
        // directly to the leaf — SwiftUI's container-level decoration
        // modifiers don't cascade to descendant `Text`.
        registerIfAbsent("primitive_string") { props, _ in
            let value = props.string("value") ?? ""
            return .custom { _DecoratedText(text: value) }
        }
        registerIfAbsent("primitive_number") { props, _ in
            let value = props.string("value") ?? ""
            return .custom { _DecoratedText(text: value) }
        }
        registerIfAbsent("primitive_null") { _, _ in
            .custom { EmptyView() }
        }
        return self
    }

    /// Register a factory only when the type isn't already registered.
    private func registerIfAbsent(
        _ type: String,
        factory: @escaping ComponentFactory
    ) {
        guard self.factory(for: type) == nil else { return }
        register(type, factory: factory)
    }
}

// `_DecoratedText` — the leaf renderer used by `primitive_string` /
// `primitive_number` — lives in `Sources/JoyDOM/Views/Environment/` so
// the SwiftUI view types stay in the Views layer.
