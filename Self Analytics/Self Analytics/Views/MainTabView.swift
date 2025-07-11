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
            
            HistoryView()
                .tabItem {
                    Image(systemName: MainTabViewLabels.Icon.chart_line_uptrend_xyaxis)
                    Text(MainTabViewLabels.history)
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: MainTabViewLabels.Icon.gear)
                    Text(MainTabViewLabels.settings)
                }
        }
    }
}

#Preview {
    MainTabView()
} 
