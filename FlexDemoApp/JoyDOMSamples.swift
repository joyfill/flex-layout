// JoyDOMSamples — curated joy-dom payloads for the paste demo's
// dropdown. Each sample is a complete, valid `Spec` JSON
// document so picking one drops you straight into a working render.
//
// Ordered roughly by complexity: Hello world (minimal) → cards
// (responsive) → signup (FormState territory) → article (primitive
// content) → pricing (multi-card responsive grid).
//
// Adding a new sample: append a `JoyDOMSample` to `JoyDOMSamples.all`
// and the dropdown picks it up automatically.

import Foundation

struct JoyDOMSample: Identifiable, Hashable {
    let id: String
    let label: String
    let json: String
}

enum JoyDOMSamples {

    static let all: [JoyDOMSample] = [
        helloWorld,
        threeCards,
        signupForm,
        article,
        pricingTiers,
        kitchenSink,
        visualCSS,
    ]

    /// Default selection on first open. Matches the demo's prior
    /// hard-coded sample so the initial UI is unchanged.
    static let defaultID = threeCards.id

    static func sample(withID id: String) -> JoyDOMSample? {
        all.first(where: { $0.id == id })
    }

    // MARK: - Sample 1 — Hello world

    private static let helloWorld = JoyDOMSample(
        id: "hello",
        label: "Hello world",
        json: #"""
        {
          "version": 1,
          "style": {},
          "breakpoints": [],
          "layout": {
            "type": "p",
            "props": { "id": "greeting" },
            "children": ["Hello, joy-dom!"]
          }
        }
        """#
    )

    // MARK: - Sample 2 — Three cards (responsive)

    private static let threeCards = JoyDOMSample(
        id: "cards",
        label: "Three cards · responsive",
        json: #"""
        {
          "version": 1,
          "style": {
            "#root": {
              "flexDirection": "column",
              "gap": { "value": 12, "unit": "px" },
              "padding": { "value": 16, "unit": "px" }
            },
            "#row": {
              "flexDirection": "column",
              "gap": { "value": 12, "unit": "px" }
            },
            "#a, #b, #c": {
              "flexGrow": 1,
              "height": { "value": 80, "unit": "px" }
            }
          },
          "breakpoints": [
            {
              "conditions": [
                { "type": "feature", "name": "width", "operator": ">=", "value": 768, "unit": "px" }
              ],
              "nodes": {},
              "style": {
                "#row": {
                  "flexDirection": "row",
                  "gap": { "value": 16, "unit": "px" }
                }
              }
            }
          ],
          "layout": {
            "type": "div",
            "props": { "id": "root" },
            "children": [
              {
                "type": "p",
                "props": { "id": "title" },
                "children": ["Hello, joy-dom!"]
              },
              {
                "type": "div",
                "props": { "id": "row" },
                "children": [
                  { "type": "card", "props": { "id": "a", "label": "Card A" } },
                  { "type": "card", "props": { "id": "b", "label": "Card B" } },
                  { "type": "card", "props": { "id": "c", "label": "Card C" } }
                ]
              },
              {
                "type": "button",
                "props": { "id": "submit", "label": "Submit", "event": "submit" }
              }
            ]
          }
        }
        """#
    )

    // MARK: - Sample 3 — Signup form

    private static let signupForm = JoyDOMSample(
        id: "signup",
        label: "Signup form · inputs + submit",
        json: #"""
        {
          "version": 1,
          "style": {
            "#root": {
              "flexDirection": "column",
              "gap": { "value": 12, "unit": "px" },
              "padding": { "value": 24, "unit": "px" }
            },
            "#row": {
              "flexDirection": "column",
              "gap": { "value": 12, "unit": "px" }
            },
            "#name, #email": {
              "flexGrow": 1,
              "height": { "value": 38, "unit": "px" }
            },
            "#submit": { "height": { "value": 40, "unit": "px" } }
          },
          "breakpoints": [
            {
              "conditions": [
                { "type": "feature", "name": "width", "operator": ">=", "value": 768, "unit": "px" }
              ],
              "nodes": {},
              "style": {
                "#row": {
                  "flexDirection": "row",
                  "gap": { "value": 16, "unit": "px" }
                }
              }
            }
          ],
          "layout": {
            "type": "div",
            "props": { "id": "root" },
            "children": [
              {
                "type": "p",
                "props": { "id": "title" },
                "children": ["Create your account"]
              },
              {
                "type": "div",
                "props": { "id": "row" },
                "children": [
                  {
                    "type": "input",
                    "props": { "id": "name", "placeholder": "Full name" }
                  },
                  {
                    "type": "input",
                    "props": { "id": "email", "placeholder": "Email address" }
                  }
                ]
              },
              {
                "type": "button",
                "props": {
                  "id": "submit",
                  "label": "Create account",
                  "event": "submit"
                }
              }
            ]
          }
        }
        """#
    )

    // MARK: - Sample 4 — Article (primitive content)

    private static let article = JoyDOMSample(
        id: "article",
        label: "Article · primitive content",
        json: #"""
        {
          "version": 1,
          "style": {
            "#article": {
              "flexDirection": "column",
              "gap": { "value": 12, "unit": "px" },
              "padding": { "value": 24, "unit": "px" }
            },
            "#title": { "height": { "value": 36, "unit": "px" } },
            "#byline": { "height": { "value": 20, "unit": "px" } }
          },
          "breakpoints": [],
          "layout": {
            "type": "div",
            "props": { "id": "article" },
            "children": [
              {
                "type": "p",
                "props": { "id": "title" },
                "children": ["The Joy of Server-Driven UI"]
              },
              {
                "type": "p",
                "props": { "id": "byline" },
                "children": ["By the joyfill team · April 2026"]
              },
              {
                "type": "p",
                "props": { "id": "lede" },
                "children": [
                  "Server-driven UI promises a single document format that renders identically across every client."
                ]
              },
              {
                "type": "p",
                "children": [
                  "The trick is finding the right level of abstraction — high enough to be platform-agnostic, low enough to express real screens. Joy-dom lands closer to HTML than to a screenshot, which is the right place for a layout layer to live."
                ]
              },
              {
                "type": "p",
                "children": [
                  "This article is rendered through the same pipeline as every other demo: a JSON document, a tree flatten, a CSS cascade, and a SwiftUI render."
                ]
              }
            ]
          }
        }
        """#
    )

    // MARK: - Sample 5 — Pricing tiers

    private static let pricingTiers = JoyDOMSample(
        id: "pricing",
        label: "Pricing tiers · 3-column",
        json: #"""
        {
          "version": 1,
          "style": {
            "#root": {
              "flexDirection": "column",
              "gap": { "value": 16, "unit": "px" },
              "padding": { "value": 24, "unit": "px" }
            },
            "#heading": { "height": { "value": 32, "unit": "px" } },
            "#tiers": {
              "flexDirection": "column",
              "gap": { "value": 12, "unit": "px" }
            },
            "#tier-free, #tier-pro, #tier-team": {
              "flexGrow": 1,
              "height": { "value": 140, "unit": "px" }
            },
            "#cta": { "height": { "value": 40, "unit": "px" } }
          },
          "breakpoints": [
            {
              "conditions": [
                { "type": "feature", "name": "width", "operator": ">=", "value": 768, "unit": "px" }
              ],
              "nodes": {},
              "style": {
                "#tiers": {
                  "flexDirection": "row",
                  "gap": { "value": 16, "unit": "px" }
                }
              }
            }
          ],
          "layout": {
            "type": "div",
            "props": { "id": "root" },
            "children": [
              {
                "type": "p",
                "props": { "id": "heading" },
                "children": ["Choose a plan"]
              },
              {
                "type": "div",
                "props": { "id": "tiers" },
                "children": [
                  {
                    "type": "card",
                    "props": { "id": "tier-free", "label": "Free — $0 / mo" }
                  },
                  {
                    "type": "card",
                    "props": { "id": "tier-pro", "label": "Pro — $15 / mo" }
                  },
                  {
                    "type": "card",
                    "props": { "id": "tier-team", "label": "Team — $40 / mo" }
                  }
                ]
              },
              {
                "type": "button",
                "props": {
                  "id": "cta",
                  "label": "Start free trial",
                  "event": "cta-tap"
                }
              }
            ]
          }
        }
        """#
    )

    // MARK: - Sample 6 — Kitchen sink (every primitive + style we support)

    /// A deliberately busy showcase that exercises most of the joy-dom
    /// surface in one document. What it covers:
    ///
    ///   • All four selector kinds — type (`p`), id (`#hero`), class
    ///     (`.feature-card`), comma-list (`#name, #email`), descendant
    ///     (`#features p`).
    ///   • Both `gap` shapes — uniform `Length` and per-axis
    ///     `{ c, r }`.
    ///   • Both `padding` shapes — uniform and per-side.
    ///   • Both `Length` units — `px` and `%`.
    ///   • Cascade priorities — type < class < id, document <
    ///     breakpoint, plus inline `props.style` overriding via id-level
    ///     specificity.
    ///   • Three breakpoints — `>= 768`, `>= 1024`, plus a no-op
    ///     `orientation: landscape` to demonstrate the media query
    ///     shape (no visible effect, but it parses).
    ///   • Per-node breakpoint override — `#hero` gets bigger padding
    ///     at `>= 1024`.
    ///   • All registered widget kinds — `card`, `button`, `input`.
    ///   • Default primitives — `div`, `p`, plus `primitive_string`
    ///     children inside `<p>` elements.
    ///   • Position + offsets + z-index — the "NEW" badge floats
    ///     absolutely over its parent feature card.
    ///   • flex-grow / flex-shrink / flex-basis on the stat row,
    ///     `flexWrap: wrap` for graceful overflow.
    ///   • `justifyContent: space-between` + `space-around`,
    ///     `alignItems: center`.
    ///   • `overflow: hidden` on the footer, `overflow: auto` inline
    ///     on the root.
    ///
    /// At ≥1024px wide it reads as a marketing page; below 600px it
    /// stacks. Drag the slider and watch every section reflow.
    private static let kitchenSink = JoyDOMSample(
        id: "kitchen-sink",
        label: "Kitchen sink · everything",
        json: #"""
        {
          "version": 1,
          "style": {
            "p": {
              "padding": { "value": 4, "unit": "px" }
            },
            "#root": {
              "flexDirection": "column",
              "gap": { "value": 24, "unit": "px" },
              "padding": { "value": 24, "unit": "px" }
            },
            "#hero": {
              "flexDirection": "column",
              "alignItems": "center",
              "gap": { "value": 12, "unit": "px" },
              "padding": {
                "top":    { "value": 32, "unit": "px" },
                "right":  { "value": 24, "unit": "px" },
                "bottom": { "value": 40, "unit": "px" },
                "left":   { "value": 24, "unit": "px" }
              },
              "height": { "value": 240, "unit": "px" }
            },
            "#hero-title": {
              "height": { "value": 40, "unit": "px" }
            },
            "#hero-subtitle": {
              "height": { "value": 22, "unit": "px" }
            },
            "#cta": {
              "height": { "value": 44, "unit": "px" },
              "width":  { "value": 200, "unit": "px" }
            },
            "#stats": {
              "flexDirection": "row",
              "justifyContent": "space-around",
              "flexWrap": "wrap",
              "gap": {
                "c": { "value": 16, "unit": "px" },
                "r": { "value": 12, "unit": "px" }
              }
            },
            ".stat": {
              "flexGrow": 1,
              "flexShrink": 1,
              "flexBasis": { "value": 30, "unit": "%" },
              "height":    { "value": 80, "unit": "px" }
            },
            "#features": {
              "flexDirection": "column",
              "gap": { "value": 12, "unit": "px" }
            },
            ".feature-card": {
              "flexGrow":   1,
              "flexShrink": 1,
              "flexBasis":  { "value": 0,   "unit": "px" },
              "height":     { "value": 140, "unit": "px" },
              "position":   "relative"
            },
            "#badge": {
              "position": "absolute",
              "top":      { "value": 8,  "unit": "px" },
              "right":    { "value": 8,  "unit": "px" },
              "zIndex":   10,
              "width":    { "value": 56, "unit": "px" },
              "height":   { "value": 22, "unit": "px" }
            },
            "#form-section": {
              "flexDirection": "column",
              "gap": { "value": 12, "unit": "px" }
            },
            "#form-row": {
              "flexDirection": "column",
              "gap": { "value": 12, "unit": "px" }
            },
            "#name, #email": {
              "flexGrow": 1,
              "height":   { "value": 38, "unit": "px" }
            },
            "#submit": {
              "height": { "value": 40, "unit": "px" }
            },
            "#footer": {
              "flexDirection":  "row",
              "justifyContent": "space-between",
              "alignItems":     "center",
              "padding":        { "value": 16, "unit": "px" },
              "overflow":       "hidden",
              "height":         { "value": 56, "unit": "px" }
            },
            "#footer-nav": {
              "flexDirection": "row",
              "gap": { "value": 8, "unit": "px" }
            },
            ".nav-link": {
              "flexBasis":  { "value": 80, "unit": "px" },
              "flexShrink": 0,
              "height":     { "value": 32, "unit": "px" }
            }
          },
          "breakpoints": [
            {
              "conditions": [
                { "type": "feature", "name": "width", "operator": ">=", "value": 768, "unit": "px" }
              ],
              "nodes": {},
              "style": {
                "#features": {
                  "flexDirection": "row",
                  "gap": { "value": 16, "unit": "px" }
                },
                "#form-row": {
                  "flexDirection": "row",
                  "gap": { "value": 16, "unit": "px" }
                }
              }
            },
            {
              "conditions": [
                { "type": "feature", "name": "width", "operator": ">=", "value": 1024, "unit": "px" }
              ],
              "nodes": {
                "hero": {
                  "style": {
                    "padding": { "value": 64, "unit": "px" },
                    "height":  { "value": 320, "unit": "px" }
                  }
                }
              },
              "style": {
                "#hero-title": {
                  "height": { "value": 56, "unit": "px" }
                }
              }
            },
            {
              "conditions": [
                { "type": "feature", "name": "orientation", "value": "landscape" }
              ],
              "nodes": {},
              "style": {}
            }
          ],
          "layout": {
            "type": "div",
            "props": {
              "id": "root",
              "style": { "overflow": "auto" }
            },
            "children": [
              {
                "type": "div",
                "props": { "id": "hero" },
                "children": [
                  {
                    "type": "p",
                    "props": {
                      "id": "hero-title",
                      "style": { "padding": { "value": 0, "unit": "px" } }
                    },
                    "children": ["The Joy of Server-Driven UI"]
                  },
                  {
                    "type": "p",
                    "props": { "id": "hero-subtitle" },
                    "children": ["One JSON, every screen."]
                  },
                  {
                    "type": "button",
                    "props": { "id": "cta", "label": "Get started", "event": "cta-tap" }
                  }
                ]
              },
              {
                "type": "div",
                "props": { "id": "stats" },
                "children": [
                  { "type": "card", "props": { "id": "stat-1", "className": ["stat"], "label": "12k stars" } },
                  { "type": "card", "props": { "id": "stat-2", "className": ["stat"], "label": "1.2M downloads" } },
                  { "type": "card", "props": { "id": "stat-3", "className": ["stat"], "label": "98% uptime" } }
                ]
              },
              {
                "type": "div",
                "props": { "id": "features" },
                "children": [
                  {
                    "type": "card",
                    "props": {
                      "id": "f-fast",
                      "className": ["feature-card"],
                      "label": "Fast — typed Style end-to-end"
                    },
                    "children": [
                      {
                        "type": "card",
                        "props": { "id": "badge", "label": "NEW" }
                      }
                    ]
                  },
                  {
                    "type": "card",
                    "props": {
                      "id": "f-typed",
                      "className": ["feature-card"],
                      "label": "Typed — no string parsing in cascade"
                    }
                  },
                  {
                    "type": "card",
                    "props": {
                      "id": "f-portable",
                      "className": ["feature-card"],
                      "label": "Portable — render anywhere"
                    }
                  }
                ]
              },
              {
                "type": "div",
                "props": { "id": "form-section" },
                "children": [
                  { "type": "p", "props": { "id": "form-title" }, "children": ["Get early access"] },
                  {
                    "type": "div",
                    "props": { "id": "form-row" },
                    "children": [
                      {
                        "type": "input",
                        "props": { "id": "name",  "placeholder": "Full name" }
                      },
                      {
                        "type": "input",
                        "props": { "id": "email", "placeholder": "Email address" }
                      }
                    ]
                  },
                  {
                    "type": "button",
                    "props": { "id": "submit", "label": "Subscribe", "event": "subscribe" }
                  }
                ]
              },
              {
                "type": "div",
                "props": { "id": "footer" },
                "children": [
                  { "type": "p", "props": { "id": "copyright" }, "children": ["© 2026 joyfill"] },
                  {
                    "type": "div",
                    "props": { "id": "footer-nav" },
                    "children": [
                      { "type": "button", "props": { "id": "nav-docs",   "className": ["nav-link"], "label": "Docs",   "event": "nav-docs"   } },
                      { "type": "button", "props": { "id": "nav-spec",   "className": ["nav-link"], "label": "Spec",   "event": "nav-spec"   } },
                      { "type": "button", "props": { "id": "nav-github", "className": ["nav-link"], "label": "GitHub", "event": "nav-github" } }
                    ]
                  }
                ]
              }
            ]
          }
        }
        """#
    )

    // MARK: - Sample 7 — Visual CSS
    // Exercises backgroundColor, opacity, border, borderRadius, margin,
    // typography (fontFamily, fontSize, fontWeight, color, lineHeight,
    // letterSpacing, textAlign, textTransform), alignSelf, minWidth/maxWidth,
    // rowGap/columnGap, display:none, h1–h4, span, and img.

    static let visualCSS = JoyDOMSample(
        id: "visual-css",
        label: "Visual CSS · typography + box model",
        json: #"""
        {
          "version": 1,
          "style": {
            "#root": {
              "flexDirection": "column",
              "gap": { "value": 0, "unit": "px" },
              "backgroundColor": "#F8F9FA"
            },
            ".section": {
              "flexDirection": "column",
              "padding": { "value": 20, "unit": "px" },
              "margin": { "value": 12, "unit": "px" },
              "backgroundColor": "#FFFFFF",
              "borderRadius": { "value": 12, "unit": "px" },
              "borderWidth": { "value": 1, "unit": "px" },
              "borderColor": "#E0E0E0",
              "borderStyle": "solid"
            },
            "h1": {
              "fontSize": { "value": 28, "unit": "px" },
              "fontWeight": 700,
              "color": "#1A1A2E",
              "letterSpacing": { "value": -0.5, "unit": "px" },
              "lineHeight": 1.2
            },
            "h2": {
              "fontSize": { "value": 20, "unit": "px" },
              "fontWeight": 600,
              "color": "#16213E",
              "lineHeight": 1.3
            },
            "h3": {
              "fontSize": { "value": 16, "unit": "px" },
              "fontWeight": 500,
              "color": "#0F3460",
              "textTransform": "uppercase",
              "letterSpacing": { "value": 1, "unit": "px" }
            },
            "p": {
              "fontSize": { "value": 14, "unit": "px" },
              "color": "#555555",
              "lineHeight": 1.6
            },
            ".badge": {
              "backgroundColor": "#E8F4FD",
              "borderRadius": { "value": 20, "unit": "px" },
              "padding": { "topLeft": null, "top": { "value": 4, "unit": "px" }, "right": { "value": 12, "unit": "px" }, "bottom": { "value": 4, "unit": "px" }, "left": { "value": 12, "unit": "px" } },
              "borderWidth": { "value": 1, "unit": "px" },
              "borderColor": "#B3D9F5",
              "borderStyle": "solid"
            },
            ".badge-text": {
              "fontSize": { "value": 12, "unit": "px" },
              "fontWeight": 600,
              "color": "#1976D2",
              "textTransform": "uppercase",
              "letterSpacing": { "value": 0.5, "unit": "px" }
            },
            ".row": {
              "flexDirection": "row",
              "flexWrap": "wrap",
              "columnGap": { "value": 12, "unit": "px" },
              "rowGap": { "value": 8, "unit": "px" }
            },
            ".card": {
              "flexDirection": "column",
              "flexGrow": 1,
              "minWidth": { "value": 120, "unit": "px" },
              "maxWidth": { "value": 200, "unit": "px" },
              "padding": { "value": 16, "unit": "px" },
              "backgroundColor": "#F0F4FF",
              "borderRadius": { "value": 8, "unit": "px" }
            },
            ".card-value": {
              "fontSize": { "value": 24, "unit": "px" },
              "fontWeight": 700,
              "color": "#3B4FE0",
              "textAlign": "center"
            },
            ".card-label": {
              "fontSize": { "value": 11, "unit": "px" },
              "color": "#888888",
              "textAlign": "center",
              "textTransform": "uppercase",
              "letterSpacing": { "value": 0.8, "unit": "px" }
            },
            ".faded": {
              "opacity": 0.4
            },
            ".hidden-node": {
              "display": "none"
            }
          },
          "breakpoints": [],
          "layout": {
            "type": "div",
            "props": { "id": "root" },
            "children": [
              {
                "type": "div",
                "props": { "id": "hero-section", "className": ["section"] },
                "children": [
                  {
                    "type": "div",
                    "props": { "id": "badge-row", "className": ["row"] },
                    "children": [
                      {
                        "type": "div",
                        "props": { "id": "badge-new", "className": ["badge"] },
                        "children": [
                          { "type": "p", "props": { "id": "badge-new-text", "className": ["badge-text"] }, "children": ["New"] }
                        ]
                      },
                      {
                        "type": "div",
                        "props": { "id": "badge-v2", "className": ["badge"] },
                        "children": [
                          { "type": "p", "props": { "id": "badge-v2-text", "className": ["badge-text"] }, "children": ["v2.0"] }
                        ]
                      }
                    ]
                  },
                  { "type": "h1", "props": { "id": "hero-title" }, "children": ["Visual CSS in JoyDOM"] },
                  { "type": "p",  "props": { "id": "hero-body" },  "children": ["This sample exercises the full visual CSS property set: borders, border radius, background colors, opacity, typography, min/max sizing, and more."] }
                ]
              },
              {
                "type": "div",
                "props": { "id": "stats-section", "className": ["section"] },
                "children": [
                  { "type": "h3", "props": { "id": "stats-label" }, "children": ["At a glance"] },
                  {
                    "type": "div",
                    "props": { "id": "stats-row", "className": ["row"] },
                    "children": [
                      {
                        "type": "div",
                        "props": { "id": "stat-a", "className": ["card"] },
                        "children": [
                          { "type": "p", "props": { "id": "stat-a-val", "className": ["card-value"] }, "children": ["28"] },
                          { "type": "p", "props": { "id": "stat-a-lbl", "className": ["card-label"] }, "children": ["CSS props"] }
                        ]
                      },
                      {
                        "type": "div",
                        "props": { "id": "stat-b", "className": ["card"] },
                        "children": [
                          { "type": "p", "props": { "id": "stat-b-val", "className": ["card-value"] }, "children": ["8"] },
                          { "type": "p", "props": { "id": "stat-b-lbl", "className": ["card-label"] }, "children": ["HTML types"] }
                        ]
                      },
                      {
                        "type": "div",
                        "props": { "id": "stat-c", "className": ["card", "faded"] },
                        "children": [
                          { "type": "p", "props": { "id": "stat-c-val", "className": ["card-value"] }, "children": ["∞"] },
                          { "type": "p", "props": { "id": "stat-c-lbl", "className": ["card-label"] }, "children": ["Possible UIs"] }
                        ]
                      }
                    ]
                  }
                ]
              },
              {
                "type": "div",
                "props": { "id": "hidden-section", "className": ["hidden-node"] },
                "children": [
                  { "type": "p", "props": { "id": "hidden-p" }, "children": ["This node is display:none — it should not be visible."] }
                ]
              },
              {
                "type": "div",
                "props": { "id": "typography-section", "className": ["section"] },
                "children": [
                  { "type": "h2", "props": { "id": "typo-title" }, "children": ["Typography scale"] },
                  { "type": "h1", "props": { "id": "typo-h1" }, "children": ["Heading 1"] },
                  { "type": "h2", "props": { "id": "typo-h2" }, "children": ["Heading 2"] },
                  { "type": "h3", "props": { "id": "typo-h3" }, "children": ["Heading 3"] },
                  { "type": "h4", "props": { "id": "typo-h4" }, "children": ["Heading 4"] },
                  { "type": "p",  "props": { "id": "typo-p" },  "children": ["Body paragraph with comfortable line-height and subdued color. Designed to be readable at 14 px on any background."] }
                ]
              }
            ]
          }
        }
        """#
    )
}
