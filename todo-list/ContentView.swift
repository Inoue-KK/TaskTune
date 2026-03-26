//
//  ContentView.swift
//  todo-list
//
//  Created by 井上京佳 on 2026/03/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Todo.createdAt, order: .reverse) private var todos: [Todo]
    @State private var showingAddSheet = false

    private var pendingTodos: [Todo] { todos.filter { !$0.isCompleted } }
    private var completedTodos: [Todo] { todos.filter { $0.isCompleted } }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if todos.isEmpty {
                        emptyState
                    } else {
                        todoList
                    }
                }

                addButton
            }
            .navigationTitle("Todo")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingAddSheet) {
            AddTodoView()
                .presentationDetents([.height(200)])
                .presentationCornerRadius(20)
        }
    }

    // MARK: - Todo List

    private var todoList: some View {
        List {
            if !pendingTodos.isEmpty {
                Section {
                    ForEach(pendingTodos) { todo in
                        todoRow(todo)
                    }
                    .onDelete { indexSet in
                        deleteTodos(from: pendingTodos, at: indexSet)
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
                } header: {
                    sectionHeader("Completed", count: completedTodos.count)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func todoRow(_ todo: Todo) -> some View {
        HStack(spacing: 14) {
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    todo.isCompleted.toggle()
                }
            } label: {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(todo.isCompleted ? .green : Color(.systemGray3))
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)

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

    // MARK: - Helpers

    private func deleteTodos(from section: [Todo], at indexSet: IndexSet) {
        for index in indexSet {
            context.delete(section[index])
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Todo.self, inMemory: true)
}
