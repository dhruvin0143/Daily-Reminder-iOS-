//
//  Persistence.swift
//  dailyreminder
//
//  Created by BMIIT on 02/12/25.
//
import SwiftUI
import CoreData

struct RootTabView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager

    @FetchRequest(
        sortDescriptors: [],
        animation: .default
    )
    private var settingsArray: FetchedResults<AppSettings>

    var isDarkNow: Bool {
        themeManager.isDarkNow
    }

    var body: some View {
        ZStack {
            (isDarkNow ? AppTheme.Dark.background : AppTheme.Light.background)
                .ignoresSafeArea()

            TabView {
                TodayView()
                    .tabItem {
                        Label("Today", systemImage: "list.bullet.rectangle")
                    }

                StatsView()
                    .tabItem {
                        Label("Stats", systemImage: "chart.bar.xaxis")
                    }

                TemplatesView()
                    .tabItem {
                        Label("Templates", systemImage: "square.grid.2x2")
                    }

                NavigationStack {
                    SettingsView()
                }
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
            }
            .tint(isDarkNow ? .white : Color(red: 0.40, green: 0.53, blue: 0.98))
        }
        .onAppear {
            NotificationManager.shared.requestAuthorization()
            NotificationManager.shared.configureCategories()
            ensureSettingsAndScheduleReminder()
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { appState.activeAlarmTaskBaseId != nil },
                set: { newValue in
                    if !newValue {
                        appState.activeAlarmTaskBaseId = nil
                    }
                }
            )
        ) {
            if let baseId = appState.activeAlarmTaskBaseId {
                HighPriorityAlertView(taskBaseId: baseId)
                    .environment(\.managedObjectContext, viewContext)
                    .environmentObject(themeManager)
                    .environmentObject(appState)
            }
        }
    }

    private func ensureSettingsAndScheduleReminder() {
        if let existing = settingsArray.first {
            NotificationManager.shared.scheduleMorningReminder(settings: existing)
        } else {
            let newSettings = AppSettings(context: viewContext)
            newSettings.id = UUID()
            newSettings.morningReminderEnabled = true
            newSettings.morningReminderTime = defaultMorningTime()

            try? viewContext.save()
            NotificationManager.shared.scheduleMorningReminder(settings: newSettings)
        }
    }

    private func defaultMorningTime() -> Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour = 9
        comps.minute = 0
        return Calendar.current.date(from: comps) ?? Date()
    }
}

struct RootTabView_Previews: PreviewProvider {
    static var previews: some View {
        RootTabView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(AppState.shared)
            .environmentObject(ThemeManager.shared)
    }
}
