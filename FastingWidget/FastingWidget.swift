import WidgetKit
import SwiftUI

struct FastingEntry: TimelineEntry {
    let date: Date
    let schedule: FastingSchedule
    let water: Int
}

struct FastingProvider: TimelineProvider {
    func placeholder(in context: Context) -> FastingEntry {
        FastingEntry(date: Date(), schedule: .default, water: 2)
    }

    func getSnapshot(in context: Context, completion: @escaping (FastingEntry) -> Void) {
        completion(FastingEntry(date: Date(), schedule: SharedStore.load(), water: SharedStore.waterGlasses()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FastingEntry>) -> Void) {
        let schedule = SharedStore.load()
        let water = SharedStore.waterGlasses()
        let now = Date()
        // Pre-compute entries every 2 minutes for the next 4 hours so the ring advances
        // smoothly without spending extra refresh budget, then ask for a reload.
        var entries: [FastingEntry] = []
        for minute in stride(from: 0, through: 240, by: 2) {
            entries.append(FastingEntry(date: now.addingTimeInterval(Double(minute) * 60), schedule: schedule, water: water))
        }
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(240 * 60))))
    }
}

struct FastingWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: FastingEntry

    var body: some View {
        let s = entry.schedule.state(at: entry.date)
        FastingWidgetContent(family: family, state: s, water: entry.water)
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
        WaterWidget()
        FastingLiveActivity()
    }
}

struct FastingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "FastingWidget", provider: FastingProvider()) { entry in
            FastingWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Fasting")
        .description("Suis l'avancement de ton jeûne depuis l'écran d'accueil.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular])
    }
}

// MARK: - Water widget

struct WaterEntry: TimelineEntry {
    let date: Date
    let glasses: Int
}

struct WaterProvider: TimelineProvider {
    func placeholder(in context: Context) -> WaterEntry { WaterEntry(date: Date(), glasses: 2) }

    func getSnapshot(in context: Context, completion: @escaping (WaterEntry) -> Void) {
        completion(WaterEntry(date: Date(), glasses: SharedStore.waterGlasses()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WaterEntry>) -> Void) {
        let entry = WaterEntry(date: Date(), glasses: SharedStore.waterGlasses())
        // Reload just after midnight so the daily count resets.
        let reload = Calendar.current.nextDate(after: Date(), matching: DateComponents(hour: 0, minute: 1),
                                               matchingPolicy: .nextTime) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(reload)))
    }
}

struct WaterWidgetEntryView: View {
    let entry: WaterEntry
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: "drop.fill").foregroundStyle(Palette.water)
                Text(L.t("water_title"))
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Palette.ink)
            }
            WaterGlassesRow(count: entry.glasses, size: 20, spacing: 5)
            Text("\(entry.glasses * 200) ml / 1 L")
                .font(.caption2)
                .foregroundStyle(Palette.subtle)
        }
        .containerBackground(for: .widget) {
            LinearGradient(colors: [Color(red: 0.90, green: 0.96, blue: 1.0), Color(red: 0.83, green: 0.92, blue: 1.0)],
                           startPoint: .top, endPoint: .bottom)
        }
    }
}

struct WaterWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WaterWidget", provider: WaterProvider()) { entry in
            WaterWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(L.t("water_title"))
        .description("Track your daily water (1 L = 5 glasses).")
        .supportedFamilies([.systemSmall])
    }
}
