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
    @Binding var dueDateEnabled: Bool
    @State private var title = ""
    @State private var dueDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    @State private var repeatInterval: RepeatInterval? = nil
    @State private var repeatCount: Int = 1
    @State private var repeatWeekdays: [Int] = []
    @State private var showNotificationDeniedAlert = false
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
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
                        if !enabled { repeatInterval = nil; repeatWeekdays = [] }
                        guard enabled else { return }
                        Task {
                            let status = await NotificationManager.shared.authorizationStatus()
                            if status == .denied {
                                dueDateEnabled = false
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
                    }

                    if repeatInterval == .weekly {
                        weekdaySelector
                    } else if let interval = repeatInterval {
                        Stepper(
                            "Every \(repeatCount) \(interval.unitLabel(count: repeatCount))",
                            value: $repeatCount,
                            in: 1...99
                        )
                        .padding(.horizontal, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
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
                        repeatWeekdays: (dueDateEnabled && repeatInterval == .weekly) ? repeatWeekdays : []
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

                Spacer()
            }
            .padding()
            .navigationTitle("New Todo")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { isFocused = true }
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
}
