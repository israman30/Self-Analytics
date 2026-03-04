//
//  ProactiveNotificationService.swift
//  Self Analytics
//
//  Proactively notifies users about device health issues even when the app is closed.
//  Uses Background App Refresh to periodically check metrics and send local notifications.
//

import Foundation
import UIKit
import UserNotifications
import BackgroundTasks
import Darwin
@preconcurrency import Darwin

/// Service that monitors device metrics in the background and sends proactive notifications
/// when storage, battery drain, or RAM pressure exceed thresholds.
final class ProactiveNotificationService {
    static let shared = ProactiveNotificationService()
    
    private let userDefaults = UserDefaults.standard
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - UserDefaults Keys
    
    private enum StorageKeys {
        static let lastLowStorageNotification = "proactive_lastLowStorageNotification"
        static let lastRAMPressureNotification = "proactive_lastRAMPressureNotification"
        static let lastBatteryDrainNotification = "proactive_lastBatteryDrainNotification"
        static let lastBatteryLevel = "proactive_lastBatteryLevel"
        static let lastBatteryCheckTime = "proactive_lastBatteryCheckTime"
    }
    
    // MARK: - Thresholds
    
    private let storageWarningThreshold: Double = 90.0
    private let memoryPressureWarningThreshold: Double = 70.0
    private let memoryPressureCriticalThreshold: Double = 85.0
    private let batteryDrainThresholdPerHour: Double = 15.0 // % drop per hour
    private let notificationCooldown: TimeInterval = 3600 // 1 hour between same-type notifications
    
    private init() {}
    
    // MARK: - Setup
    
    /// Call at app launch to request permissions and schedule background tasks.
    func configure() {
        requestNotificationPermission()
        registerBackgroundTasks()
        scheduleNextBackgroundRefresh()
    }
    
    /// Call when app enters foreground to check metrics and potentially send notifications.
    func checkMetricsAndNotifyIfNeeded() {
        guard UserDefaults.standard.bool(forKey: StorageProperties.notificationsEnabled) else { return }
        guard UserDefaults.standard.bool(forKey: StorageProperties.showAlerts) else { return }
        
        let metrics = gatherMetrics()
        
        checkLowStorage(metrics: metrics)
        checkRAMPressure(metrics: metrics)
        checkBatteryDrain(metrics: metrics)
    }
    
    // MARK: - Permission & Background Tasks
    
    private func requestNotificationPermission() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                self.scheduleNextBackgroundRefresh()
            }
        }
    }
    
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.selfanalytics.metrics.refresh",
            using: nil
        ) { task in
            self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
    }
    
    func scheduleNextBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.selfanalytics.metrics.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes minimum
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // System may reject if too many tasks; will retry on next launch
        }
    }
    
    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        scheduleNextBackgroundRefresh()
        
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        checkMetricsAndNotifyIfNeeded()
        task.setTaskCompleted(success: true)
    }
    
    // MARK: - Metrics Gathering (runs in any context)
    
    private struct QuickMetrics {
        let storageUsagePercent: Double
        let memoryUsagePercent: Double
        let memoryPressure: MemoryPressure
        let batteryLevel: Double
        let isCharging: Bool
    }
    
    private func gatherMetrics() -> QuickMetrics {
        let storageUsage = getStorageUsagePercent()
        let (memoryUsage, memoryPressure) = getMemoryMetrics()
        let (batteryLevel, isCharging) = getBatteryMetrics()
        
        return QuickMetrics(
            storageUsagePercent: storageUsage,
            memoryUsagePercent: memoryUsage,
            memoryPressure: memoryPressure,
            batteryLevel: batteryLevel,
            isCharging: isCharging
        )
    }
    
    private func getStorageUsagePercent() -> Double {
        let fileManager = FileManager.default
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: NSHomeDirectory())
            let total = attributes[.systemSize] as? UInt64 ?? 1
            let free = attributes[.systemFreeSize] as? UInt64 ?? 0
            let used = total - free
            guard total > 0 else { return 0 }
            return Double(used) / Double(total) * 100
        } catch {
            return 0
        }
    }
    
    private func getMemoryMetrics() -> (usagePercent: Double, pressure: MemoryPressure) {
        let processInfo = ProcessInfo.processInfo
        let total = processInfo.physicalMemory
        let used = getUsedMemory()
        let usagePercent = total > 0 ? Double(used) / Double(total) * 100 : 0
        
        let pressure: MemoryPressure
        switch usagePercent {
        case 0..<70: pressure = .normal
        case 70..<85: pressure = .warning
        default: pressure = .critical
        }
        return (usagePercent, pressure)
    }
    
    var matchTaskSelf: mach_port_t {
        mach_task_self_
    }
    
    private func getUsedMemory() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let kerr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(matchTaskSelf, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        if kerr == KERN_SUCCESS {
            return UInt64(info.resident_size)
        }
        return ProcessInfo.processInfo.physicalMemory / 2
    }
    
    private func getBatteryMetrics() -> (level: Double, isCharging: Bool) {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        let level = Double(device.batteryLevel >= 0 ? device.batteryLevel : 0)
        let isCharging = device.batteryState == .charging || device.batteryState == .full
        return (level * 100, isCharging)
    }
    
    // MARK: - Alert Checks
    
    private func checkLowStorage(metrics: QuickMetrics) {
        guard metrics.storageUsagePercent >= storageWarningThreshold else { return }
        guard shouldSendNotification(key: StorageKeys.lastLowStorageNotification) else { return }
        
        sendNotification(
            identifier: "low-storage",
            title: ProactiveNotificationLabels.lowStorageTitle,
            body: String(format: ProactiveNotificationLabels.lowStorageBody, Int(metrics.storageUsagePercent))
        )
        userDefaults.set(Date(), forKey: StorageKeys.lastLowStorageNotification)
    }
    
    private func checkRAMPressure(metrics: QuickMetrics) {
        guard metrics.memoryPressure != .normal else { return }
        guard shouldSendNotification(key: StorageKeys.lastRAMPressureNotification) else { return }
        
        let title = ProactiveNotificationLabels.ramPressureTitle
        let body = ProactiveNotificationLabels.ramPressureBody
        sendNotification(identifier: "ram-pressure", title: title, body: body)
        userDefaults.set(Date(), forKey: StorageKeys.lastRAMPressureNotification)
    }
    
    private func checkBatteryDrain(metrics: QuickMetrics) {
        guard !metrics.isCharging else {
            // Reset tracking when charging
            userDefaults.set(metrics.batteryLevel, forKey: StorageKeys.lastBatteryLevel)
            userDefaults.set(Date(), forKey: StorageKeys.lastBatteryCheckTime)
            return
        }
        
        let lastLevel = userDefaults.double(forKey: StorageKeys.lastBatteryLevel)
        let lastTime = userDefaults.object(forKey: StorageKeys.lastBatteryCheckTime) as? Date ?? Date()
        
        // Update tracking
        userDefaults.set(metrics.batteryLevel, forKey: StorageKeys.lastBatteryLevel)
        userDefaults.set(Date(), forKey: StorageKeys.lastBatteryCheckTime)
        
        let hoursSinceLastCheck = Date().timeIntervalSince(lastTime) / 3600
        guard hoursSinceLastCheck >= 0.5 else { return } // Need at least 30 min of data
        
        let drainPerHour = (lastLevel - metrics.batteryLevel) / max(hoursSinceLastCheck, 0.01)
        guard drainPerHour >= batteryDrainThresholdPerHour else { return }
        guard shouldSendNotification(key: StorageKeys.lastBatteryDrainNotification) else { return }
        
        sendNotification(
            identifier: "battery-drain",
            title: ProactiveNotificationLabels.batteryDrainTitle,
            body: ProactiveNotificationLabels.batteryDrainBody
        )
        userDefaults.set(Date(), forKey: StorageKeys.lastBatteryDrainNotification)
    }
    
    private func shouldSendNotification(key: String) -> Bool {
        guard let lastSent = userDefaults.object(forKey: key) as? Date else { return true }
        return Date().timeIntervalSince(lastSent) >= notificationCooldown
    }
    
    private func sendNotification(identifier: String, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "\(identifier)-\(UUID().uuidString)", content: content, trigger: nil)
        notificationCenter.add(request)
    }
}

// MARK: - Labels

private enum ProactiveNotificationLabels {
    static let lowStorageTitle = "Low Storage Warning"
    static let lowStorageBody = "Your storage is %d%% full. Tap for Quick Clean suggestions."
    static let ramPressureTitle = "High Memory Pressure"
    static let ramPressureBody = "Your device is under memory pressure. Restart for optimal performance."
    static let batteryDrainTitle = "High Battery Drain Detected"
    static let batteryDrainBody = "Battery drained faster than usual in the last hour. A background process may be the cause."
}

