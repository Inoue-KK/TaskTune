//
//  ListReminderView.swift
//  todo-list
//
//  Created by 井上京佳 on 2026/05/10.
//

import SwiftUI
import UIKit

struct ListReminderView: View {
    @Bindable var todoList: TodoList
    @Environment(\.dismiss) private var dismiss

    @State private var reminderEnabled: Bool
    @State private var reminderTime: Date
    @State private var repeatInterval: RepeatInterval?
    @State private var repeatIntervalCount: Int
    @State private var repeatWeekdays: [Int]
    @State private var repeatEndCondition: RepeatEndCondition?
    @State private var repeatEndCount: Int
    @State private var repeatEndDate: Date
    @State private var showNotificationDeniedAlert = false
    @State private var selectedDetent: PresentationDetent = .height(340)
    @AppStorage("accentColor") private var accentColorHex = "#007AFF"

    init(todoList: TodoList) {
        self.todoList = todoList
        _reminderEnabled = State(initialValue: todoList.reminderEnabled)
        _reminderTime = State(initialValue: todoList.reminderTime ?? Self.defaultTime())
        _repeatInterval = State(initialValue: todoList.reminderRepeatInterval)
        _repeatIntervalCount = State(initialValue: max(1, todoList.reminderRepeatIntervalCount))
        _repeatWeekdays = State(initialValue: todoList.reminderWeekdays.isEmpty && todoList.reminderRepeatInterval == .weekly
            ? [Calendar.current.component(.weekday, from: Date())]
            : todoList.reminderWeekdays)
        _repeatEndCondition = State(initialValue: todoList.reminderRepeatEndCondition)
        _repeatEndCount = State(initialValue: max(1, todoList.reminderRepeatEndCount))
        _repeatEndDate = State(initialValue: todoList.reminderRepeatEndDate ?? Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Toggle("Remind me", isOn: $reminderEnabled.animation())
                        .tint(Color(hex: accentColorHex) ?? .blue)
                        .font(.body)
                        .padding(.horizontal, 4)
                        .onChange(of: reminderEnabled) { _, enabled in
                            if !enabled {
                                repeatInterval = nil
                                repeatWeekdays = []
                                repeatEndCondition = nil
                            }
                            updateDetent()
                            guard enabled else { return }
                            Task {
                                let status = await NotificationManager.shared.authorizationStatus()
                                if status == .denied {
                                    reminderEnabled = false
                                    updateDetent()
                                    showNotificationDeniedAlert = true
                                }
                            }
                        }

                    if reminderEnabled {
                        DatePicker(
                            "",
                            selection: $reminderTime,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))

                        Picker("Repeat", selection: $repeatInterval) {
                            Text("No Repeat").tag(Optional<RepeatInterval>.none)
                            ForEach(RepeatInterval.allCases, id: \.self) { interval in
                                Text(interval.rawValue).tag(Optional(interval))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .onChange(of: repeatInterval) { _, newVal in
                            if newVal == .weekly {
                                if repeatWeekdays.isEmpty {
                                    repeatWeekdays = [Calendar.current.component(.weekday, from: reminderTime)]
                                }
                            } else {
                                repeatWeekdays = []
                            }
                            if newVal == nil { repeatEndCondition = nil }
                            updateDetent()
                        }

                        if repeatInterval == .weekly {
                            WeekdaySelectorView(selectedWeekdays: $repeatWeekdays)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        } else if let interval = repeatInterval {
                            HStack {
                                Text("Every")
                                Spacer()
                                NumberStepperField(value: $repeatIntervalCount, range: 1...99)
                                Text(interval.unitLabel(count: repeatIntervalCount))
                                    .foregroundStyle(.secondary)
                                    .frame(minWidth: 44, alignment: .leading)
                            }
                            .padding(.horizontal, 4)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        if repeatInterval != nil {
                            endConditionPicker
                        }
                    }

                    if reminderEnabled {
                        Text("No reminder will be sent if all tasks are complete.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    Button {
                        save()
                    } label: {
                        Text("Save")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle((Color(hex: accentColorHex) ?? .blue).isLight ? Color(white: 0.3) : Color.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: accentColorHex) ?? .blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                )
            }
            .navigationTitle("Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents(
                [.height(340), .height(600), .height(700)],
                selection: $selectedDetent
            )
            .onAppear { updateDetent() }
            .alert("Notifications Disabled", isPresented: $showNotificationDeniedAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enable notifications in Settings to receive list reminders.")
            }
        }
    }

    private var endConditionPicker: some View {
        VStack(spacing: 12) {
            Picker("Ends", selection: $repeatEndCondition) {
                Text("Never").tag(Optional<RepeatEndCondition>.none)
                Text("After").tag(Optional(RepeatEndCondition.afterCount))
                Text("On Date").tag(Optional(RepeatEndCondition.onDate))
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            .onChange(of: repeatEndCondition) { _, _ in updateDetent() }

            if repeatEndCondition == .afterCount {
                HStack {
                    Text("After")
                    Spacer()
                    NumberStepperField(value: $repeatEndCount, range: 1...999)
                    Text(repeatEndCount == 1 ? "reminder" : "reminders")
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 70, alignment: .leading)
                }
                .padding(.horizontal, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else if repeatEndCondition == .onDate {
                DatePicker(
                    "",
                    selection: $repeatEndDate,
                    in: reminderTime...,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private func save() {
        todoList.reminderEnabled = reminderEnabled
        todoList.reminderTime = reminderEnabled ? reminderTime : nil
        todoList.reminderRepeatInterval = reminderEnabled ? repeatInterval : nil
        todoList.reminderRepeatIntervalCount = repeatIntervalCount
        todoList.reminderWeekdays = (reminderEnabled && repeatInterval == .weekly) ? repeatWeekdays : []
        todoList.reminderRepeatEndCondition = (reminderEnabled && repeatInterval != nil) ? repeatEndCondition : nil
        todoList.reminderRepeatEndCount = repeatEndCount
        todoList.reminderRepeatEndDate = (reminderEnabled && repeatInterval != nil && repeatEndCondition == .onDate) ? repeatEndDate : nil
        todoList.reminderOccurrenceCount = 0
        todoList.reminderLastScheduledCount = 0
        Task { await NotificationManager.shared.scheduleListReminder(for: todoList) }
        dismiss()
    }

    private func updateDetent() {
        let h: CGFloat
        if !reminderEnabled {
            h = 340
        } else if repeatInterval != nil && repeatEndCondition != nil {
            h = 700
        } else {
            h = 600
        }
        selectedDetent = .height(h)
    }

    private static func defaultTime() -> Date {
        Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    }
}
