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

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Public registry for additional resource bundles that `_DOMImage`
/// should search when resolving `bundle://<name>` URLs. Snapshot tests
/// register the spec-samples bundle here so they can load deterministic
/// PNG fixtures synchronously (AsyncImage's URLSession path never
/// resolves in a single render pass, which made every PR #93 baseline
/// pin the ProgressView spinner — see commit message + PR description).
public enum DOMImageBundleRegistry {
    /// Bundles searched in registration order. `Bundle.module` (the
    /// JoyDOM target's own resources, if any) is always tried first via
    /// `_DOMImage` itself.
    public private(set) static var bundles: [Bundle] = []

    public static func register(_ bundle: Bundle) {
        if !bundles.contains(where: { $0.bundleURL == bundle.bundleURL }) {
            bundles.append(bundle)
        }
    }
}

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
        //
        // For URLs with scheme `bundle://`, we resolve the named PNG
        // from a registered bundle synchronously. This sidesteps
        // AsyncImage entirely — necessary for snapshot tests where the
        // render pass must produce a deterministic image without
        // waiting on the run loop.
        if url.scheme == "bundle", let image = Self.loadBundleImage(from: url) {
            applyFit(image)
                .frame(maxWidth: .infinity, maxHeight: .infinity,
                       alignment: pos?.alignment ?? .center)
                .clipped()
        } else {
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
    }

    /// Resolve a `bundle://<name>` URL to a SwiftUI `Image` by walking
    /// the registered bundles. The name is taken from the URL's host
    /// (`bundle://photo-landscape` → `photo-landscape`); if the host is
    /// nil we fall back to the last path component so authors can also
    /// write `bundle:///photo-landscape` if they prefer.
    internal static func loadBundleImage(from url: URL) -> Image? {
        let name: String
        if let host = url.host, !host.isEmpty {
            name = host
        } else {
            let comps = url.path.split(separator: "/")
            guard let last = comps.last else { return nil }
            name = String(last)
        }
        // Strip a trailing `.png` if the author included it explicitly.
        let baseName: String = {
            if name.hasSuffix(".png") { return String(name.dropLast(4)) }
            return name
        }()

        let searchBundles = [Bundle.main] + DOMImageBundleRegistry.bundles
        for bundle in searchBundles {
            // Try with the test-assets subdirectory first, then fall
            // back to a flat lookup.
            let candidate =
                bundle.url(forResource: baseName, withExtension: "png",
                           subdirectory: "test-assets")
                ?? bundle.url(forResource: baseName, withExtension: "png")
            if let url = candidate {
                return loadImageFromFile(url: url)
            }
        }
        return nil
    }

    private static func loadImageFromFile(url: URL) -> Image? {
        #if canImport(UIKit)
        guard let ui = UIImage(contentsOfFile: url.path) else { return nil }
        return Image(uiImage: ui)
        #elseif canImport(AppKit)
        guard let ns = NSImage(contentsOfFile: url.path) else { return nil }
        return Image(nsImage: ns)
        #else
        return nil
        #endif
    }

    /// Apply the `object-fit` mode to a SwiftUI `Image`. Spec values:
    ///   • `.fill`       — stretch to fill the box, ignoring aspect ratio.
    ///   • `.contain`    — preserve aspect ratio, fit inside the box.
    ///   • `.cover`      — preserve aspect ratio, fill the box (cropping).
    ///   • `.none`       — render at the image's intrinsic size.
    ///   • `.scaleDown`  — whichever of `.none` / `.contain` is smaller.
    ///                     With AsyncImage we can't synchronously probe
    ///                     intrinsic size in the build phase, so we
    ///                     conservatively render as `.contain` — never
    ///                     overflows, and on smaller-than-box images the
    ///                     `aspectRatio(.fit)` modifier still preserves
    ///                     the image's natural aspect, matching the
    ///                     observable behaviour of `scale-down` for the
    ///                     intrinsic-smaller case (no upscaling, since
    ///                     `.fit` won't enlarge beyond intrinsic).
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
        case .some(.scaleDown):
            image.resizable().aspectRatio(contentMode: .fit)
        }
    }
}
