// DecoratedText — leaf renderer for `primitive_string` / `primitive_number`.
//
// Reads the `inheritedTextDecoration` environment value an ancestor handed
// down (via `JoyDOMView.applyVisual`) and paints the corresponding
// Text-level modifier — SwiftUI's container `.underline()` /
// `.strikethrough()` do not cascade through `AnyView` boundaries, so the
// leaf has to opt in.
//
// Lives alongside `TextDecorationKey` in `Views/Environment/` because it
// is a SwiftUI `View`, not registry logic; the `primitive_string` /
// `primitive_number` factories simply hand off to it.

import SwiftUI

internal struct _DecoratedText: View {
    let text: String
    @Environment(\.inheritedTextDecoration) private var decoration
    @Environment(\.inheritedCapitalize) private var capitalize

    var body: some View {
        // `text-transform: capitalize` title-cases each word. SwiftUI's
        // `.textCase` env only covers upper/lower, so we mutate the
        // string here using Foundation's `.capitalized` (Unicode-aware,
        // word-boundary based — matches CSS `capitalize` intent).
        let rendered = capitalize ? text.capitalized : text
        switch decoration {
        case .none:        Text(rendered)
        case .underline:   Text(rendered).underline()
        case .lineThrough: Text(rendered).strikethrough()
        }
    }
}
