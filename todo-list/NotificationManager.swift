//
//  NotificationManager.swift
//  todo-list
//
//  Created by 井上京佳 on 2026/04/07.
//

import UserNotifications

@MainActor
class NotificationManager: NSObject {
    static let shared = NotificationManager()

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestPermission() async {
        try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    func schedule(for todo: Todo) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [todo.notificationID])

        guard let dueDate = todo.dueDate, !todo.isCompleted, dueDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = todo.title
        content.body = "Due " + formattedDate(dueDate)
        content.sound = .default
        content.categoryIdentifier = "TODO_DUE"

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: todo.notificationID, content: content, trigger: trigger)

        try? await center.add(request)
    }

    func cancel(for todo: Todo) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [todo.notificationID])
        center.removeDeliveredNotifications(withIdentifiers: [todo.notificationID])
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
}
