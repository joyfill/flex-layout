# Bundled fonts — licenses & provenance

The font files in this directory are vendored from the [joy-dom](https://github.com/j0yhq/joy-dom)
JS runtime to give JoyDOM cross-runtime visual parity. JoyDOM tests render
`fontFamily` samples against these bundled families so SwiftUI snapshots
match what the JS runtime produces in fixtures.

## Mirror origin

- Repository: [j0yhq/joy-dom](https://github.com/j0yhq/joy-dom)
- SHA: `e0d49e209fe6765e282a7a6220d52e3f5bfd6b59`
- Path: `packages/react/tests/fixtures-assets/`
- Snapshotted on: 2026-05-18

This is a static snapshot — there is no automatic sync. If joy-dom updates its
fixture fonts and JoyDOM needs to follow, re-run the vendor step manually and
record the new SHA here.

## Families

### Geist & Geist Mono
- License: [SIL Open Font License 1.1](https://openfontlicense.org/)
- Copyright: 2023 Vercel, Inc.; design by Basement Studio + Vercel
- Upstream: https://github.com/vercel/geist-font
- Files:
  - `Geist[wght].woff2` (variable-weight roman)
  - `Geist-Italic[wght].woff2` (variable-weight italic)
  - `GeistMono[wght].woff2` (variable-weight roman)
  - `GeistMono-Italic[wght].woff2` (variable-weight italic)

The `[wght]` suffix in the filenames is the OpenType variable-font axis tag —
it identifies these as single-file variable fonts whose `wght` axis spans the
full weight range (100–900). The brackets are intentional and must be preserved.

### Libre Baskerville
- License: [SIL Open Font License 1.1](https://openfontlicense.org/)
- Copyright: 2012 Impallari Type (www.impallari.com)
- Upstream: https://fonts.google.com/specimen/Libre+Baskerville
- Files:
  - `LibreBaskerville-VariableFont_wght.ttf`
  - `LibreBaskerville-Italic-VariableFont_wght.ttf`

## OFL 1.1 summary

The SIL Open Font License permits redistribution, modification, and embedding
of these fonts so long as the OFL notices accompany them. By keeping this
LICENSES.md alongside the font binaries we satisfy that requirement; the full
OFL text is available at the link above.
