//
//  MainTabView.swift
//  Self Analytics
//
//  Created by Israel Manzo on 7/9/25.
//

import SwiftUI
import UIKit
import UserNotifications

/// The main tab container for the app.
///
/// **Implementation notes**
/// - Owns first-launch onboarding (`WelcomeView`) and the optional notification opt-in prompt.
/// - Uses simple persisted flags (`@AppStorage`) to ensure one-time UI flows (welcome + first permission prompt)
///   don't reappear on subsequent launches.
/// - Defers the system notification prompt until after onboarding to avoid stacking multiple modal experiences.
struct MainTabView: View {
    @AppStorage(StorageProperties.notificationsEnabled) private var notificationsEnabled = true
    @AppStorage("didShowNotificationsPermissionPrompt") private var didShowNotificationsPermissionPrompt = false
    @AppStorage("didShowWelcome") private var didShowWelcome = false
    
    @State private var activeSheet: ActiveSheet?
    @State private var showNotificationsPermissionAlert = false
    @State private var showNotificationsDeniedAlert = false
    @State private var isRequestingNotifications = false
    
    /// Tracks full-screen flows presented above the tab UI.
    ///
    /// This uses `Identifiable` so SwiftUI can manage the presentation lifetime and avoid double-present issues
    /// when the underlying state changes during async work.
    private enum ActiveSheet: Identifiable {
        case welcome
        
        var id: Int {
            switch self {
            case .welcome: return 1
            }
        }
    }
    
    @Environment(\.openURL) private var openURL
    
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
        .fullScreenCover(item: $activeSheet) { sheet in
            switch sheet {
            case .welcome:
                WelcomeView {
                    didShowWelcome = true
                    activeSheet = nil
                    Task { await maybeShowNotificationsPermissionAlertIfNeeded() }
                }
            }
        }
        .alert("Enable Notifications", isPresented: $showNotificationsPermissionAlert) {
            Button(isRequestingNotifications ? "Requesting…" : "Enable") {
                requestNotificationsPermission()
            }
            .disabled(isRequestingNotifications)
            
            Button("Not Now", role: .cancel) {
                notificationsEnabled = false
                ProactiveNotificationService.shared.handleUserDisabledNotifications()
            }
            .disabled(isRequestingNotifications)
        } message: {
            Text("Get alerts for network changes, high CPU/memory, low storage, battery drain, and iOS update recommendations. You can change this any time in Settings.")
        }
        .alert("Notifications are Disabled", isPresented: $showNotificationsDeniedAlert) {
            Button("Open iOS Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text("To turn them on, open iOS Settings → Notifications → Self Analytics.")
        }
        .task {
            if maybeShowWelcomeIfNeeded() { return }
            await maybeShowNotificationsPermissionAlertIfNeeded()
        }
    }
    
    /// Presents onboarding exactly once per install, before any other modal flow.
    ///
    /// Returning `true` makes the call-site short-circuit so we don't attempt to present onboarding and a
    /// notification prompt at the same time.
    private func maybeShowWelcomeIfNeeded() -> Bool {
        guard !didShowWelcome else { return false }
        guard activeSheet == nil else { return false }
        activeSheet = .welcome
        return true
    }
    
    /// Decides whether we should show the *in-app* notification opt-in explanation.
    ///
    /// This intentionally checks `UNUserNotificationCenter` first and only shows the prompt if the system status
    /// is still `.notDetermined` (i.e., we haven't asked yet). If the user has already denied, we avoid nagging
    /// and instead provide a one-tap route to iOS Settings when needed.
    private func maybeShowNotificationsPermissionAlertIfNeeded() async {
        guard !didShowNotificationsPermissionPrompt else { return }
        
        let settings = await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                continuation.resume(returning: settings)
            }
        }
        
        guard settings.authorizationStatus == .notDetermined else { return }
        guard notificationsEnabled else { return }
        guard activeSheet == nil else { return }
        
        await MainActor.run {
            didShowNotificationsPermissionPrompt = true
            showNotificationsPermissionAlert = true
        }
    }
    
    /// Requests system notification permission via `ProactiveNotificationService`.
    ///
    /// The service is responsible for the exact authorization options and for any follow-up scheduling logic.
    /// This view only owns the UI state machine (loading, success/failure, and the "open iOS settings" fallback).
    private func requestNotificationsPermission() {
        guard !isRequestingNotifications else { return }
        isRequestingNotifications = true
        
        Task {
            let granted = await ProactiveNotificationService.shared.handleUserEnabledNotifications()
            await MainActor.run {
                isRequestingNotifications = false
                if !granted {
                    showNotificationsDeniedAlert = true
                }
            }
        }
    }
}

#Preview {
    MainTabView()
}
