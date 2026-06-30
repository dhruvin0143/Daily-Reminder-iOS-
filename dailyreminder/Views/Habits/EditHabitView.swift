//
//  Persistence.swift
//  dailyreminder
//
//  Created by BMIIT on 02/12/25.
//
import SwiftUI
import CoreData

struct EditHabitView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var themeManager: ThemeManager

    @ObservedObject var habit: HabitItem

    @State private var title: String
    @State private var notes: String
    @State private var time: Date

    @State private var repeatSunday: Bool
    @State private var repeatMonday: Bool
    @State private var repeatTuesday: Bool
    @State private var repeatWednesday: Bool
    @State private var repeatThursday: Bool
    @State private var repeatFriday: Bool
    @State private var repeatSaturday: Bool

    @State private var isActive: Bool
    @State private var snoozeMinutes: Int

    private var isDark: Bool {
        themeManager.isDarkNow
    }

    // MARK: - Initializer

    init(habit: HabitItem) {
        self.habit = habit
        _title = State(initialValue: habit.title ?? "")
        _notes = State(initialValue: habit.notes ?? "")
        _time = State(initialValue: habit.time ?? Date())
        _repeatSunday = State(initialValue: habit.repeatSunday)
        _repeatMonday = State(initialValue: habit.repeatMonday)
        _repeatTuesday = State(initialValue: habit.repeatTuesday)
        _repeatWednesday = State(initialValue: habit.repeatWednesday)
        _repeatThursday = State(initialValue: habit.repeatThursday)
        _repeatFriday = State(initialValue: habit.repeatFriday)
        _repeatSaturday = State(initialValue: habit.repeatSaturday)
        _isActive = State(initialValue: habit.isActive)
        _snoozeMinutes = State(initialValue: Int(habit.snoozeIntervalMinutes))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                (isDark ? AppTheme.Dark.background : AppTheme.Light.background)
                    .ignoresSafeArea()

                Form {
                    Section {
                        TextField("Title", text: $title)
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

                        Text("If set, each habit reminder will repeat a few times at the selected interval.")
                            .font(.footnote)
                            .foregroundColor(isDark ? AppTheme.Dark.textSecondary : AppTheme.Light.textSecondary)
                    } header: {
                        Label("Repeat alert if not dismissed", systemImage: "bell.and.waveform.fill")
                    }

                    Section {
                        Toggle("Active", isOn: $isActive)
                            .tint(Color(red: 0.36, green: 0.80, blue: 0.67))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveChanges() }
                        .disabled(title.trimmed().isEmpty || !anyDaySelected)
                }
            }
        }
    }

    // MARK: - Helpers

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

    private func saveChanges() {
        let trimmed = title.trimmed()
        guard !trimmed.isEmpty, anyDaySelected else { return }

        // Cancel old notifications
        NotificationManager.shared.cancelHabitNotifications(for: habit)

        // Update entity
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
        habit.isActive = isActive
        habit.snoozeIntervalMinutes = Int16(snoozeMinutes)

        if habit.baseNotificationId == nil {
            habit.baseNotificationId = habit.id?.uuidString ?? UUID().uuidString
        }

        // Re-schedule if active
        if isActive {
            NotificationManager.shared.scheduleHabitNotifications(for: habit)
        }

        try? viewContext.save()
        dismiss()
    }
}

// MARK: - Helpers

private extension String {
    func trimmed() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct EditHabitView_Previews: PreviewProvider {
    static var previews: some View {
        let ctx = PersistenceController.preview.container.viewContext
        let h = HabitItem(context: ctx)
        h.id = UUID()
        h.title = "Gym"
        h.time = Date()
        h.repeatMonday = true
        h.repeatWednesday = true
        h.repeatFriday = true
        h.isActive = true
        h.snoozeIntervalMinutes = 5
        return EditHabitView(habit: h)
            .environment(\.managedObjectContext, ctx)
            .environmentObject(ThemeManager.shared)
    }
}
