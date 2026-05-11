# JoyDOM — iOS (SwiftUI / FlexLayout) vs. Kotlin (Compose / FlexBox)

Side-by-side coverage comparison. Anchored to the canonical [`j0yhq/joy-dom`](https://github.com/j0yhq/joy-dom) spec at commit `765acfda` (2026-05-06). Kotlin status taken from the attached `progress.md`. iOS status taken from `docs/Spec-Property-Reference.md`.

**Status legend**

- ✅ Fully implemented
- ⚠️ Implemented with documented caveat
- ❌ Parsed but not rendered, or not modeled
- ⚠️ ext — JoyDOM-specific extension beyond the canonical spec

---

## TL;DR

| Dimension | iOS | Kotlin | Note |
|---|---|---|---|
| Spec-sanctioned Style fields shipped | 48 / 48 ✅ | 48 / 48 ✅ | Both parse 100% |
| Spec-sanctioned fields rendered | 48 (5 with caveats) | ~38 (10 ❌ or ⚠️) | iOS renders considerably more end-to-end |
| Spec extensions implemented | ~10 (row-reverse, baseline, alignContent, dashed/dotted/double, fixed/sticky, inline-flex) | 1 (`display: none`) | iOS extends well past spec; Kotlin sticks closer |
| Critical layout-correctness bugs | 1 documented (`objectFit:none` + `objectPosition`) | 1 documented (`flex row` + `wrap` doesn't remeasure) | Different gaps; neither blocking common cases |

**Where iOS is ahead** (Kotlin should catch up): `boxSizing`, `margin`, `right`/`bottom` insets, `overflow:scroll/auto`, `textTransform`, `textOverflow`, `whiteSpace`, `flex row + wrap`, `objectFit` default value.

**Where Kotlin is ahead**: nothing structural — Kotlin parses everything but renders less; iOS lags only on minor color-parser and custom-fontFamily breadth (both platforms have the same limits there).

**Where both share the same gap**: color parsing (hex-only on both), custom `fontFamily` resolution, `!important`, multiple simultaneous active breakpoints, no pseudo-classes/attribute selectors.

---

## 1. Layout & Positioning

| Property | iOS | Kotlin | Comparison |
|---|---|---|---|
| `position` | ✅ both `absolute` and `relative` honor all four insets via FlexLayout | ⚠️ `absolute` only fills when all 4 insets are `0`; partial offsets only honor `top`/`left` | **iOS ahead** — Kotlin can't anchor to right/bottom yet |
| `display: flex` | ✅ default container | ✅ default container | parity |
| `display: none` | ✅ ext + diagnostic-free | ✅ ext (`Display.NONE` skips subtree) | parity |
| `display: block / inline / inline-block / inline-flex` | ⚠️ ext (block/inline/inline-block work; inline-flex degrades to flex with diagnostic) | ❌ not modeled | **iOS ahead** |
| `boxSizing: border-box` | ✅ deducts border + padding from declared width/height (PR #25) + emits diagnostic on `%` width | ❌ parsed but never applied — always content-box | **iOS ahead** — significant |
| `zIndex` | ✅ | ✅ | parity |
| `overflow: visible` | ✅ no-op (default) | ⚠️ no-op (default) | parity |
| `overflow: hidden / clip` | ✅ via clip | ✅ via `clipToBounds` | parity |
| `overflow: scroll / auto` | ✅ via FlexLayout's scrollable container | ❌ not wired to a scroll container | **iOS ahead** |
| `top` / `left` (absolute) | ✅ | ✅ | parity |
| `right` / `bottom` (absolute) | ✅ honored via FlexLayout | ❌ parsed but ignored unless all four are `0` | **iOS ahead** |

---

## 2. Sizing

| Property | iOS | Kotlin | Comparison |
|---|---|---|---|
| `width` (px / %) | ✅ | ✅ `fillMaxWidth(fraction)` | parity |
| `height` (px / %) | ✅ | ✅ symmetric | parity |
| `minWidth` / `maxWidth` | ✅ — clamps participate in flex `§9.7` redistribution | ✅ via `widthIn(min, max)` | functional parity (iOS clamping is more spec-correct in flex containers per CSS Box Sizing §10.4) |
| `minHeight` / `maxHeight` | ✅ same as min/maxWidth | ✅ via `heightIn(min, max)` | parity |

---

## 3. Flexbox

| Property | iOS | Kotlin | Comparison |
|---|---|---|---|
| `flexDirection: row / column` | ✅ | ✅ | parity |
| `flexDirection: row-reverse / column-reverse` | ✅ ext | ❌ not modeled | **iOS ahead** (joydom-swift extension) |
| `flexGrow` / `flexShrink` | ✅ multi-pass `§9.7` freeze-and-redistribute (PR #21) | ✅ via `FlexBoxScope.flex` | parity (iOS implementation is closer to CSS spec for clamp-redistribution) |
| `flexBasis` | ✅ `auto` and `Length` (px/%) | ✅ `Auto` and `Sized` (px/%) | parity |
| `justifyContent` (6 values) | ✅ | ✅ | parity |
| `alignItems: flex-start/end/center/stretch` | ✅ | ✅ (`STRETCH` falls back to `Start` outside FlexBox) | iOS slightly ahead — STRETCH works everywhere |
| `alignItems: baseline` | ✅ ext | ❌ not modeled | **iOS ahead** (extension) |
| `alignSelf` (5 values + auto) | ✅ + ext baseline | ✅ | iOS ahead (extension) |
| `flexWrap: nowrap / wrap` | ✅ both work end-to-end including row-wrap with content-sized children | ⚠️ **row + wrap doesn't remeasure** — children keep first-line widths even after wrapping (documented as the largest layout gap) | **iOS ahead — significant** |
| `flexWrap: wrap-reverse` | ✅ ext | ❌ not modeled | **iOS ahead** (extension) |
| `gap` / `rowGap` / `columnGap` | ✅ | ✅ | parity |
| `order` | ✅ | ✅ | parity |
| `alignContent` (joydom-swift ext, 7 values) | ✅ ext | ❌ not in either spec or impl | **iOS-only extension** |

---

## 4. Box Model & Visuals

| Property | iOS | Kotlin | Comparison |
|---|---|---|---|
| `backgroundColor` | ⚠️ `#hex` only; rgb/hsl/named dropped silently | ⚠️ `#RRGGBB`, `#AARRGGBB`, three named (white/black/transparent); other named + rgb/hsl dropped | similar — both gap, Kotlin slightly more permissive on alpha hex |
| `opacity` | ✅ | ✅ | parity |
| `padding` (uniform + per-side) | ✅ | ✅ | parity |
| `margin` (uniform + per-side) | ✅ **true flex-item margin** moved into `ItemStyle` (PR #21); FlexLayout subtracts margin from available space and offsets children | ⚠️ aliased to `Modifier.padding` — pushes element inward instead of pushing siblings outward; visually correct only with no siblings | **iOS ahead — significant** |
| `borderWidth` | ✅ | ✅ | parity |
| `borderColor` | ⚠️ `#hex` only | ⚠️ same parser caveats as backgroundColor | parity |
| `borderStyle: solid / none` | ✅ | ✅ | parity |
| `borderStyle: dashed / dotted / double` | ✅ ext via `StrokeStyle` builders | ❌ not modeled | **iOS ahead** (extension) |
| `borderRadius` (uniform + per-corner) | ✅ uses `UnevenRoundedRectangle` for per-corner | ✅ uses `RoundedCornerShape` | parity |

---

## 5. Typography

| Property | iOS | Kotlin | Comparison |
|---|---|---|---|
| `fontFamily` | ⚠️ `Font.custom(...)` accepted; no test confirming custom-font loading actually resolves | ⚠️ only 4 generic families resolve (`sans-serif`/`serif`/`monospace`/`cursive`); custom names fall back | both gap; iOS plumbing is more permissive |
| `fontSize` | ✅ | ✅ 1:1 to `sp` | parity |
| `fontWeight` (`normal` / `bold` / 100..900) | ✅ uses CSS Fonts Module Level 4 band mapping (149→ultraLight, 449→regular, etc.) | ✅ enforces multiples of 100 in model | both correct, different validation styles |
| `fontStyle: normal / italic` | ✅ | ✅ | parity |
| `color` | ⚠️ `#hex` only | ⚠️ same as `backgroundColor` | parity |
| `textDecoration: underline / line-through` | ✅ via custom `EnvironmentKey` cascade so it reaches Text descendants through container boundaries | ✅ | parity |
| `textAlign` | ✅ via `.multilineTextAlignment` | ✅ via `TextStyle.textAlign` + forced `fillMaxWidth` so alignment is observable | parity |
| `textTransform: uppercase / lowercase` | ✅ via SwiftUI `.textCase` environment | ❌ parsed but never applied | **iOS ahead** |
| `lineHeight` (CSS multiplier) | ⚠️ multiplier × fontSize − system natural line height; uses `UIFont.lineHeight` on iOS, `ascender−descender+leading` on macOS | ⚠️ multiplier × fontSize → sp; requires fontSize to be set | both have caveats; iOS subtracts the system leading so the rendered result is closer to CSS intent |
| `letterSpacing` | ✅ scales by font size for em-style values, passes px values absolute (PR #20) | ✅ mapped to sp | iOS has CSS-em semantics; Kotlin treats input as absolute |

---

## 6. Text Behavior

| Property | iOS | Kotlin | Comparison |
|---|---|---|---|
| `textOverflow: clip / ellipsis` | ⚠️ rendered via `.truncationMode(.tail)` for ellipsis; needs the four `TextStyles.md` preconditions to fire visibly | ❌ parsed but no rendering path | **iOS ahead** |
| `whiteSpace: normal / nowrap` | ✅ `nowrap` applies `.lineLimit(1)` | ❌ parsed but not honored | **iOS ahead** |

---

## 7. Media (`<img>`)

| Property | iOS | Kotlin | Comparison |
|---|---|---|---|
| `objectFit: fill / contain / cover / none` | ✅ via SwiftUI `.resizable()` + `.aspectRatio(contentMode:)`; nil maps to CSS spec default `fill` | ⚠️ `Default when omitted is Fit` — diverges from CSS spec which defaults to `fill` | **iOS more spec-correct** on default value |
| `objectPosition` (3×3 grid) | ⚠️ all 9 alignments cover correctly; **`objectFit:none` + `contain` with non-default position anchors at SwiftUI default rather than spec center — documented limitation** | ✅ all 9 alignments, default Center | Kotlin doesn't have iOS's documented alignment limitation, but iOS's `cover`/`fill` paths are spec-correct on default-fit |
| Default img sizing when no width/height declared | renders intrinsic; CSS-canonical authoring requires `width:100%/height:100%` on img | ✅ same | parity |

---

## 8. Selectors

| Capability | iOS | Kotlin | Comparison |
|---|---|---|---|
| Tag (`div`) | ✅ | ✅ | parity |
| Class (`.foo`) | ✅ multi-class supported | ✅ multi-class supported | parity |
| Id (`#main`) | ✅ | ✅ | parity |
| Compound (`div.foo#bar`) | ✅ | ✅ | parity |
| Selector list (`h1, h2`) | ✅ | ✅ | parity |
| Descendant (` `) | ✅ ext | ✅ ext | parity (both extend past spec) |
| Child (`>`) | ✅ ext | ✅ ext | parity |
| Adjacent sibling (`+`) | ✅ ext | ✅ ext | parity |
| General sibling (`~`) | ✅ ext | ✅ ext | parity |
| Pseudo-classes | ❌ not in spec | ❌ not in spec | parity |
| Attribute selectors | ❌ not in spec | ❌ not in spec | parity |

Both implementations ship the same selector engine — richer than what the spec sanctions but identical between platforms.

---

## 9. Cascade

| Capability | iOS | Kotlin | Comparison |
|---|---|---|---|
| Specificity (id > class > type) | ✅ | ✅ | parity |
| Source order tiebreak | ✅ | ✅ | parity |
| Inline `style` last | ✅ | ✅ | parity |
| Field-by-field merge | ✅ | ✅ | parity |
| `!important` | ❌ not in spec | ❌ not in spec | parity |

---

## 10. Breakpoints

| Capability | iOS | Kotlin | Comparison |
|---|---|---|---|
| `width` feature with `<`, `<=`, `>`, `>=` | ✅ px only | ✅ px only | parity |
| `orientation: landscape / portrait` | ✅ (no demo toggle yet) | ✅ | parity |
| `type: print` | ✅ (no demo toggle yet) | ✅ | parity |
| Logical `and` / `or` / `not` | ✅ | ✅ | parity |
| Multiple matching → most specific wins | ✅ | ✅ | parity |
| Source-order tiebreak | ✅ | ✅ | parity |
| Per-class `style` overrides (deep-merge) | ✅ | ✅ | parity |
| Per-id `nodes` overrides | ✅ | ✅ | parity |
| Restore-original via omission of override | ✅ | ✅ | parity |
| `display:none` per-breakpoint visibility | ✅ + sample | ✅ | parity |
| `order` per-breakpoint | ✅ + sample | ✅ | parity |
| Multiple breakpoints active simultaneously | ❌ by design (one wins) | ❌ by design (`activeOrNull`) | parity |

---

## 11. Node tags

| Tag | iOS | Kotlin | Note |
|---|---|---|---|
| `div` | passthrough → FlexLayout | `FlexBox` (or `Box` when `position:relative` to host absolute children) | parity |
| `span` | passthrough | `Column` with text styling | parity |
| `p` | passthrough | `Column` with text styling | parity |
| `h1`–`h6` | passthrough; typography cascades via env | `Column` wrapped in heading `TextStyle` | parity (iOS relies on CSS for size/weight; Kotlin bakes defaults) |
| `img` | `_DOMImage` (AsyncImage + objectFit/position env reader) | `coil3.AsyncImage` + objectFit/position | parity |
| Custom tag | `ComponentRegistry` factory | `customNodes` map passed to `ComposeJoyDom` | parity |

---

## Critical-bug differences

| Bug | iOS | Kotlin |
|---|---|---|
| `flex row` + `flexWrap: wrap` doesn't remeasure children for second line | ✅ works (FlexLayout passes through measure on each line) | ⚠️ documented largest gap — children keep first-line widths |
| `objectFit: none` + non-default `objectPosition` anchors at top-leading instead of spec-default center | ⚠️ documented limitation; SwiftUI alignment quirk for oversized inner content | ✅ all 9 alignments work correctly |

These are the only documented "won't render correctly" bugs in either codebase. Each is platform-specific.

---

## Open gaps prioritized — joint follow-up list

Items where one platform should catch up to the other:

### Kotlin should catch up to iOS

1. **`flex row` + `wrap` remeasure** — biggest layout-correctness gap on Kotlin; iOS handles it.
2. **`boxSizing: border-box` layout deduction** — iOS deducts; Kotlin treats as content-box.
3. **`margin` semantics** — iOS has true flex-item margin; Kotlin aliases to padding.
4. **`right` / `bottom` insets for `position: absolute`** — iOS honors all four; Kotlin only `top`/`left`.
5. **`overflow: scroll` / `auto`** — iOS wires via FlexLayout's scrollable container; Kotlin not wired.
6. **`textTransform`, `textOverflow`, `whiteSpace`** — iOS renders all three; Kotlin parses but ignores.
7. **`objectFit` default value** — iOS defaults to `fill` per CSS spec; Kotlin defaults to `Fit` (= `contain`), which means a default `<img>` payload renders differently between platforms.

### iOS should catch up to Kotlin

1. **`objectFit: none` + non-default `objectPosition` alignment** — Kotlin's all-9 grid works; iOS hits a SwiftUI alignment quirk for oversized inner content under `contain`/`none` and falls through to default position.

### Common gaps both platforms share

1. **Color parsing** — both accept `#hex` only (Kotlin slightly more permissive: `#AARRGGBB` + 3 named colors). Add the named CSS palette and `rgb()`/`rgba()`/`hsl()` on both.
2. **Custom `fontFamily`** — both have generic-family resolution but custom names fall through (Kotlin documented; iOS untested).
3. **`!important`** — not in spec, not implemented either side.
4. **Multiple simultaneous active breakpoints** — by design on both: one wins. If the spec ever opens this, both need work.
5. **Pseudo-classes (`:hover`, `:nth-child`)** — not in spec, not parsed by either.

### iOS extensions Kotlin doesn't have

These are spec extensions iOS ships that Kotlin would need to add for full parity (or that joydom-swift could remove for stricter spec compliance):

- `flex-direction: row-reverse / column-reverse`
- `flex-wrap: wrap-reverse`
- `align-items: baseline` / `align-self: baseline`
- `align-content` (whole field)
- `border-style: dashed / dotted / double`
- `position: fixed / sticky` (with diagnostic, mapped to absolute)
- `display: block / inline / inline-block / inline-flex`

---

## Recommendations

For Kotlin maintainers:
- Top three to land for end-to-end render parity: **`flex row+wrap` remeasure**, **`boxSizing` enforcement**, **true flex-item `margin`**. Each is a single-area fix; together they close the biggest visible behavioural gaps.
- Three cheap wins (each ~15–30 LoC + a test): **`textTransform`**, **`textOverflow`**, **`whiteSpace`** — all parsed already, just need to wire into `Text`/`AnnotatedString`.
- One spec-correctness change: switch the **`objectFit` default** from `Fit` to `FillBounds` so a default `<img>` matches CSS.

For iOS maintainers:
- The single divergence in our favour-to-fix is the **`objectFit:none` alignment** quirk under contain/none with oversized intrinsic content. Tracked; needs hosted snapshot tests to reproduce the SwiftUI layout cycle in isolation.
- Consider whether the spec extensions we ship (row-reverse, baseline, alignContent, dashed/dotted/double, fixed/sticky, inline-flex) should be (a) proposed upstream to `j0yhq/joy-dom`, (b) gated behind a `JoyDOMOptions.allowSpecExtensions` flag, or (c) kept as silent supersets. Currently they're implicit supersets; making the divergence explicit would help cross-platform payload portability.
