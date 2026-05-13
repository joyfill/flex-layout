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
<<<<<<< HEAD
| `position` | ✅ | 2/3/2/4 | +19 baselines | 2026-05-13 | 16 spec samples + 2 iOS-ext (`fixed`, `sticky` fall back to absolute with diagnostic) + responsive-wide method; AI walk found zero impl bugs; verified `absolute` removes the item from flex flow (siblings collapse the gap), insets anchor to the closest positioned ancestor (root viewport if none), nested positioned ancestor correctly takes precedence over root, `overflow:hidden` clips absolute children that extend past parent's border-box, `zIndex` orders absolute siblings, CSS default `relative` confirmed via default.json matching relative.json |
| `display` | ✅ | 3/4/4/4 | +21 baselines | 2026-05-13 | 15 spec samples (overview re-recorded) + 4 ios-ext (block/inline/inline-block/inline-flex) + responsive-wide method; AI walk found zero impl bugs; spec values `flex` (standard flex layout) and `none` (element + descendants removed from flow, zero space contribution) verified; default fallback (omitted = flex per joydom-swift; CSS spec would default by element type but joydom treats every node as flex) confirmed byte-identical to explicit `display: flex`; `display: none` on middle child collapses gap (siblings reflow with single gap, not gap-with-blank-slot); `display: none` on inner container hides container + all descendants; hidden child contributes zero space to flex-grow distribution (`with-grow` → 2 remaining children split full 400px width); hidden child contributes zero space to wrap-line calc (`with-wrap` 240px container fits all 3 visible items on one line, no wrap triggered); responsive breakpoint flip (`>=768px` hides `#b`) verified via `testDisplayResponsiveWide` |
| `boxSizing` | ✅ | 2/3/2/3 | +18 baselines | 2026-05-13 | 18 samples (overview rewritten as side-by-side comparison) + responsive-wide method; AI walk found zero impl bugs, 1 sample-design fix (`equal-outer-size` originally only equalized width, patched to also equalize height); visual proof for PR #25 — `border-box` deducts `borderWidth*2 + paddingMain*2` from FlexLayout-supplied size, while `content-box` (default when omitted) leaves outer = declared + padding + border; `equal-outer-size` proves border-box width=120 and content-box width=80 (+ padding 16 + border 4) both yield identical 120×120 outer; `width-padding-border` is the canonical numerical proof; nested.json shows deduction applies independently at every nesting level; responsive breakpoint flip (content-box ↔ border-box at width>=768px) confirmed |
| `zIndex` | ✅ | 5/3/2/3 | +19 baselines | 2026-05-13 | 18 samples + responsive-wide method; AI walk surfaced 1 impl bug (ZIDX-1: zIndex was fully ignored at paint time — cascade and FlexLayout storage were correct but no compositor hint reached SwiftUI) **fixed in the same PR** — `JoyDOMView.applyItem` now chains `.zIndex(Double(style.zIndex))` after `.flexItem(...)` so the SwiftUI compositor honors stacking order. Three baselines re-recorded (`negative.png`, `overview.png`, `responsive-wide.png`) to show CSS-correct stacking: `negative` (z:0 / z:-1) → red on top of green; `overview` (z:1 / z:3 / z:2) → green (z:3) on top, blue (z:2) middle, red (z:1) bottom; `responsive-wide` (breakpoint flips green's z:1 → z:-1) → red on top. Spec-compliant `no-position-no-effect` (in-flow flex children with no overlap render identically pre/post-fix) and `with-overflow-hidden` (zIndex doesn't escape clipping) verified. Source-order tiebreaker preserved for equal-zIndex siblings. |
| `overflow` | ✅ | 5/3/2/4 | +20 baselines | 2026-05-13 | 19 spec samples + responsive-wide method; AI walk found zero impl bugs and zero sample-design issues; spec values `visible`/`hidden`/`clip`/`scroll`/`auto` all verified against oversized children; documented limitation: `clip`/`scroll`/`auto` render byte-equivalent to `hidden` in static snapshots because `FlexOverflowModifier` maps clip→`.clipped()`, scroll→`ScrollView`+`.clipped()`, auto→`ViewThatFits` falling back to scroll — distinction is interaction-time, not paint-time; nested overflow:hidden containers clip independently (with-nested-overflow); overflow:hidden clips absolutely-positioned descendants (with-position-absolute-child); rounded-corner clipping verified (with-border-radius) |
| `top`/`left`/`bottom`/`right` | ✅ | 4/3/3/4 | +21 baselines | 2026-05-13 | 21 samples + responsive-wide method; ONE tracker row covers 4 CSS properties (top, left, bottom, right) all exercised under `layout/insets/`; AI walk surfaced 1 impl bug (FlexEngine ignored insets on `position: relative` items) **fixed in the same PR** — FlexEngine.solve now applies a paint-time offset to in-flow items when `position == .relative`, leaving the in-flow position siblings see unchanged per CSS §9.4; `position-relative-shifts.json` is the regression seam (green visually shifts +10/+20 without disturbing red/blue). Other invariants verified: absolute child anchors to nearest positioned ancestor (relative or absolute); falls through to root when no positioned ancestor exists; over-constrained `all-four` stretches a width-less/height-less child to fill the inset rectangle; negative insets escape the parent box; overflow:hidden parent clips off-canvas portion |

## 3. Box Model & Visuals (8 properties)

| Property | Status | Samples | Tests delta | Date | Notes |
|---|---|---|---|---|---|
| `backgroundColor` | ⬜ | 1/0/0/0 | — | — | — |
| `opacity` | ⬜ | 1/0/0/0 | — | — | — |
| `padding` | ⬜ | 1/0/0/0 | — | — | — |
| `margin` | ⬜ | 1/0/0/0 | — | — | PR #21 true flex margin needs visual proof |
| `borderWidth` | ⬜ | 1/0/0/0 | — | — | — |
| `borderColor` | ⬜ | 1/0/0/0 | — | — | — |
| `borderStyle` | ⬜ | 1/0/0/0 | — | — | Ext dashed/dotted/double have no render tests |
| `borderRadius` | ⬜ | 1/0/0/0 | — | — | — |

## 4. Sizing (3 properties)

| Property | Status | Samples | Tests delta | Date | Notes |
|---|---|---|---|---|---|
| `width` | ⬜ | 1/0/0/0 | — | — | — |
| `height` | ⬜ | 1/0/0/0 | — | — | — |
| `min`/`maxWidth` & `min`/`maxHeight` | ✅ | 5/3/2/5 + 4 per-property + 2 responsive | +23 baselines | 2026-05-14 | 22 samples covering all 4 properties (minWidth/maxWidth/minHeight/maxHeight) under combined `sizing/min-max/`; AI walk found zero impl bugs; verified CSS clamp invariants — declared < min clamps up, declared > max clamps down, `min-larger-than-max` proves CSS "min wins over max", `with-flex-grow-and-max` and `with-flex-shrink-and-min` verify the freeze-and-re-resolve algorithm for flex interactions (mirrors flexShrink/with-min-width 100/66/66 result); percent width resolves before min clamp; border-box clamps the outer box; responsive breakpoint flips minWidth 60→200 |

## 5. Typography (10 properties)

| Property | Status | Samples | Tests delta | Date | Notes |
|---|---|---|---|---|---|
| `fontFamily` | ⬜ | 1/0/0/0 | — | — | — |
| `fontSize` | ⬜ | 1/0/0/0 | — | — | — |
| `fontWeight` | ⬜ | 1/0/0/0 | — | — | CSS Fonts L4 band mapping |
| `fontStyle` | ⬜ | 1/0/0/0 | — | — | — |
| `color` | ⬜ | 1/0/0/0 | — | — | — |
| `textDecoration` | ⬜ | 1/0/0/0 | — | — | Env cascade to Text descendants |
| `textAlign` | ⬜ | 1/0/0/0 | — | — | — |
| `textTransform` | ⬜ | 1/0/0/0 | — | — | — |
| `lineHeight` | ⬜ | 1/0/0/0 | — | — | ⚠️ system-leading subtraction caveat |
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
