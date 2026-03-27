//
//  RenameListView.swift
//  todo-list
//
//  Created by 井上京佳 on 2026/03/26.
//

import SwiftUI

struct RenameListView: View {
    @Environment(\.dismiss) private var dismiss
    let todoList: TodoList
    @State private var title: String
    @FocusState private var isFocused: Bool

    init(todoList: TodoList) {
        self.todoList = todoList
        self._title = State(initialValue: todoList.title)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("List name", text: $title)
                    .font(.body)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .focused($isFocused)

                let trimmed = title.trimmingCharacters(in: .whitespaces)

                Button {
                    if !trimmed.isEmpty { todoList.title = trimmed }
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
            .navigationTitle("Rename List")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { isFocused = true }
        }
    }
}
