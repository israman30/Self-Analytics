//
//  DeviceHealth+WidgetPayload.swift
//  Self Analytics
//

import Foundation

extension DeviceHealth {
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
