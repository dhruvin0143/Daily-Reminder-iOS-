//
//  Persistence.swift
//  dailyreminder
//
//  Created by BMIIT on 02/12/25.
//
import Foundation
import UserNotifications
import CoreData

final class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationManager()
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - Basic permission

    func requestAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification auth error: \(error)")
            } else {
                print("Notification permission: \(granted)")
            }
        }
    }

    // MARK: - Categories

    func configureCategories() {
        let center = UNUserNotificationCenter.current()

        let highCategory = UNNotificationCategory(
            identifier: "HIGH_PRIORITY_TASK",
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        center.setNotificationCategories([highCategory])
        print("Notification categories configured")
    }

    // MARK: - Task notifications (long repeat window)

    private let maxRepeatCount = 20

    @discardableResult
    func scheduleTaskNotification(for task: TaskItem) -> String {
        guard let date = task.date else { return task.notificationId ?? UUID().uuidString }

        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current

        let baseId: String
        if let existing = task.notificationId, !existing.isEmpty {
            baseId = existing
        } else {
            baseId = (task.id?.uuidString ?? UUID().uuidString)
        }

        cancelTaskNotifications(forBaseId: baseId)

        let content = UNMutableNotificationContent()
        content.title = task.title ?? "Task reminder"
        if let notes = task.notes, !notes.isEmpty {
            content.body = notes
        } else {
            content.body = "It’s time for: \(task.title ?? "your task")"
        }

        if task.priority == .high {
            content.sound = .defaultCritical
            content.categoryIdentifier = "HIGH_PRIORITY_TASK"
        } else {
            content.sound = .default
        }

        let triggerDate = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let mainTrigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let firstId = "\(baseId)_0"
        let mainRequest = UNNotificationRequest(identifier: firstId, content: content, trigger: mainTrigger)
        center.add(mainRequest)

        let intervalMinutes = Int(task.snoozeIntervalMinutes)
        if intervalMinutes > 0 {
            for i in 1...maxRepeatCount {
                let fireDate = date.addingTimeInterval(TimeInterval(intervalMinutes * 60 * i))
                let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                let trig = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                let identifier = "\(baseId)_\(i)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trig)
                center.add(request)
            }
        }

        print("Scheduled task notifications for baseId=\(baseId)")
        return baseId
    }

    func cancelTaskNotifications(forBaseId baseId: String) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = requests.map { $0.identifier }.filter { $0.hasPrefix(baseId) }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    // MARK: - Habit notifications (weekly repeat)

    func scheduleHabitNotifications(for habit: HabitItem) {
        guard let time = habit.time else { return }
        guard habit.isActive else { return }

        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current

        let baseId: String
        if let existing = habit.baseNotificationId, !existing.isEmpty {
            baseId = existing
        } else {
            let newId = habit.id?.uuidString ?? UUID().uuidString
            habit.baseNotificationId = newId
            baseId = newId
        }

        cancelHabitNotifications(for: habit)

        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

        let content = UNMutableNotificationContent()
        content.title = habit.title ?? "Habit reminder"
        if let notes = habit.notes, !notes.isEmpty {
            content.body = notes
        } else {
            content.body = "Time for: \(habit.title ?? "your habit")"
        }
        content.sound = .default

        func schedule(for weekday: Int, suffix: String) {
            var dateComponents = DateComponents()
            dateComponents.weekday = weekday
            dateComponents.hour = timeComponents.hour
            dateComponents.minute = timeComponents.minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let identifier = "\(baseId)_\(suffix)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            center.add(request)
        }

        if habit.repeatSunday    { schedule(for: 1, suffix: "sun") }
        if habit.repeatMonday    { schedule(for: 2, suffix: "mon") }
        if habit.repeatTuesday   { schedule(for: 3, suffix: "tue") }
        if habit.repeatWednesday { schedule(for: 4, suffix: "wed") }
        if habit.repeatThursday  { schedule(for: 5, suffix: "thu") }
        if habit.repeatFriday    { schedule(for: 6, suffix: "fri") }
        if habit.repeatSaturday  { schedule(for: 7, suffix: "sat") }

        print("Scheduled habit notifications for baseId=\(baseId)")
    }

    func cancelHabitNotifications(for habit: HabitItem) {
        let center = UNUserNotificationCenter.current()
        guard let baseId = habit.baseNotificationId else { return }

        center.getPendingNotificationRequests { requests in
            let ids = requests.map { $0.identifier }.filter { $0.hasPrefix(baseId) }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    // MARK: - Morning reminder

    private let morningReminderId = "morning_plan_question"

    func scheduleMorningReminder(settings: AppSettings) {
        let center = UNUserNotificationCenter.current()
        cancelMorningReminder()

        guard settings.morningReminderEnabled,
              let time = settings.morningReminderTime else { return }

        let calendar = Calendar.current
        let comps = calendar.dateComponents([.hour, .minute], from: time)

        var dateComponents = DateComponents()
        dateComponents.hour = comps.hour
        dateComponents.minute = comps.minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = "What about today's plan?"
        content.body = "Open Daily Reminder and plan your day."
        content.sound = .default

        let request = UNNotificationRequest(identifier: morningReminderId, content: content, trigger: trigger)
        center.add(request)
    }

    func cancelMorningReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [morningReminderId])
    }

    // MARK: - Template notifications

    // Birthday: day-1 morning & evening, day 0 morning. Each with 3 repeats 2 mins apart, yearly.
    func scheduleBirthdayTemplate(_ item: TemplateReminderItem) {
        guard let dob = item.dateOfBirth,
              let morning = item.morningTime else { return }

        let calendar = Calendar.current
        let center = UNUserNotificationCenter.current()

        let baseId = "TEMPLATE_BIRTHDAY_\(item.id.uuidString)"
        cancelTemplateNotifications(baseIdPrefix: baseId)

        let compsDOB = calendar.dateComponents([.month, .day], from: dob)

        func scheduleDay(month: Int, day: Int, baseTime: Date, label: String) {
            let timeComps = calendar.dateComponents([.hour, .minute], from: baseTime)
            for i in 0..<3 {
                var dc = DateComponents()
                dc.month = month
                dc.day = day
                dc.hour = timeComps.hour
                dc.minute = (timeComps.minute ?? 0) + i * 2  // 2 min gaps
                let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)

                let content = UNMutableNotificationContent()
                content.title = "Birthday: \(item.title)"
                content.body = item.notes ?? "Wish them a happy birthday!"
                content.sound = .defaultCritical
                content.categoryIdentifier = "HIGH_PRIORITY_TASK"

                let id = "\(baseId)_\(label)_\(i)"
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                center.add(request)
            }
        }

        if let month = compsDOB.month, let day = compsDOB.day {
            if let evening = item.eveningTime {
                if let dayBefore = calendar.date(byAdding: .day, value: -1, to: dob),
                   let monthBefore = calendar.dateComponents([.month, .day], from: dayBefore).month,
                   let dayBeforeDay = calendar.dateComponents([.month, .day], from: dayBefore).day {
                    scheduleDay(month: monthBefore, day: dayBeforeDay, baseTime: morning, label: "d-1-morning")
                    scheduleDay(month: monthBefore, day: dayBeforeDay, baseTime: evening, label: "d-1-evening")
                }
            }
            scheduleDay(month: month, day: day, baseTime: morning, label: "d0-morning")
        }
    }

    // Daily important: for each selected weekday, 3 repeats every week at 2min gaps
    func scheduleDailyImportantTemplate(_ item: TemplateReminderItem) {
        guard let baseTime = item.dailyTime else { return }

        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        let baseId = "TEMPLATE_DAILY_\(item.id.uuidString)"
        cancelTemplateNotifications(baseIdPrefix: baseId)

        let timeComps = calendar.dateComponents([.hour, .minute], from: baseTime)

        func schedule(weekday: Int, label: String) {
            for i in 0..<3 {
                var dc = DateComponents()
                dc.weekday = weekday
                dc.hour = timeComps.hour
                dc.minute = (timeComps.minute ?? 0) + i * 2

                let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)

                let content = UNMutableNotificationContent()
                content.title = item.title
                content.body = item.notes ?? "Important reminder"
                content.sound = .defaultCritical
                content.categoryIdentifier = "HIGH_PRIORITY_TASK"

                let id = "\(baseId)_\(label)_\(i)"
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                center.add(request)
            }
        }

        if item.repeatSunday    { schedule(weekday: 1, label: "sun") }
        if item.repeatMonday    { schedule(weekday: 2, label: "mon") }
        if item.repeatTuesday   { schedule(weekday: 3, label: "tue") }
        if item.repeatWednesday { schedule(weekday: 4, label: "wed") }
        if item.repeatThursday  { schedule(weekday: 5, label: "thu") }
        if item.repeatFriday    { schedule(weekday: 6, label: "fri") }
        if item.repeatSaturday  { schedule(weekday: 7, label: "sat") }
    }

    func cancelTemplateNotifications(baseIdPrefix: String) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = requests.map { $0.identifier }.filter { $0.hasPrefix(baseIdPrefix) }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    // MARK: - Delegate

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
