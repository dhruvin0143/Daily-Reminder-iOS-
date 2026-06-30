//
//  Persistence.swift
//  dailyreminder
//
//  Created by BMIIT on 02/12/25.
//
import SwiftUI
import CoreData

struct HighPriorityAlertView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager   // currently not used but kept for future
    @FetchRequest private var tasks: FetchedResults<TaskItem>

    init(taskBaseId: String) {
        _tasks = FetchRequest<TaskItem>(
            sortDescriptors: [],
            predicate: NSPredicate(format: "notificationId == %@", taskBaseId),
            animation: .default
        )
    }

    private var task: TaskItem? {
        tasks.first
    }

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [
                    Color.black.opacity(0.9),
                    Color(red: 0.25, green: 0.02, blue: 0.05)
                ],
                center: .center,
                startRadius: 10,
                endRadius: 600
            )
            .ignoresSafeArea()

            if let task = task {
                VStack(spacing: 24) {
                    Text("HIGH PRIORITY")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())

                    VStack(spacing: 14) {
                        Text(task.title ?? "Task")
                            .font(.system(size: 30, weight: .bold))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)

                        if let notes = task.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        if let date = task.date {
                            HStack(spacing: 8) {
                                Image(systemName: "clock")
                                Text(timeString(from: date))
                            }
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.red.opacity(0.9),
                                        Color.purple.opacity(0.7)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 16)

                    HStack(spacing: 16) {
                        Button {
                            dismissAlert()
                        } label: {
                            Text("Snooze")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.15))
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }

                        Button {
                            stopTaskAlerts()
                        } label: {
                            Text("Stop")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(.red)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
            } else {
                VStack(spacing: 16) {
                    Text("Task not found")
                        .foregroundColor(.white)
                    Button("Close") {
                        dismissAlert()
                    }
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.black)
                    .clipShape(Capsule())
                }
            }
        }
    }

    private func dismissAlert() {
        appState.activeAlarmTaskBaseId = nil
    }

    private func stopTaskAlerts() {
        if let baseId = task?.notificationId {
            NotificationManager.shared.cancelTaskNotifications(forBaseId: baseId)
        }
        if let task = task {
            task.isCompleted = true
            try? viewContext.save()
        }
        dismissAlert()
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
