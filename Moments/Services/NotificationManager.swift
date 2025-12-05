//
//  NotificationManager.swift
//  Moments
//
//  Created by Teddy Dubois on 04/12/2025.
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Error requesting notification authorization: \(error)")
            return false
        }
    }

    func scheduleNotification(for event: Event) async {
        // Cancel existing notification if any
        if let identifier = event.notificationIdentifier {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        }

        let content = UNMutableNotificationContent()
        content.title = "Événement aujourd'hui !"
        content.body = "\(event.category.icon) \(event.title)"
        content.sound = .default

        // Create date components for the notification
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: event.date)
        dateComponents.hour = 9  // Notification at 9 AM
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: event.isRecurring)

        let identifier = event.notificationIdentifier ?? UUID().uuidString
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Notification scheduled for \(event.title)")
        } catch {
            print("Error scheduling notification: \(error)")
        }
    }

    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
}
