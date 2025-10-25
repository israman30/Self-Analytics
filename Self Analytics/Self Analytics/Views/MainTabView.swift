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
            
            DataUsageView()
                .tabItem {
                    Image(systemName: MainTabViewLabels.Icon.network)
                    Text(MainTabViewLabels.dataUsage)
                }
            
            HistoryView()
                .tabItem {
                    Image(systemName: MainTabViewLabels.Icon.chart_line_uptrend_xyaxis)
                    Text(MainTabViewLabels.history)
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
            MainTabViewLabels.navigate_between_dashboard_data_usage_history_and_settings
        )
    }
}

#Preview {
    MainTabView()
}
