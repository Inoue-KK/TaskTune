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
            content.body = listTitle + " · Due " + formattedDate(dueDate)
        } else {
            content.body = "Due " + formattedDate(dueDate)
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
