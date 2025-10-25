//
//  DataUsageService.swift
//  Self Analytics
//
//  Created by Israel Manzo on 7/10/25.
//

import Foundation
import UIKit
import Network

@MainActor
class DataUsageService: ObservableObject {
    @Published var currentSummary: DataUsageSummary?
    @Published var dataUsageHistory: [DataUsageSummary] = []
    @Published var dataUsageLimits: [DataUsageLimit] = []
    @Published var activeAlerts: [DataUsageAlert] = []
    @Published var isMonitoring = false
    @Published var preferences: DataUsagePreferences = .default
    
    private var timer: Timer?
    private let updateInterval: TimeInterval = 30.0 // Update every 30 seconds
    private let dataQueue = DispatchQueue(label: "DataUsageService.dataQueue", qos: .userInitiated)
    private var networkMonitor: NWPathMonitor?
    private var networkQueue = DispatchQueue(label: "DataUsageService.networkQueue")
    
    // Mock data for demonstration - in a real app, you'd integrate with system APIs
    private var mockAppData: [String: AppDataUsage] = [:]
    private var lastUpdateTime: Date = Date()
    
    init() {
        setupInitialData()
        startMonitoring()
    }
    
    deinit {
        stop()
    }
    
    nonisolated func stop() {
        Task { @MainActor in
            stopMonitoring()
        }
    }
    
    
    // MARK: - Setup Methods
    
    private func setupInitialData() {
        // Initialize with some mock apps
        let mockApps = [
            ("com.apple.Safari", "Safari"),
            ("com.apple.mobilesafari", "Safari"),
            ("com.apple.Music", "Music"),
            ("com.spotify.client", "Spotify"),
            ("com.netflix.Netflix", "Netflix"),
            ("com.youtube.ios", "YouTube"),
            ("com.apple.mail", "Mail"),
            ("com.apple.MobileSMS", "Messages"),
            ("com.apple.camera", "Camera"),
            ("com.apple.mobilecal", "Calendar")
        ]
        
        for (bundleId, name) in mockApps {
            var appUsage = AppDataUsage(
                bundleIdentifier: bundleId,
                appName: name,
                iconData: nil
            )
            
            // Generate mock usage data
            appUsage.cellularBytes = UInt64.random(in: 0...500 * 1024 * 1024) // 0-500MB
            appUsage.wifiBytes = UInt64.random(in: 100 * 1024 * 1024...2000 * 1024 * 1024) // 100MB-2GB
            
            mockAppData[bundleId] = appUsage
        }
        
        // Set up default limits
        setupDefaultLimits()
    }
    
    private func setupDefaultLimits() {
        let cellularLimit = DataUsageLimit(
            limitType: .cellular,
            limitValue: 5 * 1024 * 1024 * 1024, // 5GB
            periodType: .thisMonth,
            isEnabled: true,
            alertThresholds: [
                AlertThreshold(percentage: 75, isEnabled: true, alertType: .warning),
                AlertThreshold(percentage: 90, isEnabled: true, alertType: .critical)
            ],
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let wifiLimit = DataUsageLimit(
            limitType: .wifi,
            limitValue: 100 * 1024 * 1024 * 1024, // 100GB
            periodType: .thisMonth,
            isEnabled: false,
            alertThresholds: [
                AlertThreshold(percentage: 80, isEnabled: true, alertType: .warning),
                AlertThreshold(percentage: 95, isEnabled: true, alertType: .critical)
            ],
            createdAt: Date(),
            updatedAt: Date()
        )
        
        dataUsageLimits = [cellularLimit, wifiLimit]
    }
    
    // MARK: - Monitoring Methods
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        // Start network monitoring
        startNetworkMonitoring()
        
        // Initial update
        updateDataUsage()
        
        // Start timer for periodic updates
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateDataUsage()
            }
        }
    }
    
    func stopMonitoring() {
        isMonitoring = false
        timer?.invalidate()
        timer = nil
        stopNetworkMonitoring()
    }
    
    private func updateDataUsage() {
        Task {
            await generateMockDataUsage()
            await checkDataLimits()
        }
    }
    
    // MARK: - Data Generation (Mock Implementation)
    
    private func generateMockDataUsage() async {
        // In a real app, this would query system APIs for actual data usage
        // For now, we'll simulate realistic data patterns
        
        let currentPeriod = DataUsagePeriod(
            startDate: Calendar.current.startOfDay(for: Date()),
            endDate: Date(),
            periodType: .today
        )
        
        // Update mock data with small increments
        for (bundleId, _) in mockAppData {
            if var appUsage = mockAppData[bundleId] {
                // Simulate data usage based on time and app type
                let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdateTime)
                let baseIncrement = timeSinceLastUpdate * 1024 // Base increment per second
                
                // Different apps have different usage patterns
                let multiplier = getUsageMultiplier(for: bundleId)
                let increment = UInt64(baseIncrement * multiplier)
                
                // Randomly distribute between cellular and wifi
                let isCellular = Bool.random()
                if isCellular {
                    appUsage.cellularBytes += increment
                } else {
                    appUsage.wifiBytes += increment
                }
                
                mockAppData[bundleId] = appUsage
            }
        }
        
        // Create summary
        let totalCellular = mockAppData.values.reduce(0) { $0 + $1.cellularBytes }
        let totalWifi = mockAppData.values.reduce(0) { $0 + $1.wifiBytes }
        
        let summary = DataUsageSummary(
            period: currentPeriod,
            totalCellularBytes: totalCellular,
            totalWifiBytes: totalWifi,
            appUsages: Array(mockAppData.values),
            timestamp: Date()
        )
        
        await MainActor.run {
            self.currentSummary = summary
            self.addToHistory(summary)
            self.lastUpdateTime = Date()
        }
    }
    
    private func getUsageMultiplier(for bundleId: String) -> Double {
        // Different apps have different data usage patterns
        switch bundleId {
        case let id where id.contains("safari") || id.contains("netflix") || id.contains("youtube"):
            return 10.0 // High usage apps
        case let id where id.contains("music") || id.contains("spotify"):
            return 5.0 // Medium usage apps
        case let id where id.contains("mail") || id.contains("messages"):
            return 1.0 // Low usage apps
        default:
            return 2.0 // Default
        }
    }
    
    private func addToHistory(_ summary: DataUsageSummary) {
        dataUsageHistory.append(summary)
        
        // Keep only last 100 entries to prevent memory issues
        if dataUsageHistory.count > 100 {
            dataUsageHistory.removeFirst()
        }
    }
    
    // MARK: - Network Monitoring
    
    private func startNetworkMonitoring() {
        networkMonitor = NWPathMonitor()
        networkMonitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.handleNetworkChange(path: path)
            }
        }
        networkMonitor?.start(queue: networkQueue)
    }
    
    private func stopNetworkMonitoring() {
        networkMonitor?.cancel()
        networkMonitor = nil
    }
    
    private func handleNetworkChange(path: NWPath) {
        // Update data usage based on network changes
        if path.status == .satisfied {
            updateDataUsage()
        }
    }
    
    // MARK: - Data Limits and Alerts
    
    private func checkDataLimits() async {
        guard let summary = currentSummary else { return }
        
        var newAlerts: [DataUsageAlert] = []
        
        for limit in dataUsageLimits where limit.isEnabled {
            let currentUsage: UInt64
            switch limit.limitType {
            case .cellular:
                currentUsage = summary.totalCellularBytes
            case .wifi:
                currentUsage = summary.totalWifiBytes
            case .total:
                currentUsage = summary.totalBytes
            }
            
            let usagePercentage = Double(currentUsage) / Double(limit.limitValue) * 100
            
            for threshold in limit.alertThresholds where threshold.isEnabled {
                if usagePercentage >= threshold.percentage {
                    // Check if we already have an alert for this threshold
                    let hasExistingAlert = activeAlerts.contains { alert in
                        alert.limitType == limit.limitType &&
                        alert.threshold.id == threshold.id &&
                        !alert.isRead
                    }
                    
                    if !hasExistingAlert {
                        let alert = DataUsageAlert(
                            limitType: limit.limitType,
                            currentUsage: currentUsage,
                            limitValue: limit.limitValue,
                            threshold: threshold,
                            timestamp: Date(),
                            isRead: false
                        )
                        newAlerts.append(alert)
                    }
                }
            }
        }
        
        await MainActor.run {
            self.activeAlerts.append(contentsOf: newAlerts)
            
            // Keep only recent alerts (last 50)
            if self.activeAlerts.count > 50 {
                self.activeAlerts = Array(self.activeAlerts.suffix(50))
            }
        }
    }
    
    // MARK: - Public Methods
    
    func getDataUsageForPeriod(_ period: DataUsagePeriod) -> DataUsageSummary? {
        // Filter history by period
        let filteredHistory = dataUsageHistory.filter { summary in
            summary.period.startDate >= period.startDate &&
            summary.period.endDate <= period.endDate
        }
        
        guard !filteredHistory.isEmpty else { return nil }
        
        // Aggregate data for the period
        let totalCellular = filteredHistory.reduce(0) { $0 + $1.totalCellularBytes }
        let totalWifi = filteredHistory.reduce(0) { $0 + $1.totalWifiBytes }
        
        // Aggregate app usage
        var aggregatedApps: [String: AppDataUsage] = [:]
        for summary in filteredHistory {
            for app in summary.appUsages {
                if var existing = aggregatedApps[app.bundleIdentifier] {
                    existing.cellularBytes += app.cellularBytes
                    existing.wifiBytes += app.wifiBytes
                    aggregatedApps[app.bundleIdentifier] = existing
                } else {
                    aggregatedApps[app.bundleIdentifier] = app
                }
            }
        }
        
        return DataUsageSummary(
            period: period,
            totalCellularBytes: totalCellular,
            totalWifiBytes: totalWifi,
            appUsages: Array(aggregatedApps.values),
            timestamp: Date()
        )
    }
    
    func getChartData(for period: DataUsagePeriod.PeriodType) -> [DataUsageChartData] {
        let periodRange = period.dateRange
        let filteredHistory = dataUsageHistory.filter { summary in
            summary.period.startDate >= periodRange.start &&
            summary.period.endDate <= periodRange.end
        }
        
        return filteredHistory.map { summary in
            DataUsageChartData(
                date: summary.timestamp,
                cellularBytes: summary.totalCellularBytes,
                wifiBytes: summary.totalWifiBytes,
                totalBytes: summary.totalBytes
            )
        }
    }
    
    func getStatistics(for period: DataUsagePeriod) -> DataUsageStatistics? {
        guard let summary = getDataUsageForPeriod(period) else { return nil }
        
        let filteredHistory = dataUsageHistory.filter { s in
            s.period.startDate >= period.startDate &&
            s.period.endDate <= period.endDate
        }
        
        let averageDailyUsage = filteredHistory.isEmpty ? 0 : filteredHistory.reduce(0) { $0 + $1.totalBytes } / UInt64(filteredHistory.count)
        let peakUsage = filteredHistory.map { $0.totalBytes }.max() ?? 0
        let peakUsageDate = filteredHistory.first { $0.totalBytes == peakUsage }?.timestamp ?? Date()
        
        let sortedApps = summary.appUsages.sorted { $0.totalBytes > $1.totalBytes }
        
        return DataUsageStatistics(
            period: period,
            averageDailyUsage: averageDailyUsage,
            peakUsage: peakUsage,
            peakUsageDate: peakUsageDate,
            totalApps: summary.appUsages.count,
            mostUsedApp: sortedApps.first,
            leastUsedApp: sortedApps.last
        )
    }
    
    // MARK: - Limit Management
    
    func addDataLimit(_ limit: DataUsageLimit) {
        dataUsageLimits.append(limit)
        savePreferences()
    }
    
    func updateDataLimit(_ limit: DataUsageLimit) {
        if let index = dataUsageLimits.firstIndex(where: { $0.id == limit.id }) {
            dataUsageLimits[index] = limit
            savePreferences()
        }
    }
    
    func deleteDataLimit(_ limit: DataUsageLimit) {
        dataUsageLimits.removeAll { $0.id == limit.id }
        savePreferences()
    }
    
    func toggleDataLimit(_ limit: DataUsageLimit) {
        if let index = dataUsageLimits.firstIndex(where: { $0.id == limit.id }) {
            var updatedLimit = dataUsageLimits[index]
            updatedLimit = DataUsageLimit(
                limitType: updatedLimit.limitType,
                limitValue: updatedLimit.limitValue,
                periodType: updatedLimit.periodType,
                isEnabled: !updatedLimit.isEnabled,
                alertThresholds: updatedLimit.alertThresholds,
                createdAt: updatedLimit.createdAt,
                updatedAt: Date()
            )
            dataUsageLimits[index] = updatedLimit
            savePreferences()
        }
    }
    
    // MARK: - Alert Management
    
    func markAlertAsRead(_ alert: DataUsageAlert) {
        if let index = activeAlerts.firstIndex(where: { $0.id == alert.id }) {
            var updatedAlert = activeAlerts[index]
            updatedAlert = DataUsageAlert(
                limitType: updatedAlert.limitType,
                currentUsage: updatedAlert.currentUsage,
                limitValue: updatedAlert.limitValue,
                threshold: updatedAlert.threshold,
                timestamp: updatedAlert.timestamp,
                isRead: true
            )
            activeAlerts[index] = updatedAlert
        }
    }
    
    func dismissAlert(_ alert: DataUsageAlert) {
        activeAlerts.removeAll { $0.id == alert.id }
    }
    
    func clearAllAlerts() {
        activeAlerts.removeAll()
    }
    
    // MARK: - Preferences
    
    func updatePreferences(_ newPreferences: DataUsagePreferences) {
        preferences = newPreferences
        savePreferences()
    }
    
    private func savePreferences() {
        // In a real app, you'd save to UserDefaults or Core Data
        // For now, we'll just update the in-memory preferences
    }
    
    // MARK: - Reset Methods
    
    func resetDataUsage() {
        // Reset all mock data
        for (bundleId, _) in mockAppData {
            mockAppData[bundleId]?.cellularBytes = 0
            mockAppData[bundleId]?.wifiBytes = 0
        }
        
        dataUsageHistory.removeAll()
        currentSummary = nil
        updateDataUsage()
    }
    
    func resetDataUsageForPeriod(_ period: DataUsagePeriod.PeriodType) {
        let periodRange = period.dateRange
        
        // Remove history entries for the period
        dataUsageHistory.removeAll { summary in
            summary.period.startDate >= periodRange.start &&
            summary.period.endDate <= periodRange.end
        }
        
        // Reset current summary if it's within the period
        if let summary = currentSummary,
           summary.period.startDate >= periodRange.start &&
           summary.period.endDate <= periodRange.end {
            currentSummary = nil
            updateDataUsage()
        }
    }
}

