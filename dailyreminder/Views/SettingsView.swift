//
//  Persistence.swift
//  dailyreminder
//
//  Created by BMIIT on 02/12/25.
//
import SwiftUI
import CoreData

struct SettingsView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var themeManager: ThemeManager

    @FetchRequest(
        sortDescriptors: [],
        animation: .default
    )
    private var settingsArray: FetchedResults<AppSettings>

    private var settings: AppSettings {
        if let first = settingsArray.first {
            return first
        } else {
            let newSettings = AppSettings(context: viewContext)
            newSettings.id = UUID()
            newSettings.morningReminderEnabled = true
            newSettings.morningReminderTime = defaultMorningTime()
            try? viewContext.save()
            NotificationManager.shared.scheduleMorningReminder(settings: newSettings)
            return newSettings
        }
    }

    private var isDark: Bool {
        themeManager.isDarkNow
    }

    var body: some View {
        ZStack {
            (isDark ? AppTheme.Dark.background : AppTheme.Light.background)
                .ignoresSafeArea()

            Form {
                // MARK: Appearance card
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("Theme", selection: $themeManager.mode) {
                            Text("Dark").tag(ThemeManager.ThemeMode.dark)
                            Text("Light").tag(ThemeManager.ThemeMode.light)
                        }
                        .pickerStyle(.segmented)

                        Text("Dark is easier on eyes, Light is colorful and bright.")
                            .font(.footnote)
                            .foregroundColor(isDark ? AppTheme.Dark.textSecondary : AppTheme.Light.textSecondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Label("Appearance", systemImage: "circle.lefthalf.filled")
                }

                // MARK: Morning reminder
                Section {
                    Toggle(isOn: bindingEnabled()) {
                        HStack(spacing: 10) {
                            Image(systemName: "sun.max.fill")
                                .foregroundColor(.yellow)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Morning question")
                                    .font(.subheadline)
                                Text("Ask “What about today's plan?” at selected time.")
                                    .font(.caption)
                                    .foregroundColor(isDark ? AppTheme.Dark.textSecondary : AppTheme.Light.textSecondary)
                            }
                        }
                    }
                    .tint(Color(red: 0.40, green: 0.53, blue: 0.98))   // clearer in dark + light

                    DatePicker(
                        "Reminder time",
                        selection: bindingTime(),
                        displayedComponents: .hourAndMinute
                    )
                } header: {
                    Text("Daily planning reminder")
                } footer: {
                    Text("This reminder helps you open the app every morning and plan your tasks.")
                        .font(.footnote)
                        .foregroundColor(isDark ? AppTheme.Dark.textSecondary : AppTheme.Light.textSecondary)
                }

                // MARK: Reset
                Section {
                    Button(role: .destructive) {
                        resetAllData()
                    } label: {
                        Label("Reset all data", systemImage: "trash")
                    }
                } footer: {
                    Text("This clears all tasks, habits and settings from this device and cancels notifications.")
                        .font(.footnote)
                        .foregroundColor(isDark ? AppTheme.Dark.textSecondary : AppTheme.Light.textSecondary)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
    }

    // MARK: - Helpers

    private func defaultMorningTime() -> Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour = 9
        comps.minute = 0
        return Calendar.current.date(from: comps) ?? Date()
    }

    private func bindingEnabled() -> Binding<Bool> {
        Binding(
            get: { settings.morningReminderEnabled },
            set: { newValue in
                settings.morningReminderEnabled = newValue
                try? viewContext.save()
                NotificationManager.shared.scheduleMorningReminder(settings: settings)
            }
        )
    }

    private func bindingTime() -> Binding<Date> {
        Binding(
            get: { settings.morningReminderTime ?? defaultMorningTime() },
            set: { newTime in
                settings.morningReminderTime = newTime
                try? viewContext.save()
                NotificationManager.shared.scheduleMorningReminder(settings: settings)
            }
        )
    }

    private func resetAllData() {
        // Tasks
        let fetchTasks: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()
        if let tasks = try? viewContext.fetch(fetchTasks) {
            for task in tasks {
                if let baseId = task.notificationId {
                    NotificationManager.shared.cancelTaskNotifications(forBaseId: baseId)
                }
                viewContext.delete(task)
            }
        }

        // Habits
        let fetchHabits: NSFetchRequest<HabitItem> = HabitItem.fetchRequest()
        if let habits = try? viewContext.fetch(fetchHabits) {
            for habit in habits {
                NotificationManager.shared.cancelHabitNotifications(for: habit)
                viewContext.delete(habit)
            }
        }

        // Settings
        let fetchSettings: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
        if let settingsList = try? viewContext.fetch(fetchSettings) {
            for s in settingsList {
                NotificationManager.shared.cancelMorningReminder()
                viewContext.delete(s)
            }
        }

        try? viewContext.save()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .environmentObject(ThemeManager.shared)
        }
    }
}
