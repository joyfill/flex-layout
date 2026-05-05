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

    var body: some View {
        switch decoration {
        case .none:        Text(text)
        case .underline:   Text(text).underline()
        case .lineThrough: Text(text).strikethrough()
        }
    }
}
