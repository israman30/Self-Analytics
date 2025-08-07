//
//  MainTabView.swift
//  Self Analytics
//
//  Created by Israel Manzo on 7/9/25.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Image(systemName: MainTabViewLabels.Icon.gauge)
                    Text(MainTabViewLabels.dashboard)
                }
                .accessibilityLabel(MainTabViewLabels.dashboard)
                .accessibilityHint(
                    MainTabViewLabels.view_device_health_metrics_and_current_status
                )
            
            HistoryView()
                .tabItem {
                    Image(systemName: MainTabViewLabels.Icon.chart_line_uptrend_xyaxis)
                    Text(MainTabViewLabels.history)
                }
                .accessibilityLabel(MainTabViewLabels.history)
                .accessibilityHint(
                    MainTabViewLabels.view_historical_device_performance_data_and_trends
                )
            
            SettingsView()
                .tabItem {
                    Image(systemName: MainTabViewLabels.Icon.gear)
                    Text(MainTabViewLabels.settings)
                }
                .accessibilityLabel(MainTabViewLabels.settings)
                .accessibilityHint(
                    MainTabViewLabels.configure_app_settings_and_preferences
                )
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(MainTabViewLabels.mainNavigation)
        .accessibilityHint(
            MainTabViewLabels.navigate_between_dashboard_history_and_settings
        )
    }
}

#Preview {
    MainTabView()
} 
