# JoyDOM Swift — Spec Property Reference

A per-property reference for the JoyDOM Swift implementation, anchored to the canonical [`j0yhq/joy-dom`](https://github.com/j0yhq/joy-dom) spec.

| | |
|---|---|
| Spec commit | `765acfda0243648c97c4f198e5d1c8e4d88bfc0f` ("Work on media specs") |
| Spec date | 2026-05-06 |
| Spec sources | `spec.ts`, `guides/CSS.md`, `guides/Styles.md`, `guides/TextStyles.md`, `guides/Breakpoints.md`, `guides/BackgroundImages.md` |
| Local impl | `Sources/JoyDOM/Model/Spec.swift`, `Sources/JoyDOM/Cascade/StyleResolver.swift`, `Sources/JoyDOM/Views/JoyDOMView.swift` |

## Reading this doc

Each category opens with a short intro and a single capability table. The columns mean:

- **Property** — the field name as it appears in `spec.ts`.
- **Spec values** — the legal type / value list verbatim from `spec.ts`.
- **iOS impl** — `✅` + the Swift type that models it. `⚠️ ext` prefixes mean joydom-swift accepts more values than the canonical spec (e.g. `flex-direction: row-reverse`). `❌` means not modeled.
- **Works** — `✅` reaches the renderer correctly, `⚠️` ships with a known caveat, `❌` is broken / unimplemented.
- **Test coverage** — XCTest names that pin the behavior. `❌` = no dedicated test.
- **JSON template** — anchor link into the appendix for that category, where every legal value is shown in a runnable `Spec` snippet.

JSON snippets follow the on-the-wire `Spec` shape (`version: 1`, `style: { selector: Style }`, `breakpoints: [...]`, `layout: Node`). Lengths use the typed object form `{ "value": N, "unit": "px" }` — never bare numbers.

> **Spec extensions ship knowingly.** joydom-swift accepts a wider value set than `spec.ts` for a handful of fields (e.g. `position: fixed | sticky`, `flexDirection: row-reverse`, `borderStyle: dashed | dotted | double`, `display: block | inline | inline-block | inline-flex | none`, `alignItems: baseline`, `flexWrap: wrap-reverse`, `alignContent`). These extras land for forward-compat with future spec growth; producers targeting the canonical spec should avoid them. They're flagged inline as `⚠️ ext`.

---

## 1. Layout & Positioning

Positioning, display mode, box-sizing semantics, stacking, overflow, and absolute-position offsets. Spec sanctions only two `position` keywords (`absolute | relative`); joydom-swift extends with `fixed | sticky` (rendered as `absolute` + warning diagnostic).

| Property | Spec values | iOS impl | Works | Test coverage | JSON template |
|---|---|---|---|---|---|
| `position` | `'absolute' \| 'relative'` | ⚠️ ext `Position` (also `fixed`, `sticky` → fall back to `absolute`) | ⚠️ `fixed` / `sticky` warn + render as `absolute` | `testPositionRelative`, `testPositionAbsolute`, `testPositionFixedFallsBackToAbsolute`, `testPositionStickyFallsBackToAbsolute`, `testPositionFixedEmitsDiagnostic`, `testPositionStickyEmitsDiagnostic` | [→ position](#position) |
| `display` | `'flex'` | ⚠️ ext `Display` (also `block`, `inline`, `inline-block`, `inline-flex`, `none`) | ⚠️ `inline-flex` substitutes `flex` + warns; `none` hides | `testDisplayFlex`, `testDisplayBlock`, `testDisplayInlineBlockMapsToInline`, `testDisplayInlineMapsToInline`, `testDisplayInlineFlexMapsToFlex`, `testDisplayNoneSetsIsDisplayNone`, `testDisplayInlineFlexEmitsDiagnostic` | [→ display](#display) |
| `boxSizing` | `'border-box'` | ✅ `Style.BoxSizing` | ⚠️ `border-box` + percentage width/height with non-zero padding/border can't be deducted at cascade time and emits a diagnostic | `testBoxSizingBorderBoxRoundTripsThroughCodable`, `testBoxSizingDecodesFromHyphenatedString`, `testBoxSizingBorderBoxFlowsAllTheWayToFlexLayoutAsAdjustedWidth`, `testBorderBoxDeductsBorderAndPaddingOnMainAxis` (+ ~25 more in `BoxSizingTests`) | [→ boxSizing](#boxsizing) |
| `zIndex` | `number` | ✅ `Int` | ✅ | `testZIndex` | [→ zIndex](#zindex) |
| `overflow` | `'visible' \| 'hidden' \| 'clip' \| 'scroll' \| 'auto'` | ✅ `Overflow` | ✅ writes both container + item overflow | `testOverflowEachValue`, `testOverflowAlsoMirrorsToItem` | [→ overflow](#overflow) |
| `top` | `Length<'px'>` | ✅ `Length` | ✅ | `testTopBottomLeftRightOffsetsLandOnEdges` | [→ inset](#inset-top--left--bottom--right) |
| `left` | `Length<'px'>` | ✅ `Length` | ✅ | `testTopBottomLeftRightOffsetsLandOnEdges` | [→ inset](#inset-top--left--bottom--right) |
| `bottom` | `Length<'px'>` | ✅ `Length` | ✅ | `testTopBottomLeftRightOffsetsLandOnEdges` | [→ inset](#inset-top--left--bottom--right) |
| `right` | `Length<'px'>` | ✅ `Length` | ✅ | `testTopBottomLeftRightOffsetsLandOnEdges` | [→ inset](#inset-top--left--bottom--right) |

### Templates — Layout & Positioning

#### `position`
```json
{
  "version": 1,
  "style": {
    "#absolute-card": { "position": "absolute", "top": { "value": 0, "unit": "px" }, "left": { "value": 0, "unit": "px" } },
    "#relative-card": { "position": "relative" }
  },
  "breakpoints": [],
  "layout": {
    "type": "div",
    "props": { "id": "root" },
    "children": [
      { "type": "div", "props": { "id": "relative-card" } },
      { "type": "div", "props": { "id": "absolute-card" } }
    ]
  }
}
```

#### `display`
```json
{
  "version": 1,
  "style": {
    "#flex-row":     { "display": "flex", "flexDirection": "row" },
    "#hidden-node":  { "display": "none" }
  },
  "breakpoints": [],
  "layout": {
    "type": "div",
    "props": { "id": "flex-row" },
    "children": [
      { "type": "div", "props": { "id": "hidden-node" } },
      { "type": "p", "children": ["Visible sibling"] }
    ]
  }
}
```

#### `boxSizing`
```json
{
  "version": 1,
  "style": {
    "#border-box-card": {
      "boxSizing": "border-box",
      "width":  { "value": 100, "unit": "px" },
      "padding": { "value": 8,  "unit": "px" },
      "borderWidth": { "value": 4, "unit": "px" },
      "borderColor": "#000000",
      "borderStyle": "solid"
    }
  },
  "breakpoints": [],
  "layout": { "type": "div", "props": { "id": "border-box-card" } }
}
```

#### `zIndex`
```json
{
  "version": 1,
  "style": {
    "#bg":    { "position": "absolute", "zIndex": 0 },
    "#fg":    { "position": "absolute", "zIndex": 1 }
  },
  "breakpoints": [],
  "layout": {
    "type": "div",
    "props": { "id": "stack", "style": { "position": "relative" } },
    "children": [
      { "type": "div", "props": { "id": "bg" } },
      { "type": "div", "props": { "id": "fg" } }
    ]
  }
}
```

#### `overflow`
```json
{
  "version": 1,
  "style": {
    "#visible": { "overflow": "visible" },
    "#hidden":  { "overflow": "hidden" },
    "#clip":    { "overflow": "clip" },
    "#scroll":  { "overflow": "scroll" },
    "#auto":    { "overflow": "auto" }
  },
  "breakpoints": [],
  "layout": {
    "type": "div",
    "props": { "id": "root" },
    "children": [
      { "type": "div", "props": { "id": "visible" } },
      { "type": "div", "props": { "id": "hidden"  } },
      { "type": "div", "props": { "id": "clip"    } },
      { "type": "div", "props": { "id": "scroll"  } },
      { "type": "div", "props": { "id": "auto"    } }
    ]
  }
}
```

#### Inset (`top` / `left` / `bottom` / `right`)
```json
{
  "version": 1,
  "style": {
    "#pinned": {
      "position": "absolute",
      "top":    { "value": 8,  "unit": "px" },
      "left":   { "value": 16, "unit": "px" },
      "bottom": { "value": 8,  "unit": "px" },
      "right":  { "value": 16, "unit": "px" }
    }
  },
  "breakpoints": [],
  "layout": {
    "type": "div",
    "props": { "id": "frame", "style": { "position": "relative" } },
    "children": [{ "type": "div", "props": { "id": "pinned" } }]
  }
}
```

---

## 2. Sizing

Width / height plus min / max constraints. `width` and `height` accept px or `%`; the four min / max fields are px-only per spec.

| Property | Spec values | iOS impl | Works | Test coverage | JSON template |
|---|---|---|---|---|---|
| `width` | `Length<'px' \| '%'>` | ✅ `Length` | ✅ | `testWidthPxAndPercent` | [→ width / height](#width--height) |
| `height` | `Length<'px' \| '%'>` | ✅ `Length` | ✅ | `testHeightPxAndPercent` | [→ width / height](#width--height) |
| `minWidth` | `Length<'px'>` | ✅ `Length` | ✅ | `testMinMaxWidthRoundTripIntoItemStyle`, `testMinMaxSizingRoundTrip`, `testMinMaxMapsToItemStyle`, `testMinMaxPropagateThroughFlexEngine` | [→ min/max sizing](#min--max-sizing) |
| `maxWidth` | `Length<'px'>` | ✅ `Length` | ✅ | `testMinMaxWidthRoundTripIntoItemStyle`, `testMinMaxPropagateThroughFlexEngine` | [→ min/max sizing](#min--max-sizing) |
| `minHeight` | `Length<'px'>` | ✅ `Length` | ✅ | `testMinMaxHeightRoundTripIntoItemStyle`, `testMinMaxPropagateThroughFlexEngine` | [→ min/max sizing](#min--max-sizing) |
| `maxHeight` | `Length<'px'>` | ✅ `Length` | ✅ | `testMinMaxHeightRoundTripIntoItemStyle`, `testMinMaxPropagateThroughFlexEngine` | [→ min/max sizing](#min--max-sizing) |

### Templates — Sizing

#### `width` / `height`
```json
{
  "version": 1,
  "style": {
    "#fixed":   { "width": { "value": 200, "unit": "px" }, "height": { "value": 120, "unit": "px" } },
    "#fluid":   { "width": { "value": 100, "unit": "%"  }, "height": { "value": 50,  "unit": "%"  } }
  },
  "breakpoints": [],
  "layout": {
    "type": "div",
    "props": { "id": "root", "style": { "flexDirection": "row" } },
    "children": [
      { "type": "div", "props": { "id": "fixed" } },
      { "type": "div", "props": { "id": "fluid" } }
    ]
  }
}
```

#### Min / max sizing
```json
{
  "version": 1,
  "style": {
    "#elastic": {
      "width":     { "value": 50,  "unit": "%"  },
      "minWidth":  { "value": 120, "unit": "px" },
      "maxWidth":  { "value": 480, "unit": "px" },
      "height":    { "value": 50,  "unit": "%"  },
      "minHeight": { "value": 80,  "unit": "px" },
      "maxHeight": { "value": 320, "unit": "px" }
    }
  },
  "breakpoints": [],
  "layout": { "type": "div", "props": { "id": "elastic" } }
}
```

---

## 3. Flexbox

Container axis controls (`flexDirection`, `justifyContent`, `alignItems`, `flexWrap`, gap), per-item growth (`flexGrow`, `flexShrink`, `flexBasis`, `alignSelf`, `order`). Spec sanctions only `row | column` for direction and `nowrap | wrap` for wrap; joydom-swift extends with the reverse keywords plus `alignItems: baseline`, `alignSelf: baseline`, and the entire `alignContent` axis (not in `spec.ts`).

| Property | Spec values | iOS impl | Works | Test coverage | JSON template |
|---|---|---|---|---|---|
| `flexDirection` | `'row' \| 'column'` | ⚠️ ext `Style.FlexDirection` (also `row-reverse`, `column-reverse`) | ✅ | `testFlexDirectionRow`, `testFlexDirectionColumn`, `testFlexDirectionRowReverseMapsToFlexLayoutRowReverse`, `testFlexDirectionColumnReverseMapsToFlexLayoutColumnReverse` | [→ flexDirection](#flexdirection) |
| `flexGrow` | `number` | ✅ `Double` | ✅ | `testFlexGrowFractional` | [→ flexGrow / flexShrink](#flexgrow--flexshrink) |
| `flexShrink` | `number` | ✅ `Double` | ✅ | `testFlexShrinkExplicitZeroOverridesDefault`, `testFlexShrinkNonZero` | [→ flexGrow / flexShrink](#flexgrow--flexshrink) |
| `flexBasis` | `Length<'px' \| '%'> \| 'auto'` | ✅ `FlexBasisValue` | ✅ | `testFlexBasisPxPoints`, `testFlexBasisPercentFraction`, `testFlexBasisAutoMapsToFlexAuto`, `testFlexBasisLengthMapsToPoints` | [→ flexBasis](#flexbasis) |
| `justifyContent` | `'flex-start' \| 'flex-end' \| 'center' \| 'space-between' \| 'space-around' \| 'space-evenly'` | ✅ `Style.JustifyContent` | ✅ | `testJustifyContentEachValue`, `testJustifyContentSpaceEvenlyMapsToContainer` | [→ justifyContent](#justifycontent) |
| `alignItems` | `'flex-start' \| 'flex-end' \| 'center' \| 'stretch'` | ⚠️ ext `Style.AlignItems` (also `baseline`) | ✅ | `testAlignItemsEachValue`, `testAlignItemsBaselineMapsToFlexLayoutBaseline`, `testAlignItemsStretchMapsToContainer` | [→ alignItems](#alignitems) |
| `alignSelf` | `'auto' \| 'flex-start' \| 'flex-end' \| 'center' \| 'stretch'` | ⚠️ ext `Style.AlignSelf` (also `baseline`) | ✅ | `testAlignSelfMapsToItemStyle`, `testAlignSelfBaselineMapsToFlexLayoutBaseline` | [→ alignSelf](#alignself) |
| `flexWrap` | `'nowrap' \| 'wrap'` | ⚠️ ext `Style.FlexWrap` (also `wrap-reverse`) | ✅ | `testFlexWrapNowrap`, `testFlexWrapWrap`, `testFlexWrapWrapReverseMapsToFlexLayoutWrapReverse` | [→ flexWrap](#flexwrap) |
| `gap` | `Length<'px'>` | ✅ `Gap` (uniform or per-axis `{ c, r }`) | ✅ | `testGapUniformSetsTopLevelGap`, `testGapAxesSetsRowAndColumnSeparately`, `testGapUniformEncodesAsLength`, `testGapAxesEncodesWithCAndR` | [→ gap](#gap) |
| `rowGap` | `Length<'px'>` | ✅ `Length` | ✅ | `testRowGapMapsToContainer`, `testRowColumnGapOverrideUniformGap` | [→ rowGap / columnGap](#rowgap--columngap) |
| `columnGap` | `Length<'px'>` | ✅ `Length` | ✅ | `testColumnGapMapsToContainer`, `testRowColumnGapOverrideUniformGap` | [→ rowGap / columnGap](#rowgap--columngap) |
| `order` | `number` | ✅ `Int` | ✅ | `testOrder`, `testBreakpointOrderOverrideAppliesAtMatchingViewport`, `testRemovingOrderFromBreakpointRestoresPrimaryOrder` | [→ order](#order) |
| (extension) `alignContent` | not in `spec.ts` | ⚠️ ext `Style.AlignContent` (`flex-start`, `flex-end`, `center`, `space-between`, `space-around`, `space-evenly`, `stretch`) | ✅ ships, no spec coverage | `testAlignContentEachValueMapsThrough` | [→ alignContent](#aligncontent-extension) |

### Templates — Flexbox

#### `flexDirection`
All four values (`row` and `column` are spec; `row-reverse` and `column-reverse` are joydom-swift extensions):
```json
{
  "version": 1,
  "style": {
    "#row":            { "flexDirection": "row" },
    "#col":            { "flexDirection": "column" },
    "#row-reverse":    { "flexDirection": "row-reverse" },
    "#col-reverse":    { "flexDirection": "column-reverse" }
  },
  "breakpoints": [],
  "layout": {
    "type": "div",
    "props": { "id": "row" },
    "children": [
      { "type": "div", "props": { "id": "col"         } },
      { "type": "div", "props": { "id": "row-reverse" } },
      { "type": "div", "props": { "id": "col-reverse" } }
    ]
  }
}
```

#### `flexGrow` / `flexShrink`
```json
{
  "version": 1,
  "style": {
    "#fixed":  { "flexGrow": 0, "flexShrink": 0, "width": { "value": 80, "unit": "px" } },
    "#fill":   { "flexGrow": 1, "flexShrink": 1 },
    "#fast":   { "flexGrow": 2, "flexShrink": 0.5 }
  },
  "breakpoints": [],
  "layout": {
    "type": "div",
    "props": { "id": "row", "style": { "flexDirection": "row" } },
    "children": [
      { "type": "div", "props": { "id": "fixed" } },
      { "type": "div", "props": { "id": "fill"  } },
      { "type": "div", "props": { "id": "fast"  } }
    ]
  }
}
```

#### `flexBasis`
```json
{
  "version": 1,
  "style": {
    "#auto":     { "flexBasis": "auto" },
    "#px-basis": { "flexBasis": { "value": 120, "unit": "px" } },
    "#pct-basis":{ "flexBasis": { "value": 40,  "unit": "%"  } }
  },
  "breakpoints": [],
  "layout": {
    "type": "div",
    "props": { "id": "row", "style": { "flexDirection": "row" } },
    "children": [
      { "type": "div", "props": { "id": "auto"     } },
      { "type": "div", "props": { "id": "px-basis" } },
      { "type": "div", "props": { "id": "pct-basis"} }
    ]
  }
}
```

#### `justifyContent`
```json
{
  "version": 1,
  "style": {
    "#start":   { "flexDirection": "row", "justifyContent": "flex-start" },
    "#end":     { "flexDirection": "row", "justifyContent": "flex-end" },
    "#center":  { "flexDirection": "row", "justifyContent": "center" },
    "#between": { "flexDirection": "row", "justifyContent": "space-between" },
    "#around":  { "flexDirection": "row", "justifyContent": "space-around" },
    "#evenly":  { "flexDirection": "row", "justifyContent": "space-evenly" }
  },
  "breakpoints": [],
  "layout": { "type": "div", "props": { "id": "start" } }
}
```

#### `alignItems`
```json
{
  "version": 1,
  "style": {
    "#start":    { "flexDirection": "row", "alignItems": "flex-start" },
    "#end":      { "flexDirection": "row", "alignItems": "flex-end" },
    "#center":   { "flexDirection": "row", "alignItems": "center" },
    "#stretch":  { "flexDirection": "row", "alignItems": "stretch" },
    "#baseline": { "flexDirection": "row", "alignItems": "baseline" }
  },
  "breakpoints": [],
  "layout": { "type": "div", "props": { "id": "start" } }
}
```
> `baseline` is a joydom-swift extension — not in `spec.ts`. Producers targeting the canonical spec should stick to the four sanctioned keywords.

#### `alignSelf`
```json
{
  "version": 1,
  "style": {
    "#auto":     { "alignSelf": "auto" },
    "#start":    { "alignSelf": "flex-start" },
    "#end":      { "alignSelf": "flex-end" },
    "#center":   { "alignSelf": "center" },
    "#stretch":  { "alignSelf": "stretch" },
    "#baseline": { "alignSelf": "baseline" }
  },
  "breakpoints": [],
  "layout": {
    "type": "div",
    "props": { "id": "row", "style": { "flexDirection": "row", "alignItems": "stretch" } },
    "children": [
      { "type": "div", "props": { "id": "auto"     } },
      { "type": "div", "props": { "id": "start"    } },
      { "type": "div", "props": { "id": "end"      } },
      { "type": "div", "props": { "id": "center"   } },
      { "type": "div", "props": { "id": "stretch"  } },
      { "type": "div", "props": { "id": "baseline" } }
    ]
  }
}
```

#### `flexWrap`
```json
{
  "version": 1,
  "style": {
    "#nowrap":       { "flexDirection": "row", "flexWrap": "nowrap" },
    "#wrap":         { "flexDirection": "row", "flexWrap": "wrap" },
    "#wrap-reverse": { "flexDirection": "row", "flexWrap": "wrap-reverse" }
  },
  "breakpoints": [],
  "layout": { "type": "div", "props": { "id": "wrap" } }
}
```
> `wrap-reverse` is a joydom-swift extension.

#### `gap`
```json
{
  "version": 1,
  "style": {
    "#uniform-gap":    { "flexDirection": "row", "flexWrap": "wrap", "gap": { "value": 12, "unit": "px" } },
    "#per-axis-gap":   { "flexDirection": "row", "flexWrap": "wrap",
                          "gap": { "c": { "value": 12, "unit": "px" }, "r": { "value": 24, "unit": "px" } } }
  },
  "breakpoints": [],
  "layout": { "type": "div", "props": { "id": "uniform-gap" } }
}
```

#### `rowGap` / `columnGap`
```json
{
  "version": 1,
  "style": {
    "#grid": {
      "flexDirection": "row",
      "flexWrap": "wrap",
      "rowGap":    { "value": 16, "unit": "px" },
      "columnGap": { "value": 8,  "unit": "px" }
    }
  },
  "breakpoints": [],
  "layout": { "type": "div", "props": { "id": "grid" } }
}
```

#### `order`
```json
{
  "version": 1,
  "style": {
    "#first":  { "order": 1 },
    "#second": { "order": 2 },
    "#third":  { "order": 3 }
  },
  "breakpoints": [],
  "layout": {
    "type": "div",
    "props": { "id": "row", "style": { "flexDirection": "row" } },
    "children": [
      { "type": "div", "props": { "id": "third"  } },
      { "type": "div", "props": { "id": "first"  } },
      { "type": "div", "props": { "id": "second" } }
    ]
  }
}
```

#### `alignContent` (extension)
Not in `spec.ts` — joydom-swift accepts and forwards. Authors targeting the canonical spec should avoid this field.
```json
{
  "version": 1,
  "style": {
    "#wrap-grid": {
      "flexDirection": "row",
      "flexWrap": "wrap",
      "alignContent": "space-between"
    }
  },
  "breakpoints": [],
  "layout": { "type": "div", "props": { "id": "wrap-grid" } }
}
```

---

## 4. Box Model & Visuals

Background, opacity, padding, margin, and border properties. Hex-only colors per `Styles.md` (no `rgb` / `rgba`). `padding`, `margin`, and `borderRadius` accept either a uniform `Length` or a per-side / per-corner object.

| Property | Spec values | iOS impl | Works | Test coverage | JSON template |
|---|---|---|---|---|---|
| `backgroundColor` | `string` (hex) | ✅ `String` | ✅ | `testBackgroundColorMapsToVisual`, `testBackgroundColorRoundTrip` | [→ backgroundColor](#backgroundcolor) |
| `opacity` | `number` (0–1) | ✅ `Double` | ✅ | `testOpacityMapsToVisual`, `testOpacityRoundTrip` | [→ opacity](#opacity) |
| `padding` | `Length<'px'> \| { top, right, bottom, left }` | ✅ `Padding` enum | ✅ | `testPaddingUniformSetsAllSides`, `testPaddingSidesAppliesPerSide`, `testPaddingUniformEncodesAsLength`, `testPaddingSidesEncodesWithFourKeys` | [→ padding](#padding) |
| `margin` | `Length<'px'> \| { top, right, bottom, left }` | ✅ `Padding` enum (reused) | ✅ lands on item, not visual | `testMarginUniformLandsOnItemNotVisual`, `testMarginPerSideLandsOnItem`, `testMarginUniformRoundTrip`, `testMarginSidesRoundTrip`, `testMarginMapsToItem` | [→ margin](#margin) |
| `borderWidth` | `Length<'px'>` | ✅ `Length` | ✅ | `testBorderMapsToVisual`, `testBorderPropertiesRoundTrip` | [→ border](#border-width--color--style) |
| `borderColor` | `string` (hex) | ✅ `String` | ✅ | `testBorderMapsToVisual`, `testBorderPropertiesRoundTrip` | [→ border](#border-width--color--style) |
| `borderStyle` | `'solid' \| 'none'` | ⚠️ ext `Style.BorderStyleProp` (also `dashed`, `dotted`, `double`) | ✅ | `testSolidRoundTripsToVisualStyle`, `testNoneRoundTripsToVisualStyle`, `testDashedRoundTripsToVisualStyle`, `testDottedRoundTripsToVisualStyle`, `testDoubleRoundTripsToVisualStyle`, `testJoyDOMViewBuildsBodyForDashedBorder`, `testJoyDOMViewBuildsBodyForDottedBorder`, `testJoyDOMViewBuildsBodyForDoubleBorder` | [→ borderStyle](#borderstyle) |
| `borderRadius` | `Length<'px'> \| { topLeft?, topRight?, bottomRight?, bottomLeft? }` | ✅ `BorderRadius` enum | ✅ | `testBorderRadiusUniformRoundTrip`, `testBorderRadiusCornersRoundTrip`, `testBorderRadiusPartialCornersRoundTrip`, `testBorderRadiusMapsToVisual` | [→ borderRadius](#borderradius) |

### Templates — Box Model & Visuals

#### `backgroundColor`
```json
{
  "version": 1,
  "style": {
    "#card": { "backgroundColor": "#FF8800" }
  },
  "breakpoints": [],
  "layout": { "type": "div", "props": { "id": "card" } }
}
```

#### `opacity`
```json
{
  "version": 1,
  "style": {
    "#fully-visible": { "opacity": 1 },
    "#half":          { "opacity": 0.5 },
    "#hidden":        { "opacity": 0 }
  },
  "breakpoints": [],
  "layout": {
    "type": "div",
    "props": { "id": "row", "style": { "flexDirection": "row" } },
    "children": [
      { "type": "div", "props": { "id": "fully-visible" } },
      { "type": "div", "props": { "id": "half"          } },
      { "type": "div", "props": { "id": "hidden"        } }
    ]
  }
}
```

#### `padding`
```json
{
  "version": 1,
  "style": {
    "#uniform": { "padding": { "value": 16, "unit": "px" } },
    "#sides": {
      "padding": {
        "top":    { "value":  8, "unit": "px" },
        "right":  { "value": 16, "unit": "px" },
        "bottom": { "value":  8, "unit": "px" },
        "left":   { "value": 16, "unit": "px" }
      }
    }
  },
  "breakpoints": [],
  "layout": {
    "type": "div",
    "props": { "id": "uniform" },
    "children": [{ "type": "div", "props": { "id": "sides" } }]
  }
}
```

#### `margin`
Same shape as `padding` — uniform `Length<px>` or per-side object. Lands on the flex item style (not the box visual).
```json
{
  "version": 1,
  "style": {
    "#uniform-m": { "margin": { "value": 12, "unit": "px" } },
    "#sided-m": {
      "margin": {
        "top":    { "value":  4, "unit": "px" },
        "right":  { "value":  8, "unit": "px" },
        "bottom": { "value":  4, "unit": "px" },
        "left":   { "value":  8, "unit": "px" }
      }
    }
  },
  "breakpoints": [],
  "layout": {
    "type": "div",
    "props": { "id": "row", "style": { "flexDirection": "row" } },
    "children": [
      { "type": "div", "props": { "id": "uniform-m" } },
      { "type": "div", "props": { "id": "sided-m"   } }
    ]
  }
}
```

#### Border (`width` / `color` / `style`)
```json
{
  "version": 1,
  "style": {
    "#bordered": {
      "borderWidth": { "value": 2, "unit": "px" },
      "borderColor": "#222244",
      "borderStyle": "solid"
    }
  },
  "breakpoints": [],
  "layout": { "type": "div", "props": { "id": "bordered" } }
}
```

#### `borderStyle`
```json
{
  "version": 1,
  "style": {
    "#solid":  { "borderWidth": { "value": 2, "unit": "px" }, "borderColor": "#000000", "borderStyle": "solid" },
    "#none":   { "borderWidth": { "value": 2, "unit": "px" }, "borderColor": "#000000", "borderStyle": "none" },
    "#dashed": { "borderWidth": { "value": 2, "unit": "px" }, "borderColor": "#000000", "borderStyle": "dashed" },
    "#dotted": { "borderWidth": { "value": 2, "unit": "px" }, "borderColor": "#000000", "borderStyle": "dotted" },
    "#double": { "borderWidth": { "value": 4, "unit": "px" }, "borderColor": "#000000", "borderStyle": "double" }
  },
  "breakpoints": [],
  "layout": { "type": "div", "props": { "id": "solid" } }
}
```
> `dashed`, `dotted`, and `double` are joydom-swift extensions. Spec sanctions only `solid | none`.

#### `borderRadius`
```json
{
  "version": 1,
  "style": {
    "#pill":    { "borderRadius": { "value": 999, "unit": "px" } },
    "#corners": {
      "borderRadius": {
        "topLeft":     { "value": 12, "unit": "px" },
        "topRight":    { "value":  4, "unit": "px" },
        "bottomRight": { "value": 12, "unit": "px" },
        "bottomLeft":  { "value":  4, "unit": "px" }
      }
    }
  },
  "breakpoints": [],
  "layout": {
    "type": "div",
    "props": { "id": "pill" },
    "children": [{ "type": "div", "props": { "id": "corners" } }]
  }
}
```

---

## 5. Typography

Font metadata, color, decoration, alignment, transform, line height, letter spacing. `lineHeight` is a unitless multiplier (matching CSS). `fontWeight` is a string ("normal" / "bold") or a number 100..900.

| Property | Spec values | iOS impl | Works | Test coverage | JSON template |
|---|---|---|---|---|---|
| `fontFamily` | `string` | ✅ `String` | ✅ | `testCustomFontFamilyProducesNonNilFont`, `testCustomFontFamilyDiffersFromSystemFont`, `testSystemFallbackWhenFontFamilyAbsent` | [→ fontFamily](#fontfamily) |
| `fontSize` | `Length<'px'>` | ✅ `Length` | ✅ | `testTypographyMapsToVisual`, `testTypographyRoundTrip` | [→ fontSize](#fontsize) |
| `fontWeight` | `'normal' \| 'bold' \| 100 \| 200 \| ... \| 900` | ✅ `Style.FontWeight` (custom Codable: string OR int) | ✅ | `testFontWeightNamedRoundTrip`, `testFontWeightNumericRoundTrip`, `testFontWeightDecodesNamedStrings`, `testFontWeightDecodesNumbers`, `testWeightAtAndBelow149IsUltraLight` (+8 more in `FontWeightMappingTests`) | [→ fontWeight](#fontweight) |
| `fontStyle` | `'normal' \| 'italic'` | ✅ `Style.FontStyleProp` | ✅ | `testFontStyleItalicCarriesThrough` | [→ fontStyle](#fontstyle) |
| `color` | `string` (hex) | ✅ `String` | ✅ | `testTypographyMapsToVisual` | [→ color](#color) |
| `textDecoration` | `'none' \| 'underline' \| 'line-through'` | ✅ `Style.TextDecoration` | ✅ | `testTextDecorationRoundTrip`, `testTextDecorationLandsInComputedVisualStyle`, `testJoyDOMViewBuildsWithUnderlineOnContainer`, `testJoyDOMViewBuildsWithLineThroughOnContainer`, `testJoyDOMViewBuildsWithNoneDecoration`, `testDecoratedTextBuildsForEachDecoration` | [→ textDecoration](#textdecoration) |
| `textAlign` | `'left' \| 'center' \| 'right'` | ✅ `Style.TextAlign` | ✅ | `testTypographyMapsToVisual` | [→ textAlign](#textalign) |
| `textTransform` | `'none' \| 'uppercase' \| 'lowercase'` | ✅ `Style.TextTransform` | ✅ | `testTypographyMapsToVisual` | [→ textTransform](#texttransform) |
| `lineHeight` | `number` (multiplier) | ✅ `Double` | ✅ | `testLineSpacingMatchesTargetMinusSystem`, `testLineSpacingScalesWithFontSize`, `testLineSpacingZeroForUnitMultiplier` | [→ lineHeight](#lineheight) |
| `letterSpacing` | `Length<'px'>` | ✅ `Length` (also accepts `em` and bare units → resolved via fontSize) | ✅ | `testLetterSpacingPxStaysAbsolute`, `testLetterSpacingEmScalesByFontSize`, `testLetterSpacingEmDefaultsToSeventeenWhenFontSizeUnset` | [→ letterSpacing](#letterspacing) |

### Templates — Typography

#### `fontFamily`
```json
{
  "version": 1,
  "style": {
    "#headline": { "fontFamily": "Georgia", "fontSize": { "value": 24, "unit": "px" } }
  },
  "breakpoints": [],
  "layout": {
    "type": "p",
    "props": { "id": "headline" },
    "children": ["Hello, joy-dom!"]
  }
}
```

#### `fontSize`
```json
{
  "version": 1,
  "style": {
    "#small": { "fontSize": { "value": 12, "unit": "px" } },
    "#body":  { "fontSize": { "value": 16, "unit": "px" } },
    "#h1":    { "fontSize": { "value": 32, "unit": "px" } }
  },
  "breakpoints": [],
  "layout": {
    "type": "div",
    "props": { "id": "root" },
    "children": [
      { "type": "p",  "props": { "id": "small" }, "children": ["Caption"] },
      { "type": "p",  "props": { "id": "body"  }, "children": ["Body"]    },
      { "type": "h1", "props": { "id": "h1"    }, "children": ["Heading"] }
    ]
  }
}
```

#### `fontWeight`
Both forms — named string and numeric:
```json
{
  "version": 1,
  "style": {
    "#normal":     { "fontWeight": "normal" },
    "#bold":       { "fontWeight": "bold"   },
    "#w100": { "fontWeight": 100 },
    "#w200": { "fontWeight": 200 },
    "#w300": { "fontWeight": 300 },
    "#w400": { "fontWeight": 400 },
    "#w500": { "fontWeight": 500 },
    "#w600": { "fontWeight": 600 },
    "#w700": { "fontWeight": 700 },
    "#w800": { "fontWeight": 800 },
    "#w900": { "fontWeight": 900 }
  },
  "breakpoints": [],
  "layout": { "type": "p", "props": { "id": "normal" }, "children": ["Weighty"] }
}
```

#### `fontStyle`
```json
{
  "version": 1,
  "style": {
    "#normal":  { "fontStyle": "normal" },
    "#italic":  { "fontStyle": "italic" }
  },
  "breakpoints": [],
  "layout": {
    "type": "div",
    "props": { "id": "root" },
    "children": [
      { "type": "p", "props": { "id": "normal" }, "children": ["Plain"]  },
      { "type": "p", "props": { "id": "italic" }, "children": ["Italic"] }
    ]
  }
}
```

#### `color`
```json
{
  "version": 1,
  "style": {
    "#brand": { "color": "#0066CC" }
  },
  "breakpoints": [],
  "layout": { "type": "p", "props": { "id": "brand" }, "children": ["Brand-coloured."] }
}
```

#### `textDecoration`
```json
{
  "version": 1,
  "style": {
    "#none":         { "textDecoration": "none" },
    "#underline":    { "textDecoration": "underline" },
    "#line-through": { "textDecoration": "line-through" }
  },
  "breakpoints": [],
  "layout": {
    "type": "div",
    "props": { "id": "root" },
    "children": [
      { "type": "p", "props": { "id": "none"         }, "children": ["Plain"]   },
      { "type": "p", "props": { "id": "underline"    }, "children": ["Linked"]  },
      { "type": "p", "props": { "id": "line-through" }, "children": ["Removed"] }
    ]
  }
}
```

#### `textAlign`
```json
{
  "version": 1,
  "style": {
    "#left":   { "textAlign": "left" },
    "#center": { "textAlign": "center" },
    "#right":  { "textAlign": "right" }
  },
  "breakpoints": [],
  "layout": {
    "type": "div",
    "props": { "id": "root" },
    "children": [
      { "type": "p", "props": { "id": "left"   }, "children": ["Left aligned"]   },
      { "type": "p", "props": { "id": "center" }, "children": ["Center aligned"] },
      { "type": "p", "props": { "id": "right"  }, "children": ["Right aligned"]  }
    ]
  }
}
```

#### `textTransform`
```json
{
  "version": 1,
  "style": {
    "#none":      { "textTransform": "none" },
    "#upper":     { "textTransform": "uppercase" },
    "#lower":     { "textTransform": "lowercase" }
  },
  "breakpoints": [],
  "layout": {
    "type": "div",
    "props": { "id": "root" },
    "children": [
      { "type": "p", "props": { "id": "none"  }, "children": ["MixED Case"] },
      { "type": "p", "props": { "id": "upper" }, "children": ["MixED Case"] },
      { "type": "p", "props": { "id": "lower" }, "children": ["MixED Case"] }
    ]
  }
}
```

#### `lineHeight`
```json
{
  "version": 1,
  "style": {
    "#tight":   { "fontSize": { "value": 16, "unit": "px" }, "lineHeight": 1.0 },
    "#regular": { "fontSize": { "value": 16, "unit": "px" }, "lineHeight": 1.4 },
    "#loose":   { "fontSize": { "value": 16, "unit": "px" }, "lineHeight": 1.8 }
  },
  "breakpoints": [],
  "layout": { "type": "p", "props": { "id": "regular" }, "children": ["Multiline body text demoing line height."] }
}
```

#### `letterSpacing`
```json
{
  "version": 1,
  "style": {
    "#tracked": { "letterSpacing": { "value": 1, "unit": "px" } },
    "#em":      { "letterSpacing": { "value": 0.05, "unit": "em" }, "fontSize": { "value": 18, "unit": "px" } }
  },
  "breakpoints": [],
  "layout": { "type": "p", "props": { "id": "tracked" }, "children": ["Tracked letters."] }
}
```

---

## 6. Text Behavior

Text overflow + wrapping. Per `TextStyles.md`, ellipsis only fires when the element has `overflow: "hidden"`, `whiteSpace: "nowrap"`, a constrained width, AND the text sits directly in that element.

| Property | Spec values | iOS impl | Works | Test coverage | JSON template |
|---|---|---|---|---|---|
| `textOverflow` | `'clip' \| 'ellipsis'` | ✅ `Style.TextOverflow` | ⚠️ requires the four pre-conditions from `TextStyles.md` to render `…`; otherwise clips silently | `testTextDecorationRoundTrip` (round-trip), no dedicated render-pass test | [→ textOverflow](#textoverflow) |
| `whiteSpace` | `'normal' \| 'nowrap'` | ✅ `Style.WhiteSpace` | ✅ | round-trips through `Style` Codable; no dedicated unit test | [→ whiteSpace](#whitespace) |

### Templates — Text Behavior

#### `textOverflow`
The full ellipsis recipe — width-bound ancestor + `overflow: hidden` + `whiteSpace: nowrap` + `textOverflow: ellipsis`:
```json
{
  "version": 1,
  "style": {
    "#frame": {
      "width": { "value": 200, "unit": "px" },
      "overflow": "hidden"
    },
    "#clipped": {
      "overflow": "hidden",
      "whiteSpace": "nowrap",
      "textOverflow": "clip"
    },
    "#elided": {
      "overflow": "hidden",
      "whiteSpace": "nowrap",
      "textOverflow": "ellipsis"
    }
  },
  "breakpoints": [],
  "layout": {
    "type": "div",
    "props": { "id": "frame" },
    "children": [
      { "type": "p", "props": { "id": "clipped" }, "children": ["Lorem ipsum dolor sit amet"] },
      { "type": "p", "props": { "id": "elided"  }, "children": ["Lorem ipsum dolor sit amet"] }
    ]
  }
}
```

#### `whiteSpace`
```json
{
  "version": 1,
  "style": {
    "#wrap":    { "whiteSpace": "normal" },
    "#one-line":{ "whiteSpace": "nowrap" }
  },
  "breakpoints": [],
  "layout": {
    "type": "div",
    "props": { "id": "root", "style": { "width": { "value": 200, "unit": "px" } } },
    "children": [
      { "type": "p", "props": { "id": "wrap"     }, "children": ["Wraps as needed across multiple lines."] },
      { "type": "p", "props": { "id": "one-line" }, "children": ["Stays on a single line."] }
    ]
  }
}
```

---

## 7. Media

Replaced-element scaling and positioning for the `img` primitive. Both fields land in the cascade, propagate via SwiftUI environment values, and are consumed by `_DOMImage`.

| Property | Spec values | iOS impl | Works | Test coverage | JSON template |
|---|---|---|---|---|---|
| `objectFit` | `'fill' \| 'contain' \| 'cover' \| 'none'` | ✅ `Style.ObjectFit` | ⚠️ shipped; for `objectFit: none` (intrinsic-size image inside a smaller frame), `objectPosition` doesn't anchor — the image renders top-leading regardless. CSS-canonical path (explicit width/height + sizing fit like `cover`) works correctly. | `testObjectFitFillReachesVisualStyle`, `testObjectFitContainReachesVisualStyle`, `testObjectFitCoverReachesVisualStyle`, `testObjectFitNoneReachesVisualStyle`, `testObjectFitLandsInComputedVisualStyle`, `testApplyFitDefaultsToFillWhenObjectFitIsNil`, `testApplyFitNoneStillRendersIntrinsic`, `testDOMImageBuildsForEachObjectFit`, `testJoyDOMViewBuildsWithObjectFitOnImage` | [→ objectFit](#objectfit) |
| `objectPosition` | `{ horizontal: 'left' \| 'center' \| 'right'; vertical: 'top' \| 'center' \| 'bottom' }` | ✅ `Style.ObjectPosition` | ⚠️ honored for sizing fits; ignored for `none` (see above) | `testObjectPositionRoundTripsThroughCascade`, `testObjectPositionCenterCenterReachesVisualStyle`, `testObjectPositionAlignmentTopRow`, `testObjectPositionAlignmentCenterRow`, `testObjectPositionAlignmentBottomRow`, `testInheritedObjectPositionEnvironmentRoundTripsValue`, `testDOMImageBuildsWithObjectPosition` | [→ objectPosition](#objectposition) |

### Templates — Media

#### `objectFit`
```json
{
  "version": 1,
  "style": {
    "#fill":    { "width": { "value": 240, "unit": "px" }, "height": { "value": 160, "unit": "px" }, "objectFit": "fill" },
    "#contain": { "width": { "value": 240, "unit": "px" }, "height": { "value": 160, "unit": "px" }, "objectFit": "contain" },
    "#cover":   { "width": { "value": 240, "unit": "px" }, "height": { "value": 160, "unit": "px" }, "objectFit": "cover" },
    "#none":    { "width": { "value": 240, "unit": "px" }, "height": { "value": 160, "unit": "px" }, "objectFit": "none" }
  },
  "breakpoints": [],
  "layout": {
    "type": "div",
    "props": { "id": "gallery", "style": { "flexDirection": "column", "gap": { "value": 8, "unit": "px" } } },
    "children": [
      { "type": "img", "props": { "id": "fill",    "src": "https://example.com/photo.jpg" } },
      { "type": "img", "props": { "id": "contain", "src": "https://example.com/photo.jpg" } },
      { "type": "img", "props": { "id": "cover",   "src": "https://example.com/photo.jpg" } },
      { "type": "img", "props": { "id": "none",    "src": "https://example.com/photo.jpg" } }
    ]
  }
}
```

#### `objectPosition`
All nine `horizontal × vertical` corner / edge / center pairings:
```json
{
  "version": 1,
  "style": {
    "#tl": { "objectFit": "cover", "objectPosition": { "horizontal": "left",   "vertical": "top"    } },
    "#tc": { "objectFit": "cover", "objectPosition": { "horizontal": "center", "vertical": "top"    } },
    "#tr": { "objectFit": "cover", "objectPosition": { "horizontal": "right",  "vertical": "top"    } },
    "#cl": { "objectFit": "cover", "objectPosition": { "horizontal": "left",   "vertical": "center" } },
    "#cc": { "objectFit": "cover", "objectPosition": { "horizontal": "center", "vertical": "center" } },
    "#cr": { "objectFit": "cover", "objectPosition": { "horizontal": "right",  "vertical": "center" } },
    "#bl": { "objectFit": "cover", "objectPosition": { "horizontal": "left",   "vertical": "bottom" } },
    "#bc": { "objectFit": "cover", "objectPosition": { "horizontal": "center", "vertical": "bottom" } },
    "#br": { "objectFit": "cover", "objectPosition": { "horizontal": "right",  "vertical": "bottom" } }
  },
  "breakpoints": [],
  "layout": {
    "type": "img",
    "props": {
      "id": "tl",
      "src": "https://example.com/photo.jpg",
      "style": { "width": { "value": 240, "unit": "px" }, "height": { "value": 160, "unit": "px" } }
    }
  }
}
```

---

## 8. Selectors

Per `Styles.md`, top-level keys in `style` are selectors. The spec sanctions three forms — type (element name like `div`), `.class`, and `#id` — plus compound selectors that mix them. joydom-swift additionally accepts the four CSS combinators (descendant, child, adjacent sibling, general sibling), which the canonical spec does not specify.

| Selector | Spec values | iOS impl | Works | Test coverage | JSON template |
|---|---|---|---|---|---|
| Type (`div`, `p`, `h1`, …) | bare element name | ✅ `Element` part in `CompoundSelector` | ✅ | `testParsesElementSelector`, `testSpecificityOfElement`, `testStyleFieldsTranslateToComputedStyle` | [→ type-selector](#type-selector) |
| Class (`.cta`) | `.name` | ✅ `Class` part | ✅ | `testParsesClassSelector`, `testSpecificityOfClass`, `testClassSelectorWinsOverType` | [→ class-selector](#class-selector) |
| Id (`#hero`) | `#name` | ✅ `Id` part | ✅ | `testParsesIDSelector`, `testSpecificityOfID`, `testIDSelectorWinsOverClassAndType` | [→ id-selector](#id-selector) |
| Compound (`p.cta#hero`) | concatenated parts, no whitespace | ✅ `CompoundSelector` | ✅ | `testParsesCompoundElementAndClass`, `testParsesCompoundElementClassID`, `testParsesCompoundMultipleClasses`, `testParsesCompoundIDThenClass`, `testSpecificityOfCompoundSumsContributions` | [→ compound-selector](#compound-selector) |
| Descendant combinator (`p .cta`) | ⚠️ ext, not in spec | ⚠️ ext `ComplexSelector` | ✅ accepted | `testParsesDescendantCombinator`, `testParsesDescendantChain`, `testDescendantCombinatorMatches` | [→ combinators-extension](#combinators-extension) |
| Child combinator (`section > p`) | ⚠️ ext | ⚠️ ext | ✅ | `testParsesChildCombinator`, `testParsesChildCombinatorWithoutSurroundingSpace` | [→ combinators-extension](#combinators-extension) |
| Adjacent sibling (`h2 + p`) | ⚠️ ext | ⚠️ ext | ✅ | `testAdjacentMatchesImmediatePredecessor`, `testAdjacentDoesNotMatchNonAdjacentTarget`, `testAdjacentSiblingCombinatorMatches` | [→ combinators-extension](#combinators-extension) |
| General sibling (`h2 ~ p`) | ⚠️ ext | ⚠️ ext | ✅ | `testGeneralMatchesImmediatePredecessor`, `testGeneralMatchesNonAdjacentLater`, `testGeneralSiblingCombinatorMatchesNonImmediate` | [→ combinators-extension](#combinators-extension) |

> Per `Styles.md`, selector specificity ranks `type < class < id`. joydom-swift's `Specificity` type sums contributions per compound, producing CSS-equivalent ordering. Pseudo-classes, pseudo-elements, and attribute selectors are explicitly rejected by the parser (`testRejectsAttributeSelector`, `testRejectsPseudoClassSelector`, `testRejectsPseudoElementSelector`).

### Templates — Selectors

#### Type selector
```json
{
  "version": 1,
  "style": {
    "p":  { "color": "#222222", "fontSize": { "value": 16, "unit": "px" } },
    "h1": { "color": "#000000", "fontSize": { "value": 32, "unit": "px" } }
  },
  "breakpoints": [],
  "layout": {
    "type": "div",
    "props": { "id": "root" },
    "children": [
      { "type": "h1", "children": ["Heading"] },
      { "type": "p",  "children": ["Body."]   }
    ]
  }
}
```

#### Class selector
```json
{
  "version": 1,
  "style": {
    ".card":      { "padding": { "value": 16, "unit": "px" }, "backgroundColor": "#FFFFFF" },
    ".card-dark": { "backgroundColor": "#222222", "color": "#FFFFFF" }
  },
  "breakpoints": [],
  "layout": {
    "type": "div",
    "props": { "id": "row", "style": { "flexDirection": "row" } },
    "children": [
      { "type": "div", "props": { "id": "a", "className": ["card"] } },
      { "type": "div", "props": { "id": "b", "className": ["card", "card-dark"] } }
    ]
  }
}
```

#### Id selector
```json
{
  "version": 1,
  "style": {
    "#hero": { "padding": { "value": 32, "unit": "px" }, "backgroundColor": "#0066CC" }
  },
  "breakpoints": [],
  "layout": { "type": "div", "props": { "id": "hero" } }
}
```

#### Compound selector
```json
{
  "version": 1,
  "style": {
    "p.cta":          { "color": "#0066CC" },
    "div.card#hero":  { "borderWidth": { "value": 2, "unit": "px" }, "borderColor": "#0066CC", "borderStyle": "solid" }
  },
  "breakpoints": [],
  "layout": {
    "type": "div",
    "props": { "id": "hero", "className": ["card"] },
    "children": [{ "type": "p", "props": { "className": ["cta"] }, "children": ["Buy now"] }]
  }
}
```

#### Combinators (extension)
Not in `spec.ts` — joydom-swift accepts all four CSS combinators. Producers targeting the canonical spec should keep selectors flat (type / class / id / compound).
```json
{
  "version": 1,
  "style": {
    "section p":        { "color": "#444444" },
    "section > p":      { "fontWeight": "bold" },
    "h2 + p":           { "fontStyle": "italic" },
    "h2 ~ p":           { "textDecoration": "underline" }
  },
  "breakpoints": [],
  "layout": {
    "type": "section",
    "children": [
      { "type": "h2", "children": ["Title"] },
      { "type": "p",  "children": ["Lead paragraph."] },
      { "type": "p",  "children": ["Follow-up."]      }
    ]
  }
}
```

---

## 9. Cascade

Cascade order is `Document.style → Breakpoint.style → node.props.style → Breakpoint.nodes[id].style`, with selector specificity (`type < class < id`) breaking ties and source order resolving same-specificity collisions. The cascade applies field-by-field, so partial overrides keep sibling fields intact.

| Behavior | Description | iOS impl | Works | Test coverage | JSON template |
|---|---|---|---|---|---|
| Document → Breakpoint → inline order | Inline `node.props.style` beats document selectors; active breakpoint per-node `nodes[id].style` beats inline. | ✅ `StyleResolver.resolve` + `RuleBuilder` | ✅ | `testInlinePropsStyleBeatsClassSelector`, `testBreakpointPerNodeStyleBeatsBaseInline` | [→ cascade-precedence](#cascade-precedence) |
| Specificity ordering (`type < class < id`) | Higher specificity wins when both selectors match the same node. | ✅ `Specificity` type | ✅ | `testIDSelectorWinsOverClassAndType`, `testClassSelectorWinsOverType`, `testSpecificityOrdering`, `testSpecificityOfCompoundSumsContributions` | [→ specificity-tiers](#specificity-tiers) |
| Source-order tie-break | If specificities are equal, the rule defined later wins. | ✅ `StyleResolver` sort by `sourceOrder` | ✅ | `testLaterSourceOrderWinsOnEqualSpecificity`, `testSpecificityTieBreaksByLaterSourceOrder` | [→ source-order](#source-order) |
| Multi-class source order | When a node lists `["a","b"]` in `className`, classes resolve in array order — later classes win on ties. | ✅ `StyleTreeBuilder` orders class rules per-node | ✅ | `testParseListReturnsSingleSelector`, `testParseListSplitsOnComma`, `testStyleFieldsTranslateToComputedStyle` | [→ multi-class](#multi-class) |

### Templates — Cascade

#### Cascade precedence
Three layers, from weakest to strongest. The breakpoint's `nodes` override at the bottom wins outright.
```json
{
  "version": 1,
  "style": {
    "#headline": { "color": "#222222", "fontSize": { "value": 24, "unit": "px" } }
  },
  "breakpoints": [
    {
      "conditions": [{ "type": "feature", "name": "width", "operator": ">=", "value": 768, "unit": "px" }],
      "nodes": {
        "headline": { "style": { "color": "#0066CC" } }
      },
      "style": {
        "#headline": { "fontSize": { "value": 32, "unit": "px" } }
      }
    }
  ],
  "layout": {
    "type": "h1",
    "props": {
      "id": "headline",
      "style": { "fontFamily": "Georgia" }
    },
    "children": ["Cascade demo"]
  }
}
```

#### Specificity tiers
`#hero` (id) beats `.card` (class) beats `div` (type) for the same field.
```json
{
  "version": 1,
  "style": {
    "div":   { "color": "#666666" },
    ".card": { "color": "#0066CC" },
    "#hero": { "color": "#FF0000" }
  },
  "breakpoints": [],
  "layout": {
    "type": "div",
    "props": { "id": "hero", "className": ["card"] },
    "children": [{ "type": "p", "children": ["Red wins."] }]
  }
}
```

#### Source order
Same-specificity rules — second wins.
```json
{
  "version": 1,
  "style": {
    ".first":  { "color": "#FF0000" },
    ".second": { "color": "#00AA00" }
  },
  "breakpoints": [],
  "layout": {
    "type": "p",
    "props": { "className": ["first", "second"] },
    "children": ["Green wins"]
  }
}
```

#### Multi-class
```json
{
  "version": 1,
  "style": {
    ".bg-card": { "backgroundColor": "#FFFFFF", "padding": { "value": 16, "unit": "px" } },
    ".inverse": { "backgroundColor": "#000000", "color": "#FFFFFF" }
  },
  "breakpoints": [],
  "layout": {
    "type": "div",
    "props": { "id": "card", "className": ["bg-card", "inverse"] },
    "children": [{ "type": "p", "children": ["Inverse wins on shared keys."] }]
  }
}
```

---

## 10. Breakpoints

Breakpoints provide CSS-`@media`-style overrides. Per `Breakpoints.md`: only one breakpoint applies at a time (no merging across breakpoints), but the active breakpoint deep-merges into the primary document. Removing a property in the breakpoint restores the primary value (e.g. drop `order` → re-flow returns to declaration order).

| Capability | Behavior | iOS impl | Works | Test coverage | JSON template |
|---|---|---|---|---|---|
| `conditions` (width / orientation / print) | Each entry is a `MediaQuery`; ANDed together implicitly. | ✅ `MediaQueryEvaluator` | ✅ | `testWidthLessThanMatchesUnderBoundary`, `testWidthGreaterThanMatchesAboveBoundary`, `testOrientationPortraitMatches`, `testOrientationLandscapeMatches`, `testTypePrintMatchesWhenPrintFlagOn` | [→ breakpoint-conditions](#breakpoint-conditions) |
| Logical operators (`and` / `or` / `not`) | Combine subqueries; `not` inverts. | ✅ `LogicalOp`, `MediaQuery.not` | ✅ | `testLogicalAndMatchesWhenAllConditionsMatch`, `testLogicalAndFailsWhenOneConditionFails`, `testLogicalOrMatchesWhenAnyConditionMatches`, `testNotInvertsInnerMatch`, `testNestedNotAndOrCombinationEvaluatesCorrectly` | [→ breakpoint-logical](#breakpoint-logical) |
| `nodes:{id:{props}}` overrides | Replace per-node props (`className`, `style`, extras) under the active breakpoint. | ✅ `BreakpointResolver.flattenNodes` + `RuleBuilder` | ✅ | `testActiveBreakpointHasItsContent`, `testActiveBreakpointExtrasReplaceMatchingKey`, `testFlattenBreakpointOverridesSplitsClassNameAndExtras` | [→ breakpoint-nodes-override](#breakpoint-nodes-override) |
| `style:{selector:Style}` per-breakpoint cascade | Selector-keyed style block applied while the breakpoint is active, layered above document `style`. | ✅ `StyleTreeBuilder.merge(breakpoint:)` | ✅ | `testSingleMatchingBreakpointReturned`, `testHigherSpecificityWinsOverLowerWhenBothMatch` | [→ breakpoint-style-block](#breakpoint-style-block) |
| Deep merge | Properties not overridden in the breakpoint survive from the primary doc. | ✅ field-level apply in `StyleResolver` | ✅ | `testBreakpointDeepMergePreservesNonOverriddenFields`, `testNonOverriddenBaseExtrasSurviveMerge` | [→ breakpoint-deep-merge](#breakpoint-deep-merge) |
| Restore primary (remove `order`) | Omit `order` in the breakpoint's node override → primary declaration order returns. | ✅ override = absent → no rule | ✅ | `testRemovingOrderFromBreakpointRestoresPrimaryOrder` | [→ breakpoint-restore-order](#breakpoint-restore-order) |
| Restore primary (remove `display: none`) | Omit `display: none` in breakpoint → node visibility returns. | ✅ | ✅ | `testRemovingDisplayNoneFromBreakpointRestoresVisibility` | [→ breakpoint-restore-visibility](#breakpoint-restore-visibility) |
| Custom node ordering via `order` | Reorder siblings per breakpoint without re-parenting. | ✅ | ✅ | `testBreakpointOrderOverrideAppliesAtMatchingViewport` | [→ breakpoint-order-swap](#breakpoint-order-swap) |
| Custom node visibility via `display: none` | Hide a node in one breakpoint without removing it from the tree. | ✅ | ✅ | `testBreakpointDisplayNoneOverrideHidesNode` | [→ breakpoint-visibility](#breakpoint-visibility) |
| `className` swap | Replace the active class list per breakpoint (overrides primary `className`). | ✅ | ✅ | `testFlattenBreakpointOverridesSplitsClassNameAndExtras`, `testOverrideAddsNewKeyWithoutDroppingBase` | [→ breakpoint-classname-swap](#breakpoint-classname-swap) |

### Templates — Breakpoints

#### Breakpoint conditions
Width range, orientation, and `@media print`:
```json
{
  "version": 1,
  "style": { "#root": { "padding": { "value": 8, "unit": "px" } } },
  "breakpoints": [
    {
      "conditions": [
        { "type": "feature", "name": "width", "operator": "<", "value": 768, "unit": "px" }
      ],
      "nodes": {},
      "style": { "#root": { "flexDirection": "column" } }
    },
    {
      "conditions": [
        { "type": "feature", "name": "width", "operator": ">=", "value": 768, "unit": "px" }
      ],
      "nodes": {},
      "style": { "#root": { "flexDirection": "row" } }
    },
    {
      "conditions": [
        { "type": "feature", "name": "orientation", "value": "landscape" }
      ],
      "nodes": {},
      "style": { "#root": { "padding": { "value": 16, "unit": "px" } } }
    },
    {
      "conditions": [{ "type": "type", "value": "print" }],
      "nodes": {},
      "style": { "#root": { "backgroundColor": "#FFFFFF" } }
    }
  ],
  "layout": { "type": "div", "props": { "id": "root" } }
}
```

#### Breakpoint logical (`and` / `or` / `not`)
```json
{
  "version": 1,
  "style": {},
  "breakpoints": [
    {
      "conditions": [
        {
          "op": "and",
          "conditions": [
            { "type": "feature", "name": "width",       "operator": ">=", "value": 768, "unit": "px" },
            { "type": "feature", "name": "orientation", "value": "landscape" }
          ]
        }
      ],
      "nodes": {},
      "style": { "#root": { "flexDirection": "row" } }
    },
    {
      "conditions": [
        {
          "op": "or",
          "conditions": [
            { "type": "feature", "name": "width", "operator": "<", "value": 480, "unit": "px" },
            { "type": "type",    "value": "print" }
          ]
        }
      ],
      "nodes": {},
      "style": { "#root": { "flexDirection": "column" } }
    },
    {
      "conditions": [
        { "op": "not", "condition": { "type": "type", "value": "print" } }
      ],
      "nodes": {},
      "style": { "#root": { "backgroundColor": "#F4F4F4" } }
    }
  ],
  "layout": { "type": "div", "props": { "id": "root" } }
}
```

#### Breakpoint nodes override
```json
{
  "version": 1,
  "style": {},
  "breakpoints": [
    {
      "conditions": [{ "type": "feature", "name": "width", "operator": ">=", "value": 768, "unit": "px" }],
      "nodes": {
        "headline": {
          "className": ["headline-tablet"],
          "style":     { "fontSize": { "value": 32, "unit": "px" } }
        }
      },
      "style": {}
    }
  ],
  "layout": {
    "type": "h1",
    "props": {
      "id": "headline",
      "className": ["headline-mobile"],
      "style": { "fontSize": { "value": 24, "unit": "px" } }
    },
    "children": ["Responsive heading"]
  }
}
```

#### Breakpoint style block
```json
{
  "version": 1,
  "style": {
    ".card": { "padding": { "value":  8, "unit": "px" } }
  },
  "breakpoints": [
    {
      "conditions": [{ "type": "feature", "name": "width", "operator": ">=", "value": 1024, "unit": "px" }],
      "nodes": {},
      "style": {
        ".card":  { "padding": { "value": 24, "unit": "px" } },
        "#hero":  { "fontSize": { "value": 48, "unit": "px" } }
      }
    }
  ],
  "layout": {
    "type": "div",
    "props": { "id": "hero", "className": ["card"] },
    "children": ["Big screen"]
  }
}
```

#### Breakpoint deep merge
Primary defines color + padding; breakpoint only overrides color → padding survives.
```json
{
  "version": 1,
  "style": {
    "#item": { "color": "#FF0000", "padding": { "value": 12, "unit": "px" } }
  },
  "breakpoints": [
    {
      "conditions": [{ "type": "feature", "name": "width", "operator": ">=", "value": 768, "unit": "px" }],
      "nodes": {},
      "style": { "#item": { "color": "#0066CC" } }
    }
  ],
  "layout": { "type": "p", "props": { "id": "item" }, "children": ["Color flips, padding stays"] }
}
```

#### Breakpoint restore order
Drop `order` at the wide viewport — reading order returns to declaration order.
```json
{
  "version": 1,
  "style": {
    "#a": { "order": 3 },
    "#b": { "order": 1 },
    "#c": { "order": 2 }
  },
  "breakpoints": [
    {
      "conditions": [{ "type": "feature", "name": "width", "operator": ">=", "value": 1024, "unit": "px" }],
      "nodes": {
        "a": { "style": {} },
        "b": { "style": {} },
        "c": { "style": {} }
      },
      "style": {}
    }
  ],
  "layout": {
    "type": "div",
    "props": { "id": "row", "style": { "flexDirection": "row" } },
    "children": [
      { "type": "div", "props": { "id": "a" } },
      { "type": "div", "props": { "id": "b" } },
      { "type": "div", "props": { "id": "c" } }
    ]
  }
}
```

#### Breakpoint restore visibility
Primary hides the badge; tablet breakpoint omits `display: none` so it returns.
```json
{
  "version": 1,
  "style": {
    "#badge": { "display": "none" }
  },
  "breakpoints": [
    {
      "conditions": [{ "type": "feature", "name": "width", "operator": ">=", "value": 768, "unit": "px" }],
      "nodes": {
        "badge": { "style": {} }
      },
      "style": {}
    }
  ],
  "layout": {
    "type": "div",
    "props": { "id": "row" },
    "children": [{ "type": "span", "props": { "id": "badge" }, "children": ["NEW"] }]
  }
}
```

#### Breakpoint order swap
```json
{
  "version": 1,
  "style": {},
  "breakpoints": [
    {
      "conditions": [{ "type": "feature", "name": "width", "operator": ">=", "value": 768, "unit": "px" }],
      "nodes": {
        "primary":   { "style": { "order": 2 } },
        "secondary": { "style": { "order": 1 } }
      },
      "style": {}
    }
  ],
  "layout": {
    "type": "div",
    "props": { "id": "row", "style": { "flexDirection": "row" } },
    "children": [
      { "type": "div", "props": { "id": "primary"   } },
      { "type": "div", "props": { "id": "secondary" } }
    ]
  }
}
```

#### Breakpoint visibility
```json
{
  "version": 1,
  "style": {},
  "breakpoints": [
    {
      "conditions": [{ "type": "feature", "name": "width", "operator": "<", "value": 768, "unit": "px" }],
      "nodes": {
        "desktop-nav":  { "style": { "display": "none" } }
      },
      "style": {}
    },
    {
      "conditions": [{ "type": "feature", "name": "width", "operator": ">=", "value": 768, "unit": "px" }],
      "nodes": {
        "mobile-menu":  { "style": { "display": "none" } }
      },
      "style": {}
    }
  ],
  "layout": {
    "type": "div",
    "props": { "id": "header", "style": { "flexDirection": "row" } },
    "children": [
      { "type": "div",  "props": { "id": "desktop-nav" } },
      { "type": "span", "props": { "id": "mobile-menu" }, "children": ["☰"] }
    ]
  }
}
```

#### Breakpoint className swap
```json
{
  "version": 1,
  "style": {
    ".tone-light": { "backgroundColor": "#FFFFFF", "color": "#222222" },
    ".tone-dark":  { "backgroundColor": "#111111", "color": "#FFFFFF" }
  },
  "breakpoints": [
    {
      "conditions": [{ "type": "feature", "name": "orientation", "value": "landscape" }],
      "nodes": {
        "panel": { "className": ["tone-dark"] }
      },
      "style": {}
    }
  ],
  "layout": {
    "type": "div",
    "props": { "id": "panel", "className": ["tone-light"] },
    "children": [{ "type": "p", "children": ["Landscape goes dark."] }]
  }
}
```

---

## 11. Patterns (guides)

Recipes from `BackgroundImages.md` and `TextStyles.md` for cases the spec doesn't model directly.

| Pattern | Why | iOS impl | Works | Test coverage | JSON template |
|---|---|---|---|---|---|
| Background image wrapper | `background-image` isn't in the spec; recreate with a `position: relative` wrapper containing an absolutely-positioned `img` (zIndex 0) plus content layer (zIndex 1). | ✅ via cascade + `_DOMImage` | ✅ shipped, demo sample `backgroundImageWrapper` | covered by `JoyDOMSamplesIntegrityTests` (round-trip) + `ObjectFitCascadeTests` for the inner img | [→ background-image-wrapper](#background-image-wrapper) |
| Ellipsis pre-conditions | `textOverflow: ellipsis` only works when the text is directly inside an element with `overflow: hidden`, `whiteSpace: nowrap`, AND a parent-constrained width. | ✅ honored by SwiftUI text layout | ⚠️ silent if pre-conditions miss — clips without trailing `…` | no dedicated render test; round-trip pinned by `testTextDecorationRoundTrip` | [→ ellipsis-recipe](#ellipsis-recipe) |

### Templates — Patterns

#### Background image wrapper
Per `BackgroundImages.md`: wrapper (`position: relative` + `overflow: hidden`) → `img` (`position: absolute`, pinned, `objectFit: cover`, `zIndex: 0`) → content layer (`zIndex: 1`).
```json
{
  "version": 1,
  "style": {
    "#hero-frame": {
      "position": "relative",
      "overflow": "hidden",
      "width":  { "value": 360, "unit": "px" },
      "height": { "value": 200, "unit": "px" },
      "borderRadius": { "value": 12, "unit": "px" }
    },
    "#hero-bg": {
      "position": "absolute",
      "top":    { "value": 0, "unit": "px" },
      "left":   { "value": 0, "unit": "px" },
      "right":  { "value": 0, "unit": "px" },
      "bottom": { "value": 0, "unit": "px" },
      "objectFit": "cover",
      "objectPosition": { "horizontal": "center", "vertical": "center" },
      "zIndex": 0,
      "opacity": 0.7
    },
    "#hero-content": {
      "position": "absolute",
      "top":    { "value": 0, "unit": "px" },
      "left":   { "value": 0, "unit": "px" },
      "right":  { "value": 0, "unit": "px" },
      "bottom": { "value": 0, "unit": "px" },
      "padding": { "value": 24, "unit": "px" },
      "zIndex": 1,
      "color": "#FFFFFF",
      "fontWeight": "bold",
      "fontSize": { "value": 28, "unit": "px" }
    }
  },
  "breakpoints": [],
  "layout": {
    "type": "div",
    "props": { "id": "hero-frame" },
    "children": [
      { "type": "img", "props": { "id": "hero-bg", "src": "https://example.com/photo.jpg" } },
      { "type": "div", "props": { "id": "hero-content" }, "children": [
        { "type": "h1", "children": ["Welcome aboard"] }
      ] }
    ]
  }
}
```

#### Ellipsis recipe
All four pre-conditions in one snippet: parent-constrained width, `overflow: hidden`, `whiteSpace: nowrap`, text directly in the `p`.
```json
{
  "version": 1,
  "style": {
    "#frame": { "width": { "value": 240, "unit": "px" } },
    "#title": {
      "overflow": "hidden",
      "whiteSpace": "nowrap",
      "textOverflow": "ellipsis"
    }
  },
  "breakpoints": [],
  "layout": {
    "type": "div",
    "props": { "id": "frame" },
    "children": [
      { "type": "p", "props": { "id": "title" }, "children": ["A very long product title that will get truncated"] }
    ]
  }
}
```

---

## Appendix — Property count

48 spec-sanctioned properties from `spec.ts`'s `Style` interface, all modeled in `Sources/JoyDOM/Model/Spec.swift`:

`position`, `display`, `boxSizing`, `zIndex`, `overflow`, `top`, `left`, `bottom`, `right`, `flexDirection`, `flexGrow`, `flexShrink`, `flexBasis`, `justifyContent`, `alignItems`, `alignSelf`, `flexWrap`, `gap`, `rowGap`, `columnGap`, `order`, `width`, `maxWidth`, `minWidth`, `height`, `maxHeight`, `minHeight`, `backgroundColor`, `opacity`, `padding`, `margin`, `borderWidth`, `borderColor`, `borderStyle`, `borderRadius`, `fontFamily`, `fontSize`, `fontWeight`, `fontStyle`, `color`, `textDecoration`, `textAlign`, `textTransform`, `lineHeight`, `letterSpacing`, `objectFit`, `objectPosition`, `textOverflow`, `whiteSpace`.

(`whiteSpace` rounds the count to 49 if you split text behavior from typography; the canonical `Style` interface lists `textOverflow` twice in the table guide and once in `spec.ts`. The interface has 48 distinct fields.)

joydom-swift adds one extension property (`alignContent`) plus extra enum values flagged `⚠️ ext` in the tables above.
