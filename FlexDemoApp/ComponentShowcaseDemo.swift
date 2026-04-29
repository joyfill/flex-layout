// ComponentShowcaseDemo — Tier 2 kitchen-sink demo.
//
// Renders a single `CSSLayout` payload whose schema mixes every
// `ComponentBody` factory the library ships:
//
//   • .custom(...)  — pure SwiftUI card + an auto-sizing Text block
//                     whose content length is driven by a slider.
//                     CSS leaves `height` unset → FlexLayout falls back
//                     to the SwiftUI intrinsic height, so the container
//                     grows/shrinks with the text.
//   • .webView(...) — a WKWebView panel that reports its own
//                     measured `document.documentElement.scrollHeight`
//                     back to Swift via the onMessage channel. The
//                     demo stamps the new height into the `#web-card`
//                     CSS rule, triggering CSSLayout re-render and a
//                     live resize — a proper dynamic-height WebView
//                     round-trip.
//   • .uiKit(...)   — UIKit `UILabel` on iOS/iPadOS with attributed
//                     text. macOS (no UIKit) falls back to `.custom`
//                     with a matching SwiftUI Text so the demo still
//                     builds and looks right.
//   • .custom list  — a ForEach that grows a vertical list as the user
//                     taps a `+ row` button — proves that intrinsic
//                     sizing composes through several levels of nested
//                     flex containers.
//
// Cross-cutting themes the demo exercises on purpose:
//
//   * Dynamic content heights: two different mechanisms (intrinsic
//     SwiftUI sizing + JS-reported WebView height) live side by side
//     so you can see each in isolation.
//   * Event round-trip: every action button emits a named event; the
//     root `.onEvent` sink logs it into a rolling debug panel.
//   * Binding round-trip: the WebView's "Clear" button posts a
//     message that mutates FormState, which re-renders the text card.
//
// Kept deliberately standalone — no shared helpers beyond the
// sidebar-level `ResponsivePreview` wrapper in `ContentView`.

import SwiftUI
import CSSLayout

struct ComponentShowcaseDemo: View {

    // MARK: - Authoring state

    @StateObject private var form = FormState(values: [
        "article.title":   "Tier 2 in one view",
        "article.excerpt": "Mix SwiftUI, UIKit, and WebKit factories in a single server-driven layout.",
    ])

    /// Slider drives how many sentences the dynamic Text block shows.
    /// Each tick adds ~40-60 pts of intrinsic height — the CSS leaves
    /// `#excerpt-card` without a height rule so the container follows.
    @State private var sentenceCount: Double = 2

    /// Tapping `+ row` grows this; the custom list factory reads it
    /// from FormState and renders that many rows. The list item CSS
    /// has a fixed per-row height (`#row-*`) but the *container* has
    /// none, so the parent flex box lengthens naturally as rows appear.
    @State private var rowCount: Int = 3

    /// Measured content height of the WebView, in points. Populated
    /// when the embedded `ResizeObserver` posts via the `cssLayout`
    /// JS bridge. We bake it back into the CSS string so the flex
    /// slot resizes to fit the HTML content.
    @State private var webContentHeight: CGFloat = 180

    /// Rolling console of events the root `.onEvent(...)` sink saw.
    /// Each entry is prefixed with the event's `sourceID` so it's
    /// obvious which component fired.
    @State private var eventLog: [String] = []

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                controlPanel
                Divider()
                canvas
                debugPanel
            }
            .padding(24)
            .frame(maxWidth: 720, alignment: .leading)
        }
    }

    // MARK: - Chrome

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Component Showcase")
                .font(.title2.weight(.semibold))
            Text(
                "Every ComponentBody factory (.custom, .uiKit, .webView) "
                + "used in one CSSLayout payload. Drag the sliders to see "
                + "both intrinsic-height sizing and JS-reported WebView "
                + "heights respond live."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    private var controlPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Text("Excerpt length")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 110, alignment: .leading)
                Slider(value: $sentenceCount, in: 1...6, step: 1)
                Text("\(Int(sentenceCount)) sentence" + (Int(sentenceCount) == 1 ? "" : "s"))
                    .font(.system(.caption, design: .monospaced))
                    .frame(width: 80, alignment: .trailing)
            }
            HStack(spacing: 12) {
                Text("Comment rows")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 110, alignment: .leading)
                Stepper(value: $rowCount, in: 0...8) {
                    Text("\(rowCount) row" + (rowCount == 1 ? "" : "s"))
                        .font(.system(.caption, design: .monospaced))
                }
            }
        }
    }

    private var canvas: some View {
        CSSLayout(payload: payload, registry: registry)
            .formState(form)
            .onEvent("*") { event in
                eventLog.append("\(event.sourceID) → \(event.name)")
                if eventLog.count > 10 {
                    eventLog.removeFirst(eventLog.count - 10)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(12)
            .background(Color(white: 0.96))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.gray.opacity(0.25))
            )
    }

    private var debugPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            GroupBox("WebView self-reported height (JS → Swift)") {
                HStack {
                    Text("measured")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(webContentHeight)) pt")
                        .font(.system(.caption, design: .monospaced))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.green.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .padding(6)
            }

            GroupBox("Event log (bubbled to root)") {
                VStack(alignment: .leading, spacing: 2) {
                    if eventLog.isEmpty {
                        Text("Tap a button or resize the HTML card…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(eventLog.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .padding(6)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Live payload

    /// The excerpt Text is driven by the slider — longer excerpt, taller
    /// card, no CSS height needed.
    private var excerptText: String {
        let sentences = [
            "ComponentBody wraps SwiftUI, UIKit, and WebKit surfaces behind one factory type.",
            "The resolver calls makeView() and drops the result into the flex tree.",
            "Intrinsic-height views keep their natural size — CSS height:auto is the default.",
            "WebKit content can post its own measured height back through the onMessage channel.",
            "UIKit wrappers get a separate make/update closure pair so SwiftUI can drive updates.",
            "Every bridge falls back to a SwiftUI view when the host platform lacks the primitive.",
        ]
        let take = max(1, min(sentences.count, Int(sentenceCount)))
        return sentences.prefix(take).joined(separator: " ")
    }

    /// Rebuilt on every render — when `webContentHeight` changes the CSS
    /// string changes, CSSPayloadCache sees a new payload key, and the
    /// resolver re-lays out `#web-card` to the new height.
    private var payload: CSSPayload {
        let measuredHeight = Int(webContentHeight.rounded())

        let css = """
        #root {
            display: flex;
            flex-direction: column;
            gap: 14px;
            padding: 16px;
        }
        #header       { height: 62px; }
        #kinds-strip  { height: 44px; }
        /* excerpt-card has NO height rule — auto = intrinsic SwiftUI height */
        #web-card     { height: \(measuredHeight)px; }
        #uikit-card   { height: 54px; }
        #actions {
            display: flex;
            flex-direction: row;
            gap: 10px;
        }
        #action-primary, #action-secondary { flex: 1; height: 40px; }
        /* comment-list has no height rule either — grows with child count */
        .comment-row { height: 36px; }
        """

        var schema: [SchemaEntry] = [
            SchemaEntry(id: "header", type: "header-card",
                        props: ["binding.title":   "article.title",
                                "binding.excerpt": "article.excerpt"]),
            SchemaEntry(id: "kinds-strip", type: "kinds-strip"),
            SchemaEntry(id: "excerpt-card", type: "excerpt-card",
                        props: ["text": excerptText]),
            SchemaEntry(id: "web-card", type: "web-card"),
            SchemaEntry(id: "uikit-card", type: "uikit-card",
                        props: ["label": "UILabel · Tier 2 bridge"]),
            SchemaEntry(id: "comment-list", type: "comment-list",
                        props: ["count": "\(rowCount)"]),
            SchemaEntry(id: "actions"),
            SchemaEntry(id: "action-primary",   type: "action-button",
                        parentID: "actions",
                        props: ["text": "Publish", "event": "publish", "style": "primary"]),
            SchemaEntry(id: "action-secondary", type: "action-button",
                        parentID: "actions",
                        props: ["text": "Save draft", "event": "save-draft", "style": "secondary"]),
        ]

        // Expand the comment list into concrete nodes so each row has
        // its own id and CSS class. Lets us demonstrate that "container
        // with children" is orthogonal to "which ComponentBody kind".
        for i in 0..<rowCount {
            schema.append(SchemaEntry(
                id: "row-\(i)",
                type: "comment-row",
                classes: ["comment-row"],
                parentID: "comment-list",
                props: ["index": "\(i + 1)"]
            ))
        }

        return CSSPayload(css: css, schema: schema)
    }

    // MARK: - Registry

    private var registry: ComponentRegistry {
        let r = ComponentRegistry()

        // ── .custom — simple SwiftUI header card ────────────────────
        r.register("header-card") { props, events in
            .custom {
                VStack(alignment: .leading, spacing: 4) {
                    Text(events.binding("title").wrappedValue)
                        .font(.headline)
                    Text(events.binding("excerpt").wrappedValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityIdentifier(props.id)
            }
        }

        // ── .custom — decorative "kinds" strip with 3 badges ─────────
        r.register("kinds-strip") { props, _ in
            .custom {
                HStack(spacing: 8) {
                    KindBadge(color: .blue,   label: ".custom")
                    KindBadge(color: .orange, label: ".webView")
                    KindBadge(color: .purple, label: ".uiKit")
                    Spacer()
                }
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity, minHeight: 36)
                .background(Color(white: 0.99))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color.gray.opacity(0.2))
                )
                .accessibilityIdentifier(props.id)
            }
        }

        // ── .custom — excerpt card, intrinsic-height Text ───────────
        // No CSS `height` on #excerpt-card. FlexSize.auto ⇒ FlexLayout
        // defers to SwiftUI's natural sizing, so the card grows with
        // the sentence count.
        r.register("excerpt-card") { props, _ in
            let body = props.string("text") ?? ""
            return .custom {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Excerpt · intrinsic height")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(body)
                        .font(.system(.body))
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.yellow.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.yellow.opacity(0.45))
                )
                .accessibilityIdentifier(props.id)
            }
        }

        // ── .webView — HTML panel that measures itself and posts the
        //    height back through the JS bridge. The SwiftUI parent
        //    stores the reported height in @State so the next render
        //    bakes it into the `#web-card` CSS rule.
        r.register("web-card") { props, events in
            let id = props.id
            #if canImport(WebKit) && !os(tvOS) && !os(watchOS)
            return .webView(
                html: Self.webCardHTML,
                onMessage: { payload in
                    switch payload["kind"] {
                    case "resize":
                        if let raw = payload["height"],
                           let h = Double(raw),
                           h.isFinite, h > 0 {
                            let clamped = max(120, min(360, h + 20)) // +20 for internal padding
                            DispatchQueue.main.async {
                                webContentHeight = clamped
                            }
                        }
                    case "event":
                        let name = payload["name"] ?? "web-event"
                        DispatchQueue.main.async {
                            events.emit(name, payload: payload)
                        }
                    default:
                        break
                    }
                }
            )
            #else
            return .custom {
                Text("WKWebView unavailable on this platform")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityIdentifier(id)
            }
            #endif
        }

        // ── .uiKit — UILabel on iOS; SwiftUI fallback on macOS ──────
        r.register("uikit-card") { props, _ in
            let labelText = props.string("label") ?? ""
            let id = props.id
            #if canImport(UIKit) && !os(watchOS)
            return .uiKit(
                make: { () -> UILabel in
                    let l = UILabel()
                    l.text = labelText
                    l.textColor = .label
                    l.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.12)
                    l.layer.cornerRadius = 8
                    l.layer.masksToBounds = true
                    l.textAlignment = .center
                    l.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
                    l.accessibilityIdentifier = id
                    return l
                },
                update: { label in
                    if label.text != labelText { label.text = labelText }
                }
            )
            #else
            return .custom {
                Text(labelText)
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.purple.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.purple.opacity(0.3))
                    )
                    .accessibilityIdentifier(id)
            }
            #endif
        }

        // ── .custom container (no body — schema children render it).
        //    Included only so the resolver knows about the `actions`
        //    and `comment-list` types. The resolver always wraps
        //    nodes-with-children in a nested FlexLayout anyway, so
        //    the body we return here is never drawn.
        let passthrough: ComponentFactory = { _, _ in
            .custom { EmptyView() }
        }
        r.register("comment-list", factory: passthrough)

        // ── .custom — one row of the growing list. Individual rows
        //    have a CSS-pinned height (36pt) so the *list* shows the
        //    "nested container grows with child count" dynamic without
        //    individual rows also having to solve intrinsic sizing.
        r.register("comment-row") { props, _ in
            let index = props.string("index") ?? "?"
            return .custom {
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.teal.opacity(0.7))
                        .frame(width: 22, height: 22)
                        .overlay(
                            Text(index)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                        )
                    Text("Comment #\(index) · intrinsic row")
                        .font(.caption)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .background(Color.teal.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .accessibilityIdentifier(props.id)
            }
        }

        // ── .custom — primary/secondary action buttons that emit the
        //    name declared in the schema `event` prop.
        r.register("action-button") { props, events in
            let text  = props.string("text")  ?? "Action"
            let name  = props.string("event") ?? "action"
            let style = props.string("style") ?? "secondary"
            return .custom {
                Group {
                    if style == "primary" {
                        Button(text) { events.emit(name, payload: [:]) }
                            .buttonStyle(.borderedProminent)
                    } else {
                        Button(text) { events.emit(name, payload: [:]) }
                            .buttonStyle(.bordered)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityIdentifier(props.id)
            }
        }

        return r
    }

    // MARK: - HTML blob for the .webView factory

    /// The page installs a `ResizeObserver` on `<body>` and posts
    /// `{kind: "resize", height: "<px>"}` whenever the content height
    /// changes. The Swift side clamps the value and drives the
    /// `#web-card` CSS rule.
    ///
    /// The "Emit click" button demonstrates the `{kind: "event", ...}`
    /// path — the Swift onMessage handler forwards it into the normal
    /// `ComponentEvents.emit` pipeline so the root-level `.onEvent`
    /// handler logs it like any other bubble.
    fileprivate static let webCardHTML: String = """
    <!doctype html>
    <html>
      <head>
        <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
        <style>
          html, body { margin: 0; padding: 0; }
          body {
            font: -apple-system-body, sans-serif;
            color: #1d1d1f;
            padding: 12px 14px;
            background: linear-gradient(180deg, #fff5e6 0%, #ffe8c7 100%);
            box-sizing: border-box;
          }
          h3  { margin: 0 0 6px; font-size: 14px; color: #8a4f00; }
          p   { margin: 0 0 10px; font-size: 12px; line-height: 1.45; color: #4a3200; }
          .row { display: flex; gap: 8px; align-items: center; }
          button {
            font-size: 12px;
            padding: 5px 10px;
            border-radius: 6px;
            border: 1px solid #d3a970;
            background: #fffaf0;
            color: #6b3d00;
          }
          .extra { display: none; font-size: 11px; color: #6b3d00; margin-top: 8px; }
          .extra.show { display: block; }
        </style>
      </head>
      <body>
        <h3>WKWebView — self-measuring</h3>
        <p>This HTML measures its own content height via <code>ResizeObserver</code> and posts the value back to Swift. The flex slot re-renders to match, keeping the card tight around its content.</p>
        <div class=\"row\">
          <button onclick=\"toggleExtra()\">Toggle details</button>
          <button onclick=\"emitClick()\">Emit click event</button>
        </div>
        <div class=\"extra\" id=\"extra\">
          Expanding this panel grows the WebView content. The
          <em>ResizeObserver</em> fires, posts the new scrollHeight,
          and Swift rewrites the CSS rule for <code>#web-card</code>
          — live end-to-end.
        </div>
        <script>
          function post(obj) {
            window.webkit.messageHandlers.cssLayout.postMessage(obj);
          }
          function toggleExtra() {
            document.getElementById('extra').classList.toggle('show');
          }
          function emitClick() {
            post({kind: 'event', name: 'web-clicked', from: 'webview'});
          }
          const ro = new ResizeObserver(entries => {
            for (const e of entries) {
              const h = Math.ceil(e.contentRect.height);
              post({kind: 'resize', height: String(h)});
            }
          });
          ro.observe(document.body);
        </script>
      </body>
    </html>
    """
}

// MARK: - Decorative badge used in the kinds strip

private struct KindBadge: View {
    let color: Color
    let label: String

    var body: some View {
        Text(label)
            .font(.system(.caption, design: .monospaced).weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(color.opacity(0.35))
            )
    }
}

#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif
