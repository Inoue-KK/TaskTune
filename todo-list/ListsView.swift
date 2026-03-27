//
//  ListsView.swift
//  todo-list
//
//  Created by 井上京佳 on 2026/03/26.
//

import SwiftUI
import SwiftData

struct ListsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TodoList.sortOrder) private var savedLists: [TodoList]
    @State private var lists: [TodoList] = []
    @State private var editMode: EditMode = .inactive
    @State private var showingAddSheet = false
    @State private var renamingList: TodoList?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if lists.isEmpty {
                        emptyState
                    } else {
                        listOfLists
                    }
                }

                if !editMode.isEditing {
                    addButton
                }
            }
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
            .environment(\.editMode, $editMode)
            .safeAreaInset(edge: .top) {
                HStack {
                    Text("Lists")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                    Spacer()
                    if !lists.isEmpty {
                        Button(editMode.isEditing ? "Done" : "Edit") {
                            editMode = editMode.isEditing ? .inactive : .active
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                    }
                }
                .background(.clear)
            }
        }
        .onAppear { lists = savedLists }
        .onChange(of: savedLists) { _, newValue in lists = newValue }
        .sheet(item: $renamingList) { list in
            RenameListView(todoList: list)
                .presentationDetents([.height(280)])
                .presentationCornerRadius(20)
        }
        .sheet(isPresented: $showingAddSheet) {
            AddListView(nextSortOrder: lists.count)
                .presentationDetents([.height(280)])
                .presentationCornerRadius(20)
        }
    }

    // MARK: - List of Lists

    private var listOfLists: some View {
        List {
            ForEach(lists) { list in
                Group {
                    if editMode.isEditing {
                        rowContent(for: list)
                    } else {
                        NavigationLink(destination: ContentView(todoList: list)) {
                            rowContent(for: list)
                        }
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        context.delete(list)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading) {
                    Button {
                        renamingList = list
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    .tint(.orange)
                }
            }
            .onMove { source, destination in
                lists.move(fromOffsets: source, toOffset: destination)
                for (index, list) in lists.enumerated() {
                    list.sortOrder = index
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Row Content

    private func rowContent(for list: TodoList) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(list.title)
                    .font(.body)
                Text("\(list.todos.count) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 64))
                .foregroundStyle(Color(.systemGray3))
            Text("No lists yet")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            Text("Tap the + button to create one")
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
}

#Preview {
    ListsView()
        .modelContainer(for: TodoList.self, inMemory: true)
}
