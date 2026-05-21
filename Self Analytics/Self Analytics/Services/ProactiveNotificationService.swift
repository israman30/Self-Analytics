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
import Network
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
        static let lastHighCPUNotification = "proactive_lastHighCPUNotification"
        static let lastWiFiLossNotification = "proactive_lastWiFiLossNotification"
        static let lastNetworkDisconnectedNotification = "proactive_lastNetworkDisconnectedNotification"
        static let lastLowHealthScoreNotification = "proactive_lastLowHealthScoreNotification"
        static let lastIOSUpdateNotification = "proactive_lastIOSUpdateNotification"
        static let lastBatteryLevel = "proactive_lastBatteryLevel"
        static let lastBatteryCheckTime = "proactive_lastBatteryCheckTime"
        static let lastObservedHealthScore = "proactive_lastObservedHealthScore"
        static let lastObservedConnectionType = "proactive_lastObservedConnectionType"
    }
    
    // MARK: - Thresholds
    
    private let storageWarningThreshold: Double = 90.0
    private let memoryPressureWarningThreshold: Double = 70.0
    private let memoryPressureCriticalThreshold: Double = 85.0
    private let cpuHighUsageThreshold: Double = 85.0
    private let lowHealthScoreThreshold: Int = 60
    private let minimumSafeIOSMajorVersion: Int = 18
    private let batteryDrainThresholdPerHour: Double = 15.0 // % drop per hour
    private let notificationCooldown: TimeInterval = 3600 // 1 hour between same-type notifications
    private let networkNotificationCooldown: TimeInterval = 10 * 60 // 10 minutes
    private let iOSUpdateNotificationCooldown: TimeInterval = 24 * 3600 // 24 hours
    
    private init() {}
    
    // MARK: - Setup
    
    /// Call at app launch to register background tasks and restore scheduling.
    func configure() {
        registerBackgroundTasks()
        Task { await refreshScheduling() }
    }
    
    /// Call when app enters foreground to check metrics and potentially send notifications.
    func checkMetricsAndNotifyIfNeeded() {
        guard areAlertsEnabled else { return }
        
        let metrics = gatherMetrics()
        
        checkLowStorage(metrics: metrics)
        checkRAMPressure(metrics: metrics)
        checkHighCPU(metrics: metrics)
        checkNetworkConnectivity(metrics: metrics)
        checkIOSUpdateRecommendation()
        checkBatteryDrain(metrics: metrics)
    }
    
    /// Called from in-app foreground monitoring when a fresh `DeviceHealth` snapshot is available.
    /// Uses the same notification preferences + cooldown behavior as background checks.
    func handleForegroundHealthUpdate(_ health: DeviceHealth) {
        guard areAlertsEnabled else { return }
        
        // iOS update recommendation (checked at most once/day; avoid doing it on every tick).
        checkIOSUpdateRecommendation()
        
        // CPU
        if health.cpu.usagePercentage >= cpuHighUsageThreshold,
           shouldSendNotification(key: StorageKeys.lastHighCPUNotification) {
            sendNotification(
                identifier: "high-cpu",
                title: ProactiveNotificationLabels.highCpuTitle,
                body: String(format: ProactiveNotificationLabels.highCpuBody, Int(health.cpu.usagePercentage.rounded()))
            )
            userDefaults.set(Date(), forKey: StorageKeys.lastHighCPUNotification)
        }
        
        // Health score (only computed reliably from `DeviceHealth`)
        let score = health.overallScore
        let lastScore = userDefaults.object(forKey: StorageKeys.lastObservedHealthScore) as? Int ?? score
        userDefaults.set(score, forKey: StorageKeys.lastObservedHealthScore)
        
        let drop = lastScore - score
        let shouldWarnScore = score <= lowHealthScoreThreshold || (drop >= 20 && score < 80)
        if shouldWarnScore,
           shouldSendNotification(key: StorageKeys.lastLowHealthScoreNotification) {
            sendNotification(
                identifier: "low-health-score",
                title: ProactiveNotificationLabels.lowHealthScoreTitle,
                body: String(format: ProactiveNotificationLabels.lowHealthScoreBody, score, health.healthStatus.description)
            )
            userDefaults.set(Date(), forKey: StorageKeys.lastLowHealthScoreNotification)
        }
    }
    
    /// Called from network monitoring when the network status changes.
    func handleNetworkStatusTransition(previous: NetworkStatus, current: NetworkStatus) {
        guard areAlertsEnabled else { return }
        guard previous != current else { return }
        
        var didNotifyWiFiLoss = false
        
        // Losing Wi‑Fi specifically (Wi‑Fi -> anything else)
        if previous == .wifiConnected, current != .wifiConnected,
           shouldSendNotification(key: StorageKeys.lastWiFiLossNotification, cooldown: networkNotificationCooldown) {
            let body: String
            switch current {
            case .cellularConnected:
                body = ProactiveNotificationLabels.wifiLostToCellularBody
            case .ethernetConnected, .connected:
                body = ProactiveNotificationLabels.wifiLostSwitchedBody
            default:
                body = ProactiveNotificationLabels.wifiLostDisconnectedBody
            }
            
            sendNotification(
                identifier: "wifi-lost",
                title: ProactiveNotificationLabels.wifiLostTitle,
                body: body
            )
            userDefaults.set(Date(), forKey: StorageKeys.lastWiFiLossNotification)
            didNotifyWiFiLoss = true
        }
        
        // Full network disconnect
        if !didNotifyWiFiLoss, previous.isConnected, !current.isConnected,
           shouldSendNotification(key: StorageKeys.lastNetworkDisconnectedNotification, cooldown: networkNotificationCooldown) {
            sendNotification(
                identifier: "network-disconnected",
                title: ProactiveNotificationLabels.networkDisconnectedTitle,
                body: ProactiveNotificationLabels.networkDisconnectedBody
            )
            userDefaults.set(Date(), forKey: StorageKeys.lastNetworkDisconnectedNotification)
        }
    }
    
    // MARK: - Permission & Background Tasks

    /// Requests notification authorization as a direct result of a user action (e.g. onboarding / toggle).
    /// Returns `true` if the system granted authorization.
    @MainActor
    func requestAuthorizationFromUser() async -> Bool {
        await withCheckedContinuation { continuation in
            notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    @MainActor
    func refreshScheduling() async {
        let settings = await getNotificationSettings()
        let authorized = settings.authorizationStatus == .authorized
            || settings.authorizationStatus == .provisional
            || settings.authorizationStatus == .ephemeral

        let notificationsEnabled = userDefaults.bool(forKey: StorageProperties.notificationsEnabled)
        let weeklyEnabled = userDefaults.bool(forKey: StorageProperties.weeklyHealthSummaryEnabled)

        if authorized && notificationsEnabled {
            scheduleNextBackgroundRefresh()
        } else {
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: "com.selfanalytics.metrics.refresh")
        }

        if authorized && notificationsEnabled && weeklyEnabled {
            scheduleWeeklySummaryNotification()
        } else {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [Self.weeklySummaryIdentifier])
        }
    }

    @MainActor
    func handleUserEnabledNotifications() async -> Bool {
        let settings = await getNotificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = await requestAuthorizationFromUser()
        }
        await refreshScheduling()
        let updated = await getNotificationSettings()
        return updated.authorizationStatus == .authorized
            || updated.authorizationStatus == .provisional
            || updated.authorizationStatus == .ephemeral
    }

    func handleUserDisabledNotifications() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: "com.selfanalytics.metrics.refresh")
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [Self.weeklySummaryIdentifier])
    }

    private func getNotificationSettings() async -> UNNotificationSettings {
        await withCheckedContinuation { continuation in
            notificationCenter.getNotificationSettings { settings in
                continuation.resume(returning: settings)
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
        let cpuUsagePercent: Double
        let networkStatus: NetworkStatus
        let connectionType: NetworkConnectionType
        let batteryLevel: Double
        let isCharging: Bool
    }
    
    private func gatherMetrics() -> QuickMetrics {
        let storageUsage = getStorageUsagePercent()
        let (memoryUsage, memoryPressure) = getMemoryMetrics()
        let cpuUsage = getEstimatedCPUUsage()
        let (networkStatus, connectionType) = getNetworkSnapshot()
        let (batteryLevel, isCharging) = getBatteryMetrics()
        
        return QuickMetrics(
            storageUsagePercent: storageUsage,
            memoryUsagePercent: memoryUsage,
            memoryPressure: memoryPressure,
            cpuUsagePercent: cpuUsage,
            networkStatus: networkStatus,
            connectionType: connectionType,
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
    
    private func getEstimatedCPUUsage() -> Double {
        // Same heuristic as `DeviceMetricsService` (iOS doesn't provide direct CPU usage APIs).
        let processInfo = ProcessInfo.processInfo
        let systemUptime = processInfo.systemUptime
        
        let totalMemory = processInfo.physicalMemory
        let usedMemory = getUsedMemory()
        let availableFraction = totalMemory > 0 ? Double(totalMemory - usedMemory) / Double(totalMemory) : 0
        
        let baseUsage = 20.0
        let memoryFactor = (1.0 - availableFraction) * 30.0
        let timeFactor = sin(systemUptime / 60.0) * 10.0
        
        return min(100.0, max(0.0, baseUsage + memoryFactor + timeFactor))
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
        let body = String(
            format: ProactiveNotificationLabels.ramPressureBody,
            Int(metrics.memoryUsagePercent.rounded()),
            metrics.memoryPressure == .critical ? "critical" : "high"
        )
        sendNotification(identifier: "ram-pressure", title: title, body: body)
        userDefaults.set(Date(), forKey: StorageKeys.lastRAMPressureNotification)
    }
    
    private func checkHighCPU(metrics: QuickMetrics) {
        guard metrics.cpuUsagePercent >= cpuHighUsageThreshold else { return }
        guard shouldSendNotification(key: StorageKeys.lastHighCPUNotification) else { return }
        
        sendNotification(
            identifier: "high-cpu",
            title: ProactiveNotificationLabels.highCpuTitle,
            body: String(format: ProactiveNotificationLabels.highCpuBody, Int(metrics.cpuUsagePercent.rounded()))
        )
        userDefaults.set(Date(), forKey: StorageKeys.lastHighCPUNotification)
    }
    
    private func checkIOSUpdateRecommendation() {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        guard version.majorVersion < minimumSafeIOSMajorVersion else { return }
        guard shouldSendNotification(key: StorageKeys.lastIOSUpdateNotification, cooldown: iOSUpdateNotificationCooldown) else { return }
        
        sendNotification(
            identifier: "ios-update",
            title: ProactiveNotificationLabels.iOSUpdateTitle,
            body: String(format: ProactiveNotificationLabels.iOSUpdateBody, version.majorVersion, minimumSafeIOSMajorVersion)
        )
        userDefaults.set(Date(), forKey: StorageKeys.lastIOSUpdateNotification)
    }
    
    private func checkNetworkConnectivity(metrics: QuickMetrics) {
        // Track connection type changes across background refreshes.
        let previousRaw = userDefaults.object(forKey: StorageKeys.lastObservedConnectionType) as? String
        let previousType = previousRaw.flatMap { NetworkConnectionType.fromPersistedString($0) }
        userDefaults.set(metrics.connectionType.persistedString, forKey: StorageKeys.lastObservedConnectionType)
        
        var didNotifyWiFiLoss = false
        if previousType == .wifi, metrics.connectionType != .wifi,
           shouldSendNotification(key: StorageKeys.lastWiFiLossNotification, cooldown: networkNotificationCooldown) {
            let body = metrics.connectionType == .cellular
                ? ProactiveNotificationLabels.wifiLostToCellularBody
                : ProactiveNotificationLabels.wifiLostDisconnectedBody
            
            sendNotification(identifier: "wifi-lost", title: ProactiveNotificationLabels.wifiLostTitle, body: body)
            userDefaults.set(Date(), forKey: StorageKeys.lastWiFiLossNotification)
            didNotifyWiFiLoss = true
        }
        
        if !didNotifyWiFiLoss, (metrics.networkStatus == .disconnected || metrics.networkStatus == .notFound),
           shouldSendNotification(key: StorageKeys.lastNetworkDisconnectedNotification, cooldown: networkNotificationCooldown) {
            sendNotification(
                identifier: "network-disconnected",
                title: ProactiveNotificationLabels.networkDisconnectedTitle,
                body: ProactiveNotificationLabels.networkDisconnectedBody
            )
            userDefaults.set(Date(), forKey: StorageKeys.lastNetworkDisconnectedNotification)
        }
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
    
    private func shouldSendNotification(key: String, cooldown: TimeInterval? = nil) -> Bool {
        guard let lastSent = userDefaults.object(forKey: key) as? Date else { return true }
        return Date().timeIntervalSince(lastSent) >= (cooldown ?? notificationCooldown)
    }
    
    private func sendNotification(identifier: String, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "\(identifier)-\(UUID().uuidString)", content: content, trigger: nil)
        notificationCenter.add(request)
    }
    
    private var areAlertsEnabled: Bool {
        UserDefaults.standard.bool(forKey: StorageProperties.notificationsEnabled)
            && UserDefaults.standard.bool(forKey: StorageProperties.showAlerts)
    }
    
    private func getNetworkSnapshot() -> (status: NetworkStatus, connectionType: NetworkConnectionType) {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "ProactiveNotificationService.NetworkSnapshot")
        let semaphore = DispatchSemaphore(value: 0)
        
        var status: NetworkStatus = .unknown
        var type: NetworkConnectionType = .none
        
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                if path.usesInterfaceType(.wifi) {
                    status = .wifiConnected
                    type = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    status = .cellularConnected
                    type = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    status = .ethernetConnected
                    type = .ethernet
                } else {
                    status = .connected
                    type = .wifi
                }
            } else {
                if path.availableInterfaces.isEmpty {
                    status = .notFound
                } else {
                    status = .disconnected
                }
                type = .none
            }
            semaphore.signal()
        }
        
        monitor.start(queue: queue)
        _ = semaphore.wait(timeout: .now() + 0.6)
        monitor.cancel()
        return (status, type)
    }
    
    // MARK: - Weekly Health Summary (Sunday 9 AM)
    
    private static let weeklySummaryIdentifier = "com.selfanalytics.weeklyHealthSummary"
    
    private func scheduleWeeklySummaryNotification() {
        let (title, body) = generateWeeklySummaryContent()
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.weekday = 1  // Sunday
        dateComponents.hour = 9
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: Self.weeklySummaryIdentifier, content: content, trigger: trigger)
        notificationCenter.add(request)
    }
    
    private func generateWeeklySummaryContent() -> (title: String, body: String) {
        let title = "Health Summary"
        
        guard let comparison = WeeklyMetricsStorage.shared.weeklyComparison() else {
            return (title, "Keep using Self Analytics to get your weekly device health insights!")
        }
        
        let (thisMem, thisCpu, _) = comparison.thisWeek
        let (lastMem, lastCpu, _) = comparison.lastWeek
        
        // Prefer the most positive change for the message
        let cpuChange = lastCpu > 0 ? (lastCpu - thisCpu) / lastCpu * 100 : 0
        let memChange = lastMem > 0 ? (lastMem - thisMem) / lastMem * 100 : 0
        
        if cpuChange >= 10 {
            return (title, String(format: "Your device ran %.0f%% cooler this week!", cpuChange))
        }
        if memChange >= 10 {
            return (title, String(format: "Memory usage dropped %.0f%% this week!", memChange))
        }
        if cpuChange >= 5 || memChange >= 5 {
            return (title, "Your device performed better this week. Keep it up!")
        }
        if thisCpu > lastCpu + 15 || thisMem > lastMem + 15 {
            return (title, "Your device worked harder this week. Consider closing unused apps.")
        }
        
        return (title, "Your device health stayed consistent this week.")
    }
}

// MARK: - Labels

private enum ProactiveNotificationLabels {
    static let lowStorageTitle = "Low Storage Warning"
    static let lowStorageBody = "Your storage is %d%% full. Tap for Quick Clean suggestions."
    static let ramPressureTitle = "High Memory Pressure"
    static let ramPressureBody = "Memory usage is %d%% (%@). Close unused apps to improve performance."
    static let batteryDrainTitle = "High Battery Drain Detected"
    static let batteryDrainBody = "Battery drained faster than usual in the last hour. A background process may be the cause."
    
    static let highCpuTitle = "High CPU Usage"
    static let highCpuBody = "CPU usage is around %d%%. Closing heavy apps can help."
    
    static let wifiLostTitle = "Wi‑Fi Connection Changed"
    static let wifiLostDisconnectedBody = "Wi‑Fi is no longer connected. Check your router or network settings."
    static let wifiLostToCellularBody = "Wi‑Fi dropped and you’re now on cellular data."
    static let wifiLostSwitchedBody = "Wi‑Fi is no longer active. Your device switched networks."
    
    static let networkDisconnectedTitle = "Network Disconnected"
    static let networkDisconnectedBody = "No internet connection detected."
    
    static let lowHealthScoreTitle = "Device Health Alert"
    static let lowHealthScoreBody = "Your device health score is %d/100 (%@). Review CPU, memory, and storage to improve it."
    
    static let iOSUpdateTitle = "iOS Update Recommended"
    static let iOSUpdateBody = "You’re on iOS %d. Updating to iOS %d or later is recommended for security fixes."
}

private extension NetworkConnectionType {
    var persistedString: String {
        switch self {
        case .wifi: return "wifi"
        case .cellular: return "cellular"
        case .ethernet: return "ethernet"
        case .none: return "none"
        }
    }
    
    static func fromPersistedString(_ value: String) -> NetworkConnectionType? {
        switch value {
        case "wifi": return .wifi
        case "cellular": return .cellular
        case "ethernet": return .ethernet
        case "none": return .some(.none)
        default: return nil
        }
    }
}

