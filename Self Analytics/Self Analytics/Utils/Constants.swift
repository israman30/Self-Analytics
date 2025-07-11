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

struct DashboardViewLabels {
    static let deviceHealth = "Device Health"
    static let alerts = "Alerts"
    static let recommendations = "Recommendations"
    static let quickActions = "Quick Actions"
    
    struct MetricCard {
        static let memory = "Memory"
        static let cpu = "CPU"
        static let battery = "Battery"
        static let storage = "Storage"
        static let network = "Network"
        static let available = "Available"
        static let highUsage = "High Usage"
        static let normal = "Normal"
        static let charging = "Charging"
        static let lowPowerMode = "Low Power Mode"
        static let freeSpace = "Free Space"
    }
    
    struct Icon {
        static let memorychip = "memorychip"
        static let cpu = "cpu"
        static let externaldrive_fill = "externaldrive.fill"
        static let externaldrive = "externaldrive"
        
        static let speedometer = "speedometer"
        static let trash = "trash"
        static let gear = "gear"
        static let apple_logo = "apple.logo"
        
        static let battery_100_bolt = "battery.100.bolt"
        static let battery_25 = "battery.25"
        static let battery_50 = "battery.50"
        static let battery_75 = "battery.75"
        
        static let wifi = "wifi"
        static let antenna_radiowaves_left_and_right = "antenna.radiowaves.left.and.right"
        static let network = "network"
        static let wifi_slash = "wifi.slash"
    }
    
    static let speedTest = "Speed Test"
    static let clearCache = "Clear Cache"
    static let setting = "Settings"
    static let appStore = "App Store"
}
