import WidgetKit
import SwiftUI

struct TodaySummaryEntry: TimelineEntry {
    let date: Date
    let summary: TodaySummary?
}

// MARK: - Timeline Provider

struct TodaySummaryProvider: TimelineProvider {

    func placeholder(in context: Context) -> TodaySummaryEntry {
        TodaySummaryEntry(
            date: Date(),
            summary: TodaySummary(
                generatedAt: Date(),
                totalTasks: 6,
                completedTasks: 3,
                nextTaskTitle: "Study iOS",
                nextTaskTime: Date().addingTimeInterval(3600),
                highCount: 2,
                mediumCount: 3,
                lowCount: 1,
                activeHabitsToday: 4
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TodaySummaryEntry) -> ()) {
        let summary = TodaySummaryStorage.load()
        completion(TodaySummaryEntry(date: Date(), summary: summary))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodaySummaryEntry>) -> ()) {
        let summary = TodaySummaryStorage.load()
        let entry = TodaySummaryEntry(date: Date(), summary: summary)

        // Widget will also be reloaded by WidgetCenter in the app
        let nextDate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextDate)))
    }
}

// MARK: - Widget View

struct TodaySummaryWidgetView: View {
    var entry: TodaySummaryEntry
    @Environment(\.widgetFamily) var family

    // Dark theme background (matches your app)
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.02, blue: 0.12),
                Color(red: 0.02, green: 0.07, blue: 0.18),
                Color(red: 0.04, green: 0.02, blue: 0.10)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private let highColor = Color(red: 0.95, green: 0.28, blue: 0.35)
    private let mediumColor = Color(red: 0.98, green: 0.71, blue: 0.20)
    private let lowColor = Color(red: 0.47, green: 0.56, blue: 0.85)

    var body: some View {
        ZStack {
            backgroundGradient

            switch family {
            case .systemMedium:
                mediumLayout
            default:
                smallLayout
            }
        }
    }

    // MARK: - Small widget (tasks focus)

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Today")
                .font(.caption)
                .foregroundColor(.white.opacity(0.75))

            if let summary = entry.summary, summary.totalTasks > 0 {
                let pct = Int(
                    Double(summary.completedTasks) /
                    Double(max(summary.totalTasks, 1)) * 100.0
                )

                Text("\(summary.completedTasks)/\(summary.totalTasks) tasks")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("\(pct)% completed")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))

                HStack(spacing: 6) {
                    PriorityChip(label: "H", count: summary.highCount, color: highColor)
                    PriorityChip(label: "M", count: summary.mediumCount, color: mediumColor)
                    PriorityChip(label: "L", count: summary.lowCount, color: lowColor)
                }

                if let nextTitle = summary.nextTaskTitle {
                    Divider().background(Color.white.opacity(0.3))

                    Text("Next:")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))

                    Text(nextTitle)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                }

            } else {
                Text("No tasks yet")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("Open app and add a task.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()
        }
        .padding(12)
    }

    // MARK: - Medium widget (combined Tasks + Habits)

    private var mediumLayout: some View {
        HStack(spacing: 10) {

            // Left: tasks
            VStack(alignment: .leading, spacing: 6) {
                Text("Tasks")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.75))

                if let summary = entry.summary, summary.totalTasks > 0 {
                    let pct = Int(
                        Double(summary.completedTasks) /
                        Double(max(summary.totalTasks, 1)) * 100.0
                    )

                    Text("\(summary.completedTasks)/\(summary.totalTasks)")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("\(pct)% completed")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))

                    HStack(spacing: 6) {
                        PriorityChip(label: "H", count: summary.highCount, color: highColor)
                        PriorityChip(label: "M", count: summary.mediumCount, color: mediumColor)
                        PriorityChip(label: "L", count: summary.lowCount, color: lowColor)
                    }
                    .padding(.top, 2)

                } else {
                    Text("No tasks")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Add from app")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()
            }

            Divider().background(Color.white.opacity(0.3))

            // Right: habits
            VStack(alignment: .leading, spacing: 6) {
                Text("Habits")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.75))

                if let summary = entry.summary, summary.activeHabitsToday > 0 {
                    Text("\(summary.activeHabitsToday) today")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Health, water, gym, etc.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                } else {
                    Text("No habits")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Add daily habits\nin the app.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                }

                Spacer()
            }
        }
        .padding(12)
    }
}

// Small chip showing priority count like 1H / 3M / 2L
struct PriorityChip: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)

            Text("\(count)\(label)")
                .font(.caption2.bold())
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(color.opacity(0.22))
        .foregroundColor(.white)
        .clipShape(Capsule())
    }
}

// MARK: - Widget

struct DailyReminderWidget: Widget {
    let kind: String = "DailyReminderWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodaySummaryProvider()) { entry in
            TodaySummaryWidgetView(entry: entry)
        }
        .configurationDisplayName("Today Summary")
        .description("Tasks + habits overview with priorities.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
