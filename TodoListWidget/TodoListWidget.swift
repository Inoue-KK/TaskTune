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

// MARK: - AppEnum: Font Size

enum WidgetFontSize: String, AppEnum {
    case small, medium, large

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "文字サイズ"
    static var caseDisplayRepresentations: [WidgetFontSize: DisplayRepresentation] = [
        .small: "小",
        .medium: "中（標準）",
        .large: "大"
    ]

    var itemFont: Font {
        switch self {
        case .small: .caption
        case .medium: .subheadline
        case .large: .body
        }
    }

    var iconFont: Font {
        switch self {
        case .small: .caption2
        case .medium: .caption
        case .large: .subheadline
        }
    }
}

// MARK: - AppEnum: Accent Color

enum WidgetAccentColor: String, AppEnum {
    case blue, red, green, orange, purple, pink

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "アクセントカラー"
    static var caseDisplayRepresentations: [WidgetAccentColor: DisplayRepresentation] = [
        .blue: "ブルー",
        .red: "レッド",
        .green: "グリーン",
        .orange: "オレンジ",
        .purple: "パープル",
        .pink: "ピンク"
    ]

    var color: Color {
        switch self {
        case .blue: .blue
        case .red: .red
        case .green: .green
        case .orange: .orange
        case .purple: .purple
        case .pink: .pink
        }
    }
}

// MARK: - AppEnum: Background

enum WidgetBackground: String, AppEnum {
    case auto, white, black, clear

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "背景"
    static var caseDisplayRepresentations: [WidgetBackground: DisplayRepresentation] = [
        .auto: "自動",
        .white: "ホワイト",
        .black: "ブラック",
        .clear: "透明"
    ]

    var color: Color {
        switch self {
        case .auto: Color(.systemBackground)
        case .white: .white
        case .black: .black
        case .clear: .clear
        }
    }
}

// MARK: - AppEnum: Row Height

enum WidgetRowHeight: String, AppEnum {
    case compact, normal, comfortable

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "行の高さ"
    static var caseDisplayRepresentations: [WidgetRowHeight: DisplayRepresentation] = [
        .compact: "コンパクト",
        .normal: "標準",
        .comfortable: "ゆったり"
    ]

    var verticalPadding: CGFloat {
        switch self {
        case .compact: 2
        case .normal: 6
        case .comfortable: 11
        }
    }
}

// MARK: - AppEnum: Checkbox Position

enum WidgetCheckboxPosition: String, AppEnum {
    case leading, trailing

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "チェックボックス位置"
    static var caseDisplayRepresentations: [WidgetCheckboxPosition: DisplayRepresentation] = [
        .leading: "左",
        .trailing: "右"
    ]
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
    static var title: LocalizedStringResource = "ウィジェット設定"
    static var description = IntentDescription("リストとデザインを設定してください")

    @Parameter(title: "リスト", optionsProvider: ListNamesProvider())
    var listTitle: String?

    @Parameter(title: "文字サイズ", default: .medium)
    var fontSize: WidgetFontSize

    @Parameter(title: "アクセントカラー", default: .blue)
    var accentColor: WidgetAccentColor

    @Parameter(title: "背景", default: .auto)
    var background: WidgetBackground

    @Parameter(title: "残タスク数を表示", default: true)
    var showRemainingCount: Bool

    @Parameter(title: "完了数を表示", default: false)
    var showCompletedCount: Bool

    @Parameter(title: "行の高さ", default: .normal)
    var rowHeight: WidgetRowHeight

    @Parameter(title: "チェックボックス位置", default: .leading)
    var checkboxPosition: WidgetCheckboxPosition

    @Parameter(title: "完了済みも表示（Largeのみ）", default: false)
    var showCompleted: Bool
}

// MARK: - Widget Settings

struct WidgetSettings: Sendable {
    let fontSize: WidgetFontSize
    let accentColor: WidgetAccentColor
    let background: WidgetBackground
    let showRemainingCount: Bool
    let showCompletedCount: Bool
    let rowHeight: WidgetRowHeight
    let checkboxPosition: WidgetCheckboxPosition
    let showCompleted: Bool

    /// フォントサイズと行の高さから1行あたりの推定ピクセル高さを返す
    var estimatedRowHeight: CGFloat {
        let lineHeight: CGFloat
        switch fontSize {
        case .small: lineHeight = 16
        case .medium: lineHeight = 20
        case .large: lineHeight = 22
        }
        return lineHeight + rowHeight.verticalPadding * 2
    }

    static let `default` = WidgetSettings(
        fontSize: .medium,
        accentColor: .blue,
        background: .auto,
        showRemainingCount: true,
        showCompletedCount: false,
        rowHeight: .normal,
        checkboxPosition: .leading,
        showCompleted: false
    )

    init(from intent: SelectListIntent) {
        fontSize = intent.fontSize
        accentColor = intent.accentColor
        background = intent.background
        showRemainingCount = intent.showRemainingCount
        showCompletedCount = intent.showCompletedCount
        rowHeight = intent.rowHeight
        checkboxPosition = intent.checkboxPosition
        showCompleted = intent.showCompleted
    }

    init(
        fontSize: WidgetFontSize,
        accentColor: WidgetAccentColor,
        background: WidgetBackground,
        showRemainingCount: Bool,
        showCompletedCount: Bool,
        rowHeight: WidgetRowHeight,
        checkboxPosition: WidgetCheckboxPosition,
        showCompleted: Bool
    ) {
        self.fontSize = fontSize
        self.accentColor = accentColor
        self.background = background
        self.showRemainingCount = showRemainingCount
        self.showCompletedCount = showCompletedCount
        self.rowHeight = rowHeight
        self.checkboxPosition = checkboxPosition
        self.showCompleted = showCompleted
    }
}

// MARK: - Entry

struct TodoWidgetEntry: TimelineEntry {
    let date: Date
    let listTitle: String
    let pendingTodos: [String]
    let completedTodos: [String]
    let settings: WidgetSettings

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
            settings: .default
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
        let settings = WidgetSettings(from: configuration)
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
                    settings: settings
                )
            }
        } catch {}
        return TodoWidgetEntry(
            date: Date(),
            listTitle: "Todo",
            pendingTodos: [],
            completedTodos: [],
            settings: settings
        )
    }
}

// MARK: - Todo Row View

struct TodoRowView: View {
    let title: String
    let listTitle: String
    let isCompleted: Bool
    let settings: WidgetSettings

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
            .font(settings.fontSize.iconFont)
            .foregroundStyle(isCompleted ? .secondary : settings.accentColor.color)
    }

    private var rowContent: some View {
        HStack(spacing: 8) {
            if settings.checkboxPosition == .leading { checkbox }
            Text(title)
                .font(settings.fontSize.itemFont)
                .lineLimit(1)
                .foregroundStyle(isCompleted ? .secondary : .primary)
                .strikethrough(isCompleted)
            Spacer()
            if settings.checkboxPosition == .trailing { checkbox }
        }
        .padding(.vertical, settings.rowHeight.verticalPadding)
    }
}

// MARK: - Widget Header View

struct WidgetHeaderView: View {
    let entry: TodoWidgetEntry

    var body: some View {
        HStack {
            Text(entry.listTitle)
                .font(.headline)
                .lineLimit(1)
            Spacer()
            HStack(spacing: 6) {
                if entry.settings.showRemainingCount {
                    Text("\(entry.totalPending) left")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if entry.settings.showCompletedCount {
                    Text("\(entry.totalCompleted) done")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let entry: TodoWidgetEntry

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: entry.totalPending == 0 ? "checkmark.circle.fill" : "circle.dotted")
                .font(.system(size: 32))
                .foregroundStyle(entry.totalPending == 0 ? .green : entry.settings.accentColor.color)

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
        .containerBackground(for: .widget) { entry.settings.background.color }
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: TodoWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WidgetHeaderView(entry: entry)
            Divider().padding(.bottom, 8)
            GeometryReader { proxy in
                pendingList(availableHeight: proxy.size.height)
            }
        }
        .padding()
        .containerBackground(for: .widget) { entry.settings.background.color }
    }

    @ViewBuilder
    private func pendingList(availableHeight: CGFloat) -> some View {
        let count = max(1, Int(availableHeight / entry.settings.estimatedRowHeight))
        let toShow = Array(entry.pendingTodos.prefix(count))
        let remaining = entry.totalPending - toShow.count

        VStack(alignment: .leading, spacing: 0) {
            if entry.pendingTodos.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("All done!").font(.subheadline).foregroundStyle(.secondary)
                }
            } else {
                ForEach(Array(toShow.enumerated()), id: \.offset) { _, title in
                    TodoRowView(title: title, listTitle: entry.listTitle, isCompleted: false, settings: entry.settings)
                }
                if remaining > 0 {
                    Text("+ \(remaining) more")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
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
        .containerBackground(for: .widget) { entry.settings.background.color }
    }

    @ViewBuilder
    private func todoList(availableHeight: CGFloat) -> some View {
        let showCompletedSection = entry.settings.showCompleted && !entry.completedTodos.isEmpty
        let rowH = entry.settings.estimatedRowHeight
        // 完了セクションがある場合、上60%を未完了・下40%を完了に割り当てる
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
                    Text("All done!").font(.subheadline).foregroundStyle(.secondary)
                }
            } else {
                ForEach(Array(pendingToShow.enumerated()), id: \.offset) { _, title in
                    TodoRowView(title: title, listTitle: entry.listTitle, isCompleted: false, settings: entry.settings)
                }
                if remaining > 0 {
                    Text("+ \(remaining) more")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 2)
                }
                if showCompletedSection {
                    Divider().padding(.vertical, 8)
                    ForEach(Array(entry.completedTodos.prefix(completedCount).enumerated()), id: \.offset) { _, title in
                        TodoRowView(title: title, listTitle: entry.listTitle, isCompleted: true, settings: entry.settings)
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
        .description("リストとデザインを自由にカスタマイズできます。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
