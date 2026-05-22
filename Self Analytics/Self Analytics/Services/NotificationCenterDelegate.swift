//
//  NotificationCenterDelegate.swift
//  Self Analytics
//
//  Ensures local notifications are presented while app is in the foreground.
//

import Foundation
import UserNotifications

/// Foreground presentation policy for local notifications.
///
/// By default, iOS suppresses notification UI when the app is active. This delegate opts into showing a banner/
/// list entry (plus sound/badge) so proactive alerts remain visible even during active use.
final class NotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationCenterDelegate()
    
    private override init() {}
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .list, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
}

