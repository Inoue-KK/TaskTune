//
//  Todo.swift
//  todo-list
//
//  Created by 井上京佳 on 2026/03/26.
//

import Foundation
import SwiftData

enum RepeatInterval: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"

    var calendarComponent: Calendar.Component {
        switch self {
        case .daily: return .day
        case .weekly: return .weekOfYear
        case .monthly: return .month
        }
    }
}

@Model
class Todo {
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var sortOrder: Int = 0
    var todoList: TodoList?
    var dueDate: Date?
    var notificationID: String = UUID().uuidString
    var repeatInterval: RepeatInterval? = nil
    var missedCount: Int = 0

    init(title: String, sortOrder: Int = 0, dueDate: Date? = nil, repeatInterval: RepeatInterval? = nil) {
        self.title = title
        self.isCompleted = false
        self.createdAt = Date()
        self.sortOrder = sortOrder
        self.dueDate = dueDate
        self.repeatInterval = repeatInterval
    }
}
