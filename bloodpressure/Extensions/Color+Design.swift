import SwiftUI

extension Color {
    // Primary Brand Color
    static let softRed = Color(hex: "FF6B6B")
    
    // Backgrounds
    static let pureWhite = Color(hex: "FFFFFF")
    static let offWhite = Color(hex: "FAFAFA")
    
    // Text
    static let slate = Color(hex: "2D3436")
    
    // Status
    static let softTeal = Color(hex: "00B894")
    static let softOrange = Color(hex: "FAB1A0") // Slightly adjusted for visibility
    static let bpHigh = softRed
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
