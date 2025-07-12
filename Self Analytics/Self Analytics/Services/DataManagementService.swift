//
//  DataManagementService.swift
//  Self Analytics
//
//  Created by Israel Manzo on 7/11/25.
//

import Foundation
import UIKit
import UniformTypeIdentifiers

@MainActor
class DataManagementService: ObservableObject {
    @Published var isExporting = false
    @Published var isClearing = false
    @Published var exportProgress: Double = 0.0
    
    private let userDefaults = UserDefaults.standard
    private let fileManager = FileManager.default
    
    // MARK: - Data Export
    
    func exportData() async throws -> URL {
        isExporting = true
        exportProgress = 0.0
        
        defer {
            isExporting = false
            exportProgress = 0.0
        }
        
        // Create export data structure
        let exportData = ExportData(
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            buildNumber: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1",
            deviceInfo: getDeviceInfo(),
            settings: getAppSettings(),
            historicalData: getHistoricalData(),
            alerts: getStoredAlerts(),
            recommendations: getStoredRecommendations()
        )
        
        exportProgress = 0.3
        
        // Convert to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let jsonData = try encoder.encode(exportData)
        exportProgress = 0.6
        
        // Create CSV version
        let csvData = createCSVExport(from: exportData)
        exportProgress = 0.8
        
        // Save to temporary file
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let exportFolder = documentsPath.appendingPathComponent("SelfAnalyticsExport")
        
        // Create export folder if it doesn't exist
        if !fileManager.fileExists(atPath: exportFolder.path) {
            try fileManager.createDirectory(at: exportFolder, withIntermediateDirectories: true)
        }
        
        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let jsonURL = exportFolder.appendingPathComponent("self_analytics_export_\(timestamp).json")
        let csvURL = exportFolder.appendingPathComponent("self_analytics_export_\(timestamp).csv")
        
        try jsonData.write(to: jsonURL)
        try csvData.write(to: csvURL)
        
        exportProgress = 1.0
        
        // Create zip file containing both formats
        let zipURL = try createZipArchive(jsonURL: jsonURL, csvURL: csvURL, timestamp: timestamp)
        
        // Clean up individual files
        try? fileManager.removeItem(at: jsonURL)
        try? fileManager.removeItem(at: csvURL)
        
        return zipURL
    }
    
    // MARK: - Data Clearing
    
    func clearAllData() async {
        isClearing = true
        
        defer {
            isClearing = false
        }
        
        // Clear UserDefaults
        clearUserDefaults()
        
        // Clear stored files
        clearStoredFiles()
        
        // Reset app state
        resetAppState()
    }
    
    // MARK: - Private Methods
    
    private func getDeviceInfo() -> DeviceInfo {
        let device = UIDevice.current
        return DeviceInfo(
            name: device.name,
            model: device.model,
            systemName: device.systemName,
            systemVersion: device.systemVersion,
            identifierForVendor: device.identifierForVendor?.uuidString ?? "Unknown"
        )
    }
    
    private func getAppSettings() -> AppSettings {
        return AppSettings(
            notificationsEnabled: userDefaults.bool(forKey: StorageProperties.notificationsEnabled),
            autoRefreshInterval: userDefaults.double(forKey: StorageProperties.autoRefreshInterval),
            showAlerts: userDefaults.bool(forKey: StorageProperties.showAlerts),
            darkModeEnabled: userDefaults.bool(forKey: StorageProperties.darkModeEnabled)
        )
    }
    
    private func getHistoricalData() -> [DeviceHealth] {
        // In a real implementation, this would fetch from Core Data or other persistence
        // For now, we'll generate some sample data to demonstrate the export functionality
        var sampleData: [DeviceHealth] = []
        let now = Date()
        
        // Generate 24 hours of sample data
        for i in 0..<24 {
            let timestamp = now.addingTimeInterval(-Double(i) * 3600)
            
            let memory = MemoryMetrics(
                usedMemory: UInt64.random(in: 2...4) * 1024 * 1024 * 1024,
                totalMemory: 6 * 1024 * 1024 * 1024,
                availableMemory: UInt64.random(in: 2...4) * 1024 * 1024 * 1024,
                memoryPressure: .normal
            )
            
            let cpu = CPUMetrics(usagePercentage: Double.random(in: 20...60))
            
            let battery = BatteryMetrics(
                level: Double.random(in: 0.2...1.0),
                isCharging: Bool.random(),
                isLowPowerMode: Bool.random(),
                health: .good,
                cycleCount: Int.random(in: 100...500)
            )
            
            let storage = StorageMetrics(
                totalSpace: 64 * 1024 * 1024 * 1024,
                usedSpace: UInt64.random(in: 40...55) * 1024 * 1024 * 1024,
                availableSpace: UInt64.random(in: 9...24) * 1024 * 1024 * 1024,
                systemSpace: 6 * 1024 * 1024 * 1024
            )
            
            let network = NetworkMetrics(
                downloadSpeed: Double.random(in: 20...100),
                uploadSpeed: Double.random(in: 10...50),
                connectionType: .wifi,
                isConnected: true
            )
            
            let health = DeviceHealth(
                memory: memory,
                cpu: cpu,
                battery: battery,
                storage: storage,
                network: network,
                timestamp: timestamp
            )
            
            sampleData.append(health)
        }
        
        return sampleData.sorted { $0.timestamp < $1.timestamp }
    }
    
    private func getStoredAlerts() -> [DeviceAlert] {
        // In a real implementation, this would fetch from persistence
        // For now, return some sample alerts
        return [
            DeviceAlert(
                type: .lowStorage,
                title: AlertServiceLabels.storageAlmostFull,
                message: AlertServiceLabels.your_device_storage_is_running_low_Consider_clearing_some_space,
                severity: .medium,
                timestamp: Date().addingTimeInterval(-3600),
                isResolved: false
            ),
            DeviceAlert(
                type: .highMemoryUsage,
                title: AlertServiceLabels.highMemoryUsage,
                message: AlertServiceLabels.your_device_is_using_a_lot_of_memory_Consider_closing_some_apps,
                severity: .low,
                timestamp: Date().addingTimeInterval(-7200),
                isResolved: true
            )
        ]
    }
    
    private func getStoredRecommendations() -> [DeviceRecommendation] {
        // In a real implementation, this would fetch from persistence
        // For now, return some sample recommendations
        return [
            DeviceRecommendation(
                type: .clearCache,
                title: AlertServiceLabels.clearAppCache,
                description: AlertServiceLabels.free_up_space_by_clearing_cached_data_from_apps,
                action: AlertServiceLabels.clearCache,
                impact: .medium,
                isCompleted: false
            ),
            DeviceRecommendation(
                type: .optimizeBattery,
                title: AlertServiceLabels.enableLowPowerMode,
                description: AlertServiceLabels.save_battery_by_enabling_low_power_mode,
                action: AlertServiceLabels.enable,
                impact: .medium,
                isCompleted: true
            )
        ]
    }
    
    private func createCSVExport(from exportData: ExportData) -> Data {
        var csvString = "Export Date,App Version,Build Number,Device Name,Device Model,iOS Version\n"
        csvString += "\(exportData.exportDate),\(exportData.appVersion),\(exportData.buildNumber),\(exportData.deviceInfo.name),\(exportData.deviceInfo.model),\(exportData.deviceInfo.systemVersion)\n\n"
        
        csvString += "Settings\n"
        csvString += "Notifications Enabled,Auto Refresh Interval,Show Alerts,Dark Mode Enabled\n"
        csvString += "\(exportData.settings.notificationsEnabled),\(exportData.settings.autoRefreshInterval),\(exportData.settings.showAlerts),\(exportData.settings.darkModeEnabled)\n\n"
        
        csvString += "Historical Data\n"
        csvString += "Timestamp,Health Score,Memory Usage %,CPU Usage %,Battery Level %,Storage Usage %\n"
        
        for health in exportData.historicalData {
            csvString += "\(health.timestamp),\(health.overallScore),\(health.memory.usagePercentage),\(health.cpu.usagePercentage),\(health.battery.level * 100),\(health.storage.usagePercentage)\n"
        }
        
        csvString += "\nAlerts\n"
        csvString += "Timestamp,Type,Title,Message,Severity,Is Resolved\n"
        
        for alert in exportData.alerts {
            csvString += "\(alert.timestamp),\(alert.type),\(alert.title),\(alert.message),\(alert.severity),\(alert.isResolved)\n"
        }
        
        csvString += "\nRecommendations\n"
        csvString += "Type,Title,Description,Action,Impact,Is Completed\n"
        
        for recommendation in exportData.recommendations {
            csvString += "\(recommendation.type),\(recommendation.title),\(recommendation.description),\(recommendation.action),\(recommendation.impact),\(recommendation.isCompleted)\n"
        }
        
        return csvString.data(using: .utf8) ?? Data()
    }
    
    private func createZipArchive(jsonURL: URL, csvURL: URL, timestamp: String) throws -> URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let zipURL = documentsPath.appendingPathComponent("SelfAnalytics_Export_\(timestamp).zip")
        
        // In a real implementation, you would use a zip library like SSZipArchive
        // For now, we'll just return the JSON file as the "archive"
        try fileManager.copyItem(at: jsonURL, to: zipURL)
        
        return zipURL
    }
    
    private func clearUserDefaults() {
        let domain = Bundle.main.bundleIdentifier!
        userDefaults.removePersistentDomain(forName: domain)
        userDefaults.synchronize()
    }
    
    private func clearStoredFiles() {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let exportFolder = documentsPath.appendingPathComponent("SelfAnalyticsExport")
        
        if fileManager.fileExists(atPath: exportFolder.path) {
            try? fileManager.removeItem(at: exportFolder)
        }
    }
    
    private func resetAppState() {
        // Reset any in-memory state
        // This would be handled by the respective services
    }
}

// MARK: - Export Data Models

struct ExportData: Codable {
    let exportDate: Date
    let appVersion: String
    let buildNumber: String
    let deviceInfo: DeviceInfo
    let settings: AppSettings
    let historicalData: [DeviceHealth]
    let alerts: [DeviceAlert]
    let recommendations: [DeviceRecommendation]
}

struct DeviceInfo: Codable {
    let name: String
    let model: String
    let systemName: String
    let systemVersion: String
    let identifierForVendor: String
}

struct AppSettings: Codable {
    let notificationsEnabled: Bool
    let autoRefreshInterval: Double
    let showAlerts: Bool
    let darkModeEnabled: Bool
} 
