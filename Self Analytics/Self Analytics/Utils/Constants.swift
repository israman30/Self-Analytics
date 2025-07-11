//
//  Constants.swift
//  Self Analytics
//
//  Created by Israel Manzo on 7/10/25.
//

import Foundation

struct StorageProperties {
    static let notificationsEnabled = "notificationsEnabled"
    static let autoRefreshInterval = "autoRefreshInterval"
    static let showAlerts = "showAlerts"
    static let darkModeEnabled = "darkModeEnabled"
}

struct SettingViewLabels {
    static let notifications = "Notifications"
    static let autoRefreshTitle = "Auto Refresh"
    static let showAlerts = "Show Alerts"
    static let darkModeTitle = "Dark Mode"
    static let enableNotifications = "Enable Notifications"
    static let appSettings = "App Settings"
    static let autorefreshInterval = "Auto Refresh Interval"
    
    struct TimeIntervar {
        static let two_seconds = "2 seconds"
        static let five_seconds = "5 seconds"
        static let ten_seconds = "10 seconds"
        static let thirty_seonconds = "30 seconds"
    }
    
    static let darkMode = "Dark Mode"
    static let about = "About"
    static let version = "Version"
    static let version_number = "1.0.0"
    static let build = "Build"
    static let build_number = "1"
    
    static let support = "Support"
    static let privacyPolicy = "Privacy Policy"
    static let termsOfService = "Terms of Service"
    static let contactSupport = "Contact Support"
    
    static let data = "Data"
    static let exportData = "Export Data"
    static let clearAllData = "Clear All Data"
    static let settings = "Settings"
}

struct MainTabViewLabels {
    static let dashboard = "Dashboard"
    static let history = "History"
    static let settings = "Settings"
    
    struct Icon {
        static let gauge = "gauge"
        static let chart_line_uptrend_xyaxis = "chart.line.uptrend.xyaxis"
        static let gear = "gear"
    }
}

struct HistoryViewLabels {
    static let history = "History"
    static let timeRange = "Time Range"
    static let healthScoreTrend = "Health Score Trend"
    
    static let time = "Time"
    static let score = "Score"
    static let value = "Value"
    
    static let chartRequiresiOS16OrLater = "Charts require iOS 16 or later."
    
    struct MetricChart {
        static let memoryUsage = "Memory Usage"
        static let cpuUsage = "CPU Usage"
        static let batteryLevel = "Battery Level"
        static let storageUsage = "Storage Usage"
    }
    
    static let performanceSummary = "Performance Summary"
    
    struct SummaryRow {
        static let averageHealthScore = "Average Health Score"
        static let peakMemoryUsage = "Peak Memory Usage"
        static let peakCPUUsage = "Peak CPU Usage"
        static let lowestBatteryLevel = "Lowest Battery Level"
        static let dataPoints = "Data Points"
    }

    static let average = "Average"
    static let peak = "Peak"
}
