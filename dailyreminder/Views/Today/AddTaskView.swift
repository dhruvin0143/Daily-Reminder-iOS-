//
//  Persistence.swift
//  dailyreminder
//
//  Created by BMIIT on 02/12/25.
//
import SwiftUI
import CoreData

struct AddTaskView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var themeManager: ThemeManager

    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var date: Date = AddTaskView.defaultNextHourDate()

    @State private var snoozeMinutes: Int = 0   // 0, 2, 5, 10
    @State private var priority: TaskPriority = .medium

    private var isDark: Bool {
        themeManager.isDarkNow
    }

    private var isDateValid: Bool {
        // Do not allow date/time before "now - 1 minute"
        date >= Date().addingTimeInterval(-60)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                (isDark ? AppTheme.Dark.background : AppTheme.Light.background)
                    .ignoresSafeArea()

                Form {
                    Section("Quick templates") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                templateButton(
                                    title: "Study iOS",
                                    notes: "Focus on Swift / SwiftUI for 1 hour",
                                    hourOffset: 1
                                )
                                templateButton(
                                    title: "Workout",
                                    notes: "Gym / home workout session",
                                    hourOffset: 2
                                )
                                templateButton(
                                    title: "Reading",
                                    notes: "Read a book for 30 minutes",
                                    hourOffset: 3
                                )
                                templateButton(
                                    title: "Project work",
                                    notes: "Progress on personal / college project",
                                    hourOffset: 4
                                )
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    Section {
                        TextField("Title", text: $title)
                        TextField("Notes (optional)", text: $notes, axis: .vertical)
                            .lineLimit(1...4)
                    } header: {
                        Label("Task", systemImage: "text.badge.checkmark")
                    }

                    Section {
                        Picker("Priority", selection: $priority) {
                            Text("Low").tag(TaskPriority.low)
                            Text("Medium").tag(TaskPriority.medium)
                            Text("High").tag(TaskPriority.high)
                        }
                        .pickerStyle(.segmented)

                        Text(priorityDescription)
                            .font(.footnote)
                            .foregroundColor(isDark ? AppTheme.Dark.textSecondary : AppTheme.Light.textSecondary)
                    } header: {
                        Label("Priority level", systemImage: "flag.fill")
                    }

                    Section {
                        DatePicker("Date & Time", selection: $date)
                        if !isDateValid {
                            Text("Please choose a future time. Past date/time is not allowed.")
                                .font(.footnote)
                                .foregroundColor(.red)
                        }
                    } header: {
                        Label("When to remind", systemImage: "calendar.badge.clock")
                    }

                    Section {
                        Picker("Repeat", selection: $snoozeMinutes) {
                            Text("Use default for \(priority.label)").tag(0)
                            Text("Every 2 min").tag(2)
                            Text("Every 5 min").tag(5)
                            Text("Every 10 min").tag(10)
                        }
                        .pickerStyle(.menu)

                        Text("If set, this task will remind again many times at this interval until you mark it complete.")
                            .font(.footnote)
                            .foregroundColor(isDark ? AppTheme.Dark.textSecondary : AppTheme.Light.textSecondary)
                    } header: {
                        Label("Repeat alert if not dismissed", systemImage: "bell.and.waves.left.and.right.fill")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveTask() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || !isDateValid)
                }
            }
        }
    }

    private var priorityDescription: String {
        switch priority {
        case .low:
            return "Low: normal reminder, no extra repeats by default."
        case .medium:
            return "Medium: more important task, gentle repeats every 5 minutes by default."
        case .high:
            return "High: very important task, aggressive repeats every 2 minutes by default."
        }
    }

    private func templateButton(title: String, notes: String, hourOffset: Int) -> some View {
        Button {
            self.title = title
            self.notes = notes

            let now = Date()
            var comps = Calendar.current.dateComponents([.year, .month, .day, .hour], from: now)
            if let hour = comps.hour {
                comps.hour = hour + hourOffset
            }
            comps.minute = 0
            self.date = Calendar.current.date(from: comps) ?? now
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

    private func saveTask() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, isDateValid else { return }

        let task = TaskItem(context: viewContext)
        task.id = UUID()
        task.title = trimmed
        task.notes = notes.isEmpty ? nil : notes
        task.date = date
        task.isCompleted = false
        task.priority = priority
        task.snoozeIntervalMinutes = Int16(snoozeMinutes)

        let baseId = NotificationManager.shared.scheduleTaskNotification(for: task)
        task.notificationId = baseId

        try? viewContext.save()
        TodaySummaryUpdater.update(using: viewContext)
        dismiss()
    }

    static func defaultNextHourDate() -> Date {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        var comps = calendar.dateComponents([.year, .month, .day], from: now)
        comps.hour = currentHour + 1
        comps.minute = 0
        return calendar.date(from: comps) ?? now
    }
}

struct AddTaskView_Previews: PreviewProvider {
    static var previews: some View {
        AddTaskView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(ThemeManager.shared)
    }
}
