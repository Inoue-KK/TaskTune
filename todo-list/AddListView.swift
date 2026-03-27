//
//  AddListView.swift
//  todo-list
//
//  Created by 井上京佳 on 2026/03/26.
//

import SwiftUI
import SwiftData

struct AddListView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let nextSortOrder: Int
    @State private var title = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("e.g. Shopping", text: $title)
                    .font(.body)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .focused($isFocused)

                let trimmed = title.trimmingCharacters(in: .whitespaces)

                Button {
                    guard !trimmed.isEmpty else { return }
                    context.insert(TodoList(title: trimmed, sortOrder: nextSortOrder))
                    dismiss()
                } label: {
                    Text("Add")
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
            .navigationTitle("New List")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { isFocused = true }
        }
    }
}
