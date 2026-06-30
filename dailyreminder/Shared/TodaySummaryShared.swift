//
//  Persistence.swift
//  dailyreminder
//
//  Created by BMIIT on 02/12/25.
//
import Foundation

/// Summary of today's tasks that the app writes and the widget reads.
struct TodaySummary: Codable {
    let generatedAt: Date

    // Tasks
    let totalTasks: Int
    let completedTasks: Int
    let nextTaskTitle: String?
    let nextTaskTime: Date?

    // Priority-wise task counts
    let highCount: Int
    let mediumCount: Int
    let lowCount: Int

    // Habits
    let activeHabitsToday: Int
}

/// App Group configuration — make sure `id` matches your App Group.
/// For you it should be: group.bmiit.com.dailyreminder
struct AppGroupConfig {
    static let id = "group.bmiit.com.dailyreminder"

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: id)
    }
}

struct TodaySummaryStorage {
    private static let key = "todaySummary"

    static func load() -> TodaySummary? {
        guard let defaults = AppGroupConfig.defaults,
              let data = defaults.data(forKey: key) else {
            return nil
        }
        return try? JSONDecoder().decode(TodaySummary.self, from: data)
    }

    static func save(_ summary: TodaySummary) {
        guard let defaults = AppGroupConfig.defaults,
              let data = try? JSONEncoder().encode(summary) else { return }
        defaults.set(data, forKey: key)
    }
}
