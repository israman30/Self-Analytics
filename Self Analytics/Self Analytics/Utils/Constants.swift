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
    
    // Data Management Labels
    static let exportInProgress = "Exporting Data..."
    static let exportComplete = "Export Complete"
    static let exportFailed = "Export Failed"
    static let clearDataTitle = "Clear All Data"
    static let clearDataMessage = "This will permanently delete all your data including settings, history, and preferences. This action cannot be undone."
    static let clearDataConfirm = "Clear Data"
    static let clearDataCancel = "Cancel"
    static let clearingData = "Clearing Data..."
    static let dataCleared = "Data Cleared"
    static let shareExport = "Share Export"
    static let exportSuccess = "Data exported successfully"
    static let exportError = "Export Error"
    static let generalError = "Error"
    static let ok = "OK"
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

struct SpeedTestViewLabels {
    static let testingNetworkSpeed = "Testing network speed..."
    static let speedTestComplete = "Speed Test Complete"
    static let networkSpeedTest = "Network Speed Test"
    static let testInternetConnectionPerformance = "Test your internet connection speed to check performance"
    
    static let startTest = "Start Test"
    static let testAgain = "Test Again"
    
    static let done = "Done"
    static let speedTest = "Speed Test"
    
    static let download = "Download"
    static let upload = "Upload"
    
    struct Icon {
        static let checkmark_circle_fill = "checkmark.circle.fill"
        static let arrow_down_circle_fill = "arrow.down.circle.fill"
        static let arrow_up_circle_fill = "arrow.up.circle.fill"
        static let speedometer = "speedometer"
    }
    
    static let fast = "Fast"
    static let good = "Good"
    static let fair = "Fair"
    static let slow = "Slow"
}

struct MetricCardLabels {
    struct Icon {
        static let exclamationmark_triangle_fill = "exclamationmark.triangle.fill"
    }
}

struct HealthScoreCardLabels {
    static let score = "Score"
    static let deviceHealth = "Device Health"
}

struct AlertCardLabels {
    static let resolve = "Resolve"
    static let dismiss = "Dismiss"
    
    struct Icon {
        static let externaldrive_fill = "externaldrive.fill"
        static let memorychip = "memorychip"
        static let cpu = "cpu"
        static let battery_25 = "battery.25"
        static let battery_100 = "battery.100"
        static let wifi = "wifi"
        static let shield = "shield"
    }
}

struct RecommendationCardLabels {
    struct Icon {
        static let checkmark_circle_fill = "checkmark.circle.fill"
    }
}

struct AlertServiceLabels {
    static let storageAlmostFull = "Storage Almost Full"
    static let highMemoryUsage = "High Memory Usage"
    static let highCPUUsage = "High CPU Usage"
    static let lowBattery = "Low Battery"
    static let poorBatteryHealth = "Poor Battery Health"
    static let slowNetworkConnection = "Slow Network Connection"
    
    static let clearAppCache = "Clear App Cache"
    static let reviewLargeFiles = "Review Large Files"
    static let enableLowPowerMode = "Enable Low Power Mode"
    static let runNetworkSpeedTest = "Run Network Speed Test"
    static let reviewAppPersmissions = "Review App Permissions"
    static let updateApps = "Update Apps"
    static let iOSUpdateAvailable = "iOS Update Available"
    
    static let free_up_space_by_clearing_cached_data_from_apps = "Free up space by clearing cached data from apps"
    static let clearCache = "Clear Cache"
    static let check_for_large_photos_videos_or_downloads_you_can_delete = "Check for large photos, videos, or downloads you can delete"
    static let reviewFiles = "Review Files"
    static let save_battery_by_enabling_low_power_mode = "Save battery by enabling Low Power Mode"
    static let enable = "Enable"
    static let check_your_actual_network_performance = "Check your actual network performance"
    static let testSpeed = "Test Speed"
    static let check_which_apps_have_access_to_your_data = "Check which apps have access to your data"
    static let review = "Review"
    static let keep_your_apps_updated_for_security_and_performance = "Keep your apps updated for security and performance"
    static let update = "Update"
    static let an_ios_update_is_available_with_security_improvements = "A new iOS update is available with security improvements"
}

struct SchemeURL {
    static let appStore = "itms-apps://itunes.apple.com/app/id"
}
