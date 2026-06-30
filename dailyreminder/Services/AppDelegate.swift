//
//  AppDelegate.swift
//  dailyreminder
//
//  Created by BMIIT on 02/12/25.
//

import UIKit
import UserNotifications

/// Notification categories (types)
enum NotificationCategory: String {
    case highTask = "HIGH_TASK_ALERT"
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {

        let center = UNUserNotificationCenter.current()
        center.delegate = self

        // Configure custom categories (snooze/stop)
        NotificationManager.shared.configureCategories()

        return true
    }

    // Called when user taps on a notification / notification action
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let content = response.notification.request.content
        let userInfo = content.userInfo
        let baseId = userInfo["taskBaseId"] as? String

        if content.categoryIdentifier == NotificationCategory.highTask.rawValue {
            switch response.actionIdentifier {
            case UNNotificationDefaultActionIdentifier:
                // User tapped the notification body → show full-screen alert
                if let baseId = baseId {
                    DispatchQueue.main.async {
                        AppState.shared.activeAlarmTaskBaseId = baseId
                    }
                }

            case "STOP_ACTION":
                if let baseId = baseId {
                    NotificationManager.shared.cancelTaskNotifications(forBaseId: baseId)
                }

            case "SNOOZE_ACTION":
                // We already pre-scheduled future repeats for this task,
                // so snooze action just dismisses this one.
                break

            default:
                break
            }
        }

        completionHandler()
    }
}
