# Property-by-Property Test Coverage — Plan & Workflow

**Branch:** `test/spec-property-coverage` (cut from `main`).
**Goal:** Walk every CSS property in the canonical [`j0yhq/joy-dom`](https://github.com/j0yhq/joy-dom) spec, verify the iOS implementation matches CSS semantics for every legal value and reasonable edge / interaction, fix divergences as they surface, and lock the verified behaviour in with both layout-assertion and snapshot tests.

**Spec anchor:** commit `765acfda` (2026-05-06).

**Status going in:** all 48 spec-sanctioned Style fields parse and resolve through the cascade. 5 are documented as ⚠️ partial. PR #28 has shipped one value-sweep sample per property in `Sources/JoyDOMSampleSpecs/Resources/<category>/<property>.json`. This plan expands from that baseline to comprehensive per-property verification.

**Dependencies:**
- ✅ Cascade + resolver tests already pass for every field (`StyleFieldTranslationTests`, `BreakpointResolverTests`, etc.) — these stay untouched
- 🔵 PR #27 (`docs/spec-coverage`) and PR #28 (`feat/spec-property-browser`) should land before this branch starts producing property work, so the test target can `import JoyDOMSampleSpecs` and the manual checklist in `Spec-Test-Plan.md` is current

---

## Goals

1. Every spec property has a **value-sweep** JSON sample (✅ shipped in PR #28)
2. Every spec property has 2-3 additional JSON samples covering **edge values**, **container contexts**, and **property interactions**
3. Every spec property has at least one **cascade-assertion test** (resolve the spec, assert ComputedStyle has the expected value)
4. Every spec property with visible rendering has at least one **snapshot test** (render once, save baseline image, re-render to catch pixel regressions)
5. Every divergence found during manual testing has either a fix or a documented regression test
6. A **tracker** (`docs/Property-Coverage-Tracker.md`) records progress per property: date, edge cases found, bugs filed/fixed, test count

## Non-goals

- Re-testing data-only behaviour already covered by unit tests (Codable round-trip, selector parsing, cascade specificity, breakpoint matching)
- Adding new properties or extending the spec
- Performance benchmarking
- iPad / tvOS / watchOS specific rendering (snapshot tests run on iOS simulator only for now)

---

## Phase 0 — Snapshot test infrastructure

**Why first:** the bugs we hit in PRs #20, #21, #26 (objectFit fill, breakpointVisibility slots invisible, _DOMImage alignment) were all visual regressions that unit tests against `some View` returns couldn't catch. Snapshot testing closes that gap and is the single biggest leverage for the rest of this work.

**Add to Package.swift** as a test-only dependency:

```swift
dependencies: [
    .package(
        url: "https://github.com/pointfreeco/swift-snapshot-testing",
        from: "1.17.0"
    ),
],
...
.testTarget(
    name: "JoyDOMTests",
    dependencies: [
        "JoyDOM",
        "JoyDOMSampleSpecs",
        .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
    ],
    path: "Tests/JoyDOMTests"
)
```

**Add a helper** at `Tests/JoyDOMTests/Snapshot/JoyDOMSnapshotHelpers.swift`:

```swift
import XCTest
import SnapshotTesting
import SwiftUI
@testable import JoyDOM

extension XCTestCase {
    /// Render a JoyDOM Spec at a fixed viewport width and snapshot it.
    func assertSnapshot(
        spec: Spec,
        viewportWidth: CGFloat = 800,
        height: CGFloat = 600,
        named name: String? = nil,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line
    ) {
        let view = JoyDOMView(spec: spec)
            .viewport(.init(width: viewportWidth))
            .frame(width: viewportWidth, height: height)
        assertSnapshot(
            of: view,
            as: .image(precision: 0.99, perceptualPrecision: 0.97),
            named: name,
            file: file,
            testName: testName,
            line: line
        )
    }
}
```

**Snapshot directory:** `Tests/JoyDOMTests/Snapshot/__Snapshots__/` (git-tracked).

**Done criteria for Phase 0:** one demo snapshot test passes (use `helloWorld` sample to verify the harness works), CI is green, baseline image committed.

---

## Per-property workflow template

Apply this to every property in the matrix below. Target time: **30–60 min per property**.

### Step 1 — Audit existing coverage (5 min)

```bash
# Find existing samples
ls Sources/JoyDOMSampleSpecs/Resources/<category>/ | grep <property>

# Find existing tests
grep -rn "<property>" Tests/JoyDOMTests/
```

Note what's already there.

### Step 2 — Author edge / context / interaction samples (15-25 min)

Add JSON files to `Sources/JoyDOMSampleSpecs/Resources/<category>/`:

- `<property>-edges.json` — zero, negative, very large, missing (default), unit-less if applicable
- `<property>-contexts.json` — same value in row vs column container, narrow vs wide viewport, OR split into `<property>-in-row.json` / `<property>-in-column.json` if the diff is large
- `<property>-with-<other>.json` — pair with 1-2 closely-related properties

Add manifest entries in `Resources/manifest.json`. Match the existing summary style.

### Step 3 — Manual test in the demo (5-10 min)

1. `swift run FlexDemoApp`
2. Spec Property Browser → category → each new sample
3. Confirm rendering matches CSS spec expectation. Drag viewport slider through any breakpoints.
4. Note any divergence. Take a screenshot if it's surprising.

### Step 4 — Fix or document divergence (variable)

For each divergence:
- **Fix it on the spot** if scope is contained (≤30 LoC). Add a regression test in the same commit.
- **File an issue** with reproducer JSON + expected vs actual + suggested fix. Add to the `## Known divergences` section of this doc.
- **Document the limitation** in source if it's a SwiftUI quirk we've decided to leave (like the `objectFit:none` alignment case).

### Step 5 — Write automation (10-15 min)

In `Tests/JoyDOMTests/PropertyCoverage/<Category>Tests.swift` (one file per category):

```swift
// Cascade assertion — required for every property
func test_<property>_<value>_landsOnComputedStyle() throws {
    let spec = try decode(SpecPropertySamples.sample(withID: "<category>-<property>")!.json)
    let computed = resolve(spec, nodeID: "<expected-id>")
    XCTAssertEqual(computed.<path>, <expected>)
}

// Snapshot — required for every property with visible rendering
func test_<property>_<value>_renders() throws {
    let spec = try decode(SpecPropertySamples.sample(withID: "<category>-<property>")!.json)
    assertSnapshot(spec: spec, viewportWidth: 800)
}

// Layout assertion — for flex/sizing properties where geometry is testable
func test_<property>_<value>_geometry() throws {
    // ... assert via FlexLayout's measure output if reachable from test target
}
```

For interaction samples, add a test per interaction.

### Step 6 — Update the tracker (2 min)

In `docs/Property-Coverage-Tracker.md`:

- Date tested
- Sample count (value-sweep / edges / contexts / interactions)
- Test count delta
- Bugs filed / fixed
- Status: ✅ done / ⚠️ partial-with-doc-limitation / 🔴 blocker

### Step 7 — Commit (per property OR per category)

Per property if the diff is small (one new sample + one test file edit), per category if the work groups naturally (e.g. all six padding/margin/border properties at once).

Commit message template:
```
test(<category>): comprehensive <property> coverage

- <N> new JSON samples (edges, contexts, interactions)
- <M> cascade assertions in <Category>Tests.swift
- <K> snapshot tests, baselines in __Snapshots__/
- (Fixed: <bug if any>)
- (Doc: <limitation if any>)
```

---

## Property walk order

Ordered by impact × risk × cohesion. Each row is roughly half a day of focused work.

| # | Category | Properties (count) | Why this order | Estimated time |
|---|---|---|---|---|
| 0 | **Infrastructure** | swift-snapshot-testing dep + helper + 1 baseline | Prerequisite for everything | 2-3 hr |
| 1 | **Flexbox** | flexDirection, flexGrow, flexShrink, flexBasis, justifyContent, alignItems, alignSelf, flexWrap, gap/rowGap/columnGap, order (12) | Highest-traffic features; many interact; PR #21's freeze-and-redistribute work needs end-to-end snapshots | 1 day |
| 2 | **Layout & Positioning** | position, display, boxSizing, zIndex, overflow, top/left/bottom/right (9) | Underpins absolute layering; PR #25's box-sizing deduction has no visual sample | 1 day |
| 3 | **Box Model & Visuals** | backgroundColor, opacity, padding, margin, borderWidth, borderColor, borderStyle, borderRadius (8) | PR #21's true flex margin needs visual proofs; border-style ext (dashed/dotted/double) has zero rendering tests | 1 day |
| 4 | **Sizing** | width, height, min/max (6) | Smaller surface; mostly cascade-asserted already | half day |
| 5 | **Typography** | fontFamily, fontSize, fontWeight, fontStyle, color, textDecoration, textAlign, textTransform, lineHeight, letterSpacing (10) | Many ⚠️ partial cases here (lineHeight, letterSpacing em, fontWeight bands) | 1 day |
| 6 | **Text Behavior** | textOverflow, whiteSpace (2) | Pair with Typography; verify ellipsis preconditions document |  half day |
| 7 | **Media** | objectFit, objectPosition (2) | Heavy lifting already done in PR #26; this phase closes the `none + objectPosition` alignment limitation if possible | half day |
| 8 | **Selectors** | type, class, id, compound, descendant, child, +, ~ (8) | Mostly unit-tested; add 1 visual sample per combinator for snapshot regression | half day |
| 9 | **Cascade** | Document → Breakpoint → inline; specificity; multi-class source order (3) | Unit-tested; add 1 snapshot per behaviour | quarter day |
| 10 | **Breakpoints** | width, orientation, print, and/or/not, per-node-overrides, deep-merge, custom-order, custom-visibility, classname-swap (10) | PR #25 + PR #26 shipped most samples; this phase adds snapshots at narrow + wide viewports for each one | 1 day |
| 11 | **Patterns** | BackgroundImages wrapper, ellipsis preconditions (2) | Wrap-up; visual proof of canonical recipes | quarter day |

**Total estimated:** ~6 working days. Realistic with interruptions: 8-10 days, spread over 2-3 weeks.

---

## Bug-fix policy during the walk

If manual testing surfaces a divergence:

| Scope of fix | Action |
|---|---|
| ≤30 LoC, no architectural change | Fix on the spot in the property's commit |
| 30-200 LoC OR touches FlexLayout engine | File issue + add `XCTSkip` regression test + flag in `## Known divergences` |
| Requires spec clarification | Comment on j0yhq/joy-dom + skip the test case + flag in this doc |

Don't let a single property block the rest of the walk. Each phase ships independently.

---

## Tracker

Live tracker at `docs/Property-Coverage-Tracker.md` — created in Phase 0 with an empty checklist for all 11 categories. Update Step 6 of every property walk.

Tracker columns:
- Property
- Date walked
- Value-sweep / edges / contexts / interactions sample counts
- Cascade tests / snapshot tests
- Bugs filed / fixed
- Status emoji

---

## Per-PR cadence

| What | When |
|---|---|
| PR 1 — Phase 0 infrastructure | swift-snapshot-testing dep, helper, 1 baseline, empty tracker doc, this plan doc |
| PR 2 — Flexbox category | All 12 flexbox properties walked end-to-end |
| PR 3 — Layout category | All 9 layout properties |
| PR 4 — Box model category | All 8 box-model properties |
| PR 5-11 — One per remaining category | … |
| PR 12 — Wrap-up | Tracker finalised, summary of fixes/limitations published as `docs/Property-Coverage-Summary.md` |

Total: ~12 PRs over 2-3 weeks. Each PR is reviewable in 30-60 min by a colleague.

---

## Done criteria for the whole project

- Every category in the tracker shows ✅ done or ⚠️ partial-with-documented-limitation
- Snapshot baseline directory has 100+ images
- Test count delta: +200-300 tests vs. the start
- All bugs surfaced during the walk either fixed or have a regression test that asserts the current behaviour (no silent divergences)
- `docs/Property-Coverage-Summary.md` published with: properties tested, divergences fixed, limitations documented, follow-up items for engine/SwiftUI work
- All open PRs merged
