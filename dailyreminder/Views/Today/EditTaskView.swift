//
//  Persistence.swift
//  dailyreminder
//
//  Created by BMIIT on 02/12/25.
//
import SwiftUI
import CoreData

struct EditTaskView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var themeManager: ThemeManager

    @ObservedObject var task: TaskItem

    @State private var title: String
    @State private var notes: String
    @State private var date: Date
    @State private var snoozeMinutes: Int
    @State private var priority: TaskPriority
    @State private var isCompleted: Bool

    private var isDark: Bool {
        themeManager.isDarkNow
    }

    private var isDateValid: Bool {
        // Don’t allow editing to a time that is too far in the past
        date >= Date().addingTimeInterval(-60)
    }

    init(task: TaskItem) {
        self.task = task
        _title = State(initialValue: task.title ?? "")
        _notes = State(initialValue: task.notes ?? "")
        _date = State(initialValue: task.date ?? Date())
        _snoozeMinutes = State(initialValue: Int(task.snoozeIntervalMinutes))
        _priority = State(initialValue: task.priority)
        _isCompleted = State(initialValue: task.isCompleted)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                (isDark ? AppTheme.Dark.background : AppTheme.Light.background)
                    .ignoresSafeArea()

                Form {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Title", text: $title)
                                .font(.headline)
                                .foregroundColor(isDark ? AppTheme.Dark.textPrimary : AppTheme.Light.textPrimary)

                            TextField("Notes (optional)", text: $notes, axis: .vertical)
                                .lineLimit(1...4)
                                .font(.subheadline)
                                .foregroundColor(isDark ? AppTheme.Dark.textSecondary : AppTheme.Light.textSecondary)

                            Toggle(isOn: $isCompleted) {
                                Text("Mark as completed")
                                    .font(.subheadline)
                            }
                            .tint(AppTheme.priorityColor(priority))
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Label("Task details", systemImage: "text.badge.checkmark")
                    }

                    Section {
                        Picker("Priority", selection: $priority) {
                            Text("Low").tag(TaskPriority.low)
                            Text("Medium").tag(TaskPriority.medium)
                            Text("High").tag(TaskPriority.high)
                        }
                        .pickerStyle(.segmented)

                        HStack(spacing: 6) {
                            Circle()
                                .fill(AppTheme.priorityColor(priority))
                                .frame(width: 10, height: 10)

                            Text(priorityDescription)
                                .font(.footnote)
                                .foregroundColor(isDark ? AppTheme.Dark.textSecondary : AppTheme.Light.textSecondary)
                        }
                    } header: {
                        Label("Priority", systemImage: "flag.fill")
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
                        Picker("Repeat if not dismissed", selection: $snoozeMinutes) {
                            Text("Use default for \(priority.label)").tag(0)
                            Text("Every 2 min").tag(2)
                            Text("Every 5 min").tag(5)
                            Text("Every 10 min").tag(10)
                        }
                        .pickerStyle(.menu)

                        Text("Reminder will keep repeating at this interval for a long time until you mark the task as completed.")
                            .font(.footnote)
                            .foregroundColor(isDark ? AppTheme.Dark.textSecondary : AppTheme.Light.textSecondary)
                    } header: {
                        Label("Repeat alert", systemImage: "bell.and.waves.left.and.right.fill")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveChanges() }
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
            return "Medium: gentle repeats every 5 minutes."
        case .high:
            return "High: strong repeats every 2 minutes."
        }
    }

    private func saveChanges() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, isDateValid else { return }

        // Cancel old notifications
        if let baseId = task.notificationId {
            NotificationManager.shared.cancelTaskNotifications(forBaseId: baseId)
        }

        // Update model
        task.title = trimmed
        task.notes = notes.isEmpty ? nil : notes
        task.date = date
        task.priority = priority
        task.snoozeIntervalMinutes = Int16(snoozeMinutes)
        task.isCompleted = isCompleted

        if !task.isCompleted {
            let baseId = NotificationManager.shared.scheduleTaskNotification(for: task)
            task.notificationId = baseId
        } else {
            task.notificationId = nil
        }

        try? viewContext.save()
        TodaySummaryUpdater.update(using: viewContext)
        dismiss()
    }
}

struct EditTaskView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let sample = TaskItem(context: context)
        sample.id = UUID()
        sample.title = "Edit me"
        sample.date = Date()
        sample.priorityRaw = TaskPriority.high.rawValue
        sample.snoozeIntervalMinutes = 5
        sample.isCompleted = false
        return EditTaskView(task: sample)
            .environment(\.managedObjectContext, context)
            .environmentObject(ThemeManager.shared)
    }
}
