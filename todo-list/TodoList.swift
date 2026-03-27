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
    var sortOrder: Int
    @Relationship(deleteRule: .cascade) var todos: [Todo] = []

    init(title: String, sortOrder: Int = 0) {
        self.title = title
        self.createdAt = Date()
        self.sortOrder = sortOrder
    }
}
