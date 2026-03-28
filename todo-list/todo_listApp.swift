//
//  todo_listApp.swift
//  todo-list
//
//  Created by 井上京佳 on 2026/03/26.
//

import SwiftUI
import SwiftData
import WidgetKit

// ⚠️ ウィジェットと同じApp GroupのIDに書き換えてください
// 例: "group.com.yourname.todo-list"
private let appGroupID = "group.com.inoue-kk.todo-list"

@main
struct todo_listApp: App {
    let container: ModelContainer = {
        let storeURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)!
            .appendingPathComponent("todo-list.store")
        let config = ModelConfiguration(url: storeURL)
        return try! ModelContainer(for: TodoList.self, configurations: config)
    }()

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ListsView()
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
}
