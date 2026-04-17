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
    case yearly = "Yearly"

    var calendarComponent: Calendar.Component {
        switch self {
        case .daily: return .day
        case .weekly: return .weekOfYear
        case .monthly: return .month
        case .yearly: return .year
        }
    }

    func unitLabel(count: Int) -> String {
        switch self {
        case .daily: return count == 1 ? "day" : "days"
        case .weekly: return count == 1 ? "week" : "weeks"
        case .monthly: return count == 1 ? "month" : "months"
        case .yearly: return count == 1 ? "year" : "years"
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
    var repeatIntervalCount: Int = 1
    var repeatWeekdays: [Int] = []  // Calendar weekday numbers: 1=Sun, 2=Mon, ..., 7=Sat
    var missedCount: Int = 0

    var repeatDescription: String {
        guard let interval = repeatInterval else { return "" }
        if interval == .weekly && !repeatWeekdays.isEmpty {
            let symbols = Calendar.current.shortWeekdaySymbols
            return repeatWeekdays.sorted().map { symbols[$0 - 1] }.joined(separator: ", ")
        }
        let count = repeatIntervalCount
        return count == 1 ? interval.rawValue : "Every \(count) \(interval.unitLabel(count: count))"
    }

    init(title: String, sortOrder: Int = 0, dueDate: Date? = nil, repeatInterval: RepeatInterval? = nil, repeatIntervalCount: Int = 1, repeatWeekdays: [Int] = []) {
        self.title = title
        self.isCompleted = false
        self.createdAt = Date()
        self.sortOrder = sortOrder
        self.dueDate = dueDate
        self.repeatInterval = repeatInterval
        self.repeatIntervalCount = repeatIntervalCount
        self.repeatWeekdays = repeatWeekdays
    }
}

/// 指定された曜日リストのうち、date 以降で最も近い日時を返す
func nextWeekdayOccurrence(after date: Date, weekdays: [Int], time: Date) -> Date {
    let cal = Calendar.current
    let timeComps = cal.dateComponents([.hour, .minute], from: time)
    var earliest: Date?
    for weekday in weekdays {
        var comps = timeComps
        comps.weekday = weekday
        if let next = cal.nextDate(after: date, matching: comps, matchingPolicy: .nextTime) {
            if earliest == nil || next < earliest! { earliest = next }
        }
    }
    return earliest ?? time
}
