# Property Coverage Walkthrough

How to take a single CSS property (e.g. `flexGrow`, `padding`, `objectFit`) from
"empty `overview.json` stub" to "fully verified with snapshot baselines, Notion
table, tracker entry, bugs fixed/flagged." This is the literal sequence we ran
for `flexDirection` — distilled into a checklist so the next property doesn't
require re-deriving the workflow.

> **Pairs with**
> - [`Property-Coverage-Tracker.md`](Property-Coverage-Tracker.md) — live status
> - [`Spec-Property-Reference.md`](Spec-Property-Reference.md) — property semantics
> - [`Spec-Test-Plan.md`](Spec-Test-Plan.md) — broader test strategy

---

## TL;DR

```
1. Branch off main
2. Author variant JSONs under Sources/JoyDOMSampleSpecs/Resources/flexbox/<prop>/
3. Add manifest entries (each with snapshot.viewportWidth/height)
4. Add a test method to FlexboxSnapshotTests
5. Record baselines (SNAPSHOT_TESTING_RECORD=1 swift test --filter ...)
6. Walk each sample: predict from spec → pixel-sample baseline → diff
7. File bugs found into Tracker; fix in same branch if cheap, separate PR if not
8. Re-record baselines after any fix or sample patch
9. Push, then create Notion table for the property (script TBD or follow manual steps)
10. Update Tracker row to ✅ with sample counts and tests delta
```

---

## Step 1 — Pick the property & open a branch

Pick the next ⬜ row in the Tracker. Branch name:

```bash
git checkout main && git pull
git checkout -b test/<prop-kebab>-l2-l3
# e.g. test/flex-grow-l2-l3
```

Stay on this branch through the whole walk. Commit incrementally:
samples first, then test wiring, then per-bug-fix commits, then sample patches.

---

## Step 2 — Author variant JSONs

For each property, produce a **coverage matrix**: every meaningful value, edge
case, context, and interaction. The flex-direction set (23 samples) is the
reference template. The categories below should produce 15–25 samples for most
properties — fewer if the value set is narrow (e.g. `boxSizing` only has 2).

### 2a. Value sweep (one sample per declared value)

If the property has enumerated values (`row | row-reverse | column | column-reverse`),
each gets its own JSON. For numeric properties (`flexGrow: 0..∞`) pick 2-3
representative values (`0`, `1`, `2` say).

File naming: `<value>.json` — e.g. `row.json`, `column-reverse.json`. Use
kebab-case for multi-word enum values (`row-reverse`, not `rowReverse`).

### 2b. Defaults baseline

`default.json` — the property is **omitted entirely**. Lets the walk verify the
fallback path matches the CSS spec default (and surfaces any divergence in
JoyDOM's `FlexContainerConfig` / `ItemStyle` defaults).

### 2c. Edge cases (`<edge>.json`)

Off the top of the head — adapt per property:

- `empty.json` — container has no children
- `single-child.json` — exactly one child (no gap visible, no align interactions)
- `nested.json` — property applied at two depths
- `overview.json` — a "showcase" version. Useful as the canonical entry in
  property-grouping tools (the demo app, this Notion table). Often functionally
  identical to one of the value-sweep samples.

### 2d. Authoring style variants

- `inline.json` — property set via `node.props.style` (inline) instead of the
  document-level selector map. Verifies inline path doesn't drop the property.
- `class-selector.json` — property set on a `.class` matching multiple siblings.
  Verifies the rule applies to each, not just the first.

### 2e. Context variants (`in-<context>.json`)

- `in-absolute.json` — the property's element is `position: absolute` inside a
  `position: relative` parent. Verifies the property still applies when laid
  out outside the normal flow.
- `in-fixed-width.json` — parent has explicit `width`, forcing flex-shrink /
  overflow interactions.

### 2f. Interactions (`with-<other>.json`)

For every other Flexbox property the current one could reasonably combine with,
add one `with-<other>.json`. For `flexDirection` we had:

- `with-wrap.json`, `with-gap.json`, `with-justify-end.json`,
  `with-align-items.json`, `with-align-self.json`, `with-grow.json`,
  `with-basis.json`, `with-order.json`

Don't be exhaustive — pick combinations that produce a **visually distinct**
layout you couldn't predict from the parts. Skip combinations that just
"obviously work".

### 2g. Responsive / breakpoint (`responsive.json`)

Property changes value at a breakpoint. Adds one extra "viewport" dimension to
the property's coverage. Pair with a manifest entry that captures the narrow
viewport; for the wide viewport, add a separate test method (see Step 5) — we
can't yet declare multiple snapshot configs per sample (limitation in the
manifest schema; see `JoyDOMSampleSpecs/SpecPropertySample.swift`).

### Sample design rules

- **One concept per sample.** A `with-grow.json` that also sets `justify-content`
  hides which thing the snapshot proves.
- **Make the property visually dominant.** If `gap: 8` is buried under a 50px
  `alignContent: stretch` redistribution, the row-gap declaration is invisible
  (this is exactly what we caught in `flex-direction/with-wrap.json` and patched
  with explicit `alignContent: flex-start`).
- **Use the standard color palette** for predictability:
  - `#EF4444` red `#a`/`#l1`/etc.
  - `#10B981` green `#b`/`#l2`
  - `#3B82F6` blue `#c`/`#r1`
  - `#F59E0B` amber `#d`/`#r2`
  - `#F3F4F6` gray root background
  - `#E5E7EB` darker gray for nested-container backgrounds
- **Use the standard box class** `.box` with `width: 60, height: 60,
  borderRadius: 4` as the default child shape, unless the sample specifically
  needs different dimensions.

---

## Step 3 — Add manifest entries

Every JSON needs an entry in
`Sources/JoyDOMSampleSpecs/Resources/manifest.json` with:

```json
{
  "id": "flexbox-<prop-kebab>-<sample-kebab>",
  "file": "flexbox/<prop-kebab>/<sample-kebab>.json",
  "category": "Flexbox",
  "property": "<propCamelCase>",
  "summary": "one sentence describing what this sample demonstrates",
  "snapshot": {
    "viewportWidth": <int>,
    "height": <int>
  }
}
```

### Picking viewport size

- Width should be **just enough** to make the layout obvious. A row of 4×60px
  boxes with 8px gaps and 16px padding totals 296px — `viewportWidth: 400` gives
  comfortable margin without dwarfing the content.
- Height usually matches the content's natural extent for row layouts (~120),
  more for column layouts (~360).
- For breakpoint-flip samples, the **narrow** viewport goes here; the wide one
  is captured by the separate `<Prop>ResponsiveWide` test method.

### Summary string conventions

- Plain English. Avoid jargon.
- Mention which axis/direction the sample exercises if not obvious from the
  filename.
- For responsive samples, mention the breakpoint threshold and what flips.

---

## Step 4 — Wire up the test method

In `Tests/JoyDOMTests/PropertyCoverage/Flexbox/flexbox.swift`, add one method
per property:

```swift
func test<PropCamelCase>() {
    assertSnapshotsForSamples(in: "flexbox/<prop-kebab>")
}
```

The helper auto-discovers every sample in the directory and snapshots each at
the manifest-declared viewport. **No per-sample test method needed.**

For a responsive sample's wide-viewport second snapshot, add a dedicated method:

```swift
func test<PropCamelCase>ResponsiveWide() throws {
    let sample = try XCTUnwrap(
        SpecPropertySamples.sample(withID: "flexbox-<prop-kebab>-responsive"),
        "responsive sample missing from JoyDOMSampleSpecs bundle"
    )
    let testFileDir = ((#filePath) as NSString).deletingLastPathComponent
    let snapshotDir = (testFileDir as NSString)
        .appendingPathComponent("__Snapshots__/flexbox/<prop-kebab>")
    assertJoyDOMSnapshot(
        json: sample.json,
        viewportWidth: <wide-width>,
        height: <wide-height>,
        snapshotDirectory: snapshotDir,
        snapshotName: "responsive-wide"
    )
}
```

---

## Step 5 — Record baselines

```bash
SNAPSHOT_TESTING_RECORD=1 swift test --filter "FlexboxSnapshotTests/test<PropCamelCase>"
```

First run fails (recorded baselines = "no baseline before, fail by design"). Run
again to verify all green:

```bash
swift test --filter "FlexboxSnapshotTests/test<PropCamelCase>"
```

Recorded files land at:

```
Tests/JoyDOMTests/PropertyCoverage/Flexbox/__Snapshots__/flexbox/<prop-kebab>/<sample>.png
```

This is a pure 1:1 mirror of the JSON tree — no method-name prefix, no
counter suffix. (See `Tests/JoyDOMTests/Snapshot/JoyDOMSnapshotHelpers.swift`
for the path-controlled helper that makes this work.)

---

## Step 6 — Walk each sample

This is where bugs surface. For **each** baseline, in some logical order
(simplest first; defaults → variants → interactions → contexts):

### 6a. Read the JSON & predict the layout

Don't peek at the image yet. Write out (in your head or on paper) the expected
result:

- Where each child sits (viewport x/y bounds)
- Which axis fills, which hugs
- What gaps/padding produce
- Which colors are at which positions

Anchor every prediction in **CSS-spec semantics**. JoyDOM is supposed to match
web behavior; any deviation between your prediction (= CSS) and the snapshot
(= JoyDOM) is either a sample-design issue or an implementation bug. The walk
exists to surface those.

### 6b. Look at the snapshot

Read the PNG with the `Read` tool. Visual eyeball check — does the colored-box
arrangement match what you predicted?

### 6c. Pixel-sample for precision

Eyeballing is lossy. For each box, sample the center pixel; for boundaries
(gaps, padding) sample known coordinates. Use Python+PIL:

```python
from PIL import Image
img = Image.open('Tests/.../sample.png')
pixels = img.load()
print(f'Size: {img.size}')        # 2× viewport at retina
# Pixel coords = viewport coords × 2
for x, y, label in [(92, 92, 'red box center'), ...]:
    print(f'  ({x},{y}) {label}: {pixels[x, y]}')
```

The standard color palette:
- `#EF4444` red → `(232, 44, 53)`
- `#10B981` green → `(27, 174, 110)`
- `#3B82F6` blue → `(47, 105, 243)`
- `#F59E0B` amber → `(240, 141, 14)`
- `#F3F4F6` gray bg → `(240, 241, 244)`
- `#E5E7EB` darker gray → `(223, 225, 230)` (color profile shifts ~6 units in
  Display P3 rendering — within snapshot precision tolerance)
- `(0, 0, 0, 0)` = transparent (outside root box)

### 6d. Verdict — three outcomes

- **✅ Match.** Prediction = pixel-sampled actual. Move to next sample.
- **⚠️ Sample-design issue.** The sample is technically working but doesn't
  visually demonstrate the property because of an unrelated default (e.g.
  `align-content: stretch` swallowing the row-gap). Patch the sample, re-record,
  commit with a `fix(samples):` message.
- **🔴 Implementation bug.** JoyDOM produces a result that doesn't match CSS
  defaults. Trace the root cause through `JoyDOMView` → `ComponentResolver` →
  `StyleResolver` → `FlexEngine`. Fix or document.

---

## Step 7 — Surfacing & fixing bugs

When step 6 surfaces a divergence:

1. **Reproduce in isolation.** A failing snapshot is a great repro — keep it
   pinned.
2. **Trace the root cause.** Always go from the rendered pixel back to the
   spec → style resolution → flex engine → SwiftUI layout chain. The bug is
   usually in one specific link, even if it manifests across many samples.
3. **Add temporary instrumentation if needed.** For the `with-basis.json`
   investigation we added a `print(...)` in `FlexEngine.swift` to read out
   `basisMain` / `naturalSize` mid-layout. Critically: **remove the print
   before committing.**
4. **Fix in the same branch if it's cheap and orthogonal.** Both bugs we found
   during the flex-direction walk (`root sizing asymmetry`, `empty-div 10px
   intrinsic`) were small, single-file changes that didn't widen the PR scope.
5. **Spawn a separate task if it's deep** (e.g. requires refactoring across
   multiple modules, or affects unrelated tests). Don't let a deep dive
   sink the property's coverage PR.
6. **Document every limitation** that you accept rather than fix. Add a row to
   the Tracker's "Documented limitations" table at the bottom.

### After any fix or sample patch

```bash
swift test                    # full suite — confirm no regressions
SNAPSHOT_TESTING_RECORD=1 swift test --filter "FlexboxSnapshotTests/test<PropCamelCase>"   # re-record affected
swift test --filter "FlexboxSnapshotTests/test<PropCamelCase>"   # verify clean rerun
git add -A && git commit -m "fix(...): one-line summary"
```

Commit each fix as a separate commit so the diff and the explanation stay
proximate. Don't squash all the bug fixes into one mega-commit.

---

## Step 8 — Push & open PR

```bash
git push -u origin test/<prop-kebab>-l2-l3
gh pr create --title "Test/<prop-kebab> property coverage" --body "..."
```

PR body should list:

- Number of samples added
- Bugs found and fixed (link each commit)
- Sample patches with rationale
- Known limitations deferred (with Tracker rows linked)
- One-line summary of the property's verified behavior

---

## Step 9 — Update the Tracker

In `docs/Property-Coverage-Tracker.md`, flip the property's row from ⬜ to ✅
(or ⚠️ if a limitation was documented). Fill in:

- **Samples** column: `value-sweep / edges / contexts / interactions` count
- **Tests delta** column: rough count of new test methods (usually +1 or +2)
- **Date** column: today's date
- **Notes** column: anything noteworthy (bugs surfaced, limitations, sample
  design quirks)

---

## Step 10 — Notion table

This step is currently manual; a regenerator script is on the TODO. For now,
mirror the `flex-direction samples` database structure: see [this Notion page](https://www.notion.so/joyfill/35edef37c9a080da8bc8d0c06cd30c67) for the canonical example.

### 10a. Create a new database

Title: `<prop-kebab> samples`. Parent: same parent page as `flex-direction
samples`. Schema:

```sql
CREATE TABLE (
  "Template" TITLE,
  "iOS UI" FILES,
  "JS" RICH_TEXT,
  "Kotlin" RICH_TEXT
)
```

`Template` is the sample's basename; `iOS UI` is a hot-linked GitHub raw URL
to the PNG; `JS`/`Kotlin` columns are placeholders for other-language parity
content the team will fill in later.

### 10b. Build the GitHub raw URL base

The branch SHA pins the snapshot at a stable revision. After your PR lands:

```bash
git rev-parse HEAD   # capture this SHA before regenerating URLs
```

URL pattern:

```
https://raw.githubusercontent.com/j0yhq/flexbox-swift/<SHA>/Tests/JoyDOMTests/PropertyCoverage/Flexbox/__Snapshots__/flexbox/<prop-kebab>/<sample>.png
```

> **Pin to commit SHAs, not branch names.** Branch names with slashes
> (e.g. `test/flex-direction-l2-l3-continued`) break GitHub's raw URL format
> (slashes get treated as path segments). Commit SHAs are always single-segment
> and never get rebased away.

### 10c. Create one row per sample

Each row's properties:

- `Template`: sample basename (e.g. `"row"`)
- `iOS UI`: just the URL string (Notion auto-wraps to a file attachment).

Each row's page body:

```markdown
![<sample>.png](<github-raw-url>)

```json
{... the JSON spec content ...}
```
```

(Embedding the image in the page body lets the reader see it inline when
clicking the row, without expanding the FILES column.)

For the responsive-wide variant, include a note explaining the viewport size
trigger:

```markdown
_Note: same JSON as `responsive`, rendered at viewport <W>×<H> to trigger
the `<breakpoint>` flip._
```

### 10d. Order the rows

Same as the walk order in step 6: defaults → variants → interactions →
contexts → special.

---

## Appendix — Common patterns to copy

### Standard root container

```json
"#root": {
  "flexDirection": "row",
  "padding": { "value": 16, "unit": "px" },
  "gap":     { "value": 8,  "unit": "px" },
  "backgroundColor": "#F3F4F6"
}
```

### Standard child boxes

```json
".box": {
  "width":  { "value": 60, "unit": "px" },
  "height": { "value": 60, "unit": "px" },
  "borderRadius": { "value": 4, "unit": "px" }
}
```

### Layout list of 3 colored boxes

```json
"layout": {
  "type": "div",
  "props": { "id": "root" },
  "children": [
    { "type": "div", "props": { "id": "a", "className": ["box"] } },
    { "type": "div", "props": { "id": "b", "className": ["box"] } },
    { "type": "div", "props": { "id": "c", "className": ["box"] } }
  ]
}
```

### Style colors per id

```json
"#a": { "backgroundColor": "#EF4444" },
"#b": { "backgroundColor": "#10B981" },
"#c": { "backgroundColor": "#3B82F6" }
```

---

## What we found running this on `flexDirection`

Two implementation bugs and one sample design issue, captured here as a
reality check on what the walk surfaces (this is not a typical "everything
passed" outcome — expect bugs the first few times):

1. **Synthetic-root wrap** (PR commit `16496105`) — the resolver's
   `__joydom_root__` cascade anchor was being rendered as a real flex
   container, turning the user's `<div id="root">` into a flex item that
   hugged width and stretched height. Caught by `default.json` showing
   gray = 296×360 (asymmetric) instead of CSS-block-expected 400×360.

2. **Empty-div 10px intrinsic** (PR commit `0cb97cf1`) — the default `<div>`
   factory returned naked `Color.clear`, whose SwiftUI
   `intrinsicContentSize` is `(10, 10)`. Caught by `with-basis.json` where
   box `a` (auto basis, empty div, no width) showed a 10px red sliver
   instead of being 0-wide invisible. Fixed by `Color.clear.frame(idealWidth:
   0, idealHeight: 0)`.

3. **Sample-design — alignContent default** (PR commit `adf3409c`) — the
   `with-wrap.json` sample's `gap: 8` was invisible because the CSS-default
   `align-content: stretch` redistributed 50px of cross-axis space *between*
   the rows. Patched the sample with explicit `alignContent: flex-start`.

Whatever the next property is, expect to surface 1–3 similar findings. The
walk is doing its job.
