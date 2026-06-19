import WidgetKit
import SwiftUI

struct FastingEntry: TimelineEntry {
    let date: Date
    let schedule: FastingSchedule
}

struct FastingProvider: TimelineProvider {
    func placeholder(in context: Context) -> FastingEntry {
        FastingEntry(date: Date(), schedule: .default)
    }

    func getSnapshot(in context: Context, completion: @escaping (FastingEntry) -> Void) {
        completion(FastingEntry(date: Date(), schedule: SharedStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FastingEntry>) -> Void) {
        let schedule = SharedStore.load()
        let now = Date()
        // Pre-compute entries every 2 minutes for the next 4 hours so the ring advances
        // smoothly without spending extra refresh budget, then ask for a reload.
        var entries: [FastingEntry] = []
        for minute in stride(from: 0, through: 240, by: 2) {
            entries.append(FastingEntry(date: now.addingTimeInterval(Double(minute) * 60), schedule: schedule))
        }
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(240 * 60))))
    }
}

struct FastingWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: FastingEntry

    var body: some View {
        let s = entry.schedule.state(at: entry.date)
        FastingWidgetContent(family: family, state: s)
            .containerBackground(for: .widget) {
                LinearGradient(colors: Palette.bgColors(for: s.phase),
                               startPoint: .top, endPoint: .bottom)
            }
    }
}

@main
struct FastingWidgetBundle: WidgetBundle {
    var body: some Widget {
        FastingWidget()
    }
}

struct FastingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "FastingWidget", provider: FastingProvider()) { entry in
            FastingWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Jeûne")
        .description("Suis l'avancement de ton jeûne depuis l'écran d'accueil.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular])
    }
}
