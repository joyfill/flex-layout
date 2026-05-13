# Property Coverage Walkthrough

How to take a single CSS property (e.g. `flexGrow`, `padding`, `objectFit`) from
"empty `overview.json` stub" to "fully verified with snapshot baselines, Notion
table, tracker entry, bugs fixed/flagged."

This is the literal sequence we ran for `flexDirection` — distilled into a
checklist so the next property doesn't require re-deriving the workflow. Each
step has a **goal** and a **gate** (the concrete artifact that must exist before
moving on).

> **Step 0 (scaffold-prep)** runs **once per Tracker Section** when you first
> open coverage walks under a new top-level folder (`flexbox/`, `layout/`,
> `boxmodel/`, …). Steps 1–11 then run **once per property** within that
> Section. If the Section is already scaffolded (e.g. Flexbox after PR #1),
> skip Step 0 and start at Step 1.

> **Pairs with**
> - [`Property-Coverage-Tracker.md`](Property-Coverage-Tracker.md) — live status
> - [`Spec-Property-Reference.md`](Spec-Property-Reference.md) — per-property impl semantics + caveats
> - [`JoyDOM-Spec-Allowlist.md`](JoyDOM-Spec-Allowlist.md) — flat allowlist of every property + value samples may use (sample-author cheat-sheet)
> - [`Spec-Test-Plan.md`](Spec-Test-Plan.md) — broader test strategy

---

## Principles (apply throughout)

- **The JoyDOM CSS spec defines the scope.** Only test values and property
  combinations the [JoyDOM CSS spec](https://github.com/j0yhq/joy-dom/blob/main/apps/website/content/docs/css.mdx)
  declares supported. Iceberg things the iOS / FlexLayout primitive happens
  to handle (`row-reverse`, `column-reverse`, future native-only knobs)
  are explicitly out of scope for cross-platform coverage and live in a
  sibling `*-ios-ext/` folder with their own test method. The spec is what
  JS and Kotlin runtimes will mirror; any sample that exercises behavior
  beyond the spec produces an iOS-only artifact that JS/Kotlin can never
  match — exactly the opposite of what these tests are for.
- **Baselines are immutable artifacts.** Do not promote a snapshot to baseline
  until the sample *and* the implementation are both verified correct. Once
  promoted, a baseline only changes via an explicit, reviewed intent-to-update.
  Locking baselines too early creates a treadmill where bugs hide behind
  passing tests.
- **Triage every issue.** Tag as `bug-in-impl` (fix JoyDOM), `bug-in-sample`
  (patch JSON), `out-of-scope` (move to `*-ios-ext/`), or
  `documented-limitation` (Tracker note) **before** fixing. This keeps commits
  scoped and reviewable. See Step 8 for the triage subtree that distinguishes
  fixable `bug-in-impl` from intrinsic `documented-limitation`.
- **Probe the minimum-viable fix before deferring.** When a `bug-in-impl` first
  smells like a "cross-module refactor", spend 15-30 minutes tracing the
  actual code path before tagging it deferred. Two cases in the Layout batch
  (May 13) were initially tagged as out-of-scope refactors but turned out to
  be ≤10-line fixes once the actual gap was found:
  - **ZIDX-1** — walker said *"requires Layout-protocol painter-order sort"*.
    Reality: one line in `JoyDOMView.applyItem` chained SwiftUI's `.zIndex(_:)`
    modifier (the compositor reads its own hook, not `Layout.placeSubviews`
    placement order).
  - **CSS §9.4 relative-position insets** — walker said *"needs separate
    translate at layout time, documented-limitation"*. Reality: 8 lines in
    `FlexEngine.solve`'s in-flow loop applying the inset as a paint-time
    offset.

  First-impression diagnosis is often wrong about the layer where the fix
  lives. **Fix > defer** if the trace points at a contained change.
- **The rendering script is deterministic.** Same input → same pixels. No
  `Date()`, async ordering, random IDs, or fonts that vary by host. Re-renders
  must produce clean diffs, not noise — otherwise step 7's churn is
  indistinguishable from real changes.
- **Spec is the source of truth, not the current renderer.** Every expected
  output prediction anchors in CSS / JoyDOM spec semantics, never in "what
  JoyDOM currently does." Any divergence is either a sample-design issue or an
  implementation bug — that's exactly what the walk is designed to surface.
- **For min/max clamp predictions, use the CSS "freeze and re-resolve"
  algorithm.** When an item hits a min-size (or max-size), it is **frozen** at
  that size and the overflow / free space is then **re-resolved** over the
  remaining flexible items. It is NOT the naive "redistribute the clamped
  item's excess proportionally" intuition. Example from the `flexShrink` walk:
  in `with-min-width.json` red clamps at minWidth 100; the remaining ~8px of
  inner space is then re-flowed across green + blue → **100/66/66** (not the
  naive 100/116/116). Mispredicting this is the most common spec-algorithm
  mistake in flex walks; double-check any sample that exercises a clamp.
- **±1px subpixel rounding is expected and acceptable.** Pixel-sampled widths
  routinely show 57/58/57 where the prediction was 57/57/57, or 83 where the
  prediction was 84. Anything larger is a real divergence worth investigating,
  not noise. Document the tolerance in your verdict — don't silently accept
  larger gaps.

---

## Steps

### 0. Section scaffold-prep PR (one-time per Section)

> **Run once per Tracker Section (Flexbox, Layout & Positioning, Box Model,
> etc.) — NOT per property.** If you're starting the first walk under a brand-
> new top-level folder (`flexbox/`, `layout/`, `boxmodel/`, …), or the
> existing `Resources/<section>/` only holds flat-file stubs from initial
> seeding, do a scaffold-prep PR before firing any walkers.

When N walkers fire in parallel against a Section, they all want to:
- Migrate the same flat stubs (`layout/position.json`) into per-property
  subfolders (`layout/position/overview.json`).
- Create the same `Tests/JoyDOMTests/PropertyCoverage/<Section>/<section>.swift`
  test class.
- Edit overlapping `manifest.json` entries to point at the new paths.

Doing this work N times in parallel produces guaranteed race conditions and
manifest conflicts at PR-open. Doing it once up-front, in a small "chore"
PR, gives every walker a clean tree to work from. The Layout batch on May 13
proved this out: PR #50 was a ~3-minute scaffold PR that eliminated all
race conditions for the 6 parallel walkers that followed.

#### Scaffold-prep checklist

```bash
git checkout -b chore/<section>-section-scaffold

# 1. Create per-property subfolders + move flat stubs to <subfolder>/overview.json
mkdir -p Sources/JoyDOMSampleSpecs/Resources/<section>/<prop1> \
         Sources/JoyDOMSampleSpecs/Resources/<section>/<prop2> \
         …
git mv Sources/JoyDOMSampleSpecs/Resources/<section>/<prop1>.json \
       Sources/JoyDOMSampleSpecs/Resources/<section>/<prop1>/overview.json
# … repeat for each stub …

# 2. Update manifest.json `file` field for each migrated stub (targeted sed
#    to preserve the file's existing \u-escape convention — don't reserialize
#    the whole file with json.dump):
sed -i '' "s|\"file\": \"<section>/<prop1>.json\"|\"file\": \"<section>/<prop1>/overview.json\"|" \
         Sources/JoyDOMSampleSpecs/Resources/manifest.json

# 3. Create empty test class skeleton at
#    Tests/JoyDOMTests/PropertyCoverage/<Section>/<section>.swift:
#
#    final class <Section>SnapshotTests: XCTestCase {
#        // Walkers append their test methods below.
#    }

# 4. Validate:
swift test --filter "SpecPropertySamplesTests"

# 5. PR + merge.
```

**Gate:** Every property under the Section has a subfolder with the existing
stub renamed to `overview.json`. Manifest reflects new paths. Test class
skeleton exists. `SpecPropertySamplesTests` still passes.

---

### 1. Scope the property

**1a. Read the spec — the canonical one.** Fetch the property's row from the
[JoyDOM CSS spec](https://github.com/j0yhq/joy-dom/blob/main/apps/website/content/docs/css.mdx)
(the `.mdx` table is the source of truth). The accepted values listed in the
`Type` column define the **complete** set of cases this property is allowed
to exercise. Anything the iOS FlexLayout primitive *could* render but the
spec doesn't list (e.g. `flexDirection: 'row-reverse'`) is **out of scope**
for the cross-platform sample set.

Also read the corresponding row in
[`Spec-Property-Reference.md`](Spec-Property-Reference.md) for JoyDOM-specific
notes and any documented limitations.

```bash
# Quick fetch when offline / for inclusion in PR descriptions:
gh api repos/j0yhq/joy-dom/contents/apps/website/content/docs/css.mdx \
  --jq '.content' | base64 -d | grep -A2 "^| <prop>"
```

**1b. Enumerate use cases — bounded by the spec.** Cross every spec-allowed
value with the bucket list below. Skip any combination whose value isn't in
the spec. Most spec-bounded properties produce 15–25 samples total; fewer if
the value set is narrow (e.g. `boxSizing` only has one allowed value:
`'border-box'`).

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

**1c. iOS extensions (if any).** If the iOS implementation supports values the
JoyDOM spec doesn't list (e.g. `row-reverse`, `column-reverse`), enumerate
those separately. They get their own folder, their own test method, and
**do not appear** in the cross-platform Notion table. See Step 2 for layout.

**Gate:** A written list of sample filenames, split into two groups: in-scope
(spec-aligned) and ios-ext (if any).

---

### 2. Author sample JSONs

Spec-aligned samples (the cross-platform ones) land at:
```
Sources/JoyDOMSampleSpecs/Resources/flexbox/<prop-kebab>/<sample-kebab>.json
```

iOS-only extension samples (Step 1c) — if any — land at:
```
Sources/JoyDOMSampleSpecs/Resources/flexbox/<prop-kebab>-ios-ext/<sample-kebab>.json
```

The two folders are siblings. The snapshot helper's prefix filter
(`hasPrefix("flexbox/<prop-kebab>/")`) keeps them separated automatically.

#### Design rules

- **`display: flex` is mandatory on every flex container.** The JoyDOM CSS spec
  defines `display` as `'flex' | 'none'` — there is no implicit flex layout.
  JoyDOM-swift will render flex children even when `display: flex` is omitted,
  but the sample is spec-malformed and JS/Kotlin runtimes will not match.
  Always declare it explicitly on `#root` (and on every nested flex container).
  See [`JoyDOM-Spec-Allowlist.md`](JoyDOM-Spec-Allowlist.md) for the grep
  recipe you can run before recording baselines.
- **One concept per sample.** A `with-grow.json` that also tweaks
  `justify-content` hides which thing the snapshot proves.
- **Make the property visually dominant.** If a CSS default swallows the
  declaration (e.g. `align-content: stretch` redistributing space and hiding
  a `gap: 8`), the snapshot doesn't prove anything. Caught this in
  `flex-direction/with-wrap.json` — patched it with explicit
  `alignContent: flex-start` so the row-gap actually shows.
- **For cross-axis properties (`alignItems`, `alignSelf`), at least one sample
  must have varied cross-axis item dimensions.** If every item has the same
  cross-axis size, the cross-axis line size equals each item's size and the
  alignment override has nothing to align *against* — the snapshot collapses
  to flex-start regardless of declared value. Surfaced by `alignSelf/with-wrap.json`
  (originally 4 equal-height boxes, fixed to mixed heights — see "What we
  learned running parallel walkers" below).
- **Container dimensions must fit inside the snapshot viewport.** A
  container wider than `viewportWidth` (or taller than `height`) will be
  clipped at the viewport edge, hiding the property's effect off-canvas.
  Surfaced by `flexWrap/in-column.json` (originally 320px container on a
  240px viewport — clipped the wrapped second column). Step 4's grep recipe
  catches this before recording.
- **Avoid class names that lexically collide with CSS keywords.** `.fixed`,
  `.sticky`, `.absolute`, `.inline`, `.block`, `.dashed`, etc. as class names
  trip up greps that screen for out-of-spec values (e.g. `position: "fixed"`)
  and confuse readers scanning JSON. Use behavioural names like `.no-shrink`,
  `.pinned`, `.dashed-border` — anything that doesn't read like a property
  value.
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

See the [Appendix](#appendix--reusable-snippets) for copy-paste starters and
[`JoyDOM-Spec-Allowlist.md`](JoyDOM-Spec-Allowlist.md) for the canonical list
of every property + value JoyDOM samples may use.

**Gate:** Every filename from Step 1 has a JSON.

---

### 3. Add manifest entries

> **Order matters: manifest before validation.** `SpecPropertySamplesTests`
> iterates `SpecPropertySamples.all`, which is populated from the manifest.
> Files not yet in the manifest are silently skipped by the validator — so
> running Step 4 first against un-manifested JSONs produces a misleading
> "all green" with zero coverage of your new samples.

For each spec-aligned JSON, add to
`Sources/JoyDOMSampleSpecs/Resources/manifest.json`:

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

For an iOS-only extension JSON (Step 1c / Step 2 second folder):

```json
{
  "id": "flexbox-<prop-kebab>-ios-ext-<sample-kebab>",
  "file": "flexbox/<prop-kebab>-ios-ext/<sample-kebab>.json",
  "category": "Flexbox",
  "property": "<propCamelCase>-iOSExt",
  "summary": "iOS-ext <value>: <description> (not in JoyDOM spec; covered only by the iOS FlexLayout primitive)",
  "snapshot": { ... }
}
```

The `-iOSExt` suffix on `property` and the "not in spec" preamble on
`summary` make the boundary explicit when scanning the manifest.

#### Picking viewport size

- Width: just enough to make the layout obvious. A row of 4×60px boxes
  totals ~296px → `viewportWidth: 400` leaves comfortable margin without
  dwarfing content.
- Height: matches natural extent — ~120 for row layouts, ~360 for column.
- For breakpoint-flip samples, the **narrow** viewport goes here; the wide
  viewport is captured by a separate `<Prop>ResponsiveWide` test method.

**Gate:** Every JSON has a manifest entry.

---

### 4. Schema validation

Now that the manifest references every new file, run the validator:

```bash
swift test --filter "SpecPropertySamplesTests"
```

This decodes each manifested sample as a `Spec`, walks it through
`RuleBuilder` + `StyleTreeBuilder`, and reports missing keys, malformed
breakpoints, unknown property names, or cascade-time failures. **No
`try? JSONDecoder()` swallowing errors** — every failure must be addressed
before rendering.

Also run the [allowlist grep recipe](JoyDOM-Spec-Allowlist.md#quick-sanity-check-for-a-finished-sample)
against your new JSONs to catch missing `display: flex` and any out-of-spec
values (`row-reverse`, `wrap-reverse`, `alignContent`, etc.) before they
become baselines.

#### Container-fits-viewport sanity check

Each sample's root container width/height must be ≤ the manifest's
`viewportWidth` / `height`. Otherwise the container clips at the viewport
edge and the off-canvas portion isn't tested. Quick Python check:

```bash
python3 <<'EOF'
import json, glob
m = json.load(open('Sources/JoyDOMSampleSpecs/Resources/manifest.json'))
for s in m['samples']:
    if not s['file'].startswith('flexbox/<prop-kebab>/'): continue
    spec = json.load(open(f"Sources/JoyDOMSampleSpecs/Resources/{s['file']}"))
    root = spec.get('style', {}).get('#root', {})
    w = root.get('width', {}).get('value') if isinstance(root.get('width'), dict) else None
    h = root.get('height', {}).get('value') if isinstance(root.get('height'), dict) else None
    vw, vh = s['snapshot']['viewportWidth'], s['snapshot']['height']
    if w and w > vw: print(f"  CLIP: {s['file']} width={w} > viewport={vw}")
    if h and h > vh: print(f"  CLIP: {s['file']} height={h} > viewport={vh}")
EOF
```

Empty output = clean. Any printed line is a sample whose container is
larger than its snapshot viewport — fix before recording. (Surfaced this
on `flexWrap/in-column.json` which originally had a 320px container in a
240px viewport.)

**Gate:** Validator passes for all samples; allowlist grep produces no hits; container-fits-viewport check is clean.

---

### 5. Render & screenshot (the script)

#### Wire up the test methods

In `Tests/JoyDOMTests/PropertyCoverage/Flexbox/flexbox.swift`, add the
spec-aligned method:

```swift
func test<PropCamelCase>() {
    assertSnapshotsForSamples(in: "flexbox/<prop-kebab>")
}
```

If iOS extensions exist (Step 1c), add a sibling method that walks the
`*-ios-ext/` folder — this is the regression seam for iOS-only behavior
that shouldn't bleed into cross-platform coverage:

```swift
/// iOS-only extensions of `<prop>` (e.g. `row-reverse`, `column-reverse`).
///
/// These values are NOT in the JoyDOM CSS spec (which restricts
/// `<prop>` to `<spec-values>`), but the underlying FlexLayout primitive
/// supports them. Kept in a sibling folder so the iOS code path stays
/// regression-tested without polluting the cross-platform sample set —
/// JS/Kotlin runtimes won't implement these and shouldn't compare against
/// the corresponding baselines.
func test<PropCamelCase>IosExt() {
    assertSnapshotsForSamples(in: "flexbox/<prop-kebab>-ios-ext")
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
4. **Pixel-samples for precision** (Python + PIL).

   > **Harness caveat:** in some Claude-Code sandboxes `python3 --version`
   > works but `python3 <script>` is blocked by permissions. Three walkers
   > in the parallel-walker batch (`alignItems`, `alignSelf`, `flexBasis`)
   > hit this. If you're in that mode: **multimodal `Read` on each PNG is
   > an accepted fallback for integer-positioned predictions** (most flex
   > samples produce integer widths because the FlexEngine rounds box
   > sizes to the nearest pixel). Use the predicted positions as a guide
   > and compare visually. ±2px subpixel tolerance for visual review vs.
   > ±1px for PIL. Document which mode you used in your AI-review verdict.

   **Preferred technique: colored-run scan** — scans a horizontal (or
   vertical) line through the rendered boxes and auto-detects each colored
   run's span. Scales across all samples in a folder without hand-tuning
   coordinates per sample. The `flexShrink` walk used this to verify 20
   baselines in one shot:

   ```python
   from PIL import Image
   COLORS = {"red":(232,44,53),"green":(27,174,110),
             "blue":(47,105,243),"amber":(240,141,14)}
   def color_at(px):
       r,g,b,*_ = px
       for name,(cr,cg,cb) in COLORS.items():
           if abs(r-cr)<=12 and abs(g-cg)<=12 and abs(b-cb)<=12: return name
       return None
   def find_runs(path, scan_y_viewport):
       img = Image.open(path); px = img.load(); w,h = img.size
       y = int(scan_y_viewport * 2)   # viewport→retina
       runs, cur, start = [], None, 0
       for x in range(w):
           c = color_at(px[x, y])
           if c != cur:
               if cur in COLORS: runs.append((cur, start/2, (x)/2))
               cur, start = c, x
       if cur in COLORS: runs.append((cur, start/2, w/2))
       return runs
   # Example: scan mid-box-height
   for color, x_start, x_end in find_runs(".../sample.png", 46):
       print(f"  {color} viewport_x=[{x_start:.1f}..{x_end:.1f}] width={x_end-x_start:.1f}")
   ```

   For column-direction samples, swap to a vertical scan at a fixed x.

   **Fallback: targeted pixel samples** — when colored-run scanning won't
   resolve a question (e.g. verifying a single non-colored property like
   `borderColor`), drop to direct pixel reads:

   ```python
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

#### Coverage-parity scan

Before declaring the review complete, **diff your sample folder against the
two or three most recent walks' folders**:

```bash
ls Sources/JoyDOMSampleSpecs/Resources/flexbox/<new-prop>/ | sort > /tmp/new
ls Sources/JoyDOMSampleSpecs/Resources/flexbox/<prior-prop>/ | sort > /tmp/prior
diff /tmp/prior /tmp/new
```

Any sample the prior walk had that yours doesn't — either justify the
omission (e.g. `flex-grow/with-shrink.json` mirrors as `flex-shrink/with-grow.json`,
same concept under a different name) or **add it now**. The `flexShrink` walk
missed `nested.json` on the first pass; the gap was only found post-merge
during a final review. Catching parity gaps here saves a follow-up PR.

Append findings to the triaged list from Step 6. Don't fix yet — just triage.

**Gate:** Combined AI + human issue list, fully triaged with one of the four
tags above. Coverage-parity diff inspected and either matched or justified.

---

### 8. Fix all issues

Work through the triaged list. **Group commits by category** so the diff
narrates the work:

```
fix(view|engine|resolver|registry): <one-line summary>     # bug-in-impl
fix(samples): <one-line summary>                            # bug-in-sample
docs(tracker): <prop> limitation — <one-line>               # documented-limitation
```

#### Triage subtree: `bug-in-impl` vs `documented-limitation`

When you find an impl divergence from CSS spec, the triage decision matters
more than the label — picking `documented-limitation` for a fixable bug
means future readers will leave it broken. Use this decision tree:

```
Did the AI/human review find a divergence from CSS spec?
│
├── Can the impl be brought to spec with a contained change (<50 LOC,
│   one or two source files)? ──── yes ──► bug-in-impl
│   │                                       fix in the SAME PR (see below)
│   │                                       no documented-limitation entry
│   │
│   └─ no ──► Is the fix genuinely cross-module (>200 LOC, multiple
│             frameworks, requires API redesign)?
│             │
│             ├── yes ──► documented-limitation, with a deferred-fix
│             │           tracking issue + short Tracker note about scope
│             │
│             └── no ──► STOP. Probe deeper. Most "cross-module refactors"
│                       turn out to be 5-20 LOC changes once the actual
│                       code path is traced. Don't tag deferred without
│                       first attempting the minimum-viable fix (see
│                       Principles).
│
└── Is the divergence intrinsic to the platform or testing methodology
    (SwiftUI semantics that don't render offscreen, snapshot-testing
    blind spots, etc.)? ──── yes ──► documented-limitation
                                     The impl signals correct intent;
                                     the limitation is in the rendering /
                                     testing environment, not JoyDOM.
                                     Example: `overflow:scroll` indicators
                                     don't paint in static snapshots
                                     regardless of `.scrollIndicators(.visible)`.
```

Two May-13 cases where this triage went wrong on first pass and right on
second:

| Walker first-pass | Reality after probe |
|---|---|
| ZIDX-1: "documented-limitation, cross-module Layout-protocol refactor" | bug-in-impl, **1 line** in `JoyDOMView.applyItem` |
| Insets §9.4: "documented-limitation, needs separate translate at layout time" | bug-in-impl, **8 lines** in `FlexEngine.solve`'s in-flow loop |

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

If a bug is genuinely too deep for this PR (verified by deep trace, not
just first-impression), spawn a separate task. Don't let one deep dive
sink the property's coverage PR — but per the triage subtree above, defer
only when investigation confirms the scope.

#### Fix-in-same-PR sub-sequence for `bug-in-impl`

When the bug fix is contained (the common case after the May-13 batch),
land it in the same PR as the coverage walk. The commit chain that has
been working:

```
1. fix(<scope>): <impl change>                        # the actual fix
2. test(<prop>): re-record N baselines after fix      # post-fix re-record
3. docs(tracker): <prop> ✅ (no limitation) after fix # tracker promotion
```

Tracker mechanics for the third commit:
- Flip the property's row from ⚠️ (if it was the walker's initial pass) to ✅.
- Remove any entry the walker added to the "Bugs surfaced during the walk"
  table — the bug is now resolved within this PR's scope.
- Remove any entry the walker added to the "Documented limitations" table.
- Add a notes-column blurb capturing both the bug found and the fix applied,
  with a reference to the regression-seam sample that proves it (see the
  insets and zIndex Notes columns for the established phrasing).

**Why land the fix in the coverage PR?** Per the "Baselines are immutable
artifacts. Do not promote until the sample AND the implementation are both
verified correct" principle: a baseline that captures the buggy rendering
is worse than no baseline at all — it locks the bug in until someone
notices. Re-recording in the same PR aligns the sample, baseline, and impl
on the correct CSS behavior.

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

### 10. Update Tracker, push, PR, merge

#### 10a. Update Tracker (bundle into the same PR)

Flip the property's row in `docs/Property-Coverage-Tracker.md` from ⬜ to ✅
(or ⚠️ if limitations were documented) **in the same PR as the samples**.
Both prior walks (`flexDirection`, `flexGrow`, `flexShrink`) bundled the
tracker flip into the coverage PR rather than as a follow-up commit. Fill in:

- **Samples** column: `value-sweep / edges / contexts / interactions` count.
- **Tests delta** column: count of **new** PNG files created. If
  `overview.png` already existed on `main` and you didn't re-record it, it
  doesn't count toward this number (e.g. `flexShrink` shipped 18 new sample
  PNGs + 1 nested + 1 responsive-wide = **+20 baselines**, not +21).
- **Date** column: today's date.
- **Notes** column: noteworthy bugs surfaced, limitations, sample-design
  quirks, and which CSS invariants the walk verified.

Bug entries get rows in the "Bugs surfaced during the walk" table at the
bottom; limitations get rows in "Documented limitations."

#### 10b. Branch, push, PR

> **Check for branch-name collisions first.** Locked agent worktrees on prior
> sessions can hold conventional branch names hostage. Run
> `git worktree list | grep <intended-branch>` — if a locked worktree owns
> the name, pick a fresh one (e.g. `test/<prop>-coverage` instead of
> `test/<prop>-l2-l3`) rather than forcing through with `--force`.

```bash
git push -u origin test/<prop-kebab>-coverage
gh pr create --title "test(<prop-kebab>): property coverage walk — <N> samples" \
             --body "<see below>"
```

PR body must include:
- Sample count by bucket (value sweep / edges / contexts / interactions)
- Bugs found and fixed (link each commit)
- Sample patches with rationale (link each commit)
- Known limitations deferred (link Tracker rows)
- One-line summary of the property's verified behavior
- Confirmation that the [allowlist grep](JoyDOM-Spec-Allowlist.md#quick-sanity-check-for-a-finished-sample)
  passed (display:flex present everywhere, no out-of-spec values)
- Note that Notion URLs pin to the branch HEAD SHA (Step 11) and will need
  a post-merge re-pin if the source branch is deleted (see Step 10c)

> **Stop at PR-open. Do NOT self-merge.** When the walk runs as a background
> agent, leave the merge to the human reviewer. Parallel walkers create
> overlapping edits to `manifest.json`, `flexbox.swift`, and the tracker —
> merging is the human's serialization point for conflict resolution. The
> `flexWrap` walker in the May-13 parallel batch self-merged and produced
> a one-off out-of-sequence main commit; every other walker correctly
> stopped at PR-open.

> **Merge-sequencing cost estimate (parallel batches).** The first PR in a
> parallel batch merges clean; every subsequent PR conflicts on the same
> three files (`manifest.json`, `<section>.swift`'s end-of-file, and
> `Property-Coverage-Tracker.md` rows). Resolutions are mechanical (keep
> both sides, append in stable order). **Reserve ~5-10 minutes per
> follow-up PR** for the rebase + conflict-resolve + push-pinned + merge
> cycle. The Layout batch on May 13 sequenced 6 PRs through this dance in
> roughly an hour total.

#### 10c. Capture merge SHA + restore branch SHA for Notion durability

After merge to `main`, **capture the merge commit SHA**:

```bash
git checkout main && git pull --ff-only origin main && git rev-parse main
```

This is the merge commit SHA — use it for PR-body references and post-merge
audits.

**For Notion image URL durability**, your DB pins to whichever SHA was the
branch HEAD when the agent created the DB. If your branch is:
- **Rebased before merge** (force-pushed during conflict resolution) — the
  pre-rebase HEAD SHA gets replaced on the remote and the Notion URL breaks.
- **Squash-merged with `--delete-branch`** — the branch HEAD SHA becomes
  unreachable on the remote when the branch is deleted; Notion URLs break.

The fix is to push the original SHA back as a `-pinned` ref so GitHub keeps
the commit reachable:

```bash
# After the rebase/merge dust settles, restore the SHA the Notion DB references:
git push origin <original-branch-head-sha>:refs/heads/test/<prop>-coverage-pinned
```

**This pattern is battle-tested.** Across the Flexbox batch (7 walks) and
the Layout batch (6 walks + 2 impl-bug fixes), every Notion DB stayed live
through the merge-sequencing cycle via this `-pinned` ref approach. No
broken image previews. Trust the recipe.

Or, simpler: **don't pass `--delete-branch` and don't rebase**. If the PR
merges clean and the branch sticks around at its original SHA, no post-merge
pin is needed (the `justifyContent` PR #44 went this route on May 13).

**Gate:** PR merged. Merge SHA captured. Tracker reflects the new ✅. If the
branch was rebased or deleted, a `-pinned` ref points at the SHA the Notion
DB images reference (verify by clicking through one image preview in Notion).

---

### 11. Create Notion table

New database under the [JoyDom property comparison parent page](https://www.notion.so/joyfill/35edef37c9a080da8bc8d0c06cd30c67).

> **Only spec-aligned samples go in this table.** The table represents what
> JS, Kotlin, and Swift runtimes must all produce identical pixels for. iOS-only
> extension samples (`*-ios-ext/`) do **not** appear here. If you want to
> document them for the iOS team, create them as standalone child pages under
> the parent page — that's where the `flexDirection` walk parked
> `row-reverse` and `column-reverse` after the scope split.

#### Schema

```sql
CREATE TABLE (
  "Template" TITLE,
  "Swift" FILES,
  "JS" RICH_TEXT,
  "Kotlin" RICH_TEXT
)
```

- `Template` — sample's basename
- `Swift` — hot-linked GitHub raw URL to the iOS-rendered PNG (column may also
  be called "iOS UI" in older databases — both refer to the same artifact)
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
- `Swift`: just the raw GitHub URL string. When creating pages via the Notion
  MCP `notion-create-pages` tool, pass `"Swift": "https://raw.githubusercontent.com/..."`
  — Notion wraps it into the FILES format automatically. No need to construct
  the `file://%7B...%7D` percent-encoded blob you'll see when reading existing
  rows back.

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

#### Idempotency — check for existing pages before bulk-create

`notion-create-pages` can return what looks like a cached response (or a
successful-but-orphaned create). If you retry, you may end up with two
copies of every page. The `order` DB in the May-13 batch ended up with
**40 pages where 20 were expected** because the walker retried after a
spurious failure. To prevent:

```
1. Run notion-search on the data source URL before any bulk create.
2. If the result count is non-zero, compare Template names against your
   planned row list and only create the missing ones.
3. If you must retry a partial create, query first to learn which
   Templates already landed.
```

Duplicates are cosmetic — both copies render correctly — but they clutter
the DB and make per-row updates harder. If you spot duplicates after the
fact, leave them; the MCP doesn't expose a delete-page tool.

#### Sub-agent permission caveat

If you delegate the DB rebase/update to a sub-agent via the `Agent` tool,
**the sub-agent does NOT inherit the parent's auto-approve permission
state**. `notion-update-page` will be denied. Do bulk Notion ops in the
parent context, or pre-authorize the sub-agent's tools via
`.claude/settings.json` (see `update-config` skill). Surfaced during the
May-13 batch: an order-DB rebase sub-agent hit `Permission denied` on
every update-page call.

**Gate:** One row per sample, image previews loading, JSON code blocks in
each row's body. No duplicate rows.

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

Two implementation bugs, one sample-design issue, and one scope mismatch,
captured here as a reality check: a typical first walk surfaces 2–4 such
findings. Expect them.

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

4. **Out-of-spec values (`row-reverse`, `column-reverse`)** (commit
   `620ea4d7`) — three samples used `flexDirection` values the iOS FlexLayout
   primitive supports but the [JoyDOM CSS spec](https://github.com/j0yhq/joy-dom/blob/main/apps/website/content/docs/css.mdx)
   restricts to `'row' | 'column'`. Caught by cross-referencing every sample's
   property values against the spec table after the initial walk. Moved 2
   samples to `flex-direction-ios-ext/` (kept iOS regression coverage but out
   of the cross-platform set); rewrote `with-justify-end.json` to use
   spec-valid `column` instead of `column-reverse`. Notion table now reflects
   only the 22 spec-aligned rows; the 2 reverse-direction pages live as
   standalone children of the parent Notion page. **Tag:** `out-of-scope`.
   **The "test only what the spec supports" principle in this doc is the
   prevention for next time.**

---

## What we learned running this on `flexShrink`

Zero implementation bugs surfaced — but the walk produced several
process-level findings that landed as edits to this very document. Captured
here as a reference for what a clean walk looks like and which corners are
easy to cut:

1. **CSS clamp algorithm tripped the AI prediction.** On `with-min-width`
   (red `minWidth: 100`), I predicted 100/116/116 by the naive "redistribute
   the clamped item's excess" intuition. The spec-correct answer is
   **100/66/66**: red freezes at 100, then green + blue re-shrink against
   the smaller residual free space. Surfaced the "freeze and re-resolve"
   principle now in the Principles section.

2. **Step 3 / Step 4 ordering was misleading.** The previous version told
   walkers to run schema validation before adding manifest entries — but
   the validator only iterates manifested samples, so the "all green" was
   meaningless. Swapped: now manifest is Step 3, validation is Step 4.

3. **`display: flex` was implicit-but-mandatory.** JoyDOM-swift renders flex
   children even when the property is omitted, so several existing samples
   on `main` got away with it. The spec defines `display` strictly as
   `'flex' | 'none'`, and JS / Kotlin runtimes will not auto-flex. Added
   the explicit mandate to Step 2 design rules and shipped a sibling
   [`JoyDOM-Spec-Allowlist.md`](JoyDOM-Spec-Allowlist.md) with a grep
   recipe authors run before recording baselines.

4. **Hand-coded pixel coordinates didn't scale.** The original PIL example
   hardcoded `(92, 92, 'red box center')` per sample. With 20 samples of
   variable widths, that was painful. The colored-run-scan technique now in
   Step 6 verifies all 20 baselines in one Python script.

5. **`nested.json` parity gap missed until post-merge.** The first PR didn't
   include a nested-flex sample even though `flexDirection` had one. Added
   the coverage-parity-scan step to Step 7 so future walks `diff` their
   sample folder against a prior walk's before opening the PR.

6. **`.fixed` class name collided with `position: fixed`.** A grep recipe
   that screens for out-of-spec values false-positives on className arrays
   containing reserved CSS keywords. Cosmetic, but worth avoiding — added
   to Step 2 design rules.

7. **Branch name held hostage by a locked agent worktree.** The
   conventional `test/flex-shrink-l2-l3` was owned by an abandoned worktree
   from an earlier session. Pivoted to `test/flex-shrink-coverage` rather
   than forcing the lock open. Added a worktree-collision check to Step 10.

**Tag distribution:** 0 `bug-in-impl`, 0 `bug-in-sample`, 0 `out-of-scope`,
0 `documented-limitation` — but **7 `process-improvement`** findings, all
folded back into this document.

---

## What we learned running 7 parallel walkers (2026-05-13)

Seven coverage walks (`flexBasis`, `justifyContent`, `alignItems`, `alignSelf`,
`flexWrap`, `gap`/`rowGap`/`columnGap`, `order`) fired in parallel as
background agents, each producing a PR + Notion DB. Combined output:
**~140 new sample JSONs, 6 PRs opened, 6 Notion DBs created, 0 implementation
bugs surfaced**. The walks themselves were clean; the parallelism uncovered
process gaps.

1. **Python harness blocks `python3 <script>` in some sandboxes.** Three of
   seven walkers (`alignItems`, `alignSelf`, `flexBasis`) reported that
   `python3 --version` was permitted but executing a script wasn't, blocking
   the canonical PIL colored-run scan. They fell back to multimodal `Read`
   inspection of PNGs against numerical predictions — equivalent rigor for
   integer-positioned samples, lower precision for subpixel. Step 6 now
   explicitly accepts that fallback (±2px tolerance).

2. **Cross-axis sample sizing must vary across items.** `alignSelf/with-wrap.json`
   originally used four equal-height boxes. With all flex lines at the same
   cross-axis size, `alignSelf` had nothing to align *against* — the override
   collapsed to flex-start regardless of declared value. Caught during AI
   review; fixed by mixing 80px and 40px heights. Step 2 design rules now
   require varied cross-axis dimensions for cross-axis property samples.

3. **Container must fit inside the snapshot viewport.** `flexWrap/in-column.json`
   declared a 320px container on a 240px viewport — the second wrapped column
   was clipped off-canvas. Step 4 now has a Python grep that scans manifest
   entries and flags container ≥ viewport mismatches.

4. **Notion image URLs break after rebase + squash-merge + branch delete.**
   Every walker pinned its DB to the branch HEAD SHA at create time. The
   merge sequence on May 13 surfaced three failure modes:
   - **Squash-merge with `--delete-branch`** removes the branch tip, GitHub
     loses the original SHA on remote → image URLs 404.
   - **Rebase + force-push during conflict resolution** replaces the original
     branch HEAD on remote → original SHA unreachable on remote.
   - **Clean merge without rebase or branch delete** (PR #44) — branch
     stays at original SHA → URLs keep working.

   The fix codified in Step 10c: `git push origin <orig-sha>:refs/heads/<branch>-pinned`
   restores the SHA on remote as a separate ref. Applied to PRs #42, #43,
   #45, #47, #48 during the May-13 merge cycle.

5. **Agent self-merge breaks the human serialization point.** The `flexWrap`
   walker self-merged its PR (#46). The other six correctly stopped at
   PR-open. Step 10b now explicitly forbids agent self-merge — parallel
   walkers create overlapping edits to `manifest.json` / `flexbox.swift` /
   tracker, and the human needs to control merge ordering to resolve
   conflicts.

6. **Sub-agents don't inherit parent's auto-approve permissions.** A focused
   sub-agent spawned mid-merge-cycle to rebase Notion URLs hit
   `Permission denied` on every `notion-update-page` call. Sub-agent
   sandboxes are independent. Step 11 now flags this — do bulk Notion ops
   in the parent context (or pre-authorize tools in
   `.claude/settings.json`).

7. **Notion `create-pages` can duplicate on retry.** The `order` DB ended
   up with **40 pages where 20 were expected** because the walker retried
   after what looked like a failed create. Step 11 now requires a
   `notion-search` pass over the data source before bulk-creating, and
   only adding missing Template names.

8. **`rowGap` / `columnGap` are writing-mode-oriented, not flex-axis-oriented.**
   Common misprediction. In `flexDirection: column`, `rowGap` becomes the
   main-axis (vertical) spacing; `columnGap` is a no-op in a column flex
   container with no wrap. Verified by the gap walker; documented in the
   Spec-Allowlist gap row.

**Tag distribution across the 7 walkers:** 0 `bug-in-impl`, 2 `bug-in-sample`
(both auto-detected during the walker's own AI review and patched before
PR-open), 0 `out-of-scope`, 0 `documented-limitation` — but **8 process-
improvement findings** (this section + the changes referenced above).

---

## What we learned running the Layout & Positioning batch (2026-05-13)

Six parallel walkers (`position`, `display`, `boxSizing`, `zIndex`,
`overflow`, `insets`) for Section 2. Two real impl bugs surfaced and were
fixed in their respective coverage PRs; one was a clean documented
limitation; three were clean walks. The batch produced six process
findings that became this update.

1. **"Deferred bug" was over-applied.** ZIDX-1 ("requires Layout-protocol
   painter-order sort, cross-module refactor") turned out to be a one-line
   `.zIndex(_:)` chain in `JoyDOMView.applyItem`. The CSS §9.4 insets
   "documented-limitation" turned out to be 8 lines in `FlexEngine.solve`.
   Walkers under-probe before tagging deferred. Added the
   "minimum-viable-fix probe" principle to counter-pressure premature
   deferral, and the Step 8 triage subtree to distinguish fixable bugs from
   intrinsic limitations.

2. **The bug-fix-in-coverage-PR pattern works.** Both impl bugs were
   landed in the same PRs as their coverage walks via the 3-commit
   sequence (fix → re-record → tracker promote). The "Baselines are
   immutable artifacts" principle from the original walkthrough was the
   key guidance: a baseline that captures buggy output is worse than no
   baseline. Re-recording in the same PR after the fix gets sample,
   baseline, and impl aligned on the correct CSS behavior. Step 8 now
   documents the commit chain and tracker mechanics explicitly.

3. **The scaffold-prep PR pattern eliminated race-condition conflicts.**
   PR #50 took ~3 minutes to set up per-property subfolders + the empty
   `Layout/layout.swift` class. The 6 walkers that followed had zero
   structural-file conflicts at PR-open (only the expected end-of-file
   manifest/tracker/test-method overlap at merge time, which is mechanical).
   Now codified as Step 0 — run once per Section.

4. **One walker did identify a true documented-limitation correctly.**
   The `overflow` walker flagged that `clip`/`scroll`/`auto` render byte-
   equivalent to `hidden` in static snapshots. Investigation confirmed
   this is intrinsic — SwiftUI's offscreen `ScrollView` doesn't paint
   indicators even with `.scrollIndicators(.visible)`. The impl signals
   correct intent; the limitation is in the testing methodology, not
   JoyDOM. This is the right shape of "documented-limitation": a snapshot-
   testing methodology artifact, not a code defect.

5. **Notion `-pinned` ref pattern stayed reliable.** Across all 6 Layout
   walks plus the in-PR fixes (which rebased branches and re-recorded
   baselines), every Notion DB stayed live via the pre-rebase `-pinned`
   ref. Pattern is now battle-tested.

6. **Merge sequencing is predictable.** First PR merges clean; every
   subsequent PR conflicts on `manifest.json` / `<section>.swift` /
   `Property-Coverage-Tracker.md`. The conflicts are mechanical (keep both
   sides, append). Total cost for the 6-PR Layout batch was ~1 hour.

**Tag distribution across the 6 walkers (after triage corrections):**
- 0 `bug-in-impl` deferred (the 2 walkers that initially tagged deferred
  both saw their bugs fixed in the same PR after the minimum-viable-fix
  probe)
- 2 `bug-in-impl` fixed-in-PR (ZIDX-1, CSS §9.4 insets)
- 1 `bug-in-sample` (boxSizing `equal-outer-size`, self-fixed during the
  walker's own AI review)
- 0 `out-of-scope`
- 1 `documented-limitation` (overflow indicator-rendering in static
  snapshots — intrinsic to SwiftUI's offscreen render of `ScrollView`)
- 6 `process-improvement` findings (this section + the doc changes above)
