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

// MARK: - List Names Provider

struct ListNamesProvider: DynamicOptionsProvider {
    func results() async throws -> [String] {
        let config = ModelConfiguration(url: sharedStoreURL)
        let container = try ModelContainer(for: TodoList.self, configurations: config)
        let context = ModelContext(container)
        let lists = try context.fetch(FetchDescriptor<TodoList>(sortBy: [SortDescriptor(\.sortOrder)]))
        return lists.map(\.title)
    }
}

// MARK: - Theme Names Provider

struct ThemeNamesProvider: DynamicOptionsProvider {
    func results() async throws -> [String] {
        WidgetThemeStore.loadAll().map(\.name)
    }
}

// MARK: - Widget Configuration Intent

struct SelectListIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "ウィジェット設定"
    static var description = IntentDescription("リストとテーマを選択してください")

    @Parameter(title: "リスト", optionsProvider: ListNamesProvider())
    var listTitle: String?

    @Parameter(title: "テーマ", optionsProvider: ThemeNamesProvider())
    var themeName: String?
}

// MARK: - Entry

struct TodoWidgetEntry: TimelineEntry {
    let date: Date
    let listTitle: String
    let pendingTodos: [String]
    let completedTodos: [String]
    let theme: WidgetTheme

    var totalPending: Int { pendingTodos.count }
    var totalCompleted: Int { completedTodos.count }
}

// MARK: - Provider

struct TodoWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> TodoWidgetEntry {
        TodoWidgetEntry(
            date: Date(),
            listTitle: "Shopping",
            pendingTodos: ["Milk", "Eggs", "Bread", "Apples", "Butter", "Cheese"],
            completedTodos: ["Juice"],
            theme: .default
        )
    }

    func snapshot(for configuration: SelectListIntent, in context: Context) async -> TodoWidgetEntry {
        fetchEntry(for: configuration)
    }

    func timeline(for configuration: SelectListIntent, in context: Context) async -> Timeline<TodoWidgetEntry> {
        let entry = fetchEntry(for: configuration)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func fetchEntry(for configuration: SelectListIntent) -> TodoWidgetEntry {
        let theme = WidgetThemeStore.find(name: configuration.themeName)
        do {
            let config = ModelConfiguration(url: sharedStoreURL)
            let container = try ModelContainer(for: TodoList.self, configurations: config)
            let context = ModelContext(container)
            let lists = try context.fetch(FetchDescriptor<TodoList>(sortBy: [SortDescriptor(\.sortOrder)]))
            let list = lists.first(where: { $0.title == configuration.listTitle }) ?? lists.first
            if let list {
                let sorted = list.todos.sorted { $0.sortOrder < $1.sortOrder }
                return TodoWidgetEntry(
                    date: Date(),
                    listTitle: list.title,
                    pendingTodos: sorted.filter { !$0.isCompleted }.map(\.title),
                    completedTodos: sorted.filter { $0.isCompleted }.map(\.title),
                    theme: theme
                )
            }
        } catch {}
        return TodoWidgetEntry(
            date: Date(),
            listTitle: "Todo",
            pendingTodos: [],
            completedTodos: [],
            theme: theme
        )
    }
}

// MARK: - Todo Row View

struct TodoRowView: View {
    let title: String
    let listTitle: String
    let isCompleted: Bool
    let theme: WidgetTheme

    var body: some View {
        if isCompleted {
            rowContent
        } else {
            Button(intent: CompleteTodoIntent(listTitle: listTitle, todoTitle: title)) {
                rowContent
            }
            .buttonStyle(.plain)
        }
    }

    private var checkbox: some View {
        Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
            .font(theme.fontSize.iconFont)
            .foregroundStyle(isCompleted ? theme.secondaryTextColor : theme.accentColor)
    }

    private var rowContent: some View {
        HStack(spacing: 8) {
            if theme.checkboxPosition == .leading { checkbox }
            Text(title)
                .font(theme.fontSize.itemFont)
                .lineLimit(1)
                .foregroundStyle(isCompleted ? theme.secondaryTextColor : theme.textColor)
                .strikethrough(isCompleted)
            Spacer()
            if theme.checkboxPosition == .trailing { checkbox }
        }
        .padding(.vertical, theme.rowHeight.verticalPadding)
    }
}

// MARK: - Widget Header View

struct WidgetHeaderView: View {
    let entry: TodoWidgetEntry

    var body: some View {
        HStack {
            Text(entry.listTitle)
                .font(entry.theme.fontSize.headerFont)
                .foregroundStyle(entry.theme.textColor)
                .lineLimit(1)
            Spacer()
            HStack(spacing: 6) {
                if entry.theme.showRemainingCount {
                    Text("\(entry.totalPending) left")
                        .font(.caption)
                        .foregroundStyle(entry.theme.secondaryTextColor)
                }
                if entry.theme.showCompletedCount {
                    Text("\(entry.totalCompleted) done")
                        .font(.caption)
                        .foregroundStyle(entry.theme.tertiaryTextColor)
                }
            }
        }
        .padding(.bottom, 1)
    }
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let entry: TodoWidgetEntry

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: entry.totalPending == 0 ? "checkmark.circle.fill" : "circle.dotted")
                .font(.system(size: 32))
                .foregroundStyle(entry.totalPending == 0 ? Color.green : entry.theme.accentColor)

            Text("\(entry.totalPending)")
                .font(.system(size: 48, weight: .bold))
                .minimumScaleFactor(0.5)
                .foregroundStyle(entry.theme.textColor)

            Text(entry.listTitle)
                .font(.caption)
                .foregroundStyle(entry.theme.secondaryTextColor)
                .lineLimit(1)

            Text(entry.totalPending == 1 ? "task left" : "tasks left")
                .font(.caption2)
                .foregroundStyle(entry.theme.tertiaryTextColor)
        }
        .containerBackground(for: .widget) {
            entry.theme.backgroundColor
        }
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: TodoWidgetEntry

    // Medium widget content area: ~158pt height, minus 24pt vertical padding, ~18pt header, 3pt divider ≈ 114pt for items
    private var maxItemCount: Int {
        max(1, Int(114 / entry.theme.estimatedRowHeight))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WidgetHeaderView(entry: entry)
            Divider().padding(.bottom, 1)
            pendingList
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .containerBackground(for: .widget) {
            entry.theme.backgroundColor
        }
    }

    @ViewBuilder
    private var pendingList: some View {
        let toShow = Array(entry.pendingTodos.prefix(maxItemCount))
        let remaining = entry.totalPending - toShow.count

        VStack(alignment: .leading, spacing: 0) {
            if entry.pendingTodos.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("All done!").font(.subheadline).foregroundStyle(entry.theme.secondaryTextColor)
                }
            } else {
                ForEach(Array(toShow.enumerated()), id: \.offset) { _, title in
                    TodoRowView(title: title, listTitle: entry.listTitle, isCompleted: false, theme: entry.theme)
                }
                if remaining > 0 {
                    Text("+ \(remaining) more")
                        .font(.caption)
                        .foregroundStyle(entry.theme.tertiaryTextColor)
                        .padding(.top, 2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Large Widget View

struct LargeWidgetView: View {
    let entry: TodoWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WidgetHeaderView(entry: entry)
            Divider().padding(.bottom, 8)
            GeometryReader { proxy in
                todoList(availableHeight: proxy.size.height)
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            entry.theme.backgroundColor
        }
    }

    @ViewBuilder
    private func todoList(availableHeight: CGFloat) -> some View {
        let showCompletedSection = entry.theme.showCompleted && !entry.completedTodos.isEmpty
        let rowH = entry.theme.estimatedRowHeight
        let pendingHeight = showCompletedSection ? availableHeight * 0.6 : availableHeight
        let completedHeight = availableHeight * 0.4
        let pendingCount = max(1, Int(pendingHeight / rowH))
        let completedCount = max(1, Int(completedHeight / rowH))
        let pendingToShow = Array(entry.pendingTodos.prefix(pendingCount))
        let remaining = entry.totalPending - pendingToShow.count

        VStack(alignment: .leading, spacing: 0) {
            if entry.pendingTodos.isEmpty && !showCompletedSection {
                HStack {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("All done!").font(.subheadline).foregroundStyle(entry.theme.secondaryTextColor)
                }
            } else {
                ForEach(Array(pendingToShow.enumerated()), id: \.offset) { _, title in
                    TodoRowView(title: title, listTitle: entry.listTitle, isCompleted: false, theme: entry.theme)
                }
                if remaining > 0 {
                    Text("+ \(remaining) more")
                        .font(.caption)
                        .foregroundStyle(entry.theme.tertiaryTextColor)
                        .padding(.top, 2)
                }
                if showCompletedSection {
                    Divider().padding(.vertical, 8)
                    ForEach(Array(entry.completedTodos.prefix(completedCount).enumerated()), id: \.offset) { _, title in
                        TodoRowView(title: title, listTitle: entry.listTitle, isCompleted: true, theme: entry.theme)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        case .systemLarge:
            LargeWidgetView(entry: entry)
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
        .description("リストとテーマを自由にカスタマイズできます。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
