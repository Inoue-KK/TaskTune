//
//  todo_listApp.swift
//  todo-list
//
//  Created by 井上京佳 on 2026/03/26.
//

import SwiftUI
import SwiftData

@main
struct todo_listApp: App {
    var body: some Scene {
        WindowGroup {
            ListsView()
        }
        .modelContainer(for: TodoList.self)
    }
}
