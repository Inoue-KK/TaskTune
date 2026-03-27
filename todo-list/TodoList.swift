//
//  TodoList.swift
//  todo-list
//
//  Created by 井上京佳 on 2026/03/26.
//

import Foundation
import SwiftData

@Model
class TodoList {
    var title: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var todos: [Todo] = []

    init(title: String) {
        self.title = title
        self.createdAt = Date()
    }
}
