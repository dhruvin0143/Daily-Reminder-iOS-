//
//  TaskPriority.swift
//  dailyreminder
//
//  Created by BMIIT on 02/12/25.
//
import Foundation

enum TaskPriority: Int16, CaseIterable {
    case low = 0
    case medium = 1
    case high = 2

    var label: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    /// Default snooze suggestion in minutes
    var defaultSnoozeMinutes: Int {
        switch self {
        case .low: return 0       // normal
        case .medium: return 5    // gentle
        case .high: return 2      // aggressive
        }
    }
}

// MARK: - Convenience on TaskItem

extension TaskItem {
    var priority: TaskPriority {
        get {
            TaskPriority(rawValue: self.priorityRaw) ?? .low
        }
        set {
            self.priorityRaw = newValue.rawValue
        }
    }
}
