// DOMImage — leaf renderer for the `img` primitive factory.
//
// Reads the `inheritedObjectFit` and `inheritedObjectPosition`
// environment values an ancestor handed down (via
// `JoyDOMView.applyVisual`) and applies the matching SwiftUI scaling /
// alignment modifiers. The cascade writes the values; this view
// consumes them — same pattern as `_DecoratedText`.
//
// `applyFit(_:)` is `internal` so unit tests can pin the four
// `objectFit` arms without spinning up a hosting controller.

import SwiftUI

internal struct _DOMImage: View {
    let url: URL

    @Environment(\.inheritedObjectFit)      private var fit
    @Environment(\.inheritedObjectPosition) private var pos

    var body: some View {
        // CSS-correct sizing: an `<img>` with no declared width/height
        // renders at intrinsic dimensions, and `object-fit` only takes
        // effect when the declared dimensions differ from intrinsic.
        // Authors using `object-fit` should set explicit width/height
        // (or 100% × 100%) on the img element via CSS, which JoyDOM
        // passes to FlexLayout as `.flexItem(width:height:)`.
        //
        // Known limitation: for `objectFit: none` (intrinsic-size image
        // inside a smaller frame), the image anchors at top-leading
        // regardless of `objectPosition`. Earlier attempts to honour
        // `objectPosition` here used `Color.clear.overlay(image,
        // alignment:)` and `GeometryReader { ... }`; both caused the
        // SwiftUI / FlexLayout integration to renegotiate layout on
        // every viewport change, hanging the UI. The CSS-canonical
        // path (declare explicit width/height on the img and use a
        // sizing object-fit value like `cover`) avoids this entirely;
        // the `none` + position case will get a proper fix when we add
        // hosted snapshot tests and can reproduce the layout cycle in
        // isolation.
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                applyFit(image)
            case .failure:
                // Visible signal during authoring: a faint gray tint
                // appears where the image would be. Surfaces broken
                // URLs immediately rather than silently disappearing.
                Color.gray.opacity(0.2)
            case .empty:
                ProgressView()
            @unknown default:
                Color.gray.opacity(0.1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity,
               alignment: pos?.alignment ?? .center)
        .clipped()
    }

    /// Apply the `object-fit` mode to a SwiftUI `Image`. Spec values:
    ///   • `.fill`     — stretch to fill the box, ignoring aspect ratio.
    ///   • `.contain`  — preserve aspect ratio, fit inside the box.
    ///   • `.cover`    — preserve aspect ratio, fill the box (cropping).
    ///   • `.none`     — render at the image's intrinsic size.
    ///
    /// `nil` (no `object-fit` declared) maps to `.fill`, matching the
    /// CSS initial value (CSS Image Module Level 3 §5.4). The previous
    /// behaviour rendered intrinsic size on `nil`, which made every
    /// default `<img src="…">` payload diverge from web rendering.
    @ViewBuilder
    internal func applyFit(_ image: Image) -> some View {
        switch fit {
        case .some(.fill), .none:
            image.resizable()
        case .some(.contain):
            image.resizable().aspectRatio(contentMode: .fit)
        case .some(.cover):
            image.resizable().aspectRatio(contentMode: .fill)
        case .some(.none):
            image
        }
    }
}
