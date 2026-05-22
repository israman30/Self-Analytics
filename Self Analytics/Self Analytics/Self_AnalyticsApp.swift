//
//  Self_AnalyticsApp.swift
//  Self Analytics
//
//  Created by Israel Manzo on 7/9/25.
//

import SwiftUI
import UserNotifications

@main
/// App entry point.
///
/// **Setup responsibilities**
/// - Configures the app's proactive notification system (local notifications + background refresh hooks).
/// - Installs a `UNUserNotificationCenterDelegate` so notifications can be surfaced while the app is foregrounded.
///
/// **Usage**
/// This is the only place that should perform global one-time wiring. Feature code should live in services and be
/// driven by views/view-models (rather than doing work directly in the `WindowGroup`).
struct Self_AnalyticsApp: App {
    init() {
        // Configure notification scheduling/threshold evaluation before the UI appears so first-launch flows
        // can accurately reflect current notification state.
        ProactiveNotificationService.shared.configure()
        UNUserNotificationCenter.current().delegate = NotificationCenterDelegate.shared
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}
