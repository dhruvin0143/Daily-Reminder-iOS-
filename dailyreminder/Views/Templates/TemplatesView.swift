//
//  Persistence.swift
//  dailyreminder
//
//  Created by BMIIT on 02/12/25.
//
import SwiftUI
import CoreData

struct TemplatesView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var themeManager: ThemeManager

    @StateObject private var store = TemplateReminderStore.shared

    // Core Data habits
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \HabitItem.title, ascending: true)],
        animation: .default
    )
    private var habits: FetchedResults<HabitItem>

    // Sheet / dialogs
    @State private var isPresentingTemplateEditor = false
    @State private var editingTemplateItem: TemplateReminderItem? = nil
    @State private var isEditingExistingTemplate = false

    @State private var isPresentingAddHabit = false
    @State private var editingHabit: HabitItem? = nil   // sheet(item:) – fixes “second tap” issue

    private var isDark: Bool { themeManager.isDarkNow }

    var body: some View {
        NavigationStack {
            ZStack {
                (isDark ? AppTheme.Dark.background : AppTheme.Light.background)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        header

                        habitSection

                        templateSection
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Templates")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // Dropdown-style add button
                    Menu {
                        Button {
                            isPresentingAddHabit = true
                        } label: {
                            Label("Habit", systemImage: "heart.text.square")
                        }

                        Button {
                            editingTemplateItem = nil
                            isEditingExistingTemplate = false
                            isPresentingTemplateEditor = true
                        } label: {
                            Label("Template (Birthday / Important)", systemImage: "square.grid.2x2")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            // Template editor sheet
            .sheet(isPresented: $isPresentingTemplateEditor) {
                TemplateEditorView(
                    existingItem: isEditingExistingTemplate ? editingTemplateItem : nil
                ) { newItem in
                    if isEditingExistingTemplate, let _ = editingTemplateItem {
                        TemplateReminderStore.shared.update(newItem)
                        rescheduleTemplate(newItem, wasExisting: true)
                    } else {
                        TemplateReminderStore.shared.add(newItem)
                        rescheduleTemplate(newItem, wasExisting: false)
                    }

                    isPresentingTemplateEditor = false
                    editingTemplateItem = nil
                    isEditingExistingTemplate = false
                }
                .environmentObject(themeManager)
            }
            // Add Habit sheet
            .sheet(isPresented: $isPresentingAddHabit) {
                AddHabitView()
                    .environment(\.managedObjectContext, viewContext)
                    .environmentObject(themeManager)
            }
            // Edit Habit sheet – uses item binding to avoid the “second tap” bug
            .sheet(item: $editingHabit) { habit in
                EditHabitView(habit: habit)
                    .environment(\.managedObjectContext, viewContext)
                    .environmentObject(themeManager)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Smart reminders")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(isDark ? AppTheme.Dark.textPrimary : AppTheme.Light.textPrimary)
            Text("Manage all your habits and templates (birthdays, daily important) in one place.")
                .font(.subheadline)
                .foregroundColor(isDark ? AppTheme.Dark.textSecondary : AppTheme.Light.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Habit section

    private var habitSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Habit reminders")
                    .font(.headline)
                    .foregroundColor(isDark ? AppTheme.Dark.textPrimary : AppTheme.Light.textPrimary)
                Spacer()
                Button {
                    isPresentingAddHabit = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle")
                        Text("Add habit")
                    }
                    .font(.caption)
                }
            }

            if habits.isEmpty {
                Text("No habits yet. Tap “Add habit” to create routines like water, walk or gym.")
                    .font(.footnote)
                    .foregroundColor(isDark ? AppTheme.Dark.textSecondary : AppTheme.Light.textSecondary)
            } else {
                ForEach(habits) { habit in
                    HabitRow(
                        habit: habit,
                        onEdit: {
                            editingHabit = habit      // first tap opens immediately
                        },
                        onDelete: {
                            deleteHabit(habit)
                        }
                    )
                    .environment(\.managedObjectContext, viewContext)
                    .environmentObject(themeManager)
                }
            }
        }
    }

    private func deleteHabit(_ habit: HabitItem) {
        NotificationManager.shared.cancelHabitNotifications(for: habit)
        viewContext.delete(habit)
        try? viewContext.save()
    }

    // MARK: - Template section

    private var templateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Template reminders")
                .font(.headline)
                .foregroundColor(isDark ? AppTheme.Dark.textPrimary : AppTheme.Light.textPrimary)

            if store.items.isEmpty {
                Text("No templates yet. Use the + button and choose Template to set up birthdays or daily important reminders.")
                    .font(.footnote)
                    .foregroundColor(isDark ? AppTheme.Dark.textSecondary : AppTheme.Light.textSecondary)
            } else {
                ForEach(store.items) { item in
                    templateRow(item)
                }
            }
        }
    }

    private func templateRow(_ item: TemplateReminderItem) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline.bold())
                    .foregroundColor(isDark ? AppTheme.Dark.textPrimary : AppTheme.Light.textPrimary)

                Text(item.kind.displayName)
                    .font(.caption)
                    .foregroundColor(isDark ? AppTheme.Dark.textSecondary : AppTheme.Light.textSecondary)
            }

            Spacer()

            // Active toggle
            Toggle("", isOn: Binding(
                get: { item.isActive },
                set: { newValue in
                    toggleTemplate(item, isActive: newValue)
                }
            ))
            .labelsHidden()
            .tint(AppTheme.priorityColor(.high))

            // Delete
            Button(role: .destructive) {
                deleteTemplate(item)
            } label: {
                Image(systemName: "trash")
            }
        }
        .padding(10)
        .background(
            (isDark ? AppTheme.Dark.card : AppTheme.Light.card)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        )
        // Tap row to edit (we removed the pencil icon)
        .onTapGesture {
            editingTemplateItem = item
            isEditingExistingTemplate = true
            isPresentingTemplateEditor = true
        }
    }

    // MARK: - Template actions

    private func rescheduleTemplate(_ item: TemplateReminderItem, wasExisting: Bool) {
        let basePrefix: String
        switch item.kind {
        case .birthday:
            basePrefix = "TEMPLATE_BIRTHDAY_\(item.id.uuidString)"
        case .dailyImportant:
            basePrefix = "TEMPLATE_DAILY_\(item.id.uuidString)"
        }

        if wasExisting {
            NotificationManager.shared.cancelTemplateNotifications(baseIdPrefix: basePrefix)
        }

        if item.isActive {
            switch item.kind {
            case .birthday:
                NotificationManager.shared.scheduleBirthdayTemplate(item)
            case .dailyImportant:
                NotificationManager.shared.scheduleDailyImportantTemplate(item)
            }
        }
    }

    private func toggleTemplate(_ item: TemplateReminderItem, isActive: Bool) {
        var updated = item
        updated.isActive = isActive
        TemplateReminderStore.shared.update(updated)

        let basePrefix: String
        switch item.kind {
        case .birthday:
            basePrefix = "TEMPLATE_BIRTHDAY_\(item.id.uuidString)"
        case .dailyImportant:
            basePrefix = "TEMPLATE_DAILY_\(item.id.uuidString)"
        }

        NotificationManager.shared.cancelTemplateNotifications(baseIdPrefix: basePrefix)

        if isActive {
            switch updated.kind {
            case .birthday:
                NotificationManager.shared.scheduleBirthdayTemplate(updated)
            case .dailyImportant:
                NotificationManager.shared.scheduleDailyImportantTemplate(updated)
            }
        }
    }

    private func deleteTemplate(_ item: TemplateReminderItem) {
        TemplateReminderStore.shared.remove(item)

        let basePrefix: String
        switch item.kind {
        case .birthday:
            basePrefix = "TEMPLATE_BIRTHDAY_\(item.id.uuidString)"
        case .dailyImportant:
            basePrefix = "TEMPLATE_DAILY_\(item.id.uuidString)"
        }
        NotificationManager.shared.cancelTemplateNotifications(baseIdPrefix: basePrefix)
    }
}

// MARK: - Habit Row (with tap-to-edit, toggle, delete)

private struct HabitRow: View {

    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var habit: HabitItem

    let onEdit: () -> Void
    let onDelete: () -> Void

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
            // Card – tap to edit
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

            VStack(spacing: 8) {
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
                .tint(.white)

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                }
            }
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

// MARK: - Template editor (unchanged from previous version)

private struct TemplateEditorView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager

    let existingItem: TemplateReminderItem?
    let onSave: (TemplateReminderItem) -> Void

    @State private var selectedKind: TemplateKind

    // Common
    @State private var title: String
    @State private var notes: String

    // Birthday
    @State private var birthdayDOB: Date
    @State private var birthdayMorning: Date
    @State private var birthdayEvening: Date
    @State private var birthdaySnooze: Int

    // Daily important
    @State private var dailyTime: Date
    @State private var dSun: Bool
    @State private var dMon: Bool
    @State private var dTue: Bool
    @State private var dWed: Bool
    @State private var dThu: Bool
    @State private var dFri: Bool
    @State private var dSat: Bool
    @State private var dailySnooze: Int

    private var isDark: Bool { themeManager.isDarkNow }

    init(existingItem: TemplateReminderItem?, onSave: @escaping (TemplateReminderItem) -> Void) {
        self.existingItem = existingItem
        self.onSave = onSave

        if let item = existingItem {
            _selectedKind = State(initialValue: item.kind)
            _title = State(initialValue: item.title)
            _notes = State(initialValue: item.notes ?? "")
            _birthdayDOB = State(initialValue: item.dateOfBirth ?? Date())
            _birthdayMorning = State(initialValue: item.morningTime ?? TemplatesView.defaultMorning())
            _birthdayEvening = State(initialValue: item.eveningTime ?? TemplatesView.defaultEvening())
            _birthdaySnooze = State(initialValue: item.birthdaySnoozeMinutes == 0 ? 2 : item.birthdaySnoozeMinutes)
            _dailyTime = State(initialValue: item.dailyTime ?? TemplatesView.defaultMorning())
            _dSun = State(initialValue: item.repeatSunday)
            _dMon = State(initialValue: item.repeatMonday)
            _dTue = State(initialValue: item.repeatTuesday)
            _dWed = State(initialValue: item.repeatWednesday)
            _dThu = State(initialValue: item.repeatThursday)
            _dFri = State(initialValue: item.repeatFriday)
            _dSat = State(initialValue: item.repeatSaturday)
            _dailySnooze = State(initialValue: item.dailySnoozeMinutes == 0 ? 2 : item.dailySnoozeMinutes)
        } else {
            _selectedKind = State(initialValue: .birthday)
            _title = State(initialValue: "")
            _notes = State(initialValue: "")
            _birthdayDOB = State(initialValue: Date())
            _birthdayMorning = State(initialValue: TemplatesView.defaultMorning())
            _birthdayEvening = State(initialValue: TemplatesView.defaultEvening())
            _birthdaySnooze = State(initialValue: 2)
            _dailyTime = State(initialValue: TemplatesView.defaultMorning())
            _dSun = State(initialValue: false)
            _dMon = State(initialValue: false)
            _dTue = State(initialValue: false)
            _dWed = State(initialValue: false)
            _dThu = State(initialValue: false)
            _dFri = State(initialValue: false)
            _dSat = State(initialValue: false)
            _dailySnooze = State(initialValue: 2)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                (isDark ? AppTheme.Dark.background : AppTheme.Light.background)
                    .ignoresSafeArea()

                Form {
                    Section {
                        Picker("Template type", selection: $selectedKind) {
                            ForEach(TemplateKind.allCases) { kind in
                                Text(kind.displayName).tag(kind)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Section {
                        TextField("Title / name", text: $title)
                        TextField("Notes (optional)", text: $notes, axis: .vertical)
                            .lineLimit(1...3)
                    } header: {
                        Text("Basic info")
                    }

                    Group {
                        switch selectedKind {
                        case .birthday:
                            birthdaySection
                        case .dailyImportant:
                            dailySection
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(existingItem == nil ? "New template" : "Edit template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveTemplate() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private var birthdaySection: some View {
        Section {
            DatePicker("Date of birth", selection: $birthdayDOB, displayedComponents: .date)

            DatePicker("Morning reminder time", selection: $birthdayMorning, displayedComponents: .hourAndMinute)

            DatePicker("Evening (day before)", selection: $birthdayEvening, displayedComponents: .hourAndMinute)

            Picker("Repeat gap", selection: $birthdaySnooze) {
                Text("Every 2 min (3x)").tag(2)
                Text("Every 5 min (3x)").tag(5)
                Text("Every 10 min (3x)").tag(10)
            }
            .pickerStyle(.menu)
        } header: {
            Text("Birthday behaviour")
        } footer: {
            Text("You’ll get reminders the evening before and on the birthday morning, with 3 alerts at the chosen gap.")
                .font(.footnote)
        }
    }

    private var dailySection: some View {
        Section {
            DatePicker("Reminder time", selection: $dailyTime, displayedComponents: .hourAndMinute)

            HStack {
                dayToggle("S", isOn: $dSun)
                dayToggle("M", isOn: $dMon)
                dayToggle("T", isOn: $dTue)
                dayToggle("W", isOn: $dWed)
                dayToggle("T", isOn: $dThu)
                dayToggle("F", isOn: $dFri)
                dayToggle("S", isOn: $dSat)
            }

            Picker("Repeat gap", selection: $dailySnooze) {
                Text("Every 2 min (3x)").tag(2)
                Text("Every 5 min (3x)").tag(5)
                Text("Every 10 min (3x)").tag(10)
            }
            .pickerStyle(.menu)
        } header: {
            Text("Daily behaviour")
        } footer: {
            Text("Reminder repeats 3 times on each selected day at the chosen gap.")
                .font(.footnote)
        }
    }

    private func dayToggle(_ label: String, isOn: Binding<Bool>) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            Text(label)
                .frame(maxWidth: .infinity)
                .padding(6)
                .background(
                    Group {
                        if isOn.wrappedValue {
                            LinearGradient(
                                colors: [
                                    Color(red: 0.36, green: 0.80, blue: 0.67),
                                    Color(red: 0.26, green: 0.66, blue: 0.93)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            Color.gray.opacity(0.15)
                        }
                    }
                )
                .foregroundColor(
                    isOn.wrappedValue
                    ? .white
                    : (isDark ? AppTheme.Dark.textPrimary : AppTheme.Light.textPrimary)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var canSave: Bool {
        switch selectedKind {
        case .birthday:
            return !title.trimmed().isEmpty
        case .dailyImportant:
            let anyDay = dSun || dMon || dTue || dWed || dThu || dFri || dSat
            return !title.trimmed().isEmpty && anyDay
        }
    }

    private func saveTemplate() {
        let id: UUID = existingItem?.id ?? UUID()
        let isActive = existingItem?.isActive ?? true

        let item = TemplateReminderItem(
            id: id,
            kind: selectedKind,
            title: title.trimmed(),
            notes: notes.isEmpty ? nil : notes,
            isActive: isActive,
            dateOfBirth: selectedKind == .birthday ? birthdayDOB : nil,
            morningTime: selectedKind == .birthday ? birthdayMorning : nil,
            eveningTime: selectedKind == .birthday ? birthdayEvening : nil,
            birthdaySnoozeMinutes: selectedKind == .birthday ? birthdaySnooze : 0,
            dailyTime: selectedKind == .dailyImportant ? dailyTime : nil,
            repeatSunday: selectedKind == .dailyImportant ? dSun : false,
            repeatMonday: selectedKind == .dailyImportant ? dMon : false,
            repeatTuesday: selectedKind == .dailyImportant ? dTue : false,
            repeatWednesday: selectedKind == .dailyImportant ? dWed : false,
            repeatThursday: selectedKind == .dailyImportant ? dThu : false,
            repeatFriday: selectedKind == .dailyImportant ? dFri : false,
            repeatSaturday: selectedKind == .dailyImportant ? dSat : false,
            dailySnoozeMinutes: selectedKind == .dailyImportant ? dailySnooze : 0
        )

        onSave(item)
        dismiss()
    }
}

// MARK: - Defaults

extension TemplatesView {
    static func defaultMorning() -> Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour = 9
        comps.minute = 0
        return Calendar.current.date(from: comps) ?? Date()
    }

    static func defaultEvening() -> Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour = 21
        comps.minute = 0
        return Calendar.current.date(from: comps) ?? Date()
    }
}

// MARK: - String helper

private extension String {
    func trimmed() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
