//
//  NotificationManager.swift
//  todo-list
//
//  Created by 井上京佳 on 2026/04/07.
//

import UserNotifications
import SwiftData
import UIKit

extension Notification.Name {
    static let openListByTitle = Notification.Name("openListByTitle")
}

@MainActor
class NotificationManager: NSObject {
    static let shared = NotificationManager()
    var modelContainer: ModelContainer?

    /// 繰り返しTodoについて、未来サイクル分を一度に登録する最大件数。
    /// 大きいほどアプリ未起動でも通知が途切れにくいが、iOSの 64 件 pending 上限に注意。
    static let maxScheduledOccurrences = 7

    private override init() {
        super.init()
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_TODO",
            title: NSLocalizedString("Mark Complete", comment: ""),
            options: []
        )
        let category = UNNotificationCategory(
            identifier: "TODO_DUE",
            actions: [completeAction],
            intentIdentifiers: []
        )
        let listReminderCategory = UNNotificationCategory(
            identifier: "LIST_REMINDER",
            actions: [],
            intentIdentifiers: []
        )
        center.setNotificationCategories([category, listReminderCategory])
    }

    func requestPermission() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    func schedule(for todo: Todo) async {
        let center = UNUserNotificationCenter.current()
        cancel(for: todo)

        guard let dueDate = todo.dueDate else { return }

        // 単発（繰り返しなし）
        if todo.repeatInterval == nil {
            guard !todo.isCompleted, dueDate > Date() else { return }
            let content = makeContent(for: todo, dueDate: dueDate)
            let trigger = makeTrigger(for: dueDate)
            try? await center.add(UNNotificationRequest(identifier: todo.notificationID, content: content, trigger: trigger))
            return
        }

        // 繰り返し: 未来 N サイクル分を先読み登録（完了済みなら現サイクルはスキップ）
        let dates = upcomingCycleDates(for: todo, count: Self.maxScheduledOccurrences)
        for (index, date) in dates.enumerated() {
            let content = makeContent(for: todo, dueDate: date)
            let trigger = makeTrigger(for: date)
            let id = "\(todo.notificationID)_\(index)"
            try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }
    }

    func scheduleListReminder(for list: TodoList) async {
        cancelListReminder(for: list)
        guard list.reminderEnabled, list.reminderTime != nil else { return }

        let pendingCount = list.todos.filter { !$0.isCompleted }.count
        guard pendingCount > 0 else {
            list.reminderLastScheduledCount = 0
            return
        }

        let dates = upcomingListReminderDates(for: list)
        guard !dates.isEmpty else {
            list.reminderLastScheduledCount = 0
            return
        }

        let center = UNUserNotificationCenter.current()
        let usesWeekdays = list.reminderRepeatInterval == .weekly && !list.reminderWeekdays.isEmpty

        for (index, date) in dates.enumerated() {
            let content = makeListReminderContent(for: list, pendingCount: pendingCount)
            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let id: String
            if list.reminderRepeatInterval == nil {
                id = "list_reminder_\(list.id)"
            } else if usesWeekdays {
                let weekday = Calendar.current.component(.weekday, from: date)
                id = "list_reminder_\(list.id)_\(weekday)_\(index)"
            } else {
                id = "list_reminder_\(list.id)_\(index)"
            }
            try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }

        list.reminderLastScheduledCount = dates.count
    }

    private func upcomingListReminderDates(for list: TodoList) -> [Date] {
        guard let reminderTime = list.reminderTime else { return [] }
        let now = Date()
        let maxOccurrences = Self.maxScheduledOccurrences

        guard let interval = list.reminderRepeatInterval else {
            return reminderTime > now ? [reminderTime] : []
        }

        let intervalCount = max(1, list.reminderRepeatIntervalCount)
        var limit = maxOccurrences
        if let endCond = list.reminderRepeatEndCondition, endCond == .afterCount {
            limit = min(maxOccurrences, max(0, list.reminderRepeatEndCount - list.reminderOccurrenceCount))
        }
        guard limit > 0 else { return [] }

        let endDate: Date? = (list.reminderRepeatEndCondition == .onDate) ? list.reminderRepeatEndDate : nil
        var dates: [Date] = []

        if interval == .weekly && !list.reminderWeekdays.isEmpty {
            for weekday in list.reminderWeekdays.sorted() {
                var current = nextWeekdayOccurrence(after: now, weekdays: [weekday], time: reminderTime)
                var count = 0
                while count < limit {
                    if let end = endDate, current > end { break }
                    dates.append(current)
                    count += 1
                    guard let next = Calendar.current.date(byAdding: .weekOfYear, value: intervalCount, to: current) else { break }
                    current = next
                }
            }
        } else {
            var current = reminderTime
            if current <= now {
                repeat {
                    guard let next = Calendar.current.date(byAdding: interval.calendarComponent, value: intervalCount, to: current) else { break }
                    current = next
                } while current <= now
            }
            var count = 0
            while count < limit {
                if let end = endDate, current > end { break }
                dates.append(current)
                count += 1
                guard let next = Calendar.current.date(byAdding: interval.calendarComponent, value: intervalCount, to: current) else { break }
                current = next
            }
        }

        return Array(dates.prefix(maxOccurrences))
    }

    func cancelListReminder(for list: TodoList) {
        var ids = ["list_reminder_\(list.id)"]
        for i in 0..<Self.maxScheduledOccurrences {
            ids.append("list_reminder_\(list.id)_\(i)")
        }
        for weekday in 1...7 {
            ids.append("list_reminder_\(list.id)_\(weekday)")
            for i in 0..<Self.maxScheduledOccurrences {
                ids.append("list_reminder_\(list.id)_\(weekday)_\(i)")
            }
        }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    func rescheduleAllListReminders(lists: [TodoList]) async {
        let pendingIDs = Set(await UNUserNotificationCenter.current().pendingNotificationRequests().map { $0.identifier })
        for list in lists {
            if let endCond = list.reminderRepeatEndCondition, endCond == .afterCount, list.reminderLastScheduledCount > 0 {
                let listPrefix = "list_reminder_\(list.id)"
                let stillPending = pendingIDs.filter { $0.hasPrefix(listPrefix) }.count
                let fired = max(0, list.reminderLastScheduledCount - stillPending)
                list.reminderOccurrenceCount += fired
            }
            await scheduleListReminder(for: list)
        }
    }

    private func makeListReminderContent(for list: TodoList, pendingCount: Int) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = list.title
        let bodyKey = pendingCount == 1 ? "%lld incomplete task" : "%lld incomplete tasks"
        content.body = String(format: NSLocalizedString(bodyKey, comment: ""), pendingCount)
        content.sound = .default
        content.categoryIdentifier = "LIST_REMINDER"
        content.userInfo = ["listTitle": list.title]
        return content
    }

    func cancel(for todo: Todo) {
        let prefix = todo.notificationID
        var ids = Set<String>([prefix])
        // 新スキーム: 0..N-1 のサイクルインデックス
        for i in 0..<Self.maxScheduledOccurrences { ids.insert("\(prefix)_\(i)") }
        // 旧スキーム互換: 曜日番号 1..7（Weekly 曜日指定で使われていた）
        for i in 1...7 { ids.insert("\(prefix)_\(i)") }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: Array(ids))
        center.removeDeliveredNotifications(withIdentifiers: Array(ids))
    }

    private func makeContent(for todo: Todo, dueDate: Date) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = todo.title
        if let listTitle = todo.todoList?.title, !listTitle.isEmpty {
            content.body = String(format: NSLocalizedString("%@ · Due %@", comment: ""), listTitle, formattedDate(dueDate))
        } else {
            content.body = String(format: NSLocalizedString("Due %@", comment: ""), formattedDate(dueDate))
        }
        content.sound = .default
        content.categoryIdentifier = "TODO_DUE"
        content.userInfo = [
            "notificationID": todo.notificationID,
            "listTitle": todo.todoList?.title ?? ""
        ]
        return content
    }

    private func makeTrigger(for date: Date) -> UNCalendarNotificationTrigger {
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo

        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            // 通知バナーをタップ → 該当リストへ遷移
            if let listTitle = userInfo["listTitle"] as? String, !listTitle.isEmpty {
                NotificationCenter.default.post(
                    name: .openListByTitle,
                    object: nil,
                    userInfo: ["listTitle": listTitle]
                )
            }

        case "COMPLETE_TODO":
            // アクションボタンから直接完了
            guard let notificationID = userInfo["notificationID"] as? String,
                  let container = modelContainer else { return }
            let context = container.mainContext
            let descriptor = FetchDescriptor<Todo>(
                predicate: #Predicate { $0.notificationID == notificationID }
            )
            guard let todo = try? context.fetch(descriptor).first else { return }
            todo.isCompleted = true
            todo.missedCount = 0
            try? context.save()
            // 繰り返しTodoは現サイクルだけ抑止し、未来サイクルは維持される
            await schedule(for: todo)

        default:
            break
        }
    }
}
