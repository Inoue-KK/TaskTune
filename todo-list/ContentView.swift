//
//  ContentView.swift
//  todo-list
//
//  Created by 井上京佳 on 2026/03/26.
//

import SwiftUI
import SwiftData
import CoreHaptics

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("hapticEnabled") private var hapticEnabled = true
    @AppStorage("selectedSound") private var selectedSoundRaw = CompletionSound.glint.rawValue
    @AppStorage("accentColor") private var accentColorHex = "#007AFF"
    @State private var showingAddSheet = false
    @State private var showingRenameSheet = false
    @State private var showingReminderSheet = false
    @State private var editingTodo: Todo?
    @State private var hapticEngine: CHHapticEngine?
    @State private var addButtonPressed = false
    let todoList: TodoList

    private var sortedTodos: [Todo] {
        todoList.todos.sorted { $0.sortOrder < $1.sortOrder }
    }
    private var pendingTodos: [Todo] { sortedTodos.filter { !$0.isCompleted } }
    private var completedTodos: [Todo] { sortedTodos.filter { $0.isCompleted } }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if sortedTodos.isEmpty {
                    emptyState
                } else {
                    todoListView
                }
            }

            addButton
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button {
                    showingRenameSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Text(todoList.title)
                            .font(.headline)
                        Image(systemName: "square.and.pencil")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(.primary)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingReminderSheet = true
                } label: {
                    Image(systemName: todoList.reminderEnabled ? "bell.fill" : "bell")
                        .foregroundStyle(todoList.reminderEnabled ? (Color(hex: accentColorHex) ?? .blue) : .secondary)
                }
            }
        }
        .sheet(isPresented: $showingRenameSheet) {
            RenameListView(todoList: todoList)
                .presentationDetents([.height(280)])
                .presentationCornerRadius(20)
        }
        .sheet(isPresented: $showingReminderSheet) {
            ListReminderView(todoList: todoList)
                .presentationBackground(.background)
                .presentationCornerRadius(20)
        }
        .sheet(isPresented: $showingAddSheet) {
            AddTodoView(todoList: todoList)
                .presentationBackground(.background)
                .presentationCornerRadius(20)
        }
        .sheet(item: $editingTodo) { todo in
            EditTodoView(todo: todo)
                .presentationBackground(.background)
                .presentationCornerRadius(20)
        }
        .onAppear { prepareHapticEngine() }
    }

    // MARK: - Todo List

    private var todoListView: some View {
        List {
            if !pendingTodos.isEmpty {
                Section {
                    ForEach(pendingTodos) { todo in
                        todoRow(todo)
                    }
                    .onDelete { indexSet in
                        deleteTodos(from: pendingTodos, at: indexSet)
                    }
                    .onMove { source, destination in
                        movePendingTodos(from: source, to: destination)
                    }
                } header: {
                    sectionHeader("Pending", count: pendingTodos.count)
                }
            }

            if !completedTodos.isEmpty {
                Section {
                    ForEach(completedTodos) { todo in
                        todoRow(todo)
                    }
                    .onDelete { indexSet in
                        deleteTodos(from: completedTodos, at: indexSet)
                    }
                    .onMove { source, destination in
                        moveCompletedTodos(from: source, to: destination)
                    }
                } header: {
                    sectionHeader("Completed", count: completedTodos.count)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func todoRow(_ todo: Todo) -> some View {
        HStack(spacing: 14) {
            TodoCheckboxButton(todo: todo) {
                if hapticEnabled { playHaptic() }
            } onRelease: {
                let completing = !todo.isCompleted
                withAnimation(.spring(duration: 0.3)) {
                    todo.isCompleted.toggle()
                }
                if completing {
                    if todo.repeatInterval != nil {
                        todo.missedCount = 0
                    }
                    if soundEnabled {
                        playSound(CompletionSound(rawValue: selectedSoundRaw) ?? .bubble)
                    }
                    if hapticEnabled { playHaptic() }
                }
                // 繰り返しTodoは現サイクルだけ抑止し、未来サイクルは維持される
                Task {
                    await NotificationManager.shared.schedule(for: todo)
                    await NotificationManager.shared.scheduleListReminder(for: todoList)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(todo.title)
                    .font(.body)
                    .foregroundStyle(todo.isCompleted ? Color(.systemGray2) : .primary)
                    .strikethrough(todo.isCompleted, color: Color(.systemGray2))
                    .animation(.easeInOut(duration: 0.2), value: todo.isCompleted)

                if let dueDate = todo.dueDate, !todo.isCompleted {
                    Text(dueDateLabel(dueDate))
                        .font(.caption)
                        .foregroundStyle(dueDateColor(dueDate))
                }

                if todo.repeatInterval != nil, !todo.isCompleted {
                    HStack(spacing: 4) {
                        Image(systemName: "repeat")
                        Text(todo.repeatDescription)
                        if todo.missedCount > 0 {
                            Text("· Missed ×\(todo.missedCount)")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(todo.missedCount > 0 ? Color.red : Color.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture { editingTodo = todo }
        }
        .padding(.vertical, 2)
    }

    private static let overdueDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df
    }()

    private static let todayTimeFormatter: DateFormatter = {
        let tf = DateFormatter()
        tf.dateStyle = .none
        tf.timeStyle = .short
        return tf
    }()

    private static let futureDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()

    private func dueDateLabel(_ date: Date) -> String {
        if date < Date() {
            return String(format: NSLocalizedString("Overdue · %@", comment: ""), Self.overdueDateFormatter.string(from: date))
        } else if Calendar.current.isDateInToday(date) {
            return String(format: NSLocalizedString("Today at %@", comment: ""), Self.todayTimeFormatter.string(from: date))
        } else {
            return Self.futureDateFormatter.string(from: date)
        }
    }

    private func dueDateColor(_ date: Date) -> Color {
        if date < Date() { return .red }
        if Calendar.current.isDateInToday(date) { return .orange }
        return .secondary
    }

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(count)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 64))
                .foregroundStyle(Color(.systemGray3))
            Text("No todos yet")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            Text("Tap the + button to add one")
                .font(.subheadline)
                .foregroundStyle(Color(.systemGray3))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Add Button

    private var addButton: some View {
        Image(systemName: "plus")
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundStyle((Color(hex: accentColorHex) ?? .blue).isLight ? Color(white: 0.3) : Color.white)
            .frame(width: 56, height: 56)
            .contentShape(Circle())
            .glassEffect(.regular.tint(Color(hex: accentColorHex) ?? .blue), in: Circle())
            .scaleEffect(addButtonPressed ? 1.15 : 1.0)
            .animation(.spring(duration: 0.2, bounce: 0.6), value: addButtonPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !addButtonPressed else { return }
                        addButtonPressed = true
                    }
                    .onEnded { _ in
                        addButtonPressed = false
                        showingAddSheet = true
                    }
            )
            .padding(24)
    }

    // MARK: - Haptics

    private func prepareHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        hapticEngine = try? CHHapticEngine()
        try? hapticEngine?.start()
    }

    private func playHaptic() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        guard let pattern = try? CHHapticPattern(events: [event], parameters: []),
              let player = try? hapticEngine?.makePlayer(with: pattern) else { return }
        try? hapticEngine?.start()
        try? player.start(atTime: CHHapticTimeImmediate)
    }

    // MARK: - Helpers

    private func deleteTodos(from section: [Todo], at indexSet: IndexSet) {
        for index in indexSet {
            let todo = section[index]
            NotificationManager.shared.cancel(for: todo)
            context.delete(todo)
        }
        Task { await NotificationManager.shared.scheduleListReminder(for: todoList) }
    }

    private func movePendingTodos(from source: IndexSet, to destination: Int) {
        var items = pendingTodos
        items.move(fromOffsets: source, toOffset: destination)
        for (index, todo) in (items + completedTodos).enumerated() {
            todo.sortOrder = index
        }
    }

    private func moveCompletedTodos(from source: IndexSet, to destination: Int) {
        var items = completedTodos
        items.move(fromOffsets: source, toOffset: destination)
        for (index, todo) in (pendingTodos + items).enumerated() {
            todo.sortOrder = index
        }
    }
}

private struct TodoCheckboxButton: View {
    let todo: Todo
    var onPress: () -> Void
    var onRelease: () -> Void

    @State private var pressing = false
    @AppStorage("accentColor") private var accentColorHex = "#007AFF"

    var body: some View {
        Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
            .font(.title3)
            .symbolRenderingMode(.palette)
            .foregroundStyle(
                todo.isCompleted ? ((Color(hex: accentColorHex) ?? .blue).isLight ? Color(white: 0.3) : Color.white) : Color(.systemGray3),
                todo.isCompleted ? (Color(hex: accentColorHex) ?? .blue) : Color(.systemGray3)
            )
            .contentTransition(.symbolEffect(.replace))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !pressing else { return }
                        pressing = true
                        onPress()
                    }
                    .onEnded { _ in
                        pressing = false
                        onRelease()
                    }
            )
    }
}
