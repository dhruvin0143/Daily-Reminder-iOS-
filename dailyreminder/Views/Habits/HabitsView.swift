//
//  Persistence.swift
//  dailyreminder
//
//  Created by BMIIT on 02/12/25.
//
import SwiftUI
import CoreData
import UIKit

struct HabitsView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var themeManager: ThemeManager

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \HabitItem.title, ascending: true)],
        animation: .default
    )
    private var habits: FetchedResults<HabitItem>

    private var isDark: Bool {
        themeManager.isDarkNow
    }

    @State private var showingAddHabit = false
    @State private var isEditingHabit = false
    @State private var selectedHabit: HabitItem?

    var body: some View {
        NavigationStack {
            ZStack {
                (isDark ? AppTheme.Dark.background : AppTheme.Light.background)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    header

                    if habits.isEmpty {
                        emptyState
                    } else {
                        List {
                            ForEach(habits) { habit in
                                HabitRow(
                                    habit: habit,
                                    onEdit: {
                                        selectedHabit = habit
                                        isEditingHabit = true
                                    }
                                )
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                            .onDelete(perform: deleteHabits)
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.insetGrouped)
                    }
                }
                .padding(.top, 4)
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAddHabit = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView()
                    .environment(\.managedObjectContext, viewContext)
                    .environmentObject(themeManager)
            }
            .sheet(isPresented: $isEditingHabit) {
                if let habit = selectedHabit {
                    EditHabitView(habit: habit)
                        .environment(\.managedObjectContext, viewContext)
                        .environmentObject(themeManager)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Health Habits")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(isDark ? AppTheme.Dark.textPrimary : AppTheme.Light.textPrimary)

            Text("Build routines for water, workout, sleep and more.")
                .font(.subheadline)
                .foregroundColor(isDark ? AppTheme.Dark.textSecondary : AppTheme.Light.textSecondary)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var emptyState: some View {
        VStack {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "heart.text.square")
                    .font(.system(size: 44))
                    .foregroundColor(isDark ? AppTheme.Dark.textSecondary : AppTheme.Light.textSecondary)

                Text("No habits yet")
                    .font(.headline)
                    .foregroundColor(isDark ? AppTheme.Dark.textPrimary : AppTheme.Light.textPrimary)

                Text("Tap the + button to add a habit like water, walk or gym.")
                    .font(.subheadline)
                    .foregroundColor(isDark ? AppTheme.Dark.textSecondary : AppTheme.Light.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            Spacer()
        }
    }

    private func deleteHabits(at offsets: IndexSet) {
        let toDelete = offsets.map { habits[$0] }
        for habit in toDelete {
            NotificationManager.shared.cancelHabitNotifications(for: habit)
            viewContext.delete(habit)
        }
        try? viewContext.save()
    }
}

// MARK: - Row

private struct HabitRow: View {

    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var habit: HabitItem

    let onEdit: () -> Void

    private var isDark: Bool {
        themeManager.isDarkNow
    }

    var body: some View {
        let title = habit.title ?? "Habit"
        let time = habit.time ?? Date()

        let gradient = habit.isActive
            ? LinearGradient(
                colors: [
                    Color(red: 0.36, green: 0.80, blue: 0.67),
                    Color(red: 0.26, green: 0.66, blue: 0.93)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            : LinearGradient(
                colors: [
                    Color.gray.opacity(isDark ? 0.40 : 0.18),
                    Color.gray.opacity(isDark ? 0.25 : 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

        HStack(spacing: 12) {
            // Card part – tap to edit
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.white)

                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text(timeString(from: time))
                                .font(.caption)
                        }
                        .foregroundColor(.white.opacity(0.9))
                    }

                    Spacer()

                    Text(habit.isActive ? "Active" : "Paused")
                        .font(.caption2.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.22))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }

                Text(repeatDaysString(for: habit))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.93))

                if let notes = habit.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.96))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(gradient)
            )
            .shadow(color: Color.black.opacity(isDark ? 0.65 : 0.25), radius: 10, x: 0, y: 6)
            .onTapGesture {
                onEdit()
            }

            // Toggle – only toggles, does NOT open edit anymore
            Toggle("", isOn: Binding(
                get: { habit.isActive },
                set: { newValue in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        habit.isActive = newValue
                        if newValue {
                            NotificationManager.shared.scheduleHabitNotifications(for: habit)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } else {
                            NotificationManager.shared.cancelHabitNotifications(for: habit)
                        }
                        try? viewContext.save()
                    }
                }
            ))
            .labelsHidden()
            .tint(.white)   // bright switch color for dark gradient
        }
        .padding(.vertical, 4)
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func repeatDaysString(for habit: HabitItem) -> String {
        var parts: [String] = []
        if habit.repeatSunday { parts.append("Sun") }
        if habit.repeatMonday { parts.append("Mon") }
        if habit.repeatTuesday { parts.append("Tue") }
        if habit.repeatWednesday { parts.append("Wed") }
        if habit.repeatThursday { parts.append("Thu") }
        if habit.repeatFriday { parts.append("Fri") }
        if habit.repeatSaturday { parts.append("Sat") }

        if parts.isEmpty { return "No days selected" }
        if parts.count == 7 { return "Every day" }
        return parts.joined(separator: " ")
    }
}
