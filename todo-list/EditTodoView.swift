//
//  EditTodoView.swift
//  todo-list
//
//  Created by 井上京佳 on 2026/04/08.
//

import SwiftUI
import UIKit

struct EditTodoView: View {
    @Environment(\.dismiss) private var dismiss
    let todo: Todo
    @State private var title: String
    @State private var dueDateEnabled: Bool
    @State private var dueDate: Date
    @State private var repeatInterval: RepeatInterval?
    @State private var repeatCount: Int
    @State private var repeatWeekdays: [Int]
    @State private var repeatEndCondition: RepeatEndCondition?
    @State private var repeatEndCount: Int
    @State private var repeatEndDate: Date
    @State private var showNotificationDeniedAlert = false
    @State private var selectedDetent: PresentationDetent = .height(340)
    @FocusState private var isFocused: Bool
    @AppStorage("accentColor") private var accentColorHex = "#007AFF"

    init(todo: Todo) {
        self.todo = todo
        _title = State(initialValue: todo.title)
        _dueDateEnabled = State(initialValue: todo.dueDate != nil)
        _dueDate = State(initialValue: todo.dueDate ?? Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date())
        _repeatInterval = State(initialValue: todo.repeatInterval)
        _repeatCount = State(initialValue: todo.repeatIntervalCount)
        _repeatWeekdays = State(initialValue: todo.repeatWeekdays)
        _repeatEndCondition = State(initialValue: todo.repeatEndCondition)
        _repeatEndCount = State(initialValue: todo.repeatEndCount > 0 ? todo.repeatEndCount : 3)
        _repeatEndDate = State(initialValue: todo.repeatEndDate ?? Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date())

        let hasDueDate = todo.dueDate != nil
        let hasEndValue = todo.repeatEndCondition != nil
        let h: CGFloat = hasDueDate ? (hasEndValue ? 700 : 600) : 340
        _selectedDetent = State(initialValue: .height(h))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
            VStack(spacing: 16) {
                TextField("Title", text: $title)
                    .font(.body)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.06), lineWidth: 1))
                    .focused($isFocused)

                Toggle("Due Date", isOn: $dueDateEnabled.animation())
                    .tint(Color(hex: accentColorHex) ?? .blue)
                    .font(.body)
                    .padding(.horizontal, 4)
                    .onChange(of: dueDateEnabled) { _, enabled in
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
                                dueDateEnabled = false
                                updateDetent()
                                showNotificationDeniedAlert = true
                            }
                        }
                    }

                if dueDateEnabled {
                    DatePicker(
                        "",
                        selection: $dueDate,
                        in: min(dueDate, Date())...,
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
                                repeatWeekdays = [Calendar.current.component(.weekday, from: dueDate)]
                            }
                        } else {
                            repeatWeekdays = []
                        }
                        if newVal == nil { repeatEndCondition = nil }
                        updateDetent()
                    }

                    if repeatInterval == .weekly {
                        weekdaySelector
                    } else if let interval = repeatInterval {
                        HStack {
                            Text("Every")
                            Spacer()
                            NumberStepperField(value: $repeatCount, range: 1...99)
                            Text(interval.unitLabel(count: repeatCount))
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

                let trimmed = title.trimmingCharacters(in: .whitespaces)

                Button {
                    guard !trimmed.isEmpty else { return }
                    todo.title = trimmed
                    todo.repeatInterval = dueDateEnabled ? repeatInterval : nil
                    todo.repeatWeekdays = (dueDateEnabled && repeatInterval == .weekly) ? repeatWeekdays : []
                    todo.repeatIntervalCount = (dueDateEnabled && repeatInterval != nil && repeatInterval != .weekly) ? repeatCount : 1
                    todo.repeatEndCondition = (dueDateEnabled && repeatInterval != nil) ? repeatEndCondition : nil
                    todo.repeatEndCount = repeatEndCount
                    todo.repeatEndDate = (dueDateEnabled && repeatInterval != nil && repeatEndCondition == .onDate) ? repeatEndDate : nil
                    if dueDateEnabled && repeatInterval == .weekly && !repeatWeekdays.isEmpty {
                        todo.dueDate = nextWeekdayOccurrence(after: Date(), weekdays: repeatWeekdays, time: dueDate)
                    } else {
                        todo.dueDate = dueDateEnabled ? dueDate : nil
                    }
                    Task {
                        if dueDateEnabled && !todo.isCompleted {
                            await NotificationManager.shared.schedule(for: todo)
                        } else {
                            NotificationManager.shared.cancel(for: todo)
                        }
                    }
                    dismiss()
                } label: {
                    Text("Save")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(trimmed.isEmpty ? Color.secondary : ((Color(hex: accentColorHex) ?? .blue).isLight ? Color(white: 0.3) : Color.white))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(trimmed.isEmpty ? AnyShapeStyle(Color.primary.opacity(0.06)) : AnyShapeStyle(Color(hex: accentColorHex) ?? .blue))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(trimmed.isEmpty)

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
            .navigationTitle("Edit Todo")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { isFocused = true }
            .presentationDetents(
                [.height(340), .height(600), .height(700)],
                selection: $selectedDetent
            )
            .alert("Notifications Disabled", isPresented: $showNotificationDeniedAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enable notifications in Settings to receive due date reminders.")
            }
        }
    }

    private var weekdaySelector: some View {
        WeekdaySelectorView(selectedWeekdays: $repeatWeekdays)
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
                    Text(repeatEndCount == 1 ? "repeat" : "repeats")
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 55, alignment: .leading)
                }
                .padding(.horizontal, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else if repeatEndCondition == .onDate {
                DatePicker(
                    "",
                    selection: $repeatEndDate,
                    in: dueDate...,
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

    private func updateDetent() {
        let h: CGFloat
        if !dueDateEnabled {
            h = 340
        } else if repeatInterval != nil && repeatEndCondition != nil {
            h = 700
        } else {
            h = 600
        }
        selectedDetent = .height(h)
    }
}
