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

    var reminderEnabled: Bool = false
    var reminderTime: Date? = nil
    var reminderRepeatInterval: RepeatInterval? = nil
    var reminderRepeatIntervalCount: Int = 1
    /// Weekly 時の曜日指定（Calendar weekday 番号 1=日〜7=土）
    var reminderWeekdays: [Int] = []
    var reminderRepeatEndCondition: RepeatEndCondition? = nil
    var reminderRepeatEndCount: Int = 3
    var reminderRepeatEndDate: Date? = nil
    var reminderOccurrenceCount: Int = 0
    var reminderLastScheduledCount: Int = 0

    init(title: String, sortOrder: Int = 0) {
        self.title = title
        self.createdAt = Date()
        self.sortOrder = sortOrder
    }
}
