//
//  DeviceMetricsService.swift
//  Self Analytics
//
//  Created by Israel Manzo on 7/9/25.
//

import Foundation
import UIKit
import SystemConfiguration
import Network

@MainActor
class DeviceMetricsService: ObservableObject {
    @Published var currentHealth: DeviceHealth?
    @Published var isMonitoring = false
    
    private var timer: Timer?
    private let updateInterval: TimeInterval = 5.0 // Update every 5 seconds
    
    init() {
        startMonitoring()
    }
    
    deinit {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [unowned self] in
            self.stopMonitoring()
        }
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
    
    func updateMetrics() {
        let memory = getMemoryMetrics()
        let cpu = getCPUMetrics()
        let battery = getBatteryMetrics()
        let storage = getStorageMetrics()
        let network = getNetworkMetrics()
        
        currentHealth = DeviceHealth(
            memory: memory,
            cpu: cpu,
            battery: battery,
            storage: storage,
            network: network,
            timestamp: Date()
        )
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
        // Note: iOS doesn't provide direct CPU usage APIs
        // This is a simplified implementation
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
    
    private func getNetworkMetrics() -> NetworkMetrics {
        let connectionType = getNetworkConnectionType()
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
    
    private func getNetworkConnectionType() -> NetworkConnectionType {
        // Determine network connection type by observing a single NWPath update
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkTypeQueue")

        // We'll capture the result in an atomic reference via a local constant assignment
        // to avoid mutating a captured var inside a concurrently executing closure.
        let semaphore = DispatchSemaphore(value: 0)

        var result: NetworkConnectionType = .none

        monitor.pathUpdateHandler = { path in
            // Compute the connection type from the path locally and assign to a local var
            let computedType: NetworkConnectionType
            if path.status == .satisfied {
                if path.usesInterfaceType(.wifi) {
                    computedType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    computedType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    computedType = .ethernet
                } else {
                    // Default to wifi if interface type is unknown but connected
                    computedType = .wifi
                }
            } else {
                computedType = .none
            }

            // Assign to our outer scope var exactly once before signaling.
            // This assignment happens on the monitor's serial queue before we cancel.
            result = computedType
            semaphore.signal()
        }

        monitor.start(queue: queue)

        // Wait briefly for the first path update
        _ = semaphore.wait(timeout: .now() + 0.5)

        monitor.cancel()
        return result
    }
    
    private func checkNetworkAvailability() {
        // Check if any network interfaces are available
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkAvailabilityQueue")
        
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                if path.status == .unsatisfied && path.availableInterfaces.isEmpty {
                    self?.networkStatus = .notFound
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
        let newStatus: NetworkStatus
        
        if path.status == .satisfied {
            if path.usesInterfaceType(.wifi) {
                newStatus = .wifiConnected
            } else if path.usesInterfaceType(.cellular) {
                newStatus = .cellularConnected
            } else if path.usesInterfaceType(.wiredEthernet) {
                newStatus = .ethernetConnected
            } else {
                newStatus = .connected
            }
        } else {
            newStatus = .disconnected
        }
        
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
