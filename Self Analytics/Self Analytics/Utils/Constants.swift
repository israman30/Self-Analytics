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
    static let version_number = "1.0.1"
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
    
    static let deviceModel = "Model"
    static let systemVersion = "System Version"
    static let currentDevice = "Current Device"
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
    static let cellularData = "Cellular Data"
    
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
        static let noInternetConnection = "No Internet Connection"
        static let connected = "Connected"
        static let disconnected = "Disconnected"
        static let restored = "Connection Restored"
        static let wifiConnected = "Wi-Fi Connected"
        static let usingCellularData = "Using Cellular Data"
        static let ethernetConnected = "Ethernet Connected"
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
        static let wifi_fill = "wifi"
        static let wifi_slash = "wifi.slash"
        static let antenna_radiowaves_left_and_right = "antenna.radiowaves.left.and.right"
        static let antenna_radiowaves_left_and_right_fill = "antenna.radiowaves.left.and.right.fill"
        static let network = "network"
        static let network_slash = "network.slash"
        static let exclamationmark_triangle = "exclamationmark.triangle"
        static let checkmark_circle = "checkmark.circle"
        static let antenna_radiowaves_left_and_right_circle_fill = "antenna.radiowaves.left.and.right.circle.fill"
        
        static let iphone = "iphone"
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
    
    static let networkTesting = "Network Testing"
    static let testAnyWiFiNetwork = "Test Any WiFi Network"
    static let checkCurrentNetworkPerformance = "Check your current network performance"
    static let testNow = "Test Now"
    static let currentNetwork = "Current Network"
    static let speed = "Speed"
    static let testHistory = "Test History"
    static let history = "History"
    
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
    static let overallSystemPerformance = "Overall system performance"
    
    struct Icon {
        static let heart_fill = "heart.fill"
    }
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
        static let antenna_radiowaves_left_and_right_circle_fill = "antenna.radiowaves.left.and.right.circle.fill"
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
    
    static let your_device_storage_is_running_low_Consider_clearing_some_space = "Your device storage is running low. Consider clearing some space."
    static let your_device_is_using_a_lot_of_memory_Consider_closing_some_apps = "Your device is using a lot of memory. Consider closing some apps."
}

struct SchemeURL {
    static let appStore = "itms-apps://itunes.apple.com/app/id"
}

struct CSVExportString {
    static let export_Date_App_Version_Build_Number_Device_Name_Device_Model_iOS_Version = "Export Date, App Version, Build Number, Device Name, Device Model, iOS Version"
    static let settings = "Settings"
    static let notifications_Enabled_Auto_Refresh_Interval_Show_Alerts_Dark_Mode_Enabled = "Notifications Enabled, Auto Refresh Interval, Show Alerts, Dark Mode Enabled"
    static let historicalData = "Historical Data"
    static let timestamp_Health_Score_Memory_Usage_percentage_CPU_Usage_percentage_Battery_Level_percentage_Storage_Usage = "Timestamp, Health Score, Memory Usage %,CPU Usage %, Battery Level %, Storage Usage %"
    static let alert = "Alert"
    static let timestamp_Type_Title_Message_Severity_Is_Resolved = "Timestamp,Type,Title,Message,Severity,Is Resolved"
    static let recommendations = "Recommendations"
    static let type_Title_Description_Action_Impact_Is_Completed = "Type,Title,Description,Action,Impact,Is Completed"
}

struct ContactSupportLabel {
    static let contactSupport = "Contact Support"
    static let contactMessage = "If you have any questions, issues, or feedback, please reach out to our support team. We're here to help!"
    
    struct Icon {
        static let envelope = "envelope"
        static let square_and_pencil = "square.and.pencil"
    }
    static let emailSupport = "Email Support"
    static let alertTitle = "Copied!"
    static let alertMessage = "Support email copied to clipboard."
    static let ok = "OK"
}

struct AccessibilityLabels {
    static let cellularData = "Cellular Data"
    static let tapToActivate = "Tap to activate"
    static let healthScoreTrendChart = "Health Score Trend Chart"
    static let tapToViewOurPrivacyPolicy = "Tap to view our privacy policy."
    static let tapToViewOurTermsOfService = "Tap to view our terms of service."
    static let tapToContactOurSupportTeam = "Tap to contact our support team."
    static let tapToExportYourData = "Tap to export your data."
    static let tapToClearAllYourData_thisActionCannotBeUndone = "Tap to clear all your data. This action cannot be undone"
    static let alert = "Alert"
    static let percent = "percent"
    static let completed = "Completed"
}
