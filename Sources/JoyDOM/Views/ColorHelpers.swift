// ColorHelpers — SwiftUI Color extensions for joy-dom style values.

import SwiftUI

extension Color {
    /// Initialise from a hex string. Accepts the CSS-standard forms:
    /// `"#RGB"` (3-digit shorthand, each nibble doubled to form a byte),
    /// `"#RGBA"` (4-digit shorthand with alpha), `"#RRGGBB"` (6-digit),
    /// `"#RRGGBBAA"` (8-digit with alpha). The leading `#` is optional.
    /// Returns `.clear` for malformed inputs so a bad color value degrades
    /// gracefully rather than crashing the render.
    init(hex: String) {
        let raw = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        var rgb: UInt64 = 0
        guard Scanner(string: raw).scanHexInt64(&rgb) else {
            self = .clear
            return
        }
        switch raw.count {
        case 3:
            // #RGB → expand each nibble: 0xR → 0xRR
            let r = (rgb >> 8) & 0xF
            let g = (rgb >> 4) & 0xF
            let b =  rgb       & 0xF
            self = Color(
                red:   Double((r << 4) | r) / 255,
                green: Double((g << 4) | g) / 255,
                blue:  Double((b << 4) | b) / 255
            )
        case 4:
            // #RGBA → expand each nibble: 0xR → 0xRR (with alpha)
            let r = (rgb >> 12) & 0xF
            let g = (rgb >>  8) & 0xF
            let b = (rgb >>  4) & 0xF
            let a =  rgb        & 0xF
            self = Color(
                red:     Double((r << 4) | r) / 255,
                green:   Double((g << 4) | g) / 255,
                blue:    Double((b << 4) | b) / 255,
                opacity: Double((a << 4) | a) / 255
            )
        case 6:
            self = Color(
                red:   Double((rgb >> 16) & 0xFF) / 255,
                green: Double((rgb >>  8) & 0xFF) / 255,
                blue:  Double( rgb        & 0xFF) / 255
            )
        case 8:
            self = Color(
                red:   Double((rgb >> 24) & 0xFF) / 255,
                green: Double((rgb >> 16) & 0xFF) / 255,
                blue:  Double((rgb >>  8) & 0xFF) / 255,
                opacity: Double(rgb & 0xFF) / 255
            )
        default:
            self = .clear
        }
    }
}
