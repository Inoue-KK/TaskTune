//
//  todo_listApp.swift
//  todo-list
//
//  Created by 井上京佳 on 2026/03/26.
//

import SwiftUI
import SwiftData
import WidgetKit

// ⚠️ Replace with the same App Group ID used in the widget target
// e.g. "group.com.yourname.todo-list"
private let appGroupID = "group.com.inoue-kk.todo-list"

// Bump this when the SwiftData schema changes to force store recreation on old devices
private let schemaVersion = 3
private let schemaVersionKey = "swiftDataSchemaVersion"

@MainActor
private func advanceOverdueRepeatingTodos(in container: ModelContainer) async {
    let context = container.mainContext
    let now = Date()
    let descriptor = FetchDescriptor<Todo>()
    guard let allTodos = try? context.fetch(descriptor) else { return }
    let todos = allTodos.filter { $0.repeatInterval != nil && $0.dueDate != nil }

    var didAdvance = false
    for todo in todos {
        guard let dueDate = todo.dueDate else { continue }

        if dueDate < now {
            // dueDate を未来へ進める。途中の missed サイクルをカウント
            var newDate = dueDate
            var cycles = 0
            while newDate <= now {
                guard let next = nextCycleDate(after: newDate, for: todo) else { break }
                newDate = next
                cycles += 1
            }
            guard cycles > 0 else {
                // 例えば endCondition で計算不能 → スケジュールだけ更新して継続
                await NotificationManager.shared.schedule(for: todo)
                continue
            }

            todo.repeatOccurrenceCount += cycles

            if reachedEndCondition(todo: todo, nextDate: newDate) {
                stopRepeating(todo: todo)
            } else {
                if todo.isCompleted {
                    todo.isCompleted = false
                    todo.missedCount = 0
                } else {
                    todo.missedCount += cycles
                }
                todo.dueDate = newDate
                await NotificationManager.shared.schedule(for: todo)
            }
            didAdvance = true
        } else {
            // dueDate がまだ未来でも、起動の度に未来サイクル分の通知を補充する
            // （pre-scheduled 通知が次々と発火して pending が減るため）
            await NotificationManager.shared.schedule(for: todo)
        }
    }

    if didAdvance {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

private func reachedEndCondition(todo: Todo, nextDate: Date) -> Bool {
    guard let endCond = todo.repeatEndCondition else { return false }
    switch endCond {
    case .afterCount:
        return todo.repeatOccurrenceCount >= todo.repeatEndCount
    case .onDate:
        guard let endDate = todo.repeatEndDate else { return false }
        return nextDate > endDate
    }
}

private func stopRepeating(todo: Todo) {
    todo.repeatInterval = nil
    todo.repeatWeekdays = []
    todo.repeatEndCondition = nil
    todo.repeatEndDate = nil
    todo.isCompleted = false
    todo.missedCount = 0
    NotificationManager.shared.cancel(for: todo)
}

@main
struct todo_listApp: App {
    let container: ModelContainer = {
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            fatalError("App Group '\(appGroupID)' is not configured. Check Signing & Capabilities.")
        }
        let storeURL = groupURL.appendingPathComponent("todo-list.store")

        func deleteStore() {
            for suffix in ["", "-shm", "-wal"] {
                let url = groupURL.appendingPathComponent("todo-list.store\(suffix)")
                try? FileManager.default.removeItem(at: url)
            }
        }

        // スキーマバージョンが古い場合はストアを削除して再作成
        let defaults = UserDefaults(suiteName: appGroupID)
        let savedVersion = defaults?.integer(forKey: schemaVersionKey) ?? 0
        if savedVersion < schemaVersion {
            print("Schema version changed (\(savedVersion) → \(schemaVersion)), recreating store.")
            deleteStore()
            defaults?.set(schemaVersion, forKey: schemaVersionKey)
        }

        let config = ModelConfiguration(url: storeURL)
        do {
            return try ModelContainer(for: TodoList.self, configurations: config)
        } catch {
            print("ModelContainer migration failed, recreating store: \(error)")
            deleteStore()
            do {
                return try ModelContainer(for: TodoList.self, configurations: config)
            } catch {
                fatalError("Failed to create ModelContainer even after reset: \(error)")
            }
        }
    }()

    @Environment(\.scenePhase) private var scenePhase

    init() {
        NotificationManager.shared.modelContainer = container
    }

    var body: some Scene {
        WindowGroup {
            ListsView()
                .task {
                    await NotificationManager.shared.requestPermission()
                }
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                WidgetCenter.shared.reloadAllTimelines()
            }
            if newPhase == .active {
                Task {
                    await advanceOverdueRepeatingTodos(in: container)
                    let lists = (try? container.mainContext.fetch(FetchDescriptor<TodoList>())) ?? []
                    await NotificationManager.shared.rescheduleAllListReminders(lists: lists)
                }
            }
        }
    }
}
