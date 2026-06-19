import SwiftUI

/// Pastel palette + ring gradients, shared between the app, the widgets and the Live Activity.
enum Palette {
    // Text
    static let ink = Color(red: 0.17, green: 0.17, blue: 0.33)   // deep navy
    static let sub = Color(red: 0.53, green: 0.52, blue: 0.65)

    // Backgrounds
    static let bgFastTop = Color(red: 0.93, green: 0.91, blue: 1.00)
    static let bgFastBot = Color(red: 0.85, green: 0.90, blue: 1.00)
    static let bgEatTop  = Color(red: 0.92, green: 0.98, blue: 0.93)
    static let bgEatBot  = Color(red: 0.99, green: 0.97, blue: 0.88)

    // Ring track
    static let track = Color(red: 0.89, green: 0.87, blue: 0.96)

    // Ring gradients (blue → lilac → pink → peach for fasting ; greens for eating)
    static let fastRing: [Color] = [
        Color(red: 0.60, green: 0.68, blue: 1.00),
        Color(red: 0.82, green: 0.64, blue: 0.97),
        Color(red: 1.00, green: 0.61, blue: 0.74),
        Color(red: 1.00, green: 0.73, blue: 0.52)
    ]
    static let eatRing: [Color] = [
        Color(red: 0.43, green: 0.80, blue: 0.56),
        Color(red: 0.68, green: 0.89, blue: 0.54)
    ]
    static let fastGlow = Color(red: 1.00, green: 0.60, blue: 0.78)
    static let eatGlow  = Color(red: 0.49, green: 0.82, blue: 0.55)

    // Accents (percentage text, icons)
    static let fastAccent = Color(red: 0.49, green: 0.43, blue: 0.86)
    static let eatAccent  = Color(red: 0.30, green: 0.66, blue: 0.43)
    static let peach      = Color(red: 1.00, green: 0.64, blue: 0.34)

    static func bg(_ p: FastingPhase) -> [Color] { p == .fasting ? [bgFastTop, bgFastBot] : [bgEatTop, bgEatBot] }
    static func ring(_ p: FastingPhase) -> [Color] { p == .fasting ? fastRing : eatRing }
    static func glow(_ p: FastingPhase) -> Color { p == .fasting ? fastGlow : eatGlow }
    static func accent(_ p: FastingPhase) -> Color { p == .fasting ? fastAccent : eatAccent }

    // Back-compat names used by the widgets / Live Activity.
    static let bgTop = bgFastTop
    static let bgBottom = bgFastBot
    static let ringTrack = track
    static let subtle = sub
    static let fastingA = Color(red: 0.60, green: 0.68, blue: 1.00)
    static let fastingB = Color(red: 1.00, green: 0.61, blue: 0.74)
    static let eatingA  = Color(red: 0.43, green: 0.80, blue: 0.56)
    static let eatingB  = Color(red: 0.68, green: 0.89, blue: 0.54)

    static func ringColors(for phase: FastingPhase) -> [Color] { ring(phase) }
    static func bgColors(for phase: FastingPhase) -> [Color] { bg(phase) }
}
