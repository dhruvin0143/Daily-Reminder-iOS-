//
//  Persistence.swift
//  dailyreminder
//
//  Created by BMIIT on 02/12/25.
//
import SwiftUI

@main
struct DailyReminderApp: App {   // ⚠️ If your app struct has a different name, keep your original name here.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let persistenceController = PersistenceController.shared

    // 🔹 Global state objects
    @StateObject var appState = AppState.shared
    @StateObject var themeManager = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(appState)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.mode == .dark ? .dark : .light)
        }
    }

}
