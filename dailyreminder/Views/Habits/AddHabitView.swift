//
//  Persistence.swift
//  dailyreminder
//
//  Created by BMIIT on 02/12/25.
//
import SwiftUI
import CoreData

struct AddHabitView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var systemScheme

    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var time: Date = AddHabitView.defaultTime(hour: 8, minute: 0)

    @State private var repeatSunday = false
    @State private var repeatMonday = true
    @State private var repeatTuesday = true
    @State private var repeatWednesday = true
    @State private var repeatThursday = true
    @State private var repeatFriday = true
    @State private var repeatSaturday = false

    @State private var snoozeMinutes: Int = 0  // 0, 2, 5, 10

    private var isDark: Bool {
        themeManager.isDarkNow
    }


    var body: some View {
        NavigationStack {
            ZStack {
                (isDark ? AppTheme.Dark.background : AppTheme.Light.background)
                    .ignoresSafeArea()

                Form {
                    Section("Quick health templates") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                templateButton(
                                    title: "Drink Water",
                                    notes: "Drink a glass of water",
                                    hour: 9,
                                    days: everyDay()
                                )
                                templateButton(
                                    title: "Morning Walk",
                                    notes: "10–20 minute walk",
                                    hour: 7,
                                    days: weekdays()
                                )
                                templateButton(
                                    title: "Gym",
                                    notes: "Workout session",
                                    hour: 18,
                                    days: [false, true, false, true, false, true, false]
                                )
                                templateButton(
                                    title: "Meditation",
                                    notes: "5–10 minutes calm breathing",
                                    hour: 21,
                                    days: everyDay()
                                )
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    Section {
                        TextField("Title (e.g. Drink Water)", text: $title)
                        TextField("Notes (optional)", text: $notes, axis: .vertical)
                            .lineLimit(1...4)
                    } header: {
                        Label("Habit", systemImage: "heart.text.square.fill")
                    }

                    Section {
                        DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                    } header: {
                        Label("Time of day", systemImage: "clock.fill")
                    }

                    Section {
                        HStack {
                            dayToggle("S", isOn: $repeatSunday)
                            dayToggle("M", isOn: $repeatMonday)
                            dayToggle("T", isOn: $repeatTuesday)
                            dayToggle("W", isOn: $repeatWednesday)
                            dayToggle("T", isOn: $repeatThursday)
                            dayToggle("F", isOn: $repeatFriday)
                            dayToggle("S", isOn: $repeatSaturday)
                        }
                    } header: {
                        Label("Repeat on", systemImage: "repeat")
                    }

                    Section {
                        Picker("Repeat", selection: $snoozeMinutes) {
                            Text("No repeat").tag(0)
                            Text("Every 2 min (x3)").tag(2)
                            Text("Every 5 min (x3)").tag(5)
                            Text("Every 10 min (x3)").tag(10)
                        }
                        .pickerStyle(.menu)

                        Text("If set, each habit reminder will repeat up to 3 times at the selected interval.")
                            .font(.footnote)
                            .foregroundColor(isDark ? AppTheme.Dark.textSecondary : AppTheme.Light.textSecondary)
                    } header: {
                        Label("Repeat alert if not dismissed", systemImage: "bell.and.waveform.fill")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveHabit() }
                        .disabled(title.trimmed().isEmpty || !anyDaySelected)
                }
            }
        }
    }

    // MARK: - Helpers

    private func templateButton(
        title: String,
        notes: String,
        hour: Int,
        days: [Bool]
    ) -> some View {
        Button {
            self.title = title
            self.notes = notes
            self.time = AddHabitView.defaultTime(hour: hour, minute: 0)

            if days.count == 7 {
                repeatSunday    = days[0]
                repeatMonday    = days[1]
                repeatTuesday   = days[2]
                repeatWednesday = days[3]
                repeatThursday  = days[4]
                repeatFriday    = days[5]
                repeatSaturday  = days[6]
            }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
        }
        .buttonStyle(.plain)
    }

    private func everyDay() -> [Bool] {
        [true, true, true, true, true, true, true]
    }

    private func weekdays() -> [Bool] {
        [false, true, true, true, true, true, false]
    }

    private var anyDaySelected: Bool {
        repeatSunday || repeatMonday || repeatTuesday ||
        repeatWednesday || repeatThursday || repeatFriday || repeatSaturday
    }

    private func dayToggle(_ label: String, isOn: Binding<Bool>) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            Text(label)
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(
                    isOn.wrappedValue
                    ? LinearGradient(
                        colors: [
                            Color(red: 0.36, green: 0.80, blue: 0.67),
                            Color(red: 0.26, green: 0.66, blue: 0.93)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(
                        colors: [Color.gray.opacity(0.15), Color.gray.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundColor(
                    isOn.wrappedValue
                    ? .white
                    : (isDark ? AppTheme.Dark.textPrimary : AppTheme.Light.textPrimary)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func saveHabit() {
        let trimmed = title.trimmed()
        guard !trimmed.isEmpty, anyDaySelected else { return }

        let habit = HabitItem(context: viewContext)
        habit.id = UUID()
        habit.title = trimmed
        habit.notes = notes.isEmpty ? nil : notes
        habit.time = time
        habit.repeatSunday = repeatSunday
        habit.repeatMonday = repeatMonday
        habit.repeatTuesday = repeatTuesday
        habit.repeatWednesday = repeatWednesday
        habit.repeatThursday = repeatThursday
        habit.repeatFriday = repeatFriday
        habit.repeatSaturday = repeatSaturday
        habit.isActive = true
        habit.baseNotificationId = habit.id?.uuidString ?? UUID().uuidString
        habit.snoozeIntervalMinutes = Int16(snoozeMinutes)

        NotificationManager.shared.scheduleHabitNotifications(for: habit)

        try? viewContext.save()
        dismiss()
    }

    static func defaultTime(hour: Int, minute: Int) -> Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour = hour
        comps.minute = minute
        return Calendar.current.date(from: comps) ?? Date()
    }
}

// MARK: - Helpers

private extension String {
    func trimmed() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct AddHabitView_Previews: PreviewProvider {
    static var previews: some View {
        AddHabitView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(ThemeManager.shared)
    }
}
