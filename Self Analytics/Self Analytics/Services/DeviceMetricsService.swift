//
//  DeviceMetricsService.swift
//  Self Analytics
//
//  Created by Israel Manzo on 7/9/25.
//

import Foundation
import Network
import SystemConfiguration
import UIKit
import WidgetKit

@MainActor
/// Collects device metrics on a timer and publishes the latest `DeviceHealth` snapshot.
///
/// **Implementation**
/// - Runs on the `MainActor` because it drives SwiftUI state (`@Published`) and interacts with UIKit/WidgetKit.
/// - Maintains an `NWPathMonitor` to classify connectivity changes (and to drive network-change notifications).
/// - Produces a `DeviceHealth` snapshot every `updateInterval` seconds while monitoring.
///
/// **Side effects of each update**
/// - Records daily battery/history snapshots for trend charts.
/// - Evaluates foreground proactive notifications (cooldown protected).
/// - Writes a compact widget snapshot and reloads widget timelines.
class DeviceMetricsService: ObservableObject {
    @Published var currentHealth: DeviceHealth?
    @Published var isMonitoring = false
    
    private var timer: Timer?
    /// UI-facing refresh cadence. Keep this modest to avoid battery/CPU churn.
    private let updateInterval: TimeInterval = 5.0 // Update every 5 seconds
    
    init(shouldStartMonitoring: Bool = true) {
        if shouldStartMonitoring {
            startMonitoring()
        }
    }

    convenience init(startMonitoring: Bool = true) {
        self.init(shouldStartMonitoring: startMonitoring)
    }
    
    deinit {
        // Full-screen history dismissal tears down `HistoryMainContent`'s `@StateObject`
        // service instance. Never capture `self` asynchronously here — `[unowned self]` after
        // deallocation crashes ~1s later. Tear down timer + monitor by value instead.
        timer?.invalidate()
        networkMonitor?.cancel()
    }
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        // Start network monitoring
        startNetworkMonitoring()
        
        // Initial update
        updateMetrics()
        
        // Start timer for periodic updates
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMetrics()
            }
        }
    }
    
    func stopMonitoring() {
        isMonitoring = false
        timer?.invalidate()
        timer = nil
        stopNetworkMonitoring()
    }
    
    /// Computes a fresh `DeviceHealth` snapshot and publishes it.
    ///
    /// This is the central "tick" used by the dashboard. It also fans out into persistence (history),
    /// notifications, and widget updates.
    func updateMetrics() {
        let memory = getMemoryMetrics()
        let cpu = getCPUMetrics()
        let battery = getBatteryMetrics()
        let storage = getStorageMetrics()
        let network = getNetworkMetrics()
        
        recordBatterySnapshotIfNeeded(battery)
        
        let health = DeviceHealth(
            memory: memory,
            cpu: cpu,
            battery: battery,
            storage: storage,
            network: network,
            timestamp: Date()
        )
        recordWeeklyMetricsIfNeeded(health)
        currentHealth = health
        
        // Foreground proactive notifications (cooldown-protected).
        ProactiveNotificationService.shared.handleForegroundHealthUpdate(health)
        
        let widgetPayload = health.makeWidgetPayload()
        WidgetSnapshotStore.save(widgetPayload)
        WidgetCenter.shared.reloadTimelines(ofKind: "DevicePerformanceWidget")
    }
    
    // MARK: - Memory Metrics
    
    private func getMemoryMetrics() -> MemoryMetrics {
        let processInfo = ProcessInfo.processInfo
        
        // Get physical memory info
        let totalMemory = processInfo.physicalMemory
        let usedMemory = getUsedMemory()
        let availableMemory = totalMemory - usedMemory
        
        // Determine memory pressure
        let memoryPressure: MemoryPressure
        let usagePercentage = Double(usedMemory) / Double(totalMemory) * 100
        
        switch usagePercentage {
        case 0..<70:
            memoryPressure = .normal
        case 70..<85:
            memoryPressure = .warning
        default:
            memoryPressure = .critical
        }
        
        return MemoryMetrics(
            usedMemory: usedMemory,
            totalMemory: totalMemory,
            availableMemory: availableMemory,
            memoryPressure: memoryPressure
        )
    }
    
    private func getUsedMemory() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }
        
        if kerr == KERN_SUCCESS {
            return UInt64(info.resident_size)
        } else {
            // Fallback to ProcessInfo
            return ProcessInfo.processInfo.physicalMemory / 2 // Rough estimate
        }
    }
    
    // MARK: - CPU Metrics
    private func getCPUMetrics() -> CPUMetrics {
        // iOS does not expose a public, first-party "CPU usage %" for third-party apps.
        // We use a stable heuristic so the UI can still demonstrate trends and drive thresholds.
        let usagePercentage = getEstimatedCPUUsage()
        return CPUMetrics(usagePercentage: usagePercentage)
    }
    
    private func getEstimatedCPUUsage() -> Double {
        // This is a simplified estimation based on system load
        let processInfo = ProcessInfo.processInfo
        let systemUptime = processInfo.systemUptime
        
        // Use a simple heuristic based on available memory and system uptime
        let memoryUsage = Double(ProcessInfo.processInfo.physicalMemory - getUsedMemory()) / Double(ProcessInfo.processInfo.physicalMemory)
        
        // Simulate CPU usage based on memory pressure and time
        let baseUsage = 20.0 // Base CPU usage
        let memoryFactor = (1.0 - memoryUsage) * 30.0 // Higher memory usage = higher CPU
        let timeFactor = sin(systemUptime / 60.0) * 10.0 // Oscillating factor
        
        return min(100.0, max(0.0, baseUsage + memoryFactor + timeFactor))
    }
    
    // MARK: - Battery Metrics
    
    private func getBatteryMetrics() -> BatteryMetrics {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        
        let level = device.batteryLevel
        let isCharging = device.batteryState == .charging || device.batteryState == .full
        let isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        
        // Battery health estimation (iOS doesn't provide direct access)
        let health = estimateBatteryHealth()
        
        return BatteryMetrics(
            level: Double(level),
            isCharging: isCharging,
            isLowPowerMode: isLowPowerMode,
            health: health,
            cycleCount: nil // Not available on iOS
        )
    }
    
    private func estimateBatteryHealth() -> BatteryHealth {
        let device = UIDevice.current
        let level = device.batteryLevel
        
        // Simple heuristic based on battery level and charging behavior
        // In a real app, you might use more sophisticated algorithms
        if level > 0.8 {
            return .excellent
        } else if level > 0.6 {
            return .good
        } else if level > 0.4 {
            return .fair
        } else {
            return .poor
        }
    }
    
    /// Records a battery capacity snapshot once per calendar day for the aging chart.
    private func recordBatterySnapshotIfNeeded(_ battery: BatteryMetrics) {
        let key = "battery_history_last_recorded_date"
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastRecorded = userDefaults.object(forKey: key) as? Date ?? .distantPast
        let lastRecordedDay = calendar.startOfDay(for: lastRecorded)
        
        guard today > lastRecordedDay else { return }
        
        BatteryMetricsHistoryService.shared.recordSnapshot(health: battery.health)
        userDefaults.set(Date(), forKey: key)
    }
    
    /// Records daily metrics for the Weekly Health Summary. Called once per day.
    private func recordWeeklyMetricsIfNeeded(_ health: DeviceHealth) {
        let key = "weekly_metrics_last_recorded_date"
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastRecorded = userDefaults.object(forKey: key) as? Date ?? .distantPast
        let lastRecordedDay = calendar.startOfDay(for: lastRecorded)
        
        guard today > lastRecordedDay else { return }
        
        WeeklyMetricsStorage.shared.recordSnapshot(
            memoryPercent: health.memory.usagePercentage,
            cpuPercent: health.cpu.usagePercentage,
            storagePercent: health.storage.usagePercentage
        )
        userDefaults.set(Date(), forKey: key)
    }
    
    private var userDefaults: UserDefaults { UserDefaults.standard }
    
    // MARK: - Storage Metrics
    private func getStorageMetrics() -> StorageMetrics {
        let fileManager = FileManager.default
        
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: NSHomeDirectory())
            
            let totalSpace = attributes[.systemSize] as? UInt64 ?? 0
            let freeSpace = attributes[.systemFreeSize] as? UInt64 ?? 0
            let usedSpace = totalSpace - freeSpace
            
            // Estimate system space (iOS doesn't provide this directly)
            let systemSpace = totalSpace * 10 / 100 // Assume 10% for system
            
            return StorageMetrics(
                totalSpace: totalSpace,
                usedSpace: usedSpace,
                availableSpace: freeSpace,
                systemSpace: systemSpace
            )
        } catch {
            // Fallback values
            return StorageMetrics(
                totalSpace: 64 * 1024 * 1024 * 1024, // 64GB
                usedSpace: 32 * 1024 * 1024 * 1024, // 32GB
                availableSpace: 32 * 1024 * 1024 * 1024, // 32GB
                systemSpace: 6 * 1024 * 1024 * 1024 // 6GB
            )
        }
    }
    
    // MARK: - Network Metrics
    private var networkMonitor: NWPathMonitor?
    private var networkQueue = DispatchQueue(label: "NetworkMonitor")
    @Published var networkStatus: NetworkStatus = .unknown
    private var currentConnectionType: NetworkConnectionType = .none
    
    private func getNetworkMetrics() -> NetworkMetrics {
        let connectionType = currentConnectionType
        let isConnected = connectionType != .none
        
        // Note: iOS doesn't provide direct speed measurement APIs
        // This would typically require network testing
        let downloadSpeed = estimateDownloadSpeed(connectionType: connectionType)
        let uploadSpeed = estimateUploadSpeed(connectionType: connectionType)
        
        return NetworkMetrics(
            downloadSpeed: downloadSpeed,
            uploadSpeed: uploadSpeed,
            connectionType: connectionType,
            isConnected: isConnected,
            status: networkStatus
        )
    }
    
    private func checkNetworkAvailability() {
        // Check if any network interfaces are available
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkAvailabilityQueue")
        
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                if path.status == .unsatisfied && path.availableInterfaces.isEmpty {
                    self?.networkStatus = .notFound
                    self?.currentConnectionType = .none
                    self?.updateMetrics()
                }
            }
        }
        
        monitor.start(queue: queue)
        
        // Stop monitoring after a short delay
        queue.asyncAfter(deadline: .now() + 1.0) {
            monitor.cancel()
        }
    }
    
    private func startNetworkMonitoring() {
        networkMonitor = NWPathMonitor()
        networkMonitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateNetworkStatus(path: path)
            }
        }
        networkMonitor?.start(queue: networkQueue)
        
        // Initial network availability check
        checkNetworkAvailability()
    }
    
    private var previousNetworkStatus: NetworkStatus = .unknown
    
    private func updateNetworkStatus(path: NWPath) {
        let previous = previousNetworkStatus
        let newStatus: NetworkStatus
        let newConnectionType: NetworkConnectionType
        
        if path.status == .satisfied {
            if path.usesInterfaceType(.wifi) {
                newStatus = .wifiConnected
                newConnectionType = .wifi
            } else if path.usesInterfaceType(.cellular) {
                newStatus = .cellularConnected
                newConnectionType = .cellular
            } else if path.usesInterfaceType(.wiredEthernet) {
                newStatus = .ethernetConnected
                newConnectionType = .ethernet
            } else {
                newStatus = .connected
                // Default to Wi‑Fi for unknown-but-connected paths (consistent with previous logic).
                newConnectionType = .wifi
            }
        } else {
            newStatus = .disconnected
            newConnectionType = .none
        }
        
        ProactiveNotificationService.shared.handleNetworkStatusTransition(previous: previous, current: newStatus)
        
        // Check if connection was restored
        if !previousNetworkStatus.isConnected && newStatus.isConnected {
            networkStatus = .restored
            // Reset to actual status after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.networkStatus = newStatus
                self?.updateMetrics()
            }
        } else {
            networkStatus = newStatus
        }
        
        currentConnectionType = newConnectionType
        previousNetworkStatus = newStatus
        
        // Update metrics when network status changes
        updateMetrics()
    }
    
    private func stopNetworkMonitoring() {
        networkMonitor?.cancel()
        networkMonitor = nil
    }
    
    private func estimateDownloadSpeed(connectionType: NetworkConnectionType) -> Double {
        switch connectionType {
        case .wifi:
            return Double.random(in: 20...100) // 20-100 Mbps
        case .cellular:
            return Double.random(in: 5...50) // 5-50 Mbps
        case .ethernet:
            return Double.random(in: 50...1000) // 50-1000 Mbps
        case .none:
            return 0
        }
    }
    
    private func estimateUploadSpeed(connectionType: NetworkConnectionType) -> Double {
        // Upload speeds are typically slower than download
        return estimateDownloadSpeed(connectionType: connectionType) * 0.3
    }
    
    // MARK: - Network Speed Test
    
    /// Performs a lightweight, user-initiated speed test.
    ///
    /// This implementation is currently simulated. If you replace it with a real test, keep it cancellable and
    /// ensure it doesn't run automatically in the background.
    func performSpeedTest() async -> (download: Double, upload: Double) {
        // This is a simplified speed test
        // In a real app, you'd implement actual network testing
        
        _ = Date()
        
        // Simulate download test
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        let downloadSpeed = Double.random(in: 10...100)
        
        // Simulate upload test
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        let uploadSpeed = downloadSpeed * 0.3
        
        return (download: downloadSpeed, upload: uploadSpeed)
    }
} 

