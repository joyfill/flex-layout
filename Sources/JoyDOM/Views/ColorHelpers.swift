// ColorHelpers — SwiftUI Color extensions for joy-dom style values.

import SwiftUI

extension Color {
    /// Initialise from a hex string such as `"#FF0000"` or `"FF0000"`.
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
