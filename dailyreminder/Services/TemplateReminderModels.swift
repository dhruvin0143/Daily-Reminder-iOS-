//
//  Persistence.swift
//  dailyreminder
//
//  Created by BMIIT on 02/12/25.
//
import Foundation

enum TemplateKind: String, Codable, CaseIterable, Identifiable {
    case birthday
    case dailyImportant

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .birthday: return "Birthday"
        case .dailyImportant: return "Important every day"
        }
    }
}

struct TemplateReminderItem: Identifiable, Codable {
    let id: UUID
    var kind: TemplateKind

    // Common
    var title: String
    var notes: String?
    var isActive: Bool

    // Birthday-specific
    var dateOfBirth: Date?      // full DOB, we use only month/day
    var morningTime: Date?      // time for morning reminder
    var eveningTime: Date?      // time for day-before evening reminder
    var birthdaySnoozeMinutes: Int // 2,5,10 (for 3 repeats 2min gaps we use minute offsets)

    // Daily important
    var dailyTime: Date?        // time for daily important reminder
    var repeatSunday: Bool
    var repeatMonday: Bool
    var repeatTuesday: Bool
    var repeatWednesday: Bool
    var repeatThursday: Bool
    var repeatFriday: Bool
    var repeatSaturday: Bool
    var dailySnoozeMinutes: Int // 2,5,10 (we’ll use 3 repeats with gaps)
}

final class TemplateReminderStore: ObservableObject {

    static let shared = TemplateReminderStore()

    @Published private(set) var items: [TemplateReminderItem] = []

    private let storageKey = "TemplateReminders"

    private init() {
        load()
    }

    func load() {
        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([TemplateReminderItem].self, from: data) else {
            items = []
            return
        }
        items = decoded
    }

    private func save() {
        let defaults = UserDefaults.standard
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: storageKey)
        }
    }

    func add(_ item: TemplateReminderItem) {
        items.append(item)
        save()
    }

    func update(_ item: TemplateReminderItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
            save()
        }
    }

    func remove(_ item: TemplateReminderItem) {
        items.removeAll { $0.id == item.id }
        save()
    }
}
