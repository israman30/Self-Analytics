import Foundation
import UIKit

@MainActor
class AlertService: ObservableObject {
    @Published var activeAlerts: [DeviceAlert] = []
    @Published var recommendations: [DeviceRecommendation] = []
    
    private let metricsService: DeviceMetricsService
    
    init(metricsService: DeviceMetricsService) {
        self.metricsService = metricsService
        setupObservers()
    }
    
    private func setupObservers() {
        // Monitor metrics changes to generate alerts
        Task {
            for await health in metricsService.$currentHealth.values {
                if let health = health {
                    await analyzeAndGenerateAlerts(for: health)
                    await generateRecommendations(for: health)
                }
            }
        }
    }
    
    private func analyzeAndGenerateAlerts(for health: DeviceHealth) async {
        var newAlerts: [DeviceAlert] = []
        
        // Storage alerts
        if health.storage.isLowStorage {
            let alert = DeviceAlert(
                type: .lowStorage,
                title: "Storage Almost Full",
                message: "Your device storage is \(String(format: "%.1f", health.storage.usagePercentage))% full. Consider freeing up space.",
                severity: .high,
                timestamp: Date(),
                isResolved: false
            )
            newAlerts.append(alert)
        }
        
        // Memory alerts
        if health.memory.isHighUsage {
            let alert = DeviceAlert(
                type: .highMemoryUsage,
                title: "High Memory Usage",
                message: "Memory usage is at \(String(format: "%.1f", health.memory.usagePercentage))%. Close unused apps to improve performance.",
                severity: .medium,
                timestamp: Date(),
                isResolved: false
            )
            newAlerts.append(alert)
        }
        
        // CPU alerts
        if health.cpu.isHighUsage {
            let alert = DeviceAlert(
                type: .highCPUUsage,
                title: "High CPU Usage",
                message: "CPU usage is at \(String(format: "%.1f", health.cpu.usagePercentage))%. This may affect battery life.",
                severity: .medium,
                timestamp: Date(),
                isResolved: false
            )
            newAlerts.append(alert)
        }
        
        // Battery alerts
        if health.battery.isLowBattery {
            let alert = DeviceAlert(
                type: .lowBattery,
                title: "Low Battery",
                message: "Battery level is at \(String(format: "%.0f", health.battery.level * 100))%. Connect to power soon.",
                severity: .medium,
                timestamp: Date(),
                isResolved: false
            )
            newAlerts.append(alert)
        }
        
        if health.battery.health == .poor {
            let alert = DeviceAlert(
                type: .poorBatteryHealth,
                title: "Poor Battery Health",
                message: "Your battery health is poor. Consider replacing the battery for better performance.",
                severity: .low,
                timestamp: Date(),
                isResolved: false
            )
            newAlerts.append(alert)
        }
        
        // Network alerts
        if health.network.isSlowConnection {
            let alert = DeviceAlert(
                type: .slowNetwork,
                title: "Slow Network Connection",
                message: "Your network speed is slow (\(String(format: "%.1f", health.network.downloadSpeed)) Mbps). Check your connection.",
                severity: .low,
                timestamp: Date(),
                isResolved: false
            )
            newAlerts.append(alert)
        }
        
        // Check for iOS updates
        await checkForSystemUpdates()
        
        // Add new alerts
        for alert in newAlerts {
            if !activeAlerts.contains(where: { $0.type == alert.type && !$0.isResolved }) {
                activeAlerts.append(alert)
            }
        }
        
        // Clean up resolved alerts
        activeAlerts.removeAll { $0.isResolved }
    }
    
    private func generateRecommendations(for health: DeviceHealth) async {
        var newRecommendations: [DeviceRecommendation] = []
        
        // Storage recommendations
        if health.storage.usagePercentage > 80 {
            let recommendation = DeviceRecommendation(
                type: .clearCache,
                title: "Clear App Cache",
                description: "Free up space by clearing cached data from apps",
                action: "Clear Cache",
                impact: .medium,
                isCompleted: false
            )
            newRecommendations.append(recommendation)
            
            let largeFilesRecommendation = DeviceRecommendation(
                type: .deleteLargeFiles,
                title: "Review Large Files",
                description: "Check for large photos, videos, or downloads you can delete",
                action: "Review Files",
                impact: .high,
                isCompleted: false
            )
            newRecommendations.append(largeFilesRecommendation)
        }
        
        // Battery recommendations
        if health.battery.level < 0.5 && !health.battery.isCharging {
            let recommendation = DeviceRecommendation(
                type: .optimizeBattery,
                title: "Enable Low Power Mode",
                description: "Save battery by enabling Low Power Mode",
                action: "Enable",
                impact: .medium,
                isCompleted: false
            )
            newRecommendations.append(recommendation)
        }
        
        // Network recommendations
        if health.network.isSlowConnection {
            let recommendation = DeviceRecommendation(
                type: .runSpeedTest,
                title: "Run Network Speed Test",
                description: "Check your actual network performance",
                action: "Test Speed",
                impact: .low,
                isCompleted: false
            )
            newRecommendations.append(recommendation)
        }
        
        // Security recommendations
        let securityRecommendation = DeviceRecommendation(
            type: .checkPermissions,
            title: "Review App Permissions",
            description: "Check which apps have access to your data",
            action: "Review",
            impact: .medium,
            isCompleted: false
        )
        newRecommendations.append(securityRecommendation)
        
        // Update recommendations
        let updateRecommendation = DeviceRecommendation(
            type: .updateApps,
            title: "Update Apps",
            description: "Keep your apps updated for security and performance",
            action: "Update",
            impact: .medium,
            isCompleted: false
        )
        newRecommendations.append(updateRecommendation)
        
        // Replace existing recommendations
        recommendations = newRecommendations
    }
    
    private func checkForSystemUpdates() async {
        // In a real app, you'd check for iOS updates
        // For now, we'll simulate this
        let hasUpdate = Bool.random()
        
        if hasUpdate {
            let alert = DeviceAlert(
                type: .securityUpdate,
                title: "iOS Update Available",
                message: "A new iOS update is available with security improvements.",
                severity: .medium,
                timestamp: Date(),
                isResolved: false
            )
            
            if !activeAlerts.contains(where: { $0.type == .securityUpdate && !$0.isResolved }) {
                activeAlerts.append(alert)
            }
        }
    }
    
    // MARK: - Alert Management
    
    func resolveAlert(_ alert: DeviceAlert) {
        if let index = activeAlerts.firstIndex(where: { $0.id == alert.id }) {
            activeAlerts[index] = DeviceAlert(
                type: alert.type,
                title: alert.title,
                message: alert.message,
                severity: alert.severity,
                timestamp: alert.timestamp,
                isResolved: true
            )
        }
    }
    
    func dismissAlert(_ alert: DeviceAlert) {
        activeAlerts.removeAll { $0.id == alert.id }
    }
    
    func completeRecommendation(_ recommendation: DeviceRecommendation) {
        if let index = recommendations.firstIndex(where: { $0.id == recommendation.id }) {
            recommendations[index] = DeviceRecommendation(
                type: recommendation.type,
                title: recommendation.title,
                description: recommendation.description,
                action: recommendation.action,
                impact: recommendation.impact,
                isCompleted: true
            )
        }
    }
    
    // MARK: - Quick Actions
    
    func clearSafariCache() {
        // In a real app, you'd implement actual cache clearing
        // For now, we'll just mark the recommendation as completed
        if let cacheRecommendation = recommendations.first(where: { $0.type == .clearCache }) {
            completeRecommendation(cacheRecommendation)
        }
    }
    
    func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
    
    func openAppStore() {
        if let appStoreURL = URL(string: "itms-apps://itunes.apple.com/app/id") {
            UIApplication.shared.open(appStoreURL)
        }
    }
} 