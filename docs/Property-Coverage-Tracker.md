# Property Coverage Tracker

Live status for the per-property test-coverage walk described in [`Property-Test-Workflow.md`](Property-Test-Workflow.md).

**Status legend**

- ⬜ Not started
- 🟡 In progress
- ✅ Done — value-sweep + edge / context / interaction samples + cascade test + snapshot test
- ⚠️ Done with documented limitation — see Notes column
- 🔴 Blocker — divergence found that can't be fixed within scope (see Notes)

**Sample-count column** uses `value-sweep / edges / contexts / interactions` counts.
**Test-count column** is the delta vs. baseline (607 at start of Phase 0).

---

## Phase 0 — Infrastructure

| Item | Status | Note |
|---|---|---|
| swift-snapshot-testing dependency | ✅ | Added to Package.swift, JoyDOMTests target |
| `JoyDOMSnapshotHelpers.swift` | ✅ | `assertJoyDOMSnapshot(spec:)` + JSON overload |
| Baseline snapshot test | ✅ | `JoyDOMSnapshotBaselineTests.testBaselineSnapshot` |
| Tracker doc (this file) | ✅ | |

---

## 1. Flexbox (12 properties)

| Property | Status | Samples (sweep/edges/ctx/inter) | Tests delta | Date | Notes |
|---|---|---|---|---|---|
| `flexDirection` | ✅ | 2/5/6/9 | +33 baselines | 2026-05-12 | 21 spec + 2 iOS-ext (row/column-reverse moved to `flex-direction-ios-ext/`); surfaced 2 impl bugs (synthetic-root wrap, empty-div 10px intrinsic) + 1 sample-design patch (with-wrap alignContent) |
| `flexGrow` | ✅ | 5/5/6/4 | +20 baselines | 2026-05-13 | 19 samples + responsive-wide method; AI walk found zero impl bugs; ratio-equivalence (one/two/fractional byte-identical) proven; alignContent removed from with-wrap during scope check |
| `flexShrink` | ✅ | 5/5/7/4 | +20 baselines | 2026-05-13 | 20 samples (overview kept) + responsive-wide method; AI walk found zero impl bugs; ratio-equivalence (one/two/fractional/default byte-identical at 84/84/84) proven; CSS weighted shrink (basis × shrink) verified on with-basis (45/91/136); min-clamp + reflow verified on with-min-width (100/66/66 after re-resolving overflow on non-frozen items); wrap defeats shrink confirmed; nested.json proves shrink propagation through nested flex containers |
| `flexBasis` | ✅ | 5/4/2/4 | +20 baselines | 2026-05-13 | 19 new samples + responsive-wide method (overview.png kept); AI walk found zero impl bugs; sweep covers `0`/`auto`/`px-small`/`px-large`/`percent-50`; CSS invariants verified: `auto` resolves to declared width (auto→80px), `%` resolves against container main-axis size, `basis:0+grow:1` produces equal thirds (117.33), `basis+shrink` shrinks weighted (140→84 each), minWidth/maxWidth clamp basis pre-flex (40→80, 200→120), wrap honors basis (3×120 in 300w → 2/1 split), nested basis resolves at each level independently |
| `justifyContent` | ✅ | 7/5/4/5 | +21 baselines | 2026-05-13 | 21 samples + responsive-wide method; all 6 spec enum values (flex-start, flex-end, center, space-between, space-around, space-evenly) render at CSS-spec-predicted positions; default correctly falls back to flex-start; with-grow proves justifyContent has no effect when items consume all free space; with-wrap distributes per-line; in-column verifies main-axis flip; nested proves independent main-axis distribution at each nesting level; AI walk found zero impl bugs |
| `alignItems` | ✅ | 4/5/4/5 | +19 baselines | 2026-05-13 | 17 spec samples + 1 iOS-ext (`baseline`) + responsive-wide method; AI walk found zero impl bugs; verified cross-axis positioning for flex-start/flex-end/center/stretch in row mode (60×60 boxes in 140px-tall container) and column mode (cross axis flips to horizontal); CSS default `stretch` confirmed via default.json byte-comparison with stretch.json; alignSelf override correctly shadows container alignItems (only middle child drops to flex-end while siblings stay at flex-start) |
| `alignSelf` | ✅ | 5/4/4/5 | +20 baselines | 2026-05-13 | 18 spec samples + 1 ios-ext (`baseline`) + responsive-wide method; AI walk found zero impl bugs, 1 sample-design fix (`with-wrap` initially used equal-height items so the flex-end override collapsed onto flex-start — patched to varied heights); per-item override of container `alignItems` verified across the auto/flex-start/flex-end/center/stretch sweep and all four interaction contexts (stretch parent, flex-end parent, wrap, varied heights); responsive breakpoint flip (flex-start ↔ auto) confirmed |
| `flexWrap` | ✅ | 2/4/4/5 | +17 baselines | 2026-05-13 | 15 spec samples + 1 ios-ext (wrap-reverse) + responsive-wide method; AI walk found zero impl bugs; spec values `nowrap` (with overflow → items shrink) and `wrap` (with overflow → items reflow onto multiple lines) verified; default fallback (omitted = nowrap) confirmed byte-identical to explicit nowrap; per-line free-space distribution (`with-grow` → row1 grows to 140/140, row2 grows alone to full 288) proven; per-axis `gap` (c:16, r:24) shows row-gap honored across wrapped lines; one sample-design patch (in-column container shrunk from 320→200 so it fits 240 viewport); CSS-default `align-content: stretch` avoided by leaving container height unset so lines pack at content height |
| `gap`/`rowGap`/`columnGap` | ✅ | 4/4/4/10 | +23 baselines | 2026-05-13 | 22 samples + responsive-wide method; one tracker row covers 3 distinct CSS properties (gap, rowGap, columnGap) all exercised; AI walk found zero impl bugs; rowGap/columnGap override semantics verified (gap inherited on non-overridden axis); rowGap in column-direction = vertical main-axis spacing (writing-mode-oriented, not flex-axis-oriented); columnGap in column-direction with no wrap is no-op; gap survives justifyContent:center and flexGrow distribution |
| `order` | ✅ | 5/3/2/4 | +20 baselines | 2026-05-13 | 19 samples (overview kept) + responsive-wide method; AI walk found zero impl bugs; verified negative orders + mixed signs + large-magnitude relative ordering (1000/10/100 → 10<100<1000); same-order CSS-spec stability preserved (source order tiebreaker); ordering applies on column axis; reordering coexists cleanly with justifyContent / flexWrap / flexGrow / alignSelf without affecting sizing or cross-axis alignment |

## 2. Layout & Positioning (9 properties)

| Property | Status | Samples | Tests delta | Date | Notes |
|---|---|---|---|---|---|
| `position` | ✅ | 2/3/2/4 | +19 baselines | 2026-05-13 | 16 spec samples + 2 iOS-ext (`fixed`, `sticky` fall back to absolute with diagnostic) + responsive-wide method; AI walk found zero impl bugs; verified `absolute` removes the item from flex flow (siblings collapse the gap), insets anchor to the closest positioned ancestor (root viewport if none), nested positioned ancestor correctly takes precedence over root, `overflow:hidden` clips absolute children that extend past parent's border-box, `zIndex` orders absolute siblings, CSS default `relative` confirmed via default.json matching relative.json |
| `display` | ✅ | 3/4/4/4 | +21 baselines | 2026-05-13 | 15 spec samples (overview re-recorded) + 4 ios-ext (block/inline/inline-block/inline-flex) + responsive-wide method; AI walk found zero impl bugs; spec values `flex` (standard flex layout) and `none` (element + descendants removed from flow, zero space contribution) verified; default fallback (omitted = flex per joydom-swift; CSS spec would default by element type but joydom treats every node as flex) confirmed byte-identical to explicit `display: flex`; `display: none` on middle child collapses gap (siblings reflow with single gap, not gap-with-blank-slot); `display: none` on inner container hides container + all descendants; hidden child contributes zero space to flex-grow distribution (`with-grow` → 2 remaining children split full 400px width); hidden child contributes zero space to wrap-line calc (`with-wrap` 240px container fits all 3 visible items on one line, no wrap triggered); responsive breakpoint flip (`>=768px` hides `#b`) verified via `testDisplayResponsiveWide` |
| `boxSizing` | ✅ | 2/3/2/3 | +18 baselines | 2026-05-13 | 18 samples (overview rewritten as side-by-side comparison) + responsive-wide method; AI walk found zero impl bugs, 1 sample-design fix (`equal-outer-size` originally only equalized width, patched to also equalize height); visual proof for PR #25 — `border-box` deducts `borderWidth*2 + paddingMain*2` from FlexLayout-supplied size, while `content-box` (default when omitted) leaves outer = declared + padding + border; `equal-outer-size` proves border-box width=120 and content-box width=80 (+ padding 16 + border 4) both yield identical 120×120 outer; `width-padding-border` is the canonical numerical proof; nested.json shows deduction applies independently at every nesting level; responsive breakpoint flip (content-box ↔ border-box at width>=768px) confirmed |
| `zIndex` | ✅ | 5/3/2/3 | +19 baselines | 2026-05-13 | 18 samples + responsive-wide method; AI walk surfaced 1 impl bug (ZIDX-1: zIndex was fully ignored at paint time — cascade and FlexLayout storage were correct but no compositor hint reached SwiftUI) **fixed in the same PR** — `JoyDOMView.applyItem` now chains `.zIndex(Double(style.zIndex))` after `.flexItem(...)` so the SwiftUI compositor honors stacking order. Three baselines re-recorded (`negative.png`, `overview.png`, `responsive-wide.png`) to show CSS-correct stacking: `negative` (z:0 / z:-1) → red on top of green; `overview` (z:1 / z:3 / z:2) → green (z:3) on top, blue (z:2) middle, red (z:1) bottom; `responsive-wide` (breakpoint flips green's z:1 → z:-1) → red on top. Spec-compliant `no-position-no-effect` (in-flow flex children with no overlap render identically pre/post-fix) and `with-overflow-hidden` (zIndex doesn't escape clipping) verified. Source-order tiebreaker preserved for equal-zIndex siblings. |
| `overflow` | ✅ | 5/3/2/4 | +20 baselines | 2026-05-13 | 19 spec samples + responsive-wide method; AI walk found zero impl bugs and zero sample-design issues; spec values `visible`/`hidden`/`clip`/`scroll`/`auto` all verified against oversized children; documented limitation: `clip`/`scroll`/`auto` render byte-equivalent to `hidden` in static snapshots because `FlexOverflowModifier` maps clip→`.clipped()`, scroll→`ScrollView`+`.clipped()`, auto→`ViewThatFits` falling back to scroll — distinction is interaction-time, not paint-time; nested overflow:hidden containers clip independently (with-nested-overflow); overflow:hidden clips absolutely-positioned descendants (with-position-absolute-child); rounded-corner clipping verified (with-border-radius) |
| `top`/`left`/`bottom`/`right` | ✅ | 4/3/3/4 | +21 baselines | 2026-05-13 | 21 samples + responsive-wide method; ONE tracker row covers 4 CSS properties (top, left, bottom, right) all exercised under `layout/insets/`; AI walk surfaced 1 impl bug (FlexEngine ignored insets on `position: relative` items) **fixed in the same PR** — FlexEngine.solve now applies a paint-time offset to in-flow items when `position == .relative`, leaving the in-flow position siblings see unchanged per CSS §9.4; `position-relative-shifts.json` is the regression seam (green visually shifts +10/+20 without disturbing red/blue). Other invariants verified: absolute child anchors to nearest positioned ancestor (relative or absolute); falls through to root when no positioned ancestor exists; over-constrained `all-four` stretches a width-less/height-less child to fill the inset rectangle; negative insets escape the parent box; overflow:hidden parent clips off-canvas portion |

## 3. Box Model & Visuals (8 properties)

| Property | Status | Samples | Tests delta | Date | Notes |
|---|---|---|---|---|---|
| `backgroundColor` | ✅ | 5/3/2/5 | +18 baselines | 2026-05-14 | 17 samples + responsive-wide method; AI walk surfaced 1 impl bug (CSS 3-digit / 4-digit hex shorthand silently rendered transparent because `Color(hex:)` only handled count==6/8) **fixed in the same PR** — `ColorHelpers.swift` now expands `#RGB`/`#RGBA` per CSS Color L4 §4.2 (nibble doubled); `short-hex.png` re-recorded post-fix to lock red/green/blue rendering. Other invariants verified: 8-digit alpha (`#3B82F680` = 50% blend), CSS default = transparent (`default.json` middle box → gray root shows through), `#root` background paints behind children, nested backgrounds stack independently at every nesting level (`nested-bg-on-bg`: gray → blue panel → red/amber), background fills inside border-box (`with-border`: 6px solid black border, blue inside), borderRadius clips background to rounded shape (`with-border-radius`: 0/12/40 radii), `opacity` multiplies into rendered background (`with-opacity`: 1.0/0.5/0.2), background fills grown flex widths (`with-flex-grow`: red/green-2x/blue), responsive breakpoint flip (red ↔ blue at width>=768px). |
| `opacity` | ✅ | 6/3/2/3 | +19 baselines | 2026-05-14 | 18 samples + responsive-wide method; AI walk found zero impl bugs and zero sample-design issues; value sweep 0/0.25/0.5/0.75/1 verified visually (color intensity scales linearly with opacity over gray bg); default (omitted) renders byte-identical to `opacity: 1` per CSS spec fallback; `overlap-stacking` proves CSS alpha-blend (opaque red beneath opacity-0.5 blue → purple in overlap region); opacity on parent container (`single-child`, `on-nested-container`) visually fades the whole subtree as a group (CSS group-opacity semantics); opacity affects fill + border + text uniformly (`with-border`, `on-text-content`); opacity does not affect layout (`with-flex-grow` items keep equal flex-grow widths regardless of opacity); responsive breakpoint flip (0.25 below 768px → 1.0 at ≥768px) verified via `testOpacityResponsiveWide` |
| `padding` | ✅ | 4/3/2/6 | +23 baselines | 2026-05-14 | 23 samples (overview rewritten as side-by-side uniform vs per-side showcase) + responsive-wide; AI walk found zero impl bugs, zero sample-design issues — 25/25 ✅ match on first record. Coverage: uniform `Length` sweep (0/4/16/32), per-side object form (top/right/bottom/left-only + vertical-horizontal + all-different), defaults (verifies 0), edges (empty, single-child, large-padding-narrow-container which correctly collapses content area to 0 inside a 100×200 border-box with 60px padding each side), authoring parity (inline vs class-selector byte-equivalent), boxSizing interaction (with-content-box: declared 100×60 + padding 16 → outer 132×92; with-border-box: declared 132×92 + padding 16 → same outer 132×92 with content 100×60 — verifies border-box deduction), visual layering (with-background-color paints bg under padding; with-border puts padding inside the 4px border edge; with-flex-children shrinks main-axis grow distribution by 2×20=40px), nested.json (parity vs flex-shrink + box-sizing walks), responsive 8 → 32 breakpoint flip at width≥768px |
| `margin` | ✅ | 4/4/6/7 | +26 baselines | 2026-05-14 | 25 samples + responsive-wide method; AI walk found zero impl bugs; uniform Length and per-side object forms verified; per-side sweep (top/right/bottom/left-only) + asymmetric combinations; `flex-margin-proof.json` delivers visual evidence for PR #21 (margin participates in flex layout as true flex-item spacing, not just outer wrapping); margin + gap stack additively; negative margins shift INWARD overlapping siblings; grow distributes free space after accounting for margins; resolves tracker note "PR #21 true flex margin needs visual proof" |
| `borderWidth` | ⚠️ | 8/3/2/4 | +18 baselines | 2026-05-14 | 17 samples + responsive-wide method; AI walk found zero impl bugs in borderWidth itself; value sweep 0/1/4/12px renders cleanly; content-box (default) adds border to outer (120→136 at 8px each side), border-box deducts it (outer 120 stays 120, inner area shrinks); responsive flips 1px→10px above 768. **Documented limitation:** `no-color-no-render.json` proves that when `borderColor` is omitted, joydom-swift renders no border AND reserves zero space for it (boxes stay 60×60 — content area uneaten). CSS spec defaults borderColor to currentColor; producers must set borderColor explicitly to materialize a border. Out-of-scope side-finding: `with-border-radius.json` blue box (radius 40 on 80px → circle) shows the underlying square's corners poking past the border curve as black stubs — surfaced for the future borderRadius walk, not a borderWidth bug. |
| `borderColor` | ✅ | 4/3/2/3 | +18 baselines | 2026-05-14 | 16 samples + responsive-wide method; AI walk found zero impl bugs; hex sweep (red/green/blue/black) verified; default behavior documented; `same-as-background` proves border becomes invisible against same-color background; thin (1px) and thick borders render correctly; border + borderRadius combination produces curved border; recovered from a walker that hit an API error mid-Step 3 (samples + manifest were authored but uncommitted) |
| `borderStyle` | ✅ | 2/3/2/2 | +18 baselines | 2026-05-14 | 14 spec + 3 iOS-ext (`dashed`, `dotted`, `double`) + responsive-wide method; AI walk found zero impl bugs; spec values `solid` and `none` verified; `none-overrides-width` proves zero-width border even with borderWidth set; iOS-ext dashed/dotted/double render without crash (visual distinction from solid varies by SwiftUI version); resolved the tracker note "Ext dashed/dotted/double have no render tests" |
| `borderRadius` | ✅ | 12/3/4/3 | +23 baselines | 2026-05-14 | 22 spec samples + responsive-wide method; AI walk found zero impl bugs and zero sample-design issues. Value-sweep (zero/small/medium/large/pill) verifies progressive corner rounding; per-corner samples (top-left-only/top-right-only/bottom-right-only/bottom-left-only) verify each corner of the `{ topLeft, topRight, bottomRight, bottomLeft }` object form independently; asymmetric samples (top-corners-only, diagonal) verify multi-corner combinations; circle (50px on 80×80 → no, on 100×100 with r=50) renders as perfect circle; radius-larger-than-half (r=200 on 80×80) clamps to ellipse via SwiftUI `RoundedRectangle`'s native min(width,height)/2 clamp — matches CSS spec UA clamping; interactions verify background clips to corners (with-background-color), borders curve along radius (with-border), and overflow:hidden clips children to rounded corners (with-overflow-hidden); responsive breakpoint flips 4px → 32px. |

## 4. Sizing (3 properties)

| Property | Status | Samples | Tests delta | Date | Notes |
|---|---|---|---|---|---|
| `width` | ✅ | 7/5/4/5 | +23 baselines | 2026-05-14 | 22 samples (overview rewritten) + responsive-wide method; AI walk found zero impl bugs; value sweep covers `0px`/`60px`/`160px`/`300px`/`50%`/`100%`/omitted-auto; CSS invariants verified: percent resolves against the parent's content area (50% of 368 inner → 184px), 100% fills inner area, omitted width defers to flexBasis (auto.json) or collapses empty children to 0 (default.json); flexBasis wins over declared width (`with-flex-basis` renders at 160 not 80); flexGrow expands beyond declared width when free space remains (`with-flex-grow` 60→117); minWidth clamps up (40→100), maxWidth clamps down (200→80); `width-larger-than-container` confirms flex item overflows past container right edge with flexShrink:0; nested.json verifies percent widths resolve at each level independently against that level's inner content area; responsive breakpoint flip (200px ↔ 100%) confirmed via `testWidthResponsiveWide` |
| `height` | ⚠️ | 7/3/2/4 | +21 baselines | 2026-05-14 | 20 spec samples + responsive-wide method (21 baselines); AI walk found zero impl bugs; px sweep (8/60/160/300) verified; `percent-50` and `percent-100` resolve against parent's padded inner content area (FlexLayout convention: 50% of 240-px-tall padded parent = ~104, 100% = ~208); `default` (omitted) and `auto`-equivalent absence both fall back to content-sized; column-direction confirms height is main-axis (`in-flex-column`, `with-flex-basis`, `with-flex-grow`); `with-min-height` clamps 30→100 upward, `with-max-height` clamps 240→120 downward; responsive breakpoint flip (80↔200) confirmed. **Documented limitation:** percent height of an unsized parent (`percent-of-unsized-parent.json`) does NOT collapse to 0 as CSS spec dictates — FlexLayout resolves against the parent's intrinsic content height (here ~120 = tallest sibling), so green renders ~80px instead of 0. Intrinsic to the FlexLayout primitive, not a JoyDOM-specific defect. |
| `min`/`maxWidth` & `min`/`maxHeight` | ✅ | 5/3/2/5 + 4 per-property + 2 responsive | +23 baselines | 2026-05-14 | 22 samples covering all 4 properties (minWidth/maxWidth/minHeight/maxHeight) under combined `sizing/min-max/`; AI walk found zero impl bugs; verified CSS clamp invariants — declared < min clamps up, declared > max clamps down, `min-larger-than-max` proves CSS "min wins over max", `with-flex-grow-and-max` and `with-flex-shrink-and-min` verify the freeze-and-re-resolve algorithm for flex interactions (mirrors flexShrink/with-min-width 100/66/66 result); percent width resolves before min clamp; border-box clamps the outer box; responsive breakpoint flips minWidth 60→200 |

## 5. Typography (10 properties)

| Property | Status | Samples | Tests delta | Date | Notes |
|---|---|---|---|---|---|
| `fontFamily` | ⬜ | 1/0/0/0 | — | — | — |
| `fontSize` | ✅ | 8/3/2/5 + responsive | +22 baselines | 2026-05-14 | 21 spec samples + responsive-wide method (22 baselines); value sweep 8/12/14/16/18/24/36/64 px; `default` (omitted) renders identically to `px-16`, confirming the CSS 16px spec default; edges (`very-small` 1px, `very-large` 96px, `single-character` 48px) render at expected scales; both authoring styles (`inline-style` via `node.props.style`, `class-selector` via `.large`) cascade correctly; cross-property interactions verified — `with-line-height` (1.6 multiplier wraps to 3 lines visibly spaced), `with-font-weight` (700 visibly bolder), `with-font-family` (Georgia serif), `with-color` (#0066CC blue), `in-flex-container` (12/20/32 px baselines align in a row flex container); responsive breakpoint flip 14px→32px at width≥768px verified via `testFontSizeResponsiveWide`; allowlist grep clean (`fontSize: Length<"px">` only); AI walk found zero impl bugs. |
| `fontWeight` | ⬜ | 1/0/0/0 | — | — | CSS Fonts L4 band mapping |
| `fontStyle` | ✅ | 4/3/3/3 | +14 | 2026-05-14 | Zero impl bugs. SwiftUI `.italic()` correctly applied; cascades into nested `<span>`; bold-italic and family×italic combinations all distinct. |
| `color` | ✅ | 5/3/3/8 | +21 baselines | 2026-05-14 | 20 samples + responsive-wide method; AI walk found zero impl bugs and zero sample-design issues. Value sweep verified: 3-digit hex (`short-hex`), 6-digit hex (`long-hex`, `overview`), 8-digit hex alpha (`hex-with-alpha`: FF/80/33 progressive transparency), 4-digit hex alpha (`short-hex-with-alpha`). Defaults: `default.json` confirms middle paragraph (no color declared) renders in CSS UA black while explicit-color siblings keep declared red/blue — no surprise transparent text. Inheritance: `inheritance.json` verifies color set on `#root` cascades to all `<p>` descendants; `nested-override.json` verifies #id specificity beats inherited declaration (blue/red/blue); `nested.json` verifies cascade through a nested `<div>` container into deeper text. Authoring parity verified across inline / class-selector / tag-selector (all three render byte-identical to overview-style declarations). Cross-property combos: `with-background-color` proves white-on-colored backgrounds render cleanly (color × backgroundColor); `with-opacity` shows red text fading at 1.0/0.5/0.2 (color × opacity); `with-border-color` proves matching text + border colors (color × borderColor); `with-font-size` proves color renders uniformly across 12/18/28px sizes; `contrast-pair` validates extremes (white-on-#111827, #111827-on-#F9FAFB). Responsive flip red→blue at width≥768px verified via `testColorResponsiveWide`. |
| `textDecoration` | ⬜ | 1/0/0/0 | — | — | Env cascade to Text descendants |
| `textAlign` | ⬜ | 1/0/0/0 | — | — | — |
| `textTransform` | ⬜ | 1/0/0/0 | — | — | — |
| `lineHeight` | ✅ | 6/4/2/7 | +21 | 2026-05-14 | system-leading subtraction confirmed correct (UIKit `UIFont.lineHeight` / AppKit ascender-descender-leading); `lineHeight 1.0` and ``< 1.0`` clamp lineSpacing to 0; verified via `system-leading-verify.json` (visible gap ratios match `1.5 → ~6px` / `2.0 → ~16px` at fontSize 20). Zero impl bugs. |
| `letterSpacing` | ⬜ | 1/0/0/0 | — | — | ⚠️ em scaling caveat |

## 6. Text Behavior (2 properties)

| Property | Status | Samples | Tests delta | Date | Notes |
|---|---|---|---|---|---|
| `textOverflow` | ⬜ | 1/0/0/0 | — | — | ⚠️ Requires 4 TextStyles.md preconditions |
| `whiteSpace` | ⬜ | 1/0/0/0 | — | — | — |

## 7. Media (2 properties)

| Property | Status | Samples | Tests delta | Date | Notes |
|---|---|---|---|---|---|
| `objectFit` | ⬜ | 1/0/0/0 | — | — | nil → fill (CSS spec default) |
| `objectPosition` | ⬜ | 1/0/0/0 | — | — | ⚠️ contain/none alignment limitation |

## 8. Selectors (8 capabilities)

| Capability | Status | Samples | Tests delta | Date | Notes |
|---|---|---|---|---|---|
| `type` | ⬜ | 1/0/0/0 | — | — | — |
| `.class` | ⬜ | 1/0/0/0 | — | — | — |
| `#id` | ⬜ | 1/0/0/0 | — | — | — |
| Compound (`div.foo#bar`) | ⬜ | 1/0/0/0 | — | — | — |
| Descendant (` `) | ⬜ | 0/0/0/0 | — | — | Spec extension |
| Child (`>`) | ⬜ | 0/0/0/0 | — | — | Spec extension |
| Adjacent sibling (`+`) | ⬜ | 0/0/0/0 | — | — | Spec extension |
| General sibling (`~`) | ⬜ | 0/0/0/0 | — | — | Spec extension |

## 9. Cascade (3 capabilities)

| Capability | Status | Samples | Tests delta | Date | Notes |
|---|---|---|---|---|---|
| Document → Breakpoint → Inline | ⬜ | 1/0/0/0 | — | — | — |
| Specificity (id > class > type) | ⬜ | 1/0/0/0 | — | — | — |
| Multi-class source order | ⬜ | 1/0/0/0 | — | — | — |

## 10. Breakpoints (11 capabilities)

| Capability | Status | Samples | Tests delta | Date | Notes |
|---|---|---|---|---|---|
| `width` feature | ⬜ | 1/0/0/0 | — | — | — |
| `orientation` | ⬜ | 1/0/0/0 | — | — | Demo needs toggle |
| `type: print` | ⬜ | 1/0/0/0 | — | — | Demo needs toggle |
| Logical `and` | ⬜ | 1/0/0/0 | — | — | — |
| Logical `or` | ⬜ | 1/0/0/0 | — | — | — |
| Logical `not` | ⬜ | 1/0/0/0 | — | — | — |
| Per-node overrides | ⬜ | 1/0/0/0 | — | — | — |
| Deep merge | ⬜ | 1/0/0/0 | — | — | — |
| Custom order | ⬜ | 1/0/0/0 | — | — | — |
| Custom visibility | ⬜ | 1/0/0/0 | — | — | — |
| className swap | ⬜ | 1/0/0/0 | — | — | — |

## 11. Patterns (2 patterns)

| Pattern | Status | Samples | Tests delta | Date | Notes |
|---|---|---|---|---|---|
| `BackgroundImages.md` wrapper | ⬜ | 1/0/0/0 | — | — | — |
| `TextStyles.md` ellipsis preconditions | ⬜ | 0/0/0/0 | — | — | — |

---

## Bugs surfaced during the walk

| ID | Property | Reproducer sample | Expected vs actual | Status |
|---|---|---|---|---|

## Documented limitations

| Property | Limitation | Why deferred | Tracking |
|---|---|---|---|
| `overflow` | `clip`, `scroll`, and `auto` render byte-identical to `hidden` in static UI snapshots | `FlexOverflowModifier` maps `clip`→`.clipped()`, `scroll`→`ScrollView(...)` + `.clipped()`, `auto`→`ViewThatFits` falling back to a `ScrollView` + `.clipped()` — all three end up clipped at the same container rect when content overflows and no scrollbars/gestures are exercised. The distinction is interaction-time (scrollability), not paint-time. | overflow coverage walk (this PR) |
| `borderWidth` | When `borderColor` is omitted, no border renders AND no space is reserved for it — content area stays full size as if `borderWidth: 0`. CSS spec defaults the omitted `borderColor` to `currentColor` (text color), but joydom-swift treats the absence as "do nothing." | `JoyDOMView.applyItem` applies `.overlay { RoundedRectangle.stroke(borderColor, lineWidth: borderWidth) }` only when borderColor is set; the FlexLayout primitive likewise only counts border in box-sizing math when there's a stroke to render. Bringing this to spec would require synthesizing currentColor at apply-time, which lives in a different layer than the borderWidth pipeline. Producers should always declare `borderColor` alongside `borderWidth`. | reproduced by `boxmodel/border-width/no-color-no-render.json`; surfaced during this PR's walk |
| `height` | Percent height of a parent with no fixed height does NOT collapse to 0 as CSS spec dictates — FlexLayout resolves it against the parent's intrinsic main/cross-axis content height instead. Regression seam: `sizing/height/percent-of-unsized-parent.json` (green's `height: 50%` renders ~80px instead of 0, against an unsized row parent whose intrinsic cross-axis content is the tallest sibling = 120). | The percent-resolution chain lives in FlexLayout's containing-block computation (third-party primitive). Bringing it to CSS-spec compliance would require either intercepting in JoyDOM's resolver to detect "unsized parent" cases and downgrade percents to 0/auto (with its own subtle compatibility cost vs JS/Kotlin runtimes that may also rely on FlexLayout-style resolution) or forking the primitive. Intrinsic to the platform's containing-block model, not a contained JoyDOM defect. | height coverage walk (PR #64) |
