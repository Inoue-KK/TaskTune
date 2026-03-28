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
    @State private var path = NavigationPath()
    @State private var showingAddSheet = false
    @State private var renamingList: TodoList?
    @State private var showingWidgetThemeSheet = false

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if lists.isEmpty {
                        emptyState
                    } else {
                        listOfLists
                    }
                }

                addButton
            }
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Lists")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                    Button {
                        showingWidgetThemeSheet = true
                    } label: {
                        Image(systemName: "square.grid.2x2")
                            .font(.title3)
                            .foregroundStyle(.primary)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 4)
                .background(.clear)
            }
        }
        .onAppear { lists = savedLists }
        .onChange(of: savedLists) { _, newValue in lists = newValue }
        .onOpenURL { url in
            guard url.scheme == "todolist",
                  url.host == "list",
                  let encoded = url.pathComponents.last,
                  let title = encoded.removingPercentEncoding,
                  let list = lists.first(where: { $0.title == title })
            else { return }
            path.removeLast(path.count)
            path.append(list)
        }
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
        .sheet(isPresented: $showingWidgetThemeSheet) {
            WidgetThemeListView()
        }
    }

    // MARK: - List of Lists

    private var listOfLists: some View {
        List {
            ForEach(lists) { list in
                NavigationLink(value: list) {
                    rowContent(for: list)
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
        .navigationDestination(for: TodoList.self) { list in
            ContentView(todoList: list)
        }
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
        .frame(maxWidth: .infinity)
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
