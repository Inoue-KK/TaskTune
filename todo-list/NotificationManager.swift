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

    private override init() {
        super.init()
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_TODO",
            title: "Mark Complete",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: "TODO_DUE",
            actions: [completeAction],
            intentIdentifiers: []
        )
        center.setNotificationCategories([category])
    }

    func requestPermission() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    func schedule(for todo: Todo) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: notificationIDs(for: todo))

        guard let dueDate = todo.dueDate, !todo.isCompleted, dueDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = todo.title
        content.body = "Due " + formattedDate(dueDate)
        content.sound = .default
        content.categoryIdentifier = "TODO_DUE"
        content.userInfo = [
            "notificationID": todo.notificationID,
            "listTitle": todo.todoList?.title ?? ""
        ]

        if !todo.repeatWeekdays.isEmpty {
            let now = Date()
            let timeComps = Calendar.current.dateComponents([.hour, .minute], from: dueDate)
            for weekday in todo.repeatWeekdays {
                var comps = timeComps
                comps.weekday = weekday
                guard let nextDate = Calendar.current.nextDate(after: now, matching: comps, matchingPolicy: .nextTime) else { continue }
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: nextDate),
                    repeats: false
                )
                let id = "\(todo.notificationID)_\(weekday)"
                try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
            }
        } else {
            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: todo.notificationID, content: content, trigger: trigger))
        }
    }

    func cancel(for todo: Todo) {
        let center = UNUserNotificationCenter.current()
        let ids = notificationIDs(for: todo)
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)
    }

    private func notificationIDs(for todo: Todo) -> [String] {
        todo.repeatWeekdays.isEmpty
            ? [todo.notificationID]
            : todo.repeatWeekdays.map { "\(todo.notificationID)_\($0)" }
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
            cancel(for: todo)

        default:
            break
        }
    }
}
