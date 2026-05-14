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

/// CSS `text-transform: capitalize` — title-cases each word. SwiftUI's
/// `.textCase` only ships `.uppercase`/`.lowercase`, so capitalize has
/// to ride down through the environment and be applied to the text
/// content directly at the leaf.
private struct InheritedCapitalizeKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    /// `true` when the nearest ancestor declared
    /// `text-transform: capitalize`. `_DecoratedText` reads this and
    /// title-cases its string content before painting.
    public var inheritedCapitalize: Bool {
        get { self[InheritedCapitalizeKey.self] }
        set { self[InheritedCapitalizeKey.self] = newValue }
    }
}
