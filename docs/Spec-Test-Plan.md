# JoyDOM Swift — Spec Test Plan

Maps the canonical [`j0yhq/joy-dom`](https://github.com/j0yhq/joy-dom) spec (commit `765acfda0243648c97c4f198e5d1c8e4d88bfc0f`, 2026-05-06) onto JoyDOM Swift's tests and demo samples. Samples are defined in `FlexDemoApp/JoyDOMSamples.swift` and surface through `FlexDemoApp` viewport-resizable preview. Tests live under `Tests/JoyDOMTests/` and `Tests/FlexLayoutTests/`. Audience: a reviewer manually walking the checklist in Section 2 in the demo, with the matrix in Section 1 as orientation and Section 3 as a punch-list of follow-ups.

Status legend: ✅ covered · ⚠️ partial / parses-but-no-effect · ❌ none.

---

## 1 · Spec coverage matrix

### Layout & Positioning

| Spec ref | Feature | Swift type | Unit test | Sample | Manual verify |
|---|---|---|---|---|---|
| `spec.ts:14` | `position: 'absolute'` | `Position.absolute` | `StyleFieldTranslationTests::testPositionAbsolute` ✅ | `positioning` ✅ | Card overlay sits inside relative parent at top/left/right offsets. |
| `spec.ts:14` | `position: 'relative'` | `Position.relative` | `StyleFieldTranslationTests::testPositionRelative` ✅ | `positioning` ✅ | Wrapper acts as positioning context for absolute children. |
| `spec.ts:14` (extension) | `position: 'fixed'` (diagnostic-only fallback) | `Position.fixed` | `SpecGapTests::testPositionFixedEmitsDiagnostic`, `StyleFieldTranslationTests::testPositionFixedFallsBackToAbsolute` ✅ | `positioning` (diag card) ✅ | Diagnostic card visible; treated as absolute. |
| `spec.ts:15` | `display: 'flex'` | `Display.flex` | `StyleFieldTranslationTests::testDisplayFlex` ✅ | every container sample ✅ | Children laid out along main axis. |
| `spec.ts:15` (extension) | `display: 'none'` | `Display.none` | `SpecGapTests::testDisplayNoneSetsIsDisplayNone`, `ComponentResolverTests::testDisplayNoneNodeIsFiltered` ✅ | `kitchenSink` (`#hidden-p`) ✅ | Hidden `<p>` does not appear in output tree. |
| `spec.ts:15` (extension) | `display: 'block'` / `'inline'` / `'inline-block'` / `'inline-flex'` | `Display.block/inline/inlineBlock/inlineFlex` | `StyleFieldTranslationTests::testDisplayBlock`, `testDisplayInlineBlockMapsToInline`, `testDisplayInlineMapsToInline`, `testDisplayInlineFlexMapsToFlex` ✅ | `kitchenSink` (`#footnote` block) ✅ | Block flows full width; inline flows in line. |
| `spec.ts:16` | `boxSizing: 'border-box'` | `Style.BoxSizing.borderBox` | `StyleFieldTranslationTests::testBoxSizingBorderBoxRoundTripsThroughCodable`, `testBoxSizingDecodesFromHyphenatedString`, `SpecGapTests::testBoxSizingRoundTrip` ⚠️ (parses, no layout effect) | ❌ none | n/a (no visible behavior — see §3). |
| `spec.ts:18` | `zIndex: number` | `zIndex: Int?` | `StyleFieldTranslationTests::testZIndex`, `FlexGeometryTests::testZIndex_doesNotAffectLayoutGeometry`, `testZIndex_samePriority_domOrderTieBreak` ✅ | `positioning` ✅ | Higher zIndex paints on top of lower. |
| `spec.ts:19` | `overflow: 'visible'/'hidden'/'clip'/'scroll'/'auto'` | `Overflow` | `StyleFieldTranslationTests::testOverflowEachValue`, `testOverflowAlsoMirrorsToItem` ✅ | `kitchenSink` (footer `hidden`, root `auto`) ✅ | Footer clips long text; root scrolls when content exceeds height. |
| `spec.ts:21-24` | `top` / `left` / `bottom` / `right` `Length<'px'>` | `Length?` | `StyleFieldTranslationTests::testTopBottomLeftRightOffsetsLandOnEdges`, `FlexGeometryTests::testAbsolute_*` ✅ | `positioning` ✅ | Absolute child anchored to specified edges. |

### Sizing

| Spec ref | Feature | Swift type | Unit test | Sample | Manual verify |
|---|---|---|---|---|---|
| `spec.ts:38` | `width` px / % | `Length` | `StyleFieldTranslationTests::testWidthPxAndPercent`, `FlexGeometryTests::testExplicitWidth_points_setsMainSize`, `testExplicitWidth_fraction_percentageOfMainAxis` ✅ | `cards`, `pricing`, `flexAlign` ✅ | Boxes sized to value; % scales with parent. |
| `spec.ts:39` | `maxWidth` | `Length` | `MinMaxConstraintTests::testMaxWidthClampsExplicitWidth`, `testMaxWidthOnGrowerRedistributesLeftoverToSiblings`, `SpecGapTests::testMinMaxSizingRoundTrip` ✅ | `constraints` ✅ | Width capped; surplus redistributes. |
| `spec.ts:40` | `minWidth` | `Length` | `MinMaxConstraintTests::testMinWidthRaisesExplicitWidth`, `testMinBeatsMaxOnConflict`, `testMinWidthOnShrinkingItemRedistributesShortfall` ✅ | `constraints` ✅ | Item never narrower than min. |
| `spec.ts:41` | `height` px / % | `Length` | `StyleFieldTranslationTests::testHeightPxAndPercent`, `FlexGeometryTests::testExplicitHeight_points_setsCrossSize` ✅ | `cards`, `kitchenSink` ✅ | Boxes sized vertically. |
| `spec.ts:42` | `maxHeight` | `Length` | `MinMaxConstraintTests::testMaxHeightClampsExplicitHeight` ✅ | `constraints` ✅ | Height capped. |
| `spec.ts:43` | `minHeight` | `Length` | `MinMaxConstraintTests::testMinHeightRaisesExplicitHeight`, `testIntrinsicWithMinHeightClampsUp` ✅ | `constraints` ✅ | Height never shorter than min. |

### Box Model & Visuals

| Spec ref | Feature | Swift type | Unit test | Sample | Manual verify |
|---|---|---|---|---|---|
| `spec.ts:45` | `backgroundColor: hex` | `String?` | `SpecGapTests::testBackgroundColorMapsToVisual` ✅ | `cards`, `visualCSS`, `kitchenSink` ✅ | Box paints solid hex color. |
| `spec.ts:46` | `opacity: number` | `Double?` | `SpecGapTests::testOpacityMapsToVisual` ✅ | `kitchenSink` (`#opacity-demo` 0.4) ✅ | Box rendered semi-transparent. |
| `spec.ts:47` | `padding` uniform | `Padding.uniform` | `StyleFieldTranslationTests::testPaddingUniformSetsAllSides`, `FlexGeometryTests::testPadding_offsetsAllItems`, `testPadding_reducesSpaceForGrow` ✅ | `kitchenSink`, `marginShowcase` ✅ | Inner spacing visible on all sides. |
| `spec.ts:47` | `padding` per-side | `Padding.sides` | `StyleFieldTranslationTests::testPaddingSidesAppliesPerSide` ✅ | `kitchenSink` ✅ | Asymmetric inner spacing. |
| `spec.ts:48` | `margin` uniform | `Padding.uniform` | `FlexMarginTests::testUniformMarginShrinksRowAndShiftsOrigin`, `StyleFieldTranslationTests::testMarginUniformLandsOnItemNotVisual`, `SpecGapTests::testMarginUniformRoundTrip` ✅ | `marginShowcase` ✅ | Outer spacing pushes siblings. |
| `spec.ts:48` | `margin` per-side | `Padding.sides` | `FlexMarginTests::testAsymmetricMarginShiftsOnlySpecifiedSides`, `StyleFieldTranslationTests::testMarginPerSideLandsOnItem`, `SpecGapTests::testMarginSidesRoundTrip` ✅ | `marginShowcase` ✅ | Specified sides shift; others don't. |
| `spec.ts:49` | `borderWidth` | `Length` | `SpecGapTests::testBorderPropertiesRoundTrip`, `testBorderMapsToVisual` ✅ | `cards`, `visualCSS` ✅ | Stroke thickness visible. |
| `spec.ts:50` | `borderColor: hex` | `String?` | `SpecGapTests::testBorderMapsToVisual` ✅ | `cards`, `visualCSS` ✅ | Stroke color matches hex. |
| `spec.ts:51` | `borderStyle: 'solid'` | `BorderStyleProp.solid` | `BorderStyleTests::testSolidRoundTripsToVisualStyle` ✅ | `cards`, `visualCSS`, `marginShowcase` ✅ | Solid line. |
| `spec.ts:51` | `borderStyle: 'none'` | `BorderStyleProp.none` | `BorderStyleTests::testNoneRoundTripsToVisualStyle`, `SpecGapTests::testBorderStyleNoneRoundTrip` ✅ | implicitly via missing border ✅ | No line. |
| `spec.ts:51` (extension) | `borderStyle: 'dashed'/'dotted'/'double'` | `BorderStyleProp.{dashed,dotted,double}` | `BorderStyleTests::test{Dashed,Dotted,Double}*`, `SpecGapTests::testBorderStyle*RoundTrip` ✅ | ❌ none | Distinct stroke pattern (dashed vs dotted vs double). |
| `spec.ts:52` | `borderRadius` uniform | `BorderRadius.uniform` | `SpecGapTests::testBorderRadiusUniformRoundTrip`, `testBorderRadiusMapsToVisual` ✅ | `visualCSS`, `kitchenSink` ✅ | Rounded corners. |
| `spec.ts:52` | `borderRadius` per-corner | `BorderRadius.corners` | `SpecGapTests::testBorderRadiusCornersRoundTrip`, `testBorderRadiusPartialCornersRoundTrip` ✅ | `cornerRadius` ✅ | Individually shaped corners. |

### Flexbox

| Spec ref | Feature | Swift type | Unit test | Sample | Manual verify |
|---|---|---|---|---|---|
| `spec.ts:26` | `flexDirection: 'row'` | `FlexDirection.row` | `StyleFieldTranslationTests::testFlexDirectionRow`, `FlexGeometryTests::testDirection_row_*` ✅ | `cards` (≥768), `flexAlign` ✅ | Children laid left-to-right. |
| `spec.ts:26` | `flexDirection: 'column'` | `FlexDirection.column` | `StyleFieldTranslationTests::testFlexDirectionColumn`, `FlexGeometryTests::testDirection_column_*` ✅ | `cards` (default), `kitchenSink` ✅ | Children top-to-bottom. |
| `spec.ts:26` (extension) | `flexDirection: 'row-reverse'/'column-reverse'` | `.rowReverse/.columnReverse` | `StyleFieldTranslationTests::testFlexDirection*ReverseMapsToFlexLayout*`, `FlexGeometryTests::testDirection_rowReverse/columnReverse_*` ✅ | `flexAlign` (`.dir-row-reverse`, `.dir-column-reverse`) ✅ | Order mirrored. |
| `spec.ts:27` | `flexGrow: number` | `Double?` | `StyleFieldTranslationTests::testFlexGrowFractional`, `FlexGeometryTests::testGrow_*` ✅ | `pricing`, `signup`, `constraints` ✅ | Flexible items absorb leftover space. |
| `spec.ts:28` | `flexShrink: number` | `Double?` | `StyleFieldTranslationTests::testFlexShrink*`, `FlexGeometryTests::testShrink_*` ✅ | implicitly via overflow ✅ | Items shrink when overflowing. |
| `spec.ts:29` | `flexBasis: Length` | `FlexBasisValue.length` | `StyleFieldTranslationTests::testFlexBasis{Px,Percent}*`, `SpecGapTests::testFlexBasisLength*` ✅ | `pricing`, `kitchenSink` ✅ | Items start at basis size. |
| `spec.ts:29` | `flexBasis: 'auto'` | `FlexBasisValue.auto` | `SpecGapTests::testFlexBasisAuto*`, `FlexLayoutTests::testFlexBasisEquality` ✅ | (default for many items) ✅ | Items use intrinsic size. |
| `spec.ts:30` | `justifyContent` 6 values | `JustifyContent` | `StyleFieldTranslationTests::testJustifyContentEachValue`, `FlexGeometryTests::testJustify_*` ✅ | `flexAlign`, `kitchenSink` ✅ | Each value distributes space differently. |
| `spec.ts:31` | `alignItems` 4 values | `AlignItems` | `StyleFieldTranslationTests::testAlignItemsEachValue`, `FlexGeometryTests::testAlignItems_*` ✅ | `flexAlign` ✅ | Cross-axis alignment varies per value. |
| `spec.ts:31` (extension) | `alignItems: 'baseline'` | `AlignItems.baseline` | `StyleFieldTranslationTests::testAlignItemsBaselineMapsToFlexLayoutBaseline` ✅ | ❌ none | Items align on text baseline. |
| `spec.ts:32` | `alignSelf` 5 values | `AlignSelf` | `SpecGapTests::testAlignSelfMapsToItemStyle`, `FlexGeometryTests::testAlignSelf_*` ✅ | `flexAlign` (`#self-b`, `#self-c`) ✅ | Per-item override of container `alignItems`. |
| `spec.ts:32` (extension) | `alignSelf: 'baseline'` | `AlignSelf.baseline` | `StyleFieldTranslationTests::testAlignSelfBaselineMapsToFlexLayoutBaseline` ✅ | ❌ none | Single item baseline-aligned. |
| (extension) | `alignContent` 6 values | `AlignContent` | `StyleFieldTranslationTests::testAlignContentEachValueMapsThrough`, `FlexGeometryTests::testAlignContent_*` ✅ | `flexAlign` (`.wrap-reverse`) ✅ | Multi-line packing. |
| `spec.ts:33` | `flexWrap: 'nowrap'` | `FlexWrap.nowrap` | `StyleFieldTranslationTests::testFlexWrapNowrap`, `FlexGeometryTests::testWrap_nowrap_*` ✅ | `marginShowcase` ✅ | Items shrink onto one line. |
| `spec.ts:33` | `flexWrap: 'wrap'` | `FlexWrap.wrap` | `StyleFieldTranslationTests::testFlexWrapWrap`, `FlexGeometryTests::testWrap_wrap_*` ✅ | `kitchenSink`, `flexAlign`, `visualCSS` ✅ | Overflowing items move to next line. |
| `spec.ts:33` (extension) | `flexWrap: 'wrap-reverse'` | `FlexWrap.wrapReverse` | `StyleFieldTranslationTests::testFlexWrapWrapReverseMapsToFlexLayoutWrapReverse`, `FlexGeometryTests::testWrap_wrapReverse_*` ✅ | `flexAlign` (`.wrap-reverse`) ✅ | Lines stack in reverse cross order. |
| `spec.ts:34` | `gap` uniform | `Gap.uniform` | `StyleFieldTranslationTests::testGapUniformSetsTopLevelGap`, `FlexGeometryTests::testGap_mainAxis_addedBetweenItems` ✅ | `cards`, `flexAlign`, many ✅ | Equal spacing between items. |
| `spec.ts:35` | `rowGap` | `Length` | `StyleFieldTranslationTests::testGapAxesSetsRowAndColumnSeparately`, `SpecGapTests::testRowGapMapsToContainer` ✅ | `visualCSS` ✅ | Vertical-only spacing in row container. |
| `spec.ts:36` | `columnGap` | `Length` | `StyleFieldTranslationTests::testGapAxesSetsRowAndColumnSeparately`, `SpecGapTests::testColumnGapMapsToContainer` ✅ | `visualCSS` ✅ | Horizontal-only spacing. |
| `spec.ts:37` | `order: number` | `Int?` | `StyleFieldTranslationTests::testOrder`, `FlexGeometryTests::testOrder_reordersVisualPosition` ✅ | `flexAlign` (`#order-a/b/c`) ✅ | Items render in numeric `order` not source order. |

### Typography

| Spec ref | Feature | Swift type | Unit test | Sample | Manual verify |
|---|---|---|---|---|---|
| `spec.ts:55` | `fontFamily: string` | `String?` | `FontFamilyTests::testCustomFontFamilyProducesNonNilFont`, `testCustomFontFamilyDiffersFromSystemFont`, `testSystemFallbackWhenFontFamilyAbsent` ✅ | `visualCSS`, `kitchenSink` ✅ | Distinct typeface where set. |
| `spec.ts:56` | `fontSize: Length<px>` | `Length` | `SpecGapTests::testTypographyMapsToVisual` ✅ | `visualCSS`, `kitchenSink` ✅ | Text size matches px value. |
| `spec.ts:57` | `fontWeight: 'normal'/'bold'/100..900` | `FontWeight` | `FontWeightMappingTests::testWeight*Is*` (9 buckets), `SpecGapTests::testFontWeight*RoundTrip` ✅ | `decorations` (100/400/700/900) ✅ | Visibly different weights. |
| `spec.ts:58` | `fontStyle: 'normal'/'italic'` | `FontStyleProp` | `FontFamilyTests::testFontStyleItalicCarriesThrough`, `JoyDOMViewIntegrationTests::testFontStyleItalicReachesVisualStyle` ✅ | `decorations` ✅ | Italic slant visible. |
| `spec.ts:59` | `color: hex` | `String?` | `SpecGapTests::testTypographyMapsToVisual` ✅ | `visualCSS`, `decorations` ✅ | Glyph paint matches hex. |
| `spec.ts:60` | `textDecoration: 'underline'` | `TextDecoration.underline` | `JoyDOMTextDecorationCascadeTests::testJoyDOMViewBuildsWithUnderlineOnContainer`, `testDecoratedTextBuildsForEachDecoration` ✅ | `decorations` (`.dec-underline`) ✅ | Underline below glyphs. |
| `spec.ts:60` | `textDecoration: 'line-through'` | `TextDecoration.lineThrough` | `JoyDOMTextDecorationCascadeTests::testJoyDOMViewBuildsWithLineThroughOnContainer` ✅ | `decorations` (`.dec-strike`) ✅ | Strike line through glyphs. |
| `spec.ts:60` | `textDecoration: 'none'` | `TextDecoration.none` | `JoyDOMTextDecorationCascadeTests::testJoyDOMViewBuildsWithNoneDecoration`, `testEnvironmentDefaultIsNone` ✅ | (default) ✅ | No decoration. |
| `spec.ts:61` | `textAlign: 'left'/'center'/'right'` | `TextAlign` | `JoyDOMViewIntegrationTests::testTextAlignReachesVisualStyle` ✅ | `visualCSS`, `kitchenSink` ✅ | Paragraph alignment changes. |
| `spec.ts:62` | `textTransform: 'uppercase'/'lowercase'/'none'` | `TextTransform` | `JoyDOMViewIntegrationTests::testTextTransformReachesVisualStyle` ✅ | `decorations`, `visualCSS` (`.eyebrow`) ✅ | Casing swaps for the three modes. |
| `spec.ts:63` | `lineHeight: number` | `Double?` | `LineHeightTests::testLineSpacingMatchesTargetMinusSystem`, `testLineSpacingScalesWithFontSize`, `testLineSpacingZeroForUnitMultiplier` ✅ | `visualCSS` ✅ | Wider line gap on multi-line text. |
| `spec.ts:64` | `letterSpacing: Length<px>` | `Length` | `StyleFieldTranslationTests::testLetterSpacingPxStaysAbsolute`, `testLetterSpacingEmScalesByFontSize` ✅ | `visualCSS`, `decorations` ✅ | Tracking visibly wider/tighter. |

### Media

| Spec ref | Feature | Swift type | Unit test | Sample | Manual verify |
|---|---|---|---|---|---|
| `spec.ts:69` | `objectFit: 'fill'/'contain'/'cover'/'none'` | `Style.ObjectFit` enum | `ObjectFitCascadeTests` (4 cases + cascade), `StyleFieldTranslationTests` ✅ | `objectFitGallery`, `responsiveHero`, `backgroundImageWrapper` ✅ | All four modes render distinctly side-by-side; default (no field) = `fill`. |
| `spec.ts:70-73` | `objectPosition: {horizontal,vertical}` | `Style.ObjectPosition` struct + 9-cell `Alignment` mapping | `ObjectFitCascadeTests` (9 alignment combos), `StyleFieldTranslationTests` ✅ | `objectPositionGrid` ✅ | 3×3 grid showing each alignment shifts the cover-crop point. ⚠️ Known limitation: with `objectFit: contain`/`none` and a wrapper much wider than the contained image, alignment falls through to SwiftUI default. |
| `guides/BackgroundImages.md` | wrapper-recipe (`relative` div + absolute `img` + sibling content) | composes of supported fields | `JoyDOMSamplesIntegrityTests::testBackgroundImageWrapperResolvesAbsolutePinnedImageAndContent` ✅ | `backgroundImageWrapper` ✅ | Hero card renders image behind white-text overlay at zIndex layering. |
| (`img` primitive) | `<img>` rendering with `src` extra prop | `_DOMImage` view in `Views/Environment/DOMImage.swift` | `ObjectFitCascadeTests::testDOMImageBuildsForEachObjectFit`, `SpecGapTests::testImgRegisters` ✅ | every image sample (gallery, grid, hero, wrapper) ✅ | AsyncImage loads via picsum.photos; gray placeholder on `.failure`. |

### Text Behavior

| Spec ref | Feature | Swift type | Unit test | Sample | Manual verify |
|---|---|---|---|---|---|
| `spec.ts:70` | `textOverflow: 'clip'/'ellipsis'` | `TextOverflow` | `JoyDOMViewIntegrationTests` (no direct test) — only via Codable in `SpecTests` ⚠️ | ❌ none | Long text in clipped, nowrap container shows `…` (only with the four pre-conditions per `TextStyles.md`). |
| `spec.ts:71` | `whiteSpace: 'normal'/'nowrap'` | `WhiteSpace` | `JoyDOMViewIntegrationTests::testWhiteSpaceReachesVisualStyle` ✅ | ❌ none | `nowrap` text stays one line; `normal` wraps. |

### Selectors

| Spec ref | Feature | Swift type | Unit test | Sample | Manual verify |
|---|---|---|---|---|---|
| `guides/Styles.md` | `type` selector | `Selector` element | `SelectorParserTests::testParsesElementSelector` ✅ | every sample (`p`, `div`) ✅ | Type-targeted styles apply globally. |
| `guides/Styles.md` | `.class` selector | `Selector.class` | `SelectorParserTests::testParsesClassSelector` ✅ | `decorations`, `flexAlign` ✅ | Class-targeted styles apply only to className matches. |
| `guides/Styles.md` | `#id` selector | `Selector.id` | `SelectorParserTests::testParsesIDSelector` ✅ | every sample ✅ | id-targeted styles match unique element. |
| `guides/Styles.md` | Compound (`p.intro`, `div#main.alpha.beta`) | `Compound` | `SelectorParserTests::testParsesCompound*` (5 tests) ✅ | implicit ✅ | Combined selectors match only when all parts hold. |
| (extension) | Descendant combinator (`a b`) | `Combinator.descendant` | `SelectorParserTests::testParsesDescendantCombinator/Chain`, `CascadeIntegrationTests::testDescendantCombinatorMatches` ✅ | ❌ none | Descendant rules apply at any depth. |
| (extension) | Child combinator (`a > b`) | `Combinator.child` | `SelectorParserTests::testParsesChildCombinator*` ✅ | ❌ none | Direct-child rules apply only one level deep. |
| (extension) | Adjacent-sibling (`a + b`) | `SiblingCombinator.adjacent` | `SiblingCombinatorTests::testAdjacent*`, `CascadeIntegrationTests::testAdjacentSiblingCombinatorMatches` ✅ | ❌ none | Only the next sibling matches. |
| (extension) | General-sibling (`a ~ b`) | `SiblingCombinator.general` | `SiblingCombinatorTests::testGeneral*`, `CascadeIntegrationTests::testGeneralSiblingCombinatorMatchesNonImmediate` ✅ | ❌ none | All later siblings match. |
| `guides/Styles.md` | Selector list rejection (`a, b`) | parser rejects | `SelectorParserTests::testRejectsGrouping`, `testParseListSplitsOnComma` ✅ | n/a | n/a (parser-only). |
| `guides/Styles.md` | Attribute / pseudo-class / pseudo-element rejection | parser rejects | `SelectorParserTests::testRejectsAttributeSelector`, `testRejectsPseudoClass*`, `testRejectsPseudoElement*` ✅ | n/a | n/a (parser-only). |

### Cascade

| Spec ref | Feature | Swift type | Unit test | Sample | Manual verify |
|---|---|---|---|---|---|
| `guides/Styles.md` | Document → breakpoint → inline precedence | resolver order | `CascadeIntegrationTests::testInlinePropsStyleBeatsClassSelector`, `testBreakpointPerNodeStyleBeatsBaseInline` ✅ | `cards`, `kitchenSink` ✅ | n/a (well-covered by tests). |
| `guides/Styles.md` | Specificity id > class > type | parser specificity | `SelectorParserTests::testSpecificity*`, `CascadeIntegrationTests::testIDSelectorWinsOverClassAndType`, `testClassSelectorWinsOverType` ✅ | implicit | n/a. |
| `guides/Styles.md` | Equal-specificity → later source wins | `CascadeIntegrationTests::testLaterSourceOrderWinsOnEqualSpecificity` ✅ | n/a | n/a (test-covered). |
| `guides/Styles.md` | Multi-class → source order in `className` array | resolver | `CascadeIntegrationTests::testLaterSourceOrderWinsOnEqualSpecificity` (proxy) ✅ | implicit | n/a. |

### Breakpoints

| Spec ref | Feature | Swift type | Unit test | Sample | Manual verify |
|---|---|---|---|---|---|
| `guides/Breakpoints.md` "width range syntax" `<` | `WidthOperator.lt` | `MediaQueryEvaluatorTests::testWidthLessThan*` (3 tests) ✅ | implicit | n/a (test-covered). |
| `>` / `<=` / `>=` | `WidthOperator.{gt,le,ge}` | `MediaQueryEvaluatorTests::testWidth{GreaterThan,LessThanOrEqual,GreaterThanOrEqual}*` ✅ | `cards`, `signup`, `pricing`, `kitchenSink` (`>=768`, `>=1024`) ✅ | Layout flips at boundary. |
| width without operator | feature exists | `MediaQueryEvaluatorTests::testWidthWithoutOperatorOrValueMatchesAnyViewport` ✅ | n/a | n/a. |
| `orientation: 'portrait'/'landscape'` | `Orientation` | `MediaQueryEvaluatorTests::testOrientation{Portrait,Landscape}Matches` ✅ | `kitchenSink` (orientation=landscape stub) ⚠️ | (Demo can't trigger orientation directly — see §3.) |
| `type: 'print'` | `MediaTypeKind.print` | `MediaQueryEvaluatorTests::testTypePrintMatchesWhenPrintFlagOn` ✅ | ❌ none | (Demo has no print toggle — see §3.) |
| Logical `and` | `LogicalOp.and` | `MediaQueryEvaluatorTests::testLogicalAnd*` (3) ✅ | `kitchenSink` (could combine; not currently demoed) ⚠️ | n/a. |
| Logical `or` | `LogicalOp.or` | `MediaQueryEvaluatorTests::testLogicalOr*` (3) ✅ | ❌ none | n/a. |
| Logical `not` | `LogicalOp.not` | `MediaQueryEvaluatorTests::testNotInvertsInnerMatch`, `testNestedNotAndOrCombinationEvaluatesCorrectly` ✅ | ❌ none | n/a. |
| "Multiple Matching Breakpoints" — specificity-then-source-order | `BreakpointResolver` | `BreakpointResolverTests::testHigherSpecificityWinsOverLowerWhenBothMatch`, `testSpecificityTieBreaksByLaterSourceOrder`, `testThreeWayTieReturnsLastMatching` ✅ | ❌ none | n/a (test-covered, no visible sample). |
| Deep merge `{color,padding}+{color}` → `{newColor,padding}` | resolver | `BreakpointExtrasOverrideTests::testNonOverriddenBaseExtrasSurviveMerge`, `testActiveBreakpointExtrasReplaceMatchingKey`, `BreakpointResolverTests::testBreakpointDeepMergePreservesNonOverriddenFields` ✅ | implicit (`responsiveHero` — `width:100%/height:100%` survive when breakpoint changes only `objectFit`) ✅ | At ≥768px the responsive-hero image flips fit mode but its sizing is preserved. |
| Custom node ordering via `order` style override | resolver | `FlexGeometryTests::testOrder_reordersVisualPosition`, `BreakpointResolverTests::testBreakpointOrderOverrideAppliesAtMatchingViewport` ✅ | `breakpointOrder`, `flexAlign` (`#order-*`) ✅ | Three labelled cards (A/B/C) declared `order: 1,2,3`; breakpoint flips to `3,2,1` at ≥768px. Drag past 768px to see live re-order. |
| Restore-original ordering (omit `order`) | resolver | `BreakpointResolverTests::testRemovingOrderFromBreakpointRestoresPrimaryOrder` ✅ | implicit (`breakpointOrder`) ✅ | Removing `order` from breakpoint reverts to primary value. |
| `display: 'none'` per-breakpoint visibility | resolver | `ComponentResolverTests::testDisplayNoneNodeIsFiltered`, `BreakpointResolverTests::testBreakpointDisplayNoneOverrideHidesNode` ✅ | `breakpointVisibility` ✅ | Three blue slots in a row; middle one hides at ≥768px. |
| Restore-original visibility (omit `display:none`) | resolver | `BreakpointResolverTests::testRemovingDisplayNoneFromBreakpointRestoresVisibility`, `SpecGapTests::testDisplayFlexClearsDisplayNone` ✅ | implicit (`breakpointVisibility`) ✅ | Drag below 768px — middle slot returns. |
| Per-node `nodes:{id:{props}}` overrides | `BreakpointExtrasOverrideTests::testEndToEndSpecResolvesActiveBreakpointExtrasOverride`, `testFlattenBreakpointOverridesSplitsClassNameAndExtras` ✅ | `kitchenSink` (`hero` padding/height at `>=1024`) ✅ | Hero pads/grows at desktop only. |
| Breakpoint-driven `className` swap | `JoyDOMViewIntegrationTests::testBreakpointClassNameReplacesBase` ✅ | ❌ none | n/a. |

### Patterns (guides)

| Spec ref | Feature | Unit test | Sample | Manual verify |
|---|---|---|---|---|
| `TextStyles.md` ellipsis pre-conditions (`overflow:hidden` + `whiteSpace:nowrap` + bounded width + text-direct-child) | ❌ none | ❌ none | Apply all four; long text terminates with `…`. |
| `BackgroundImages.md` wrapper recipe | `JoyDOMSamplesIntegrityTests::testBackgroundImageWrapperResolvesAbsolutePinnedImageAndContent` ✅ | `backgroundImageWrapper` ✅ | Wrapper renders image behind text overlay; zIndex layering correct. |
| Heading elements `h1`–`h6` register as primitives | `SpecGapTests::testHeadingElementsRegister` ✅ | `kitchenSink`, `visualCSS` ✅ | Heading text rendered. |
| `span` primitive registers | `SpecGapTests::testSpanRegisters` ✅ | `decorations`, `kitchenSink` ✅ | Inline span styling. |

---

## 2 · Manual test checklist

Use the FlexDemoApp viewport simulator to drive these. Drag the width slider through the called-out breakpoints and confirm the visible behavior. Pass = matches the description; fail = doesn't.

- [ ] **Hello world renders** — Load `hello`. At any width, expect a single line "Hello, joy-dom!" — no layout, no decoration. Confirms basic primitive registration and Codable round-trip.
- [ ] **Three cards reflow at 768 px** — Load `cards`. Below 768 px the cards stack vertically; at ≥768 px they flow into a row with 16 px gap. Drag across the boundary and confirm the snap. Confirms `flexDirection` toggle in a breakpoint with `>=` operator.
- [ ] **Signup form gains row layout at 768** — Load `signup`. Below 768 px the labelled inputs stack column-wise; at ≥768 px the form rows lay out left-to-right. Confirms breakpoint-driven `flexDirection` cascade onto a real form.
- [ ] **Article paragraphs flow** — Load `article`. Confirm `<p>` blocks separate, headings render larger/bolder, and primitive number/string children render inline. Confirms text-leaf decoration cascade and primitive-value rendering.
- [ ] **Pricing tiers — 3 column at desktop, stacked on phone** — Load `pricing`. At <768 px three tier cards stack vertically; at ≥768 px they sit side-by-side with equal `flexGrow`. Confirms multi-tier flex distribution + breakpoint switch.
- [ ] **Kitchen sink — `≥1024` rule layers on top of `≥768`** — Load `kitchenSink`. Drag from 700 → 800 → 1100. At 800 the features and form rows go horizontal (≥768 rule). At 1100 the hero gains 64 px padding and 320 px height (≥1024 rule). Confirms cumulative cascade across multiple matching breakpoints (specificity ordering).
- [ ] **Kitchen sink — display:none element is invisible** — Load `kitchenSink`. The paragraph with id `hidden-p` ("This node is display:none — it should not be visible.") must not appear at any width. Confirms `display:none` hides the subtree.
- [ ] **Kitchen sink — opacity demo paints faint** — Load `kitchenSink`. Find the `#opacity-demo` block: it should look semi-transparent (~40 %) over its background.
- [ ] **Kitchen sink — overflow scroll shell** — Load `kitchenSink` at very narrow width (≤320 px). Root has `overflow:auto`; expect a scrollbar/scrollable region rather than clipping. Footer (`overflow:hidden`) should clip its long line instead.
- [ ] **Decorations — underline vs line-through vs none** — Load `decorations`. Three labelled rows: underline visible under glyphs, strike line through glyphs, plain row has neither. Confirms `textDecoration` env cascade reaches text leaves.
- [ ] **Decorations — italics + uppercase combine** — Load `decorations`. The italic+uppercase row shows slanted glyphs in ALL CAPS. Confirms `fontStyle` and `textTransform` compose.
- [ ] **Decorations — four font weights are visibly distinct** — Load `decorations`. Rows tagged 100, 400, 700, 900 should look progressively heavier. Confirms numeric `fontWeight` mapping (`FontWeightMappingTests` buckets).
- [ ] **Visual CSS — typography full set** — Load `visualCSS` at 800 px. Confirm: distinct fontFamily on body vs headings; visible `letterSpacing` widening on the eyebrow; line-height widening between body lines; `textAlign:center` on the title; uppercase eyebrow.
- [ ] **Positioning — absolute child anchored, fixed degraded** — Load `positioning` at any width. Expect the relative wrapper to contain three overlay cards positioned by top/left/right. The `position:fixed` diagnostic card renders (degraded to absolute, see Spec gap test).
- [ ] **Positioning — zIndex layering** — Load `positioning`. The card with `zIndex:10` paints over the card with `zIndex:1` even when their boxes overlap visually. Confirms paint order matches numeric zIndex.
- [ ] **Corner radius — 4 distinct corner shapes** — Load `cornerRadius`. Each card on screen has a different per-corner radius (rounded top only, rounded one diagonal, etc.). Confirm visually distinct rounding per corner.
- [ ] **Flex align — alignSelf overrides container** — Load `flexAlign`. The `#self-b` and `#self-c` boxes sit at center/flex-end of their row while siblings sit at flex-start. Confirms `alignSelf` per-item override.
- [ ] **Flex align — `order` rearranges siblings** — Load `flexAlign`. Boxes labelled A/B/C are declared A→B→C but render B → C → A because of `order: 1, 2, 3`. Confirm visual order swap.
- [ ] **Flex align — all 4 directions** — Load `flexAlign`. Inspect the four direction demos (`row`, `column`, `row-reverse`, `column-reverse`): cells laid out left-to-right, top-to-bottom, right-to-left, bottom-to-top respectively.
- [ ] **Flex align — wrap-reverse** — Load `flexAlign`. The `.wrap-reverse` row wraps onto multiple lines but the second line sits **above** the first (cross-axis reversed). Confirms `flexWrap: 'wrap-reverse'`.
- [ ] **Constraints — minWidth raises, maxWidth caps** — Load `constraints`. Drag width 320 → 1400. The min-width box never shrinks below its floor at narrow widths; the max-width box never grows past its cap at wide widths. Confirms clamp ordering.
- [ ] **Constraints — surplus redistributes** — Load `constraints` at wide width. The grow-with-cap box stops at its max; remaining space goes to its uncapped sibling. Confirms `MinMaxConstraintTests::testMaxWidthOnGrowerRedistributesLeftoverToSiblings` visually.
- [ ] **Margin showcase — true flex-item margins** — Load `marginShowcase`. Boxes have visible asymmetric outer space (e.g. left-only or top-only margin) that pushes siblings, distinct from container padding. Confirms `Padding.sides` margin lands on the item not its visual chrome.
- [ ] **Border styles distinct** — Load `cards` (or `visualCSS`) and inspect borders. Solid border renders as one line. (Dashed/dotted/double live in Codable tests but no sample exercises them — see §3.)
- [ ] **Bounded-height visual sample at 280 pt** — Pin viewport to ~280 pt and load `visualCSS`. The full doc should still render in a finite, scroll-friendly height (covered by `VisualCSSSampleHeightTests`); use this as a sanity smoke before recording new layout regressions.
- [ ] **Heading hierarchy renders** — Load `kitchenSink`. h1, h2, h3, h4 must each render at the expected size relative to body `<p>`. Confirms `SpecGapTests::testHeadingElementsRegister` shows up in the demo.

### Image styles (PR #26)

- [ ] **objectFit modes side-by-side** — Load `objectFitGallery`. Four 140×140 frames in a row using the SAME 3:2 picsum source. Confirm: `fill` shows the stump stretched to 1:1 (full content visible, distorted), `contain` letterboxes (sky band top/bottom, full image visible), `cover` fills wrapper with sides cropped, `none` shows intrinsic-size visible-top crop. The right-most caption notes "no objectFit set → CSS default fill" and should look identical to the `fill` cell.
- [ ] **objectPosition 3×3 grid** — Load `objectPositionGrid`. Nine cells with `objectFit: cover` and each of the 3×3 alignment combinations. Crop point shifts per cell — top-row cells emphasize the upper portion of the source, bottom-row cells emphasize the lower; left/center/right shifts the horizontal anchor. Each cell visibly distinct.
- [ ] **Responsive hero — fit flips at 768px** — Load `responsiveHero`. Below 768px the image is in `cover` (fills wrapper edge-to-edge). Drag past 768px — `objectFit` switches to `contain` (image scaled to fit, letterbox visible). Width: 100% and height: 200px from primary cascade survive into the breakpoint (deep-merge proof).
- [ ] **Background-image wrapper recipe** — Load `backgroundImageWrapper`. 320×200 rounded card with a real picsum hero image as full-bleed background and "Background image via wrapper" white text overlaid bottom-left. Image at zIndex 0, text at zIndex 1 — text reads cleanly over image.
- [ ] **Breakpoint visibility — middle slot toggles** — Load `breakpointVisibility`. Below 768px see three blue rectangles in a row. Drag past 768px — middle rectangle disappears; left and right remain visible at full width. Drag back below — middle returns.
- [ ] **Breakpoint order — ABC ↔ CBA at 768px** — Load `breakpointOrder`. Below 768px the three labelled cards render in declared `order: 1, 2, 3` (A → B → C). At ≥768px breakpoint flips to `order: 3, 2, 1` so visual order is C → B → A. Confirms breakpoint-driven re-ordering and restore-original via the spec example.

---

## 3 · Coverage gaps

### Real spec gaps (still open)

- **`spec.ts:16` `boxSizing: 'border-box'` end-to-end visibility** — Layout deduction now works in code (PR #25), but no sample shows the visible difference between `content-box` (default) and `border-box` for a bordered, padded box of declared width. Closure: a small two-card comparison sample.
- **`spec.ts:70` `textOverflow: 'ellipsis'`** — Codable round-trip in `SpecTests` but no test asserts the rendered ellipsis, and no sample wires the four pre-conditions from `TextStyles.md`. Closure: an `ellipsisDemo` sample with a constrained-width nowrap-clip line.
- **`spec.ts:71` `whiteSpace: 'nowrap'`** — `JoyDOMViewIntegrationTests::testWhiteSpaceReachesVisualStyle` covers data flow but no sample shows the visible difference. Closure: pair with the ellipsis sample above.
- **`Breakpoints.md` `print` media type** — `MediaQueryEvaluator` supports `print`, but `FlexDemoApp` has no toggle to flip the print flag. Closure: add a "Simulate print" toggle on the demo viewport bar OR mark deferred.
- **`Breakpoints.md` `orientation`** — Same as print: evaluator-supported but demo has no orientation toggle (the `kitchenSink` orientation breakpoint is dormant). Closure: add a portrait/landscape switch to demo OR mark deferred.
- **`Breakpoints.md` "Multiple Matching Breakpoints" specificity demo** — Tests cover specificity ordering but no sample displays two overlapping conditions side-by-side with a visible "which won" indicator. Closure: a small sample with two breakpoints whose conditions both match at one viewport, labelled with which rule's color wins.
- **`borderStyle: 'dashed'/'dotted'/'double'`** — Tests cover Codable + visual mapping (`BorderStyleTests`) but no sample exercises them visually. Closure: a 4-strip border-style gallery sample (solid / dashed / dotted / double).
- **`alignItems: 'baseline'` and `alignSelf: 'baseline'`** — Mapped through to FlexLayout but not exercised by any sample; visual confirmation that text baselines align across mixed-size siblings is missing. Closure: a baseline-row sample with three different fontSize labels.
- **Selector combinators (descendant, child, adjacent-sibling, general-sibling)** — All four combinators have parser + cascade tests but no sample relies on them. Closure: an optional `combinatorDemo` sample showing each rule firing on a small tree.

### Documented behavioural limitations (not gaps in spec coverage)

- **`objectFit: contain`/`none` + non-default `objectPosition` alignment** — When the wrapper is significantly wider than the contained image's natural fit-size, the image anchors at SwiftUI's default position rather than the spec's `objectPosition` (default `.center`). Documented in `_DOMImage` source. Patterns that *would* honor it (`Color.clear.overlay`, `GeometryReader`) caused a SwiftUI/FlexLayout layout-renegotiation cycle that hung the UI on every viewport change. Proper fix needs hosted snapshot tests to reproduce the cycle in isolation. `cover` and `fill` modes are unaffected.
- **`position: fixed` / `sticky`** — Spec extension we ship; mapped to `.absolute` with a diagnostic warning at resolve time (`SpecGapTests::testPositionFixedEmitsDiagnostic`). SwiftUI has no native `position: fixed`/`sticky` semantics; mark as known-degraded.
