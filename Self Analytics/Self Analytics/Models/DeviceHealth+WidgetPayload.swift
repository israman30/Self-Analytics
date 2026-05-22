//
//  DeviceHealth+WidgetPayload.swift
//  Self Analytics
//

import Foundation

extension DeviceHealth {
    /// Converts the in-app `DeviceHealth` snapshot into a compact payload suitable for WidgetKit.
    ///
    /// **Usage**
    /// - The main app writes this payload to shared storage.
    /// - The widget extension reads and renders the latest snapshot (or a placeholder when unavailable).
    func makeWidgetPayload() -> DevicePerformanceWidgetPayload {
        let status: DevicePerformanceWidgetPayload.HealthStatusKind = switch healthStatus {
        case .excellent: .excellent
        case .good: .good
        case .fair: .fair
        case .poor: .poor
        }

        return DevicePerformanceWidgetPayload(
            healthScore: overallScore,
            healthStatus: status,
            memoryPercent: memory.usagePercentage,
            cpuPercent: cpu.usagePercentage,
            storagePercent: storage.usagePercentage,
            batteryLevel: battery.level,
            batteryCharging: battery.isCharging,
            updatedAt: timestamp
        )
    }
}
