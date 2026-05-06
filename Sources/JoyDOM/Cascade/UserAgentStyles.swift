// UserAgentStyles — built-in User Agent stylesheet that mirrors the
// default visual styling browsers ship for common HTML elements.
//
// Without this layer, an unstyled `<h4>` rendered by JoyDOM Swift would
// fall back to the inherited body typography while the same payload on
// a web browser picks up the browser's UA defaults (bold, distinct
// font-size). The visualCSS sample surfaced this gap — "Heading 4" was
// bold on web and plain on iOS. Shipping JoyDOM's own UA layer closes
// that cross-platform parity hole.
//
// Cascade integration (in `RuleBuilder`):
//   • Each entry is materialized as a `StyleResolver.Rule` whose
//     selector is a single type-selector compound (e.g. `h1`).
//   • Specificity is `(0, 0, 0, 1)` — the same as a bare type
//     selector. Author rules with class or id specificity always win.
//   • `sourceOrder = -1` so equal-specificity author type selectors
//     (e.g. `h1 { fontSize: 40 }`) beat UA defaults on source order
//     per standard CSS cascade rules.
//
// Spec position:
//   `joyfill/.joy DOM/spec.ts` does not define UA defaults — it
//   defines the typed Style schema only. The README's Core Principles
//   say "Do not violate HTML and CSS principles", and UA defaults are
//   part of CSS, so adding them is faithful to the spec's intent.
//   Spec-strict consumers can opt out via
//   `JoyDOMView.userAgentDefaults(false)`.

import Foundation

/// Built-in User Agent stylesheet. Phase 1 ships `h1`–`h6` only;
/// `b/strong/em/i` will follow once `DefaultPrimitives` registers
/// those element types (currently only `span` covers inline content).
internal enum UserAgentStyles {

    /// Default browser-like sizing for the heading hierarchy. Matches
    /// the canonical 16 px-base scale used by Chrome / Safari:
    ///   h1 = 2.00 em (32 px),  h2 = 1.50 em (24 px),
    ///   h3 = 1.17 em (19 px),  h4 = 1.00 em (16 px),
    ///   h5 = 0.83 em (13 px),  h6 = 0.67 em (11 px).
    /// All headings are bold by default.
    static let rules: [(selector: String, style: Style)] = [
        ("h1", Style(fontSize: .px(32), fontWeight: .bold)),
        ("h2", Style(fontSize: .px(24), fontWeight: .bold)),
        ("h3", Style(fontSize: .px(19), fontWeight: .bold)),
        ("h4", Style(fontSize: .px(16), fontWeight: .bold)),
        ("h5", Style(fontSize: .px(13), fontWeight: .bold)),
        ("h6", Style(fontSize: .px(11), fontWeight: .bold)),
    ]
}
