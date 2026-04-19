//
//  AddTodoView.swift
//  todo-list
//
//  Created by 井上京佳 on 2026/03/26.
//

import SwiftUI
import SwiftData
import UIKit

struct AddTodoView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let todoList: TodoList
    @State private var title = ""
    @State private var dueDateEnabled = false
    @State private var dueDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    @State private var repeatInterval: RepeatInterval? = nil
    @State private var repeatCount: Int = 1
    @State private var repeatWeekdays: [Int] = []
    @State private var repeatEndCondition: RepeatEndCondition? = nil
    @State private var repeatEndCount: Int = 3
    @State private var repeatEndDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var showNotificationDeniedAlert = false
    @State private var selectedDetent: PresentationDetent = .height(340)
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
            VStack(spacing: 16) {
                TextField("e.g. Buy milk", text: $title)
                    .font(.body)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.06), lineWidth: 1))
                    .focused($isFocused)

                Toggle("Add Due Date", isOn: $dueDateEnabled.animation())
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
                    let effectiveDueDate: Date? = {
                        guard dueDateEnabled else { return nil }
                        if repeatInterval == .weekly && !repeatWeekdays.isEmpty {
                            return nextWeekdayOccurrence(after: Date(), weekdays: repeatWeekdays, time: dueDate)
                        }
                        return dueDate
                    }()
                    let todo = Todo(
                        title: trimmed,
                        sortOrder: todoList.todos.count,
                        dueDate: effectiveDueDate,
                        repeatInterval: dueDateEnabled ? repeatInterval : nil,
                        repeatIntervalCount: (dueDateEnabled && repeatInterval != nil && repeatInterval != .weekly) ? repeatCount : 1,
                        repeatWeekdays: (dueDateEnabled && repeatInterval == .weekly) ? repeatWeekdays : [],
                        repeatEndCondition: (dueDateEnabled && repeatInterval != nil) ? repeatEndCondition : nil,
                        repeatEndCount: repeatEndCount,
                        repeatEndDate: (dueDateEnabled && repeatInterval != nil && repeatEndCondition == .onDate) ? repeatEndDate : nil
                    )
                    context.insert(todo)
                    todo.todoList = todoList
                    if dueDateEnabled {
                        Task { await NotificationManager.shared.schedule(for: todo) }
                    }
                    dismiss()
                } label: {
                    Text("Add")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(trimmed.isEmpty ? Color.secondary : .white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(trimmed.isEmpty ? AnyShapeStyle(Color.primary.opacity(0.06)) : AnyShapeStyle(Color.blue))
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
            .navigationTitle("New Todo")
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
