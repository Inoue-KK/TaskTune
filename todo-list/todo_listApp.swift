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

@main
struct todo_listApp: App {
    let container: ModelContainer = {
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            fatalError("App Group '\(appGroupID)' is not configured. Check Signing & Capabilities.")
        }
        let storeURL = groupURL.appendingPathComponent("todo-list.store")
        let config = ModelConfiguration(url: storeURL)
        do {
            return try ModelContainer(for: TodoList.self, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
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
