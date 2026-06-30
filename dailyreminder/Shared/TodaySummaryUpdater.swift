//
//  Persistence.swift
//  dailyreminder
//
//  Created by BMIIT on 02/12/25.
//
import Foundation
import CoreData
import WidgetKit   // for reloading the widget timeline

/// Calculates today's summary from Core Data and saves it into shared storage.
struct TodaySummaryUpdater {

    static func update(using context: NSManagedObjectContext) {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: todayStart) else { return }

        // ---- Tasks for today ----
        let taskRequest: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()
        taskRequest.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            todayStart as NSDate,
            tomorrow as NSDate
        )
        taskRequest.sortDescriptors = [NSSortDescriptor(keyPath: \TaskItem.date, ascending: true)]

        let tasks = (try? context.fetch(taskRequest)) ?? []

        let total = tasks.count
        let completed = tasks.filter { $0.isCompleted }.count

        // Priority-wise counts
        var high = 0
        var medium = 0
        var low = 0

        for task in tasks {
            switch task.priority {
            case .high:   high += 1
            case .medium: medium += 1
            case .low:    low += 1
            }
        }

        // Pick next upcoming incomplete task for today (or first incomplete)
        let now = Date()
        let next = tasks.first {
            !$0.isCompleted && (($0.date ?? todayStart) >= now)
        } ?? tasks.first {
            !$0.isCompleted
        }

        // ---- Habits scheduled for today ----
        let habitRequest: NSFetchRequest<HabitItem> = HabitItem.fetchRequest()
        let habits = (try? context.fetch(habitRequest)) ?? []

        let weekday = calendar.component(.weekday, from: Date()) // 1 = Sun, 2 = Mon, ...

        var activeHabitsToday = 0
        for habit in habits where habit.isActive {
            if isHabitScheduledToday(habit, weekday: weekday) {
                activeHabitsToday += 1
            }
        }

        let summary = TodaySummary(
            generatedAt: Date(),
            totalTasks: total,
            completedTasks: completed,
            nextTaskTitle: next?.title,
            nextTaskTime: next?.date,
            highCount: high,
            mediumCount: medium,
            lowCount: low,
            activeHabitsToday: activeHabitsToday
        )

        TodaySummaryStorage.save(summary)

        // 🔄 Force widget to reload whenever summary changes
        WidgetCenter.shared.reloadTimelines(ofKind: "DailyReminderWidget")
    }

    private static func isHabitScheduledToday(_ habit: HabitItem, weekday: Int) -> Bool {
        switch weekday {
        case 1: return habit.repeatSunday
        case 2: return habit.repeatMonday
        case 3: return habit.repeatTuesday
        case 4: return habit.repeatWednesday
        case 5: return habit.repeatThursday
        case 6: return habit.repeatFriday
        case 7: return habit.repeatSaturday
        default: return false
        }
    }
}
