//
//  Todo.swift
//  todo-list
//
//  Created by 井上京佳 on 2026/03/26.
//

import Foundation
import SwiftData

enum RepeatEndCondition: String, Codable {
    case afterCount = "After"
    case onDate = "On Date"
}

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
    var repeatEndCondition: RepeatEndCondition? = nil
    var repeatEndCount: Int = 1        // used when endCondition == .afterCount
    var repeatEndDate: Date? = nil     // used when endCondition == .onDate
    var repeatOccurrenceCount: Int = 0 // total number of cycles elapsed

    var repeatDescription: String {
        guard let interval = repeatInterval else { return "" }
        var base: String
        if interval == .weekly && !repeatWeekdays.isEmpty {
            let symbols = Calendar.current.shortWeekdaySymbols
            base = repeatWeekdays.sorted().map { symbols[$0 - 1] }.joined(separator: ", ")
        } else {
            let count = repeatIntervalCount
            base = count == 1 ? interval.rawValue : "Every \(count) \(interval.unitLabel(count: count))"
        }
        if let endCond = repeatEndCondition {
            switch endCond {
            case .afterCount:
                let remaining = max(0, repeatEndCount - repeatOccurrenceCount)
                base += " · \(remaining) left"
            case .onDate:
                if let endDate = repeatEndDate {
                    let f = DateFormatter()
                    f.dateStyle = .short
                    f.timeStyle = .none
                    base += " · Until \(f.string(from: endDate))"
                }
            }
        }
        return base
    }

    init(title: String, sortOrder: Int = 0, dueDate: Date? = nil,
         repeatInterval: RepeatInterval? = nil, repeatIntervalCount: Int = 1, repeatWeekdays: [Int] = [],
         repeatEndCondition: RepeatEndCondition? = nil, repeatEndCount: Int = 1, repeatEndDate: Date? = nil) {
        self.title = title
        self.isCompleted = false
        self.createdAt = Date()
        self.sortOrder = sortOrder
        self.dueDate = dueDate
        self.repeatInterval = repeatInterval
        self.repeatIntervalCount = repeatIntervalCount
        self.repeatWeekdays = repeatWeekdays
        self.repeatEndCondition = repeatEndCondition
        self.repeatEndCount = repeatEndCount
        self.repeatEndDate = repeatEndDate
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

/// 繰り返しTodoの、`date` 以降で最も近い次サイクル日時を返す
func nextCycleDate(after date: Date, for todo: Todo) -> Date? {
    guard let interval = todo.repeatInterval else { return nil }
    if interval == .weekly && !todo.repeatWeekdays.isEmpty {
        return nextWeekdayOccurrence(after: date, weekdays: todo.repeatWeekdays, time: date)
    }
    return Calendar.current.date(byAdding: interval.calendarComponent, value: todo.repeatIntervalCount, to: date)
}

/// 繰り返しTodoについて、これからスケジュールすべき未来サイクル日時を最大 `count` 件返す。
/// 終了条件（afterCount / onDate）と完了状態（完了済みなら現サイクルをスキップ）を尊重する。
func upcomingCycleDates(for todo: Todo, count: Int) -> [Date] {
    guard let baseDueDate = todo.dueDate, todo.repeatInterval != nil else { return [] }
    let now = Date()
    var dates: [Date] = []
    var current = baseDueDate
    var cycleNumber = todo.repeatOccurrenceCount + 1

    if todo.isCompleted {
        guard let next = nextCycleDate(after: current, for: todo) else { return [] }
        current = next
        cycleNumber += 1
    }

    while current <= now {
        guard let next = nextCycleDate(after: current, for: todo) else { return dates }
        current = next
        cycleNumber += 1
    }

    while dates.count < count {
        if todo.repeatEndCondition == .afterCount, cycleNumber > todo.repeatEndCount { break }
        if todo.repeatEndCondition == .onDate, let endDate = todo.repeatEndDate, current > endDate { break }
        dates.append(current)
        guard let next = nextCycleDate(after: current, for: todo) else { break }
        current = next
        cycleNumber += 1
    }

    return dates
}
