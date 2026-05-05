// TextDecorationKey — propagates `text-decoration` through SwiftUI's
// environment so primitive Text leaves can apply `.underline()` or
// `.strikethrough()` directly. Container modifiers like `.underline()`
// don't cascade to descendant `Text` views, so we hand the decoration
// down via an EnvironmentKey instead and let `primitive_string` /
// `primitive_number` factories paint it on the leaf.

import SwiftUI

/// CSS `text-decoration` value as it cascades into descendant text.
public enum InheritedTextDecoration: Equatable {
    case none
    case underline
    case lineThrough
}

private struct TextDecorationKey: EnvironmentKey {
    static let defaultValue: InheritedTextDecoration = .none
}

extension EnvironmentValues {
    /// Decoration handed down by the nearest ancestor that declared
    /// `text-decoration`. `primitive_string` / `primitive_number`
    /// factories read this and apply the corresponding modifier to
    /// their `Text` leaf so the decoration actually paints.
    public var inheritedTextDecoration: InheritedTextDecoration {
        get { self[TextDecorationKey.self] }
        set { self[TextDecorationKey.self] = newValue }
    }
}
