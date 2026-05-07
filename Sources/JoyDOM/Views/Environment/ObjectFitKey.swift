// ObjectFitKey — propagates `object-fit` and `object-position` through
// SwiftUI's environment so the `img` factory's leaf renderer can apply
// the right `.resizable() + .aspectRatio(contentMode:)` and
// `.frame(alignment:)` modifiers.
//
// Same pattern as `TextDecorationKey`: the cascade writes the resolved
// values into the environment in `JoyDOMView.applyVisual`, and a
// descendant `_DOMImage` reads them via `@Environment` and consumes
// them at paint time.

import SwiftUI

private struct InheritedObjectFitKey: EnvironmentKey {
    static let defaultValue: Style.ObjectFit? = nil
}

private struct InheritedObjectPositionKey: EnvironmentKey {
    static let defaultValue: Style.ObjectPosition? = nil
}

extension EnvironmentValues {
    /// `object-fit` value handed down by the nearest ancestor that declared
    /// it. The `img` factory's `_DOMImage` reads this and chooses between
    /// `.resizable()`, `.resizable().aspectRatio(contentMode: .fit)`,
    /// `.resizable().aspectRatio(contentMode: .fill)`, or no modifier at
    /// all.
    public var inheritedObjectFit: Style.ObjectFit? {
        get { self[InheritedObjectFitKey.self] }
        set { self[InheritedObjectFitKey.self] = newValue }
    }

    /// `object-position` value handed down by the nearest ancestor. The
    /// `img` factory's `_DOMImage` consumes this through
    /// `Style.ObjectPosition.alignment` and feeds the result into
    /// `.frame(alignment:)`.
    public var inheritedObjectPosition: Style.ObjectPosition? {
        get { self[InheritedObjectPositionKey.self] }
        set { self[InheritedObjectPositionKey.self] = newValue }
    }
}

// MARK: - ObjectPosition → SwiftUI Alignment

internal extension Style.ObjectPosition {
    /// Map the spec's 3×3 horizontal/vertical grid onto SwiftUI's
    /// `Alignment` cases. Used by `_DOMImage` to position its `Image`
    /// within the available frame.
    var alignment: Alignment {
        switch (horizontal, vertical) {
        case (.left,   .top):    return .topLeading
        case (.center, .top):    return .top
        case (.right,  .top):    return .topTrailing
        case (.left,   .center): return .leading
        case (.center, .center): return .center
        case (.right,  .center): return .trailing
        case (.left,   .bottom): return .bottomLeading
        case (.center, .bottom): return .bottom
        case (.right,  .bottom): return .bottomTrailing
        }
    }
}
