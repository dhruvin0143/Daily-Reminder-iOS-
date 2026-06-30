//
//  Persistence.swift
//  dailyreminder
//
//  Created by BMIIT on 02/12/25.
//
import SwiftUI
import CoreData

struct StatsView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var themeManager: ThemeManager

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TaskItem.date, ascending: true)],
        animation: .default
    )
    private var tasks: FetchedResults<TaskItem>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \HabitItem.title, ascending: true)],
        animation: .default
    )
    private var habits: FetchedResults<HabitItem>

    private var isDark: Bool { themeManager.isDarkNow }

    // MARK: - Live computed stats

    private var todayTasks: [TaskItem] {
        tasks.filter { $0.date.map(Calendar.current.isDateInToday) ?? false }
    }

    private var completedTodayTasks: [TaskItem] {
        todayTasks.filter { $0.isCompleted }
    }

    private var completionRateToday: Int {
        guard !todayTasks.isEmpty else { return 0 }
        return Int((Double(completedTodayTasks.count) / Double(todayTasks.count)) * 100)
    }

    private var highPriorityToday: Int {
        todayTasks.filter { $0.priority == .high }.count
    }

    private var mediumPriorityToday: Int {
        todayTasks.filter { $0.priority == .medium }.count
    }

    private var lowPriorityToday: Int {
        todayTasks.filter { $0.priority == .low }.count
    }

    private var totalHabits: Int {
        habits.count
    }

    private var activeHabits: Int {
        habits.filter { $0.isActive }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                (isDark ? AppTheme.Dark.background : AppTheme.Light.background)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 22) {

                        headerSection

                        progressCard

                        priorityCard

                        habitsCard
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Stats")
        }
    }

    // MARK: UI Sections

    private var headerSection: some View {
        VStack(spacing: 6) {
            Text("Daily Stats")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(isDark ? AppTheme.Dark.textPrimary : AppTheme.Light.textPrimary)

            Text(Date(), style: .date)
                .font(.subheadline)
                .foregroundColor(isDark ? AppTheme.Dark.textSecondary : AppTheme.Light.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Today's Progress")
                    .font(.headline)
                Spacer()
                Text("\(completionRateToday)%")
                    .font(.headline)
                    .foregroundColor(AppTheme.priorityColor(level(for: completionRateToday)))
            }

            RoundedProgressBar(progress: Double(completionRateToday) / 100.0)

            HStack {
                Text("\(completedTodayTasks.count) completed")
                Spacer()
                Text("\(todayTasks.count) total")
            }
            .font(.caption)
            .foregroundColor(isDark ? AppTheme.Dark.textSecondary : AppTheme.Light.textSecondary)
        }
        .modifier(statCard(isDark: isDark))
    }

    private var priorityCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Priority Breakdown")
                .font(.headline)

            HStack(spacing: 14) {
                priorityBadge(title: "High", count: highPriorityToday, color: AppTheme.priorityColor(.high))
                priorityBadge(title: "Medium", count: mediumPriorityToday, color: AppTheme.priorityColor(.medium))
                priorityBadge(title: "Low", count: lowPriorityToday, color: AppTheme.priorityColor(.low))
            }
        }
        .modifier(statCard(isDark: isDark))
    }

    private var habitsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Habits")
                .font(.headline)

            HStack {
                Text("Active habits: \(activeHabits)")
                Spacer()
                Text("Total: \(totalHabits)")
            }
            .font(.subheadline)
            .foregroundColor(isDark ? AppTheme.Dark.textSecondary : AppTheme.Light.textSecondary)
        }
        .modifier(statCard(isDark: isDark))
    }

    // MARK: helpers

    private func level(for rate: Int) -> TaskPriority {
        if rate >= 80 { return .high }
        if rate >= 40 { return .medium }
        return .low
    }

    private func priorityBadge(title: String, count: Int, color: Color) -> some View {
        VStack {
            Text("\(count)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
            Text(title)
                .font(.caption)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Shared card UI modifier

private struct statCard: ViewModifier {
    let isDark: Bool
    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                (isDark ? AppTheme.Dark.card : AppTheme.Light.card)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            )
            .shadow(
                color: isDark ? Color.black.opacity(0.45) : Color.black.opacity(0.08),
                radius: 8, x: 0, y: 4
            )
    }
}

// MARK: - Simple progress bar

private struct RoundedProgressBar: View {
    let progress: Double
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.20))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress)
            }
        }
        .frame(height: 10)
    }
}
