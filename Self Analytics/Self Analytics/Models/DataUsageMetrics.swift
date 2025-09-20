//
//  DataUsageMetrics.swift
//  Self Analytics
//
//  Created by Israel Manzo on 7/10/25.
//

import Foundation

// MARK: - Data Usage Models

struct AppDataUsage: Identifiable, Codable {
    let id: UUID
    let bundleIdentifier: String
    let appName: String
    let iconData: Data?
    
    var cellularBytes: UInt64 = 0
    var wifiBytes: UInt64 = 0
    
    var totalBytes: UInt64 {
        cellularBytes + wifiBytes
    }
    
    var formattedCellularUsage: String {
        ByteCountFormatter.string(fromByteCount: Int64(cellularBytes), countStyle: .file)
    }
    
    var formattedWifiUsage: String {
        ByteCountFormatter.string(fromByteCount: Int64(wifiBytes), countStyle: .file)
    }
    
    var formattedTotalUsage: String {
        ByteCountFormatter.string(fromByteCount: Int64(totalBytes), countStyle: .file)
    }
    
    var cellularPercentage: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(cellularBytes) / Double(totalBytes) * 100
    }
    
    var wifiPercentage: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(wifiBytes) / Double(totalBytes) * 100
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case bundleIdentifier
        case appName
        case iconData
        case cellularBytes
        case wifiBytes
    }
    
    init(id: UUID = UUID(), bundleIdentifier: String, appName: String, iconData: Data?, cellularBytes: UInt64 = 0, wifiBytes: UInt64 = 0) {
        self.id = id
        self.bundleIdentifier = bundleIdentifier
        self.appName = appName
        self.iconData = iconData
        self.cellularBytes = cellularBytes
        self.wifiBytes = wifiBytes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.bundleIdentifier = try container.decode(String.self, forKey: .bundleIdentifier)
        self.appName = try container.decode(String.self, forKey: .appName)
        self.iconData = try container.decodeIfPresent(Data.self, forKey: .iconData)
        self.cellularBytes = try container.decodeIfPresent(UInt64.self, forKey: .cellularBytes) ?? 0
        self.wifiBytes = try container.decodeIfPresent(UInt64.self, forKey: .wifiBytes) ?? 0
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(bundleIdentifier, forKey: .bundleIdentifier)
        try container.encode(appName, forKey: .appName)
        try container.encodeIfPresent(iconData, forKey: .iconData)
        try container.encode(cellularBytes, forKey: .cellularBytes)
        try container.encode(wifiBytes, forKey: .wifiBytes)
    }
}

struct DataUsagePeriod: Codable {
    let startDate: Date
    let endDate: Date
    let periodType: PeriodType
    
    enum PeriodType: Codable, CaseIterable {
        case today
        case thisWeek
        case thisMonth
        case lastMonth
        case custom
        
        var description: String {
            switch self {
            case .today: return "Today"
            case .thisWeek: return "This Week"
            case .thisMonth: return "This Month"
            case .lastMonth: return "Last Month"
            case .custom: return "Custom"
            }
        }
        
        var dateRange: DateInterval {
            let calendar = Calendar.current
            let now = Date()
            
            switch self {
            case .today:
                return DateInterval(start: calendar.startOfDay(for: now), end: now)
            case .thisWeek:
                let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
                return DateInterval(start: startOfWeek, end: now)
            case .thisMonth:
                let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
                return DateInterval(start: startOfMonth, end: now)
            case .lastMonth:
                let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) ?? now
                let startOfLastMonth = calendar.dateInterval(of: .month, for: lastMonth)?.start ?? lastMonth
                let endOfLastMonth = calendar.dateInterval(of: .month, for: lastMonth)?.end ?? lastMonth
                return DateInterval(start: startOfLastMonth, end: endOfLastMonth)
            case .custom:
                return DateInterval(start: now, end: now)
            }
        }
    }
}

struct DataUsageSummary: Codable {
    let period: DataUsagePeriod
    let totalCellularBytes: UInt64
    let totalWifiBytes: UInt64
    let appUsages: [AppDataUsage]
    let timestamp: Date
    
    var totalBytes: UInt64 {
        totalCellularBytes + totalWifiBytes
    }
    
    var formattedTotalCellular: String {
        ByteCountFormatter.string(fromByteCount: Int64(totalCellularBytes), countStyle: .file)
    }
    
    var formattedTotalWifi: String {
        ByteCountFormatter.string(fromByteCount: Int64(totalWifiBytes), countStyle: .file)
    }
    
    var formattedTotalUsage: String {
        ByteCountFormatter.string(fromByteCount: Int64(totalBytes), countStyle: .file)
    }
    
    var cellularPercentage: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(totalCellularBytes) / Double(totalBytes) * 100
    }
    
    var wifiPercentage: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(totalWifiBytes) / Double(totalBytes) * 100
    }
    
    var topApps: [AppDataUsage] {
        appUsages.sorted { $0.totalBytes > $1.totalBytes }
    }
}

struct DataUsageLimit: Codable, Identifiable {
    let id: UUID?
    let limitType: LimitType
    let limitValue: UInt64 // in bytes
    let periodType: DataUsagePeriod.PeriodType
    let isEnabled: Bool
    let alertThresholds: [AlertThreshold]
    let createdAt: Date
    let updatedAt: Date
    
    init(limitType: LimitType, limitValue: UInt64, periodType: DataUsagePeriod.PeriodType, isEnabled: Bool, alertThresholds: [AlertThreshold], createdAt: Date, updatedAt: Date) {
        self.id = nil
        self.limitType = limitType
        self.limitValue = limitValue
        self.periodType = periodType
        self.isEnabled = isEnabled
        self.alertThresholds = alertThresholds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    enum LimitType: Codable, CaseIterable {
        case cellular
        case wifi
        case total
        
        var description: String {
            switch self {
            case .cellular: return "Cellular Data"
            case .wifi: return "Wi-Fi Data"
            case .total: return "Total Data"
            }
        }
        
        var icon: String {
            switch self {
            case .cellular: return "antenna.radiowaves.left.and.right.circle.fill"
            case .wifi: return "wifi"
            case .total: return "network"
            }
        }
    }
    
    var formattedLimit: String {
        ByteCountFormatter.string(fromByteCount: Int64(limitValue), countStyle: .file)
    }
    
    var progressPercentage: Double {
        // This would be calculated based on current usage vs limit
        // Implementation depends on current usage data
        return 0.0
    }
}

struct AlertThreshold: Codable, Identifiable {
    let id: UUID?
    let percentage: Double // 0-100
    let isEnabled: Bool
    let alertType: AlertType
    
    init(percentage: Double, isEnabled: Bool, alertType: AlertType) {
        self.id = nil
        self.percentage = percentage
        self.isEnabled = isEnabled
        self.alertType = alertType
    }
    
    enum AlertType: Codable {
        case warning
        case critical
        
        var description: String {
            switch self {
            case .warning: return "Warning"
            case .critical: return "Critical"
            }
        }
        
        var color: String {
            switch self {
            case .warning: return "orange"
            case .critical: return "red"
            }
        }
    }
    
    var formattedThreshold: String {
        return "\(Int(percentage))%"
    }
}

struct DataUsageAlert: Codable, Identifiable {
    let id: UUID?
    let limitType: DataUsageLimit.LimitType
    let currentUsage: UInt64
    let limitValue: UInt64
    let threshold: AlertThreshold
    let timestamp: Date
    let isRead: Bool
    
    init(limitType: DataUsageLimit.LimitType, currentUsage: UInt64, limitValue: UInt64, threshold: AlertThreshold, timestamp: Date, isRead: Bool) {
        self.id = nil
        self.limitType = limitType
        self.currentUsage = currentUsage
        self.limitValue = limitValue
        self.threshold = threshold
        self.timestamp = timestamp
        self.isRead = isRead
    }
    
    var usagePercentage: Double {
        guard limitValue > 0 else { return 0 }
        return Double(currentUsage) / Double(limitValue) * 100
    }
    
    var formattedCurrentUsage: String {
        ByteCountFormatter.string(fromByteCount: Int64(currentUsage), countStyle: .file)
    }
    
    var formattedLimit: String {
        ByteCountFormatter.string(fromByteCount: Int64(limitValue), countStyle: .file)
    }
    
    var alertMessage: String {
        let usagePercent = Int(usagePercentage)
        switch threshold.alertType {
        case .warning:
            return "You've used \(usagePercent)% of your \(limitType.description.lowercased()) limit (\(formattedCurrentUsage) of \(formattedLimit))"
        case .critical:
            return "You've reached \(usagePercent)% of your \(limitType.description.lowercased()) limit (\(formattedCurrentUsage) of \(formattedLimit))"
        }
    }
}

// MARK: - Data Usage Chart Models

struct DataUsageChartData: Identifiable {
    let id = UUID()
    let date: Date
    let cellularBytes: UInt64
    let wifiBytes: UInt64
    let totalBytes: UInt64
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date)
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    var formattedTotal: String {
        ByteCountFormatter.string(fromByteCount: Int64(totalBytes), countStyle: .file)
    }
}

// MARK: - Data Usage Statistics

struct DataUsageStatistics: Codable {
    let period: DataUsagePeriod
    let averageDailyUsage: UInt64
    let peakUsage: UInt64
    let peakUsageDate: Date
    let totalApps: Int
    let mostUsedApp: AppDataUsage?
    let leastUsedApp: AppDataUsage?
    
    var formattedAverageDaily: String {
        ByteCountFormatter.string(fromByteCount: Int64(averageDailyUsage), countStyle: .file)
    }
    
    var formattedPeakUsage: String {
        ByteCountFormatter.string(fromByteCount: Int64(peakUsage), countStyle: .file)
    }
    
    var formattedPeakDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: peakUsageDate)
    }
}

// MARK: - Data Usage Preferences

struct DataUsagePreferences: Codable {
    var autoResetPeriod: DataUsagePeriod.PeriodType = .thisMonth
    var showCellularWarnings: Bool = true
    var showWifiWarnings: Bool = false
    var backgroundRefreshEnabled: Bool = true
    var detailedLoggingEnabled: Bool = false
    var defaultLimitType: DataUsageLimit.LimitType = .cellular
    
    static let `default` = DataUsagePreferences()
}
