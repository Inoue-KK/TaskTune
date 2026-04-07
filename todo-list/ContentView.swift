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
    @AppStorage("selectedSound") private var selectedSoundRaw = CompletionSound.bubble.rawValue
    @State private var showingAddSheet = false
    @State private var showingRenameSheet = false
    @State private var hapticEngine: CHHapticEngine?
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
        }
        .sheet(isPresented: $showingRenameSheet) {
            RenameListView(todoList: todoList)
                .presentationDetents([.height(280)])
                .presentationCornerRadius(20)
        }
        .sheet(isPresented: $showingAddSheet) {
            AddTodoView(todoList: todoList)
                .presentationDetents([.height(280)])
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
                    if soundEnabled {
                        playSound(CompletionSound(rawValue: selectedSoundRaw) ?? .bubble)
                    }
                    if hapticEnabled { playHaptic() }
                }
            }

            Text(todo.title)
                .font(.body)
                .foregroundStyle(todo.isCompleted ? Color(.systemGray2) : .primary)
                .strikethrough(todo.isCompleted, color: Color(.systemGray2))
                .animation(.easeInOut(duration: 0.2), value: todo.isCompleted)
        }
        .padding(.vertical, 2)
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
        Button {
            showingAddSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(.blue)
                .clipShape(Circle())
                .shadow(color: .blue.opacity(0.35), radius: 8, y: 4)
        }
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
            context.delete(section[index])
        }
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

    var body: some View {
        Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
            .font(.title3)
            .foregroundStyle(todo.isCompleted ? .green : Color(.systemGray3))
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
