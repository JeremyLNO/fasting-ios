import SwiftUI

/// Pastel palette shared between the app and the widget so they look identical.
enum Palette {
    static let bgTop     = Color(red: 0.95, green: 0.93, blue: 1.00)   // lavender mist
    static let bgBottom  = Color(red: 0.90, green: 0.97, blue: 0.99)   // soft sky
    static let ink       = Color(red: 0.28, green: 0.27, blue: 0.40)   // soft slate (text)
    static let subtle    = Color(red: 0.53, green: 0.52, blue: 0.64)   // muted text
    static let ringTrack = Color(red: 0.89, green: 0.87, blue: 0.96)   // ring background

    static let fastingA  = Color(red: 0.74, green: 0.78, blue: 0.98)   // periwinkle
    static let fastingB  = Color(red: 0.98, green: 0.80, blue: 0.91)   // pink
    static let eatingA   = Color(red: 0.72, green: 0.91, blue: 0.80)   // mint
    static let eatingB   = Color(red: 1.00, green: 0.89, blue: 0.74)   // peach

    static func ringColors(for phase: FastingPhase) -> [Color] {
        phase == .fasting ? [fastingA, fastingB] : [eatingA, eatingB]
    }

    static func bgColors(for phase: FastingPhase) -> [Color] {
        phase == .fasting
            ? [bgTop, bgBottom]
            : [Color(red: 0.93, green: 0.99, blue: 0.94), Color(red: 1.00, green: 0.97, blue: 0.91)]
    }
}
