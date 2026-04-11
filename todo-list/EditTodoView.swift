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
    @State private var showNotificationDeniedAlert = false
    @State private var selectedDetent: PresentationDetent = .height(340)
    @FocusState private var isFocused: Bool

    init(todo: Todo) {
        self.todo = todo
        _title = State(initialValue: todo.title)
        _dueDateEnabled = State(initialValue: todo.dueDate != nil)
        _dueDate = State(initialValue: todo.dueDate ?? Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date())
        _repeatInterval = State(initialValue: todo.repeatInterval)
        _selectedDetent = State(initialValue: todo.dueDate != nil ? .height(440) : .height(340))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Title", text: $title)
                    .font(.body)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .focused($isFocused)

                Toggle("Due Date", isOn: $dueDateEnabled.animation())
                    .font(.body)
                    .padding(.horizontal, 4)
                    .onChange(of: dueDateEnabled) { _, enabled in
                        if !enabled { repeatInterval = nil }
                        selectedDetent = enabled ? .height(440) : .height(340)
                        guard enabled else { return }
                        Task {
                            let status = await NotificationManager.shared.authorizationStatus()
                            if status == .denied {
                                dueDateEnabled = false
                                selectedDetent = .height(340)
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
                }

                let trimmed = title.trimmingCharacters(in: .whitespaces)

                Button {
                    guard !trimmed.isEmpty else { return }
                    todo.title = trimmed
                    todo.dueDate = dueDateEnabled ? dueDate : nil
                    todo.repeatInterval = dueDateEnabled ? repeatInterval : nil
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
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(trimmed.isEmpty ? Color(.systemGray3) : .blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(trimmed.isEmpty)

                Button("Cancel") { dismiss() }
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding()
            .navigationTitle("Edit Todo")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { isFocused = true }
            .presentationDetents([.height(340), .height(440)], selection: $selectedDetent)
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
}
