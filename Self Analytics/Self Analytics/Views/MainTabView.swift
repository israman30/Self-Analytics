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
                .accessibilityHint("View device health metrics and current status")
            
            HistoryView()
                .tabItem {
                    Image(systemName: MainTabViewLabels.Icon.chart_line_uptrend_xyaxis)
                    Text(MainTabViewLabels.history)
                }
                .accessibilityLabel(MainTabViewLabels.history)
                .accessibilityHint("View historical device performance data and trends")
            
            SettingsView()
                .tabItem {
                    Image(systemName: MainTabViewLabels.Icon.gear)
                    Text(MainTabViewLabels.settings)
                }
                .accessibilityLabel(MainTabViewLabels.settings)
                .accessibilityHint("Configure app settings and preferences")
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Main Navigation")
        .accessibilityHint("Navigate between dashboard, history, and settings")
    }
}

#Preview {
    MainTabView()
} 
