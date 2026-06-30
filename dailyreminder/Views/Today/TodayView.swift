//
//  Persistence.swift
//  dailyreminder
//
//  Created by BMIIT on 02/12/25.
//
import SwiftUI
import CoreData
import UIKit

struct TodayView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var themeManager: ThemeManager

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TaskItem.date, ascending: true)],
        animation: .default
    )
    private var allTasks: FetchedResults<TaskItem>

    private var isDark: Bool {
        themeManager.isDarkNow
    }

    private var todayTasks: [TaskItem] {
        allTasks.filter { task in
            if let date = task.date {
                return Calendar.current.isDateInToday(date)
            } else { return false }
        }
    }

    private var upcomingTasks: [TaskItem] {
        allTasks.filter { task in
            guard let date = task.date else { return false }
            if Calendar.current.isDateInToday(date) { return false }
            return date > Date()
        }
    }

    @State private var showingAddTask = false
    @State private var isEditingTask = false
    @State private var selectedTask: TaskItem?

    var body: some View {
        NavigationStack {
            ZStack {
                (isDark ? AppTheme.Dark.background : AppTheme.Light.background)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    header

                    if todayTasks.isEmpty && upcomingTasks.isEmpty {
                        emptyState
                    } else {
                        List {
                            if !todayTasks.isEmpty {
                                Section(header: Text("Today")) {
                                    ForEach(todayTasks) { task in
                                        TaskRow(task: task)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                // ✅ Only editable if not completed
                                                guard !task.isCompleted else { return }
                                                selectedTask = task
                                                isEditingTask = true
                                            }
                                            .listRowSeparator(.hidden)
                                            .listRowBackground(Color.clear)
                                    }
                                    .onDelete(perform: deleteTodayTasks)
                                }
                            }

                            if !upcomingTasks.isEmpty {
                                Section(header: Text("Upcoming")) {
                                    ForEach(upcomingTasks) { task in
                                        TaskRow(task: task)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                guard !task.isCompleted else { return }
                                                selectedTask = task
                                                isEditingTask = true
                                            }
                                            .listRowSeparator(.hidden)
                                            .listRowBackground(Color.clear)
                                    }
                                    .onDelete(perform: deleteUpcomingTasks)
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.insetGrouped)
                    }
                }
                .padding(.top, 4)
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAddTask = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .onAppear {
                TodaySummaryUpdater.update(using: viewContext)
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
                    .environment(\.managedObjectContext, viewContext)
                    .environmentObject(themeManager)
            }
            .sheet(isPresented: $isEditingTask) {
                if let task = selectedTask {
                    EditTaskView(task: task)
                        .environment(\.managedObjectContext, viewContext)
                        .environmentObject(themeManager)
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(isDark ? "logo_dark" : "logo_light")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .shadow(radius: 4)

            VStack(alignment: .leading, spacing: 6) {
                Text("Today’s Plan")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(isDark ? AppTheme.Dark.textPrimary : AppTheme.Light.textPrimary)

                Text("Sort tasks by priority and finish strong.")
                    .font(.subheadline)
                    .foregroundColor(isDark ? AppTheme.Dark.textSecondary : AppTheme.Light.textSecondary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var emptyState: some View {
        VStack {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "checklist.unchecked")
                    .font(.system(size: 44))
                    .foregroundColor(isDark ? AppTheme.Dark.textSecondary : AppTheme.Light.textSecondary)

                Text("No tasks yet")
                    .font(.headline)
                    .foregroundColor(isDark ? AppTheme.Dark.textPrimary : AppTheme.Light.textPrimary)

                Text("Tap the + button to add your first task.")
                    .font(.subheadline)
                    .foregroundColor(isDark ? AppTheme.Dark.textSecondary : AppTheme.Light.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            Spacer()
        }
    }

    private func deleteTodayTasks(at offsets: IndexSet) {
        let tasksToDelete = offsets.map { todayTasks[$0] }
        deleteTasks(tasksToDelete)
    }

    private func deleteUpcomingTasks(at offsets: IndexSet) {
        let tasksToDelete = offsets.map { upcomingTasks[$0] }
        deleteTasks(tasksToDelete)
    }

    private func deleteTasks(_ tasks: [TaskItem]) {
        for task in tasks {
            if let baseId = task.notificationId {
                NotificationManager.shared.cancelTaskNotifications(forBaseId: baseId)
            }
            viewContext.delete(task)
        }
        try? viewContext.save()
        TodaySummaryUpdater.update(using: viewContext)
    }
}

// MARK: - Row

private struct TaskRow: View {

    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var task: TaskItem

    private var isDark: Bool {
        themeManager.isDarkNow
    }

    var body: some View {
        let title = task.title ?? "Task"
        let date = task.date ?? Date()
        let priorityColor = AppTheme.priorityColor(task.priority)

        HStack(alignment: .top, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    task.isCompleted.toggle()
                    try? viewContext.save()

                    // Cancel any future reminders when completed
                    if task.isCompleted, let base = task.notificationId {
                        NotificationManager.shared.cancelTaskNotifications(forBaseId: base)
                    } else {
                        // re-schedule if re-opened
                        let base = NotificationManager.shared.scheduleTaskNotification(for: task)
                        task.notificationId = base
                        try? viewContext.save()
                    }

                    TodaySummaryUpdater.update(using: viewContext)
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(priorityColor)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .strikethrough(task.isCompleted, color: .secondary)
                            .foregroundColor(task.isCompleted ?
                                (isDark ? AppTheme.Dark.textSecondary : AppTheme.Light.textSecondary) :
                                (isDark ? AppTheme.Dark.textPrimary : AppTheme.Light.textPrimary)
                            )

                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text(timeString(from: date))
                                .font(.caption)
                        }
                        .foregroundColor(isDark ? AppTheme.Dark.textSecondary : AppTheme.Light.textSecondary)
                    }

                    Spacer()

                    Text(task.priority.label)
                        .font(.caption2.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(priorityColor.opacity(0.18))
                        .foregroundColor(priorityColor)
                        .clipShape(Capsule())
                }

                if let notes = task.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundColor(isDark ? AppTheme.Dark.textSecondary : AppTheme.Light.textSecondary)
                        .lineLimit(2)
                }
            }
            .padding(14)
            .background(
                (isDark ? AppTheme.Dark.card : AppTheme.Light.card)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            )
            .shadow(color: isDark ? Color.black.opacity(0.55) : Color.black.opacity(0.08),
                    radius: 8, x: 0, y: 4)
        }
        .padding(.vertical, 4)
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
