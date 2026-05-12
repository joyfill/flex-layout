# Property Coverage Walkthrough

How to take a single CSS property (e.g. `flexGrow`, `padding`, `objectFit`) from
"empty `overview.json` stub" to "fully verified with snapshot baselines, Notion
table, tracker entry, bugs fixed/flagged."

This is the literal sequence we ran for `flexDirection` — distilled into a
checklist so the next property doesn't require re-deriving the workflow. Each
step has a **goal** and a **gate** (the concrete artifact that must exist before
moving on).

> **Pairs with**
> - [`Property-Coverage-Tracker.md`](Property-Coverage-Tracker.md) — live status
> - [`Spec-Property-Reference.md`](Spec-Property-Reference.md) — property semantics
> - [`Spec-Test-Plan.md`](Spec-Test-Plan.md) — broader test strategy

---

## Principles (apply throughout)

- **Baselines are immutable artifacts.** Do not promote a snapshot to baseline
  until the sample *and* the implementation are both verified correct. Once
  promoted, a baseline only changes via an explicit, reviewed intent-to-update.
  Locking baselines too early creates a treadmill where bugs hide behind
  passing tests.
- **Triage every issue.** Tag as `bug-in-impl` (fix JoyDOM), `bug-in-sample`
  (patch JSON), or `documented-limitation` (Tracker note) **before** fixing.
  This keeps commits scoped and reviewable.
- **The rendering script is deterministic.** Same input → same pixels. No
  `Date()`, async ordering, random IDs, or fonts that vary by host. Re-renders
  must produce clean diffs, not noise — otherwise step 7's churn is
  indistinguishable from real changes.
- **Spec is the source of truth, not the current renderer.** Every expected
  output prediction anchors in CSS / JoyDOM spec semantics, never in "what
  JoyDOM currently does." Any divergence is either a sample-design issue or an
  implementation bug — that's exactly what the walk is designed to surface.

---

## Steps

### 1. Scope the property

**1a.** Read the CSS spec section for the property + the corresponding row in
[`Spec-Property-Reference.md`](Spec-Property-Reference.md). Note any
JoyDOM-specific extensions or documented limitations.

**1b.** Enumerate use cases across these buckets. Most properties produce
15–25 samples total; fewer if the value set is narrow (e.g. `boxSizing`
only has 2 values).

| Bucket | Examples | Filename pattern |
|---|---|---|
| Value sweep | every enum value, or 2–3 representative numbers | `row.json`, `column.json`, `<value>.json` |
| Defaults | property omitted entirely (verifies CSS-spec fallback) | `default.json` |
| Edges | empty children, single child, deep nesting, "showcase" | `empty.json`, `single-child.json`, `nested.json`, `overview.json` |
| Authoring style | inline via `node.props.style`; class selector | `inline.json`, `class-selector.json` |
| Context | `position: absolute`; constrained parent width | `in-absolute.json`, `in-fixed-width.json` |
| Interactions | combinations with other Flexbox properties | `with-wrap.json`, `with-gap.json`, `with-grow.json`, etc. |
| Responsive | breakpoint flip | `responsive.json` (+ `responsive-wide.png` from a second test method) |

For interactions, pick only combinations that produce a **visually distinct,
non-obvious result**. Skip pairs that just "obviously work".

**Gate:** A written list of sample filenames before any JSON is authored.

---

### 2. Author sample JSONs

Each JSON lands at:
```
Sources/JoyDOMSampleSpecs/Resources/flexbox/<prop-kebab>/<sample-kebab>.json
```

#### Design rules

- **One concept per sample.** A `with-grow.json` that also tweaks
  `justify-content` hides which thing the snapshot proves.
- **Make the property visually dominant.** If a CSS default swallows the
  declaration (e.g. `align-content: stretch` redistributing space and hiding
  a `gap: 8`), the snapshot doesn't prove anything. Caught this in
  `flex-direction/with-wrap.json` — patched it with explicit
  `alignContent: flex-start` so the row-gap actually shows.
- **Use the standard color palette** for predictability:
  - `#EF4444` red `#a` / `#l1`
  - `#10B981` green `#b` / `#l2`
  - `#3B82F6` blue `#c` / `#r1`
  - `#F59E0B` amber `#d` / `#r2`
  - `#F3F4F6` gray root background
  - `#E5E7EB` darker gray for nested-container backgrounds
- **Use the standard `.box` class** (`width: 60, height: 60, borderRadius: 4`)
  as the default child shape unless the sample specifically needs different
  dimensions.

See the [Appendix](#appendix--reusable-snippets) for copy-paste starters.

**Gate:** Every filename from Step 1 has a JSON.

---

### 3. Schema validation

Run the existing validator over every new sample:

```bash
swift test --filter "SpecPropertySamplesTests"
```

This decodes each sample as a `Spec` and reports missing keys, malformed
breakpoints, unknown property names. **No `try? JSONDecoder()` swallowing
errors** — every failure must be addressed before rendering.

**Gate:** Validator passes for all samples in the new property's folder.

---

### 4. Add manifest entries

For each JSON, add to `Sources/JoyDOMSampleSpecs/Resources/manifest.json`:

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

#### Picking viewport size

- Width: just enough to make the layout obvious. A row of 4×60px boxes
  totals ~296px → `viewportWidth: 400` leaves comfortable margin without
  dwarfing content.
- Height: matches natural extent — ~120 for row layouts, ~360 for column.
- For breakpoint-flip samples, the **narrow** viewport goes here; the wide
  viewport is captured by a separate `<Prop>ResponsiveWide` test method.

**Gate:** Every JSON has a manifest entry. `SpecPropertySamplesTests` still
passes.

---

### 5. Render & screenshot (the script)

#### Wire up the test method

In `Tests/JoyDOMTests/PropertyCoverage/Flexbox/flexbox.swift`:

```swift
func test<PropCamelCase>() {
    assertSnapshotsForSamples(in: "flexbox/<prop-kebab>")
}
```

For a responsive sample's wide-viewport second snapshot, add:

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

#### Run the rendering script

```bash
SNAPSHOT_TESTING_RECORD=1 swift test --filter "FlexboxSnapshotTests/test<PropCamelCase>"
```

This is **the script** — don't write a new one. The flow is deterministic
(same JSON → same pixels) and idempotent (re-running overwrites cleanly).

Recorded files land at:
```
Tests/JoyDOMTests/PropertyCoverage/Flexbox/__Snapshots__/flexbox/<prop-kebab>/<sample>.png
```

Pure 1:1 mirror of the JSON tree — no method-name prefix, no counter suffix.

> **These are NOT baselines yet.** They're screenshots for review. Baselines
> get promoted in Step 9.

**Gate:** PNG files exist for every sample in the new property's folder.

---

### 6. AI review pass

For each sample, the AI:

1. Reads the JSON
2. **Predicts expected layout from CSS spec semantics** — first principles,
   not "what JoyDOM currently does." Writes out child positions, axis
   behavior, color order, free-space distribution.
3. Reads the screenshot
4. **Pixel-samples for precision** (Python + PIL):

   ```python
   from PIL import Image
   img = Image.open('Tests/.../sample.png')
   pixels = img.load()
   # Pixel coords = viewport coords × 2 (retina)
   for x, y, label in [(92, 92, 'red box center'), ...]:
       print(f'  ({x},{y}) {label}: {pixels[x, y]}')
   ```

   Standard palette reference:
   - `#EF4444` red → `(232, 44, 53)`
   - `#10B981` green → `(27, 174, 110)`
   - `#3B82F6` blue → `(47, 105, 243)`
   - `#F59E0B` amber → `(240, 141, 14)`
   - `#F3F4F6` gray bg → `(240, 241, 244)`
   - `#E5E7EB` darker gray → `(223, 225, 230)` (~6 unit color profile shift,
     within snapshot precision tolerance)
   - `(0, 0, 0, 0)` = transparent (outside root box)

5. **Produces a triaged list.** Each sample's verdict + rationale:
   - ✅ `match` — prediction = actual
   - ⚠️ `bug-in-sample` — works but doesn't demonstrate the property
   - 🔴 `bug-in-impl` — diverges from CSS spec semantics
   - ⚠️ `documented-limitation` — known JoyDOM caveat (link to Tracker row)

**Gate:** Every sample has a verdict with rationale captured somewhere
durable (PR description, issue, scratchpad doc).

---

### 7. Human review pass

Walk every sample manually, focused on what AI typically misses:

- **Sample design weakness** — the layout technically works but doesn't
  visually demonstrate the property (AI tends to rubber-stamp these).
- **Cross-axis surprises** — color profile shifts, subpixel rounding,
  font-host variability.
- **Intent vs. spec** — does the visual match what someone *authoring* this
  spec would expect? Sometimes the spec-correct rendering is bewildering and
  the sample should be redesigned to make the property's effect clearer.

Append findings to the triaged list from Step 6. Don't fix yet — just triage.

**Gate:** Combined AI + human issue list, fully triaged with one of the four
tags above.

---

### 8. Fix all issues

Work through the triaged list. **Group commits by category** so the diff
narrates the work:

```
fix(view|engine|resolver|registry): <one-line summary>     # bug-in-impl
fix(samples): <one-line summary>                            # bug-in-sample
docs(tracker): <prop> limitation — <one-line>               # documented-limitation
```

#### Investigation pattern for `bug-in-impl`

1. Reproduce in isolation (the failing snapshot is a great repro).
2. Trace pixel → spec → resolver → engine → SwiftUI layout chain. The bug
   is usually in one specific link.
3. Add temporary instrumentation (`print(...)` in FlexEngine etc.) if
   needed. **Remove before committing.**
4. After **any** fix, re-render via Step 5's script (not manually) and check
   the diff matches your expectation.
5. Run the **full** test suite (`swift test`, no filter) — bugs in shared
   code can regress other properties.

If a bug is too deep for this PR (requires cross-module refactoring, has
unclear scope), spawn a separate task. Don't let one deep dive sink the
property's coverage PR.

**Gate:** Triaged list fully resolved. `swift test` (no filter) passes
cleanly. Re-rendered screenshots match new expectations from Step 6.

---

### 9. Promote to baselines (lock in)

The screenshots from Step 8's final re-render become the official UI test
baselines. The test method from Step 5 already wraps each sample — at this
point, all those tests pass without the `SNAPSHOT_TESTING_RECORD` flag.

```bash
swift test --filter "FlexboxSnapshotTests/test<PropCamelCase>"
```

**Gate:** The property's test method passes on a clean checkout, no recording
flag, no manual intervention.

---

### 10. Push, PR, merge

```bash
git push -u origin test/<prop-kebab>-l2-l3
gh pr create --title "Test/<prop-kebab> property coverage" --body "<see below>"
```

PR body must include:
- Sample count by bucket (value sweep / edges / contexts / interactions)
- Bugs found and fixed (link each commit)
- Sample patches with rationale (link each commit)
- Known limitations deferred (link Tracker rows)
- One-line summary of the property's verified behavior

After merge to `main`, **capture the merge commit SHA**:
```bash
git rev-parse main
```

This is what the Notion image URLs will pin against in Step 12.

**Gate:** PR merged. Merge SHA captured.

---

### 11. Update Tracker

Flip the property's row in `docs/Property-Coverage-Tracker.md` from ⬜ to ✅
(or ⚠️ if limitations were documented). Fill in:

- **Samples** column: `value-sweep / edges / contexts / interactions` count
- **Tests delta** column: rough count of new test methods (usually +1 or +2)
- **Date** column: today's date
- **Notes** column: noteworthy bugs surfaced, limitations, sample-design quirks

Bug entries get rows in the "Bugs surfaced during the walk" table at the
bottom; limitations get rows in "Documented limitations."

---

### 12. Create Notion table

New database under the [JoyDom property comparison parent page](https://www.notion.so/joyfill/35edef37c9a080da8bc8d0c06cd30c67).

#### Schema

```sql
CREATE TABLE (
  "Template" TITLE,
  "iOS UI" FILES,
  "JS" RICH_TEXT,
  "Kotlin" RICH_TEXT
)
```

- `Template` — sample's basename
- `iOS UI` — hot-linked GitHub raw URL to the PNG
- `JS` / `Kotlin` — placeholders for other-language parity content the team
  fills in later

#### Image URL pattern

```
https://raw.githubusercontent.com/j0yhq/flexbox-swift/<MERGE-SHA>/Tests/JoyDOMTests/PropertyCoverage/Flexbox/__Snapshots__/flexbox/<prop-kebab>/<sample>.png
```

> **Pin to the merge commit SHA from Step 10**, not the branch name. Branch
> names with slashes (`test/flex-direction-l2-l3-continued`) break GitHub's
> raw URL format; rebased/deleted branches lose history. Merge SHAs are
> stable forever.

#### Row contents

Properties:
- `Template`: sample basename (e.g. `"row"`)
- `iOS UI`: just the URL string (Notion auto-wraps to a file attachment)

Page body (markdown):
```markdown
![<sample>.png](<github-raw-url>)

```json
{... full JSON spec ...}
```
```

For the responsive-wide variant, include a viewport note:
```markdown
_Note: same JSON as `responsive`, rendered at viewport <W>×<H> to trigger
the `<breakpoint>` flip._
```

#### Row order

Same as the walk order in Steps 6/7: defaults → variants → interactions →
contexts → special.

**Gate:** One row per sample, image previews loading, JSON code blocks in
each row's body.

---

## Appendix — Reusable snippets

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
"#c": { "backgroundColor": "#3B82F6" },
"#d": { "backgroundColor": "#F59E0B" }
```

---

## What we found running this on `flexDirection`

Two implementation bugs and one sample-design issue, captured here as a
reality check: a typical first walk surfaces ~1–3 such findings. Expect them.

1. **Synthetic-root wrap** (commit `16496105`) — the resolver's
   `__joydom_root__` cascade anchor was being rendered as a real flex
   container, turning the user's `<div id="root">` into a flex item that
   hugged width and stretched height. Caught by `default.json` showing
   gray = 296×360 (asymmetric) instead of CSS-block-expected 400×360.
   **Tag:** `bug-in-impl`.

2. **Empty-div 10px intrinsic** (commit `0cb97cf1`) — the default `<div>`
   factory returned naked `Color.clear`, whose SwiftUI
   `intrinsicContentSize` is `(10, 10)`. Caught by `with-basis.json` where
   box `a` (auto basis, empty div, no width) showed a 10px red sliver
   instead of being 0-wide invisible. Fixed by `Color.clear.frame(idealWidth:
   0, idealHeight: 0)`. **Tag:** `bug-in-impl`.

3. **`with-wrap` alignContent default** (commit `adf3409c`) — the sample's
   `gap: 8` was invisible because the CSS-default `align-content: stretch`
   redistributed 50px of cross-axis space between rows. Patched with explicit
   `alignContent: flex-start`. **Tag:** `bug-in-sample`.
