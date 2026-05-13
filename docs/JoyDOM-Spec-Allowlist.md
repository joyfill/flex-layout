# JoyDOM CSS Spec Allowlist

A flat, copy-pasteable list of **every property and value JoyDOM samples may use**. Mirror of the canonical
[`j0yhq/joy-dom` CSS spec](https://github.com/j0yhq/joy-dom/blob/main/apps/website/content/docs/css.mdx).

**Use this when authoring property-coverage samples** (Step 2 of [`Property-Coverage-Walkthrough.md`](Property-Coverage-Walkthrough.md)).
A sample that uses any property or value NOT listed here is out of spec and will produce iOS-only artifacts that JS / Kotlin runtimes can never match — exactly the opposite of what the cross-platform sample set is for.

For deeper per-property notes (impl seam, test coverage, known caveats) see [`Spec-Property-Reference.md`](Spec-Property-Reference.md). This doc is intentionally terse.

> **`display: flex` is mandatory on every flex container in every sample.** The JoyDOM spec defines `display` with only two values: `'flex' | 'none'`. There is no implicit flex layout — a sample omitting `display: flex` on its root container is malformed even if joydom-swift happens to render it. Always declare it explicitly.

---

## Spec sync

| | |
|---|---|
| Spec source | `apps/website/content/docs/css.mdx` |
| Snapshot date | 2026-05-13 |

To refresh:
```bash
gh api repos/j0yhq/joy-dom/contents/apps/website/content/docs/css.mdx \
  --jq '.content' | base64 -d
```

---

## Length type

Every property listed as `Length<'px'>` or `Length<'px' | '%'>` takes the typed object form. **Never use bare numbers.**

```json
{ "value": 16, "unit": "px" }
{ "value": 50, "unit": "%" }
```

---

## 1. Layout & Positioning

| Property | Legal values |
|---|---|
| `position` | `"absolute"` · `"relative"` |
| `display` | `"flex"` · `"none"` |
| `boxSizing` | `"border-box"` |
| `zIndex` | `number` |
| `overflow` | `"visible"` · `"hidden"` · `"clip"` · `"scroll"` · `"auto"` |
| `top` · `left` · `bottom` · `right` | `Length<"px">` |

## 2. Flexbox

| Property | Legal values |
|---|---|
| `flexDirection` | `"row"` · `"column"` |
| `flexGrow` | `number` |
| `flexShrink` | `number` |
| `flexBasis` | `Length<"px" \| "%">` · `"auto"` |
| `justifyContent` | `"flex-start"` · `"flex-end"` · `"center"` · `"space-between"` · `"space-around"` · `"space-evenly"` |
| `alignItems` | `"flex-start"` · `"flex-end"` · `"center"` · `"stretch"` |
| `alignSelf` | `"auto"` · `"flex-start"` · `"flex-end"` · `"center"` · `"stretch"` |
| `flexWrap` | `"nowrap"` · `"wrap"` |
| `gap` · `rowGap` · `columnGap` | `Length<"px">` |
| `order` | `number` |

## 3. Sizing

| Property | Legal values |
|---|---|
| `width` · `height` | `Length<"px" \| "%">` |
| `minWidth` · `maxWidth` · `minHeight` · `maxHeight` | `Length<"px">` |

## 4. Box Model & Visuals

| Property | Legal values |
|---|---|
| `backgroundColor` | hex string (e.g. `"#EF4444"`) |
| `opacity` | `number` (0–1) |
| `padding` · `margin` | `Length<"px">` · `{ top, right, bottom, left: Length<"px"> }` |
| `borderWidth` | `Length<"px">` |
| `borderColor` | hex string |
| `borderStyle` | `"solid"` · `"none"` |
| `borderRadius` | `Length<"px">` · `{ topLeft, topRight, bottomRight, bottomLeft: Length<"px"> }` |

## 5. Typography

| Property | Legal values |
|---|---|
| `fontFamily` | string |
| `fontSize` | `Length<"px">` |
| `fontWeight` | `"normal"` · `"bold"` · `100` · `200` · `300` · `400` · `500` · `600` · `700` · `800` · `900` |
| `fontStyle` | `"normal"` · `"italic"` |
| `color` | hex string |
| `textDecoration` | `"none"` · `"underline"` · `"line-through"` |
| `textAlign` | `"left"` · `"center"` · `"right"` |
| `textTransform` | `"none"` · `"uppercase"` · `"lowercase"` |
| `lineHeight` | `number` (multiplier) |
| `letterSpacing` | `Length<"px">` |

## 6. Text Behavior

| Property | Legal values |
|---|---|
| `textOverflow` | `"clip"` · `"ellipsis"` |
| `whiteSpace` | `"normal"` · `"nowrap"` |

## 7. Media

| Property | Legal values |
|---|---|
| `objectFit` | `"fill"` · `"contain"` · `"cover"` · `"none"` |
| `objectPosition` | `horizontal vertical` where horizontal ∈ {`left`, `center`, `right`} and vertical ∈ {`top`, `center`, `bottom`} (e.g. `"left top"`, `"center center"`) |

---

## DO NOT USE (joydom-swift extensions that are out of cross-platform scope)

These values render correctly in joydom-swift but are NOT in the canonical spec. Samples using them must live under a sibling `*-ios-ext/` folder with their own test method (see [Walkthrough §1c](Property-Coverage-Walkthrough.md#1-scope-the-property)). They will never have JS/Kotlin parity.

| Property | Out-of-spec values |
|---|---|
| `position` | `"fixed"`, `"sticky"` |
| `display` | `"block"`, `"inline"`, `"inline-block"`, `"inline-flex"` |
| `flexDirection` | `"row-reverse"`, `"column-reverse"` |
| `alignItems` · `alignSelf` | `"baseline"` |
| `flexWrap` | `"wrap-reverse"` |
| `alignContent` | **entire property** (not in spec at all) |
| `borderStyle` | `"dashed"`, `"dotted"`, `"double"` |

---

## Quick sanity check for a finished sample

Before recording baselines (Step 5), grep your new JSONs:

```bash
# Every flex container must explicitly declare display: flex.
for f in <your-new-samples>/*.json; do
  grep -q '"display"[[:space:]]*:[[:space:]]*"flex"' "$f" || echo "MISSING display:flex in $f"
done

# Out-of-spec values — property-scoped to avoid false positives on className
# arrays that happen to include reserved CSS keywords like `.fixed` / `.sticky`.
grep -nE '"position"[[:space:]]*:[[:space:]]*"(fixed|sticky)"'                            <your-new-samples>/*.json
grep -nE '"display"[[:space:]]*:[[:space:]]*"(block|inline|inline-block|inline-flex)"'    <your-new-samples>/*.json
grep -nE '"flexDirection"[[:space:]]*:[[:space:]]*"(row-reverse|column-reverse)"'         <your-new-samples>/*.json
grep -nE '"flexWrap"[[:space:]]*:[[:space:]]*"wrap-reverse"'                              <your-new-samples>/*.json
grep -nE '"(alignItems|alignSelf)"[[:space:]]*:[[:space:]]*"baseline"'                    <your-new-samples>/*.json
grep -nE '"borderStyle"[[:space:]]*:[[:space:]]*"(dashed|dotted|double)"'                 <your-new-samples>/*.json
grep -nE '"alignContent"[[:space:]]*:'                                                    <your-new-samples>/*.json
```

If any line prints, fix before proceeding. Each grep is property-scoped (the
left side requires `"propertyName":`) so className arrays like
`["box", "fixed"]` will not trigger the position-fixed screen. Even so, prefer
class names that don't read like CSS values (use `.no-shrink`, not `.fixed`)
to keep human-scanning of JSON unambiguous.
