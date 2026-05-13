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
| `flexBasis` | ⬜ | 1/0/0/0 | — | — | — |
| `justifyContent` | ⬜ | 1/0/0/0 | — | — | — |
| `alignItems` | ⬜ | 1/0/0/0 | — | — | — |
| `alignSelf` | ⬜ | 1/0/0/0 | — | — | — |
| `flexWrap` | ✅ | 2/4/4/5 | +17 baselines | 2026-05-13 | 15 spec samples + 1 ios-ext (wrap-reverse) + responsive-wide method; AI walk found zero impl bugs; spec values `nowrap` (with overflow → items shrink) and `wrap` (with overflow → items reflow onto multiple lines) verified; default fallback (omitted = nowrap) confirmed byte-identical to explicit nowrap; per-line free-space distribution (`with-grow` → row1 grows to 140/140, row2 grows alone to full 288) proven; per-axis `gap` (c:16, r:24) shows row-gap honored across wrapped lines; one sample-design patch (in-column container shrunk from 320→200 so it fits 240 viewport); CSS-default `align-content: stretch` avoided by leaving container height unset so lines pack at content height |
| `gap`/`rowGap`/`columnGap` | ⬜ | 1/0/0/0 | — | — | — |
| `order` | ✅ | 5/3/2/4 | +20 baselines | 2026-05-13 | 19 samples (overview kept) + responsive-wide method; AI walk found zero impl bugs; verified negative orders + mixed signs + large-magnitude relative ordering (1000/10/100 → 10<100<1000); same-order CSS-spec stability preserved (source order tiebreaker); ordering applies on column axis; reordering coexists cleanly with justifyContent / flexWrap / flexGrow / alignSelf without affecting sizing or cross-axis alignment |

## 2. Layout & Positioning (9 properties)

| Property | Status | Samples | Tests delta | Date | Notes |
|---|---|---|---|---|---|
| `position` | ⬜ | 1/0/0/0 | — | — | — |
| `display` | ⬜ | 1/0/0/0 | — | — | — |
| `boxSizing` | ⬜ | 1/0/0/0 | — | — | PR #25 deduction needs visual sample |
| `zIndex` | ⬜ | 1/0/0/0 | — | — | — |
| `overflow` | ⬜ | 1/0/0/0 | — | — | — |
| `top`/`left`/`bottom`/`right` | ⬜ | 1/0/0/0 | — | — | Combined as `insets` |

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
| `min`/`maxWidth` & `min`/`maxHeight` | ⬜ | 1/0/0/0 | — | — | — |

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

(Empty — populated as the walk progresses.)

| ID | Property | Reproducer sample | Expected vs actual | Status |
|---|---|---|---|---|

## Documented limitations

(Empty — populated as the walk progresses.)

| Property | Limitation | Why deferred | Tracking |
|---|---|---|---|
