//
//  MainTabView.swift
//  Self Analytics
//
//  Created by Israel Manzo on 7/9/25.
//

import SwiftUI
import UserNotifications

struct MainTabView: View {
    @AppStorage(StorageProperties.notificationsEnabled) private var notificationsEnabled = true
    @AppStorage("didShowNotificationsPermissionPrompt") private var didShowNotificationsPermissionPrompt = false
    @State private var showNotificationsPermissionPrompt = false
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Image(systemName: MainTabViewLabels.Icon.gauge)
                    Text(MainTabViewLabels.dashboard)
                }
            
            UsageAndHistoryView()
                .tabItem {
                    Image(systemName: MainTabViewLabels.Icon.network)
                    Text(MainTabViewLabels.dataUsage)
                }
            
            SecurityScanView()
                .tabItem {
                    Image(systemName: MainTabViewLabels.Icon.shield_lefthalf_filled)
                    Text(MainTabViewLabels.securityScan)
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: MainTabViewLabels.Icon.gear)
                    Text(MainTabViewLabels.settings)
                }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(MainTabViewLabels.mainNavigation)
        .accessibilityHint(
            MainTabViewLabels.navigate_between_dashboard_usage_history_and_settings
        )
        .sheet(isPresented: $showNotificationsPermissionPrompt) {
            NotificationPermissionPromptView(
                isPresented: $showNotificationsPermissionPrompt,
                notificationsEnabled: $notificationsEnabled
            )
        }
        .task {
            await maybeShowNotificationsPermissionPromptIfNeeded()
        }
    }
    
    private func maybeShowNotificationsPermissionPromptIfNeeded() async {
        guard !didShowNotificationsPermissionPrompt else { return }
        defer { didShowNotificationsPermissionPrompt = true }
        
        let settings = await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                continuation.resume(returning: settings)
            }
        }
        
        guard settings.authorizationStatus == .notDetermined else { return }
        guard notificationsEnabled else { return }
        showNotificationsPermissionPrompt = true
    }
}

#Preview {
    MainTabView()
}
