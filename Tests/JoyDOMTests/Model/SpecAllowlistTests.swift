// SpecAllowlistTests — defensive CI gate that every sample JSON
// shipping under `Sources/JoyDOMSampleSpecs/Resources/` (other than
// the `*-ios-ext/` sibling folders) only uses property names and
// values that the JoyDOM cross-platform spec allows.
//
// Mirrors the allowlist documented in `docs/JoyDOM-Spec-Allowlist.md`.
// Properties / values that the iOS impl supports but the cross-platform
// spec doesn't (`alignContent`, `flexDirection: row-reverse`, negative
// `Length<"px">`, `textTransform: capitalize`, etc.) MUST live in a
// sibling `*-ios-ext/` folder, which this test skips. Anything outside
// `*-ios-ext/` that uses an out-of-spec property or value fails CI —
// preventing the kind of cross-renderer-failure surfaced when the
// Kotlin renderer choked on `alignContent`, `gap: { c, r }`, negative
// margins, and `textTransform: capitalize` (fixed in PR #95).
//
// The validation runs against the RAW JSON via `JSONSerialization`
// rather than Codable-decoded `Spec` types — Swift's enums would mask
// some violations as decode errors and shadow others (e.g. negative
// `Length` decodes fine through `Codable`). Walking the raw dict
// catches everything the Kotlin renderer would.

import XCTest
@testable import JoyDOM
import JoyDOMSampleSpecs

final class SpecAllowlistTests: XCTestCase {

    // MARK: - Allowlist (mirrors docs/JoyDOM-Spec-Allowlist.md)

    /// Every CSS property the JoyDOM cross-platform spec allows. Anything
    /// outside this set in a non-ios-ext sample fails the audit.
    private static let allowedProperties: Set<String> = [
        // Layout & Positioning
        "position", "display", "boxSizing", "zIndex", "overflow",
        "top", "left", "bottom", "right",
        // Flexbox
        "flexDirection", "flexGrow", "flexShrink", "flexBasis",
        "justifyContent", "alignItems", "alignSelf", "flexWrap",
        "gap", "rowGap", "columnGap", "order",
        // Sizing
        "width", "height", "minWidth", "maxWidth", "minHeight", "maxHeight",
        // Box Model & Visuals
        "backgroundColor", "opacity", "padding", "margin",
        "borderWidth", "borderColor", "borderStyle", "borderRadius",
        // Typography
        "fontFamily", "fontSize", "fontWeight", "fontStyle", "color",
        "textDecoration", "textAlign", "textTransform",
        "lineHeight", "letterSpacing",
        // Text Behavior
        "textOverflow", "whiteSpace",
        // Media
        "objectFit", "objectPosition",
    ]

    /// String-valued enum constraints. For each property, the set of
    /// allowed string values. Numeric values (e.g. fontWeight 100-900)
    /// are validated separately below.
    private static let allowedEnumValues: [String: Set<String>] = [
        "position":        ["absolute", "relative"],
        "display":         ["flex", "none"],
        "boxSizing":       ["border-box"],
        "overflow":        ["visible", "hidden", "clip", "scroll", "auto"],
        "flexDirection":   ["row", "column"],
        "flexWrap":        ["nowrap", "wrap"],
        "justifyContent":  ["flex-start", "flex-end", "center",
                            "space-between", "space-around", "space-evenly"],
        "alignItems":      ["flex-start", "flex-end", "center", "stretch"],
        "alignSelf":       ["auto", "flex-start", "flex-end", "center", "stretch"],
        "borderStyle":     ["solid", "none"],
        "fontStyle":       ["normal", "italic"],
        "textDecoration":  ["none", "underline", "line-through"],
        "textAlign":       ["left", "center", "right"],
        "textTransform":   ["none", "uppercase", "lowercase"],
        "whiteSpace":      ["normal", "nowrap"],
        "objectFit":       ["fill", "contain", "cover", "none"],
        "textOverflow":    ["clip", "ellipsis"],
    ]

    /// `fontWeight` accepts strings `"normal"`/`"bold"` OR numeric
    /// 100/200/.../900 (per CSS Fonts L4).
    private static let allowedFontWeightStrings: Set<String> = ["normal", "bold"]
    private static let allowedFontWeightNumbers: Set<Int> = [100, 200, 300, 400, 500, 600, 700, 800, 900]

    /// Properties whose `Length<"px">` value must be non-negative.
    /// (Padding, margin, gap, borderWidth, fontSize, letterSpacing.)
    private static let nonNegativeLengthProperties: Set<String> = [
        "padding", "margin", "gap", "rowGap", "columnGap",
        "borderWidth", "fontSize", "letterSpacing",
        "width", "height", "minWidth", "maxWidth", "minHeight", "maxHeight",
    ]

    /// objectPosition keyword axes.
    private static let objectPositionHorizontal: Set<String> = ["left", "center", "right"]
    private static let objectPositionVertical:   Set<String> = ["top", "center", "bottom"]

    // MARK: - Test

    /// Iterates every shipped sample, parses its raw JSON, and walks
    /// the `style` block (plus every breakpoint override's `style`
    /// block) checking each declaration against the allowlist above.
    /// Samples whose manifest `file` path contains `-ios-ext/` are
    /// skipped — those are the explicit iOS-only sibling folders.
    func testAllSamplesUseOnlyAllowlistedPropertiesAndValues() {
        var violations: [String] = []
        var samplesAudited = 0
        var samplesSkipped = 0

        for sample in SpecPropertySamples.all {
            // Skip *-ios-ext/ samples — they're cross-platform out-of-spec by design.
            if sample.file.contains("-ios-ext/") {
                samplesSkipped += 1
                continue
            }
            samplesAudited += 1

            guard let data = sample.json.data(using: .utf8),
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                violations.append("\(sample.file): could not parse JSON")
                continue
            }

            // Top-level style block
            if let style = obj["style"] as? [String: Any] {
                checkStyle(style, in: sample.file, violations: &violations)
            }
            // Breakpoint style overrides
            if let breakpoints = obj["breakpoints"] as? [[String: Any]] {
                for (idx, bp) in breakpoints.enumerated() {
                    if let bpStyle = bp["style"] as? [String: Any] {
                        checkStyle(bpStyle, in: "\(sample.file) (breakpoint \(idx))", violations: &violations)
                    }
                }
            }
        }

        if !violations.isEmpty {
            let msg = """
            \(violations.count) cross-platform spec violation\(violations.count == 1 ? "" : "s") found across \(samplesAudited) audited sample\(samplesAudited == 1 ? "" : "s") \
            (\(samplesSkipped) ios-ext samples skipped):

            \(violations.joined(separator: "\n"))

            Fix by either (a) changing the sample to use a spec-allowed value, or \
            (b) moving the file to a sibling `<property>-ios-ext/` folder if it \
            exercises a Swift-only behavior the cross-platform spec doesn't model. \
            See docs/JoyDOM-Spec-Allowlist.md for the full allowlist.
            """
            XCTFail(msg)
        }
    }

    // MARK: - Per-style-block walker

    private func checkStyle(_ style: [String: Any], in fileLabel: String,
                            violations: inout [String]) {
        for (selector, declsAny) in style {
            guard let decls = declsAny as? [String: Any] else { continue }
            for (prop, value) in decls {
                let ctx = "[\(selector)]/\(prop)"
                checkDeclaration(prop: prop, value: value, ctx: ctx,
                                 fileLabel: fileLabel, violations: &violations)
            }
        }
    }

    private func checkDeclaration(prop: String, value: Any, ctx: String,
                                  fileLabel: String, violations: inout [String]) {
        // 1. Property name allowlisted?
        guard Self.allowedProperties.contains(prop) else {
            violations.append("\(fileLabel) \(ctx): unsupported property `\(prop)` (not in spec allowlist)")
            return
        }

        // 2. Enum-valued property?
        if let allowed = Self.allowedEnumValues[prop] {
            if let s = value as? String, !allowed.contains(s) {
                violations.append("\(fileLabel) \(ctx): `\(prop): \"\(s)\"` not in allowed values \(allowed.sorted())")
            }
            return
        }

        // 3. fontWeight (mixed string + numeric)
        if prop == "fontWeight" {
            if let s = value as? String, !Self.allowedFontWeightStrings.contains(s) {
                violations.append("\(fileLabel) \(ctx): `fontWeight: \"\(s)\"` (allowed strings: normal, bold)")
            } else if let n = value as? Int, !Self.allowedFontWeightNumbers.contains(n) {
                violations.append("\(fileLabel) \(ctx): `fontWeight: \(n)` (allowed numbers: 100/200/.../900)")
            } else if let n = value as? Double {
                let i = Int(n)
                if Double(i) == n, !Self.allowedFontWeightNumbers.contains(i) {
                    violations.append("\(fileLabel) \(ctx): `fontWeight: \(n)` (allowed numbers: 100/200/.../900)")
                }
            }
            return
        }

        // 4. objectPosition — structured h x v
        if prop == "objectPosition" {
            if let dict = value as? [String: Any] {
                let h = dict["horizontal"] as? String ?? ""
                let v = dict["vertical"] as? String ?? ""
                if !Self.objectPositionHorizontal.contains(h) || !Self.objectPositionVertical.contains(v) {
                    violations.append("\(fileLabel) \(ctx): `objectPosition: { horizontal: \(h), vertical: \(v) }` not in allowed combos")
                }
            } else if let s = value as? String {
                let parts = s.split(separator: " ").map(String.init)
                if parts.count != 2 ||
                   !Self.objectPositionHorizontal.contains(parts[0]) ||
                   !Self.objectPositionVertical.contains(parts[1]) {
                    violations.append("\(fileLabel) \(ctx): `objectPosition: \"\(s)\"` not in allowed combos")
                }
            }
            return
        }

        // 5. padding / margin (Length OR { top, right, bottom, left } per-side)
        if prop == "padding" || prop == "margin" {
            validateLengthOrPerSide(value: value, prop: prop, ctx: ctx,
                                    fileLabel: fileLabel, violations: &violations)
            return
        }

        // 6. borderRadius (Length OR { topLeft, topRight, bottomRight, bottomLeft })
        if prop == "borderRadius" {
            if let dict = value as? [String: Any] {
                if dict["value"] != nil && dict["unit"] != nil {
                    // single Length form — validate as length
                    validateLength(value: dict, prop: prop, ctx: ctx,
                                   fileLabel: fileLabel, violations: &violations)
                } else {
                    let allowed: Set<String> = ["topLeft", "topRight", "bottomRight", "bottomLeft"]
                    for (k, v) in dict {
                        if !allowed.contains(k) {
                            violations.append("\(fileLabel) \(ctx): unsupported key `\(k)` in borderRadius object form")
                        } else if let lv = v as? [String: Any] {
                            validateLength(value: lv, prop: "\(prop).\(k)", ctx: ctx,
                                           fileLabel: fileLabel, violations: &violations)
                        }
                    }
                }
            }
            return
        }

        // 7. Plain Length<"px"> (or Length<"px"|"%">) properties — single value form.
        if Self.nonNegativeLengthProperties.contains(prop) {
            if let dict = value as? [String: Any] {
                validateLength(value: dict, prop: prop, ctx: ctx,
                               fileLabel: fileLabel, violations: &violations)
            }
        }
    }

    private func validateLengthOrPerSide(value: Any, prop: String, ctx: String,
                                         fileLabel: String, violations: inout [String]) {
        guard let dict = value as? [String: Any] else { return }
        if dict["value"] != nil && dict["unit"] != nil {
            validateLength(value: dict, prop: prop, ctx: ctx,
                           fileLabel: fileLabel, violations: &violations)
        } else {
            let allowed: Set<String> = ["top", "right", "bottom", "left"]
            for (k, v) in dict {
                if !allowed.contains(k) {
                    violations.append("\(fileLabel) \(ctx): unsupported key `\(k)` in \(prop) object form (allowed: top/right/bottom/left)")
                } else if let lv = v as? [String: Any] {
                    validateLength(value: lv, prop: "\(prop).\(k)", ctx: ctx,
                                   fileLabel: fileLabel, violations: &violations)
                }
            }
        }
    }

    /// Validates a Length-shaped dict `{ value, unit }`. Catches non-Length
    /// shapes (e.g. `gap: { c: ..., r: ... }`) and negative values on
    /// properties that require non-negative.
    private func validateLength(value: [String: Any], prop: String, ctx: String,
                                fileLabel: String, violations: inout [String]) {
        guard value["value"] != nil, let unit = value["unit"] as? String else {
            violations.append("\(fileLabel) \(ctx): invalid Length shape for \(prop) — expected { value, unit }, got \(value)")
            return
        }
        guard unit == "px" || unit == "%" else {
            violations.append("\(fileLabel) \(ctx): unsupported unit `\(unit)` for \(prop) (allowed: px, %)")
            return
        }
        // Non-negative check
        let baseProp = prop.split(separator: ".").first.map(String.init) ?? prop
        if Self.nonNegativeLengthProperties.contains(baseProp) {
            if let n = value["value"] as? Double, n < 0 {
                violations.append("\(fileLabel) \(ctx): negative Length `\(prop): \(n)\(unit)` (must be non-negative)")
            } else if let n = value["value"] as? Int, n < 0 {
                violations.append("\(fileLabel) \(ctx): negative Length `\(prop): \(n)\(unit)` (must be non-negative)")
            }
        }
    }
}
