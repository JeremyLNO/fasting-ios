import SwiftUI

struct SettingsView: View {
    @Binding var schedule: FastingSchedule
    @Environment(\.dismiss) private var dismiss

    @State private var start = Date()
    @State private var end = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Palette.bgTop, Palette.bgBottom],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 18) {
                    timeCard("Début du jeûne", "🌙", $start)
                    timeCard("Fin du jeûne", "☀️", $end)
                    summary
                    Spacer()
                    Button(action: save) {
                        Text("Enregistrer")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(colors: [Palette.fastingA, Palette.fastingB],
                                               startPoint: .leading, endPoint: .trailing),
                                in: RoundedRectangle(cornerRadius: 18)
                            )
                    }
                }
                .padding(22)
            }
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                        .foregroundStyle(Palette.ink)
                }
            }
        }
        .onAppear(perform: load)
    }

    private func timeCard(_ title: String, _ emoji: String, _ value: Binding<Date>) -> some View {
        HStack {
            Text(emoji).font(.title2)
            Text(title).font(.headline).foregroundStyle(Palette.ink)
            Spacer()
            DatePicker("", selection: value, displayedComponents: .hourAndMinute)
                .labelsHidden()
        }
        .padding(18)
        .background(.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 18))
    }

    private var summary: some View {
        let temp = scheduleFromPickers()
        let eating = 24 * 60 - temp.fastingMinutes
        let eatingText = eating % 60 == 0 ? "\(eating / 60)h" : "\(eating / 60)h\(String(format: "%02d", eating % 60))"
        return Text("\(temp.fastingHoursText) de jeûne · \(eatingText) pour manger")
            .font(.subheadline)
            .foregroundStyle(Palette.subtle)
    }

    private func scheduleFromPickers() -> FastingSchedule {
        let c = Calendar.current
        return FastingSchedule(
            startHour: c.component(.hour, from: start),
            startMinute: c.component(.minute, from: start),
            endHour: c.component(.hour, from: end),
            endMinute: c.component(.minute, from: end)
        )
    }

    private func load() {
        let c = Calendar.current
        start = c.date(bySettingHour: schedule.startHour, minute: schedule.startMinute, second: 0, of: Date()) ?? Date()
        end = c.date(bySettingHour: schedule.endHour, minute: schedule.endMinute, second: 0, of: Date()) ?? Date()
    }

    private func save() {
        schedule = scheduleFromPickers()
        SharedStore.save(schedule)
        NotificationManager.shared.reschedule(for: schedule)
        dismiss()
    }
}
