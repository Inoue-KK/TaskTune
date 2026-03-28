//
//  TodoListWidget.swift
//  TodoListWidget
//
//  Created by 井上京佳 on 2026/03/28.
//

import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

// MARK: - App Group

private let appGroupID = "group.com.inoue-kk.todo-list"

private var sharedStoreURL: URL {
    FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)!
        .appendingPathComponent("todo-list.store")
}

// MARK: - Complete Todo Intent

struct CompleteTodoIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Todo"

    @Parameter(title: "List Title")
    var listTitle: String

    @Parameter(title: "Todo Title")
    var todoTitle: String

    init() {}

    init(listTitle: String, todoTitle: String) {
        self.listTitle = listTitle
        self.todoTitle = todoTitle
    }

    func perform() async throws -> some IntentResult {
        let config = ModelConfiguration(url: sharedStoreURL)
        let container = try ModelContainer(for: TodoList.self, configurations: config)
        let context = ModelContext(container)
        let lists = try context.fetch(FetchDescriptor<TodoList>())
        if let list = lists.first(where: { $0.title == listTitle }),
           let todo = list.todos.first(where: { $0.title == todoTitle && !$0.isCompleted }) {
            todo.isCompleted = true
            try context.save()
        }
        return .result()
    }
}

// MARK: - List Selection Intent

struct ListNamesProvider: DynamicOptionsProvider {
    func results() async throws -> [String] {
        let config = ModelConfiguration(url: sharedStoreURL)
        let container = try ModelContainer(for: TodoList.self, configurations: config)
        let context = ModelContext(container)
        let lists = try context.fetch(FetchDescriptor<TodoList>(sortBy: [SortDescriptor(\.sortOrder)]))
        return lists.map(\.title)
    }
}

struct SelectListIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "リストを選択"
    static var description = IntentDescription("表示するリストを選択してください")

    @Parameter(title: "リスト", optionsProvider: ListNamesProvider())
    var listTitle: String?
}

// MARK: - Entry

struct TodoWidgetEntry: TimelineEntry {
    let date: Date
    let listTitle: String
    let pendingTodos: [String]
    let totalPending: Int
}

// MARK: - Provider

struct TodoWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> TodoWidgetEntry {
        TodoWidgetEntry(
            date: Date(),
            listTitle: "Shopping",
            pendingTodos: ["Milk", "Eggs", "Bread", "Apples"],
            totalPending: 4
        )
    }

    func snapshot(for configuration: SelectListIntent, in context: Context) async -> TodoWidgetEntry {
        fetchEntry(for: configuration.listTitle)
    }

    func timeline(for configuration: SelectListIntent, in context: Context) async -> Timeline<TodoWidgetEntry> {
        let entry = fetchEntry(for: configuration.listTitle)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func fetchEntry(for selectedTitle: String?) -> TodoWidgetEntry {
        do {
            let config = ModelConfiguration(url: sharedStoreURL)
            let container = try ModelContainer(for: TodoList.self, configurations: config)
            let context = ModelContext(container)
            let lists = try context.fetch(FetchDescriptor<TodoList>(sortBy: [SortDescriptor(\.sortOrder)]))

            let list = lists.first(where: { $0.title == selectedTitle }) ?? lists.first

            if let list {
                let pending = list.todos
                    .filter { !$0.isCompleted }
                    .sorted { $0.sortOrder < $1.sortOrder }
                return TodoWidgetEntry(
                    date: Date(),
                    listTitle: list.title,
                    pendingTodos: pending.prefix(4).map(\.title),
                    totalPending: pending.count
                )
            }
        } catch {}
        return TodoWidgetEntry(date: Date(), listTitle: "Todo", pendingTodos: [], totalPending: 0)
    }
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let entry: TodoWidgetEntry

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: entry.totalPending == 0 ? "checkmark.circle.fill" : "circle.dotted")
                .font(.system(size: 32))
                .foregroundStyle(entry.totalPending == 0 ? .green : .blue)

            Text("\(entry.totalPending)")
                .font(.system(size: 48, weight: .bold))
                .minimumScaleFactor(0.5)

            Text(entry.listTitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(entry.totalPending == 1 ? "task left" : "tasks left")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .containerBackground(for: .widget) { Color(.systemBackground) }
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: TodoWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(entry.listTitle)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text("\(entry.totalPending) left")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 8)

            Divider()
                .padding(.bottom, 8)

            if entry.pendingTodos.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("All done!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                ForEach(Array(entry.pendingTodos.enumerated()), id: \.offset) { _, title in
                    Button(intent: CompleteTodoIntent(listTitle: entry.listTitle, todoTitle: title)) {
                        HStack(spacing: 8) {
                            Image(systemName: "circle")
                                .font(.caption)
                                .foregroundStyle(.blue)
                            Text(title)
                                .font(.subheadline)
                                .lineLimit(1)
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)
                }

                if entry.totalPending > entry.pendingTodos.count {
                    Text("+ \(entry.totalPending - entry.pendingTodos.count) more")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 2)
                }
                Spacer()
            }
        }
        .padding()
        .containerBackground(for: .widget) { Color(.systemBackground) }
    }
}

// MARK: - Entry View

struct TodoWidgetEntryView: View {
    var entry: TodoWidgetEntry
    @Environment(\.widgetFamily) var family

    private var widgetURL: URL {
        let encoded = entry.listTitle.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        return URL(string: "todolist://list/\(encoded)")!
    }

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
                .widgetURL(widgetURL)
        default:
            MediumWidgetView(entry: entry)
                .widgetURL(widgetURL)
        }
    }
}

// MARK: - Widget

struct TodoListWidget: Widget {
    let kind = "TodoListWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectListIntent.self, provider: TodoWidgetProvider()) { entry in
            TodoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Todo List")
        .description("表示するリストを選択できます。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
