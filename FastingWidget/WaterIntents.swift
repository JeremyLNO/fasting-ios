import AppIntents
import WidgetKit

/// Tapping glass N sets the count to N (or empties it if it was already the top filled glass) —
/// same behaviour as tapping a glass in the app, but directly from the home-screen widget.
struct SetWaterGlassesIntent: AppIntent {
    static var title: LocalizedStringResource = "Set water glasses"
    static var description = IntentDescription("Update today's water glass count.")

    @Parameter(title: "Count")
    var count: Int

    init() { count = 0 }
    init(count: Int) { self.count = count }

    func perform() async throws -> some IntentResult {
        let current = SharedStore.waterGlasses()
        let newValue = (current == count) ? count - 1 : count
        SharedStore.setWaterGlasses(newValue)
        return .result()
    }
}
