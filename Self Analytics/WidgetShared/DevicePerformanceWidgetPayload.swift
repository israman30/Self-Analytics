//
//  DevicePerformanceWidgetPayload.swift
//  Self Analytics
//
//  Shared between the app and DevicePerformanceWidgetExtension.
//

import Foundation

/// A minimal, widget-friendly snapshot of device performance.
///
/// This type lives in `WidgetShared/` so it can be used by both:
/// - the main app (writer)
/// - the widget extension (reader)
///
/// **Field conventions**
/// - Percent values are expressed as 0–100.
/// - `batteryLevel` matches `UIDevice.batteryLevel` (0–1).
/// - `updatedAt` is the app-side timestamp for when the snapshot was generated.
struct DevicePerformanceWidgetPayload: Codable, Equatable, Sendable {
    enum HealthStatusKind: String, Codable, Sendable {
        case excellent
        case good
        case fair
        case poor
    }

    var healthScore: Int
    var healthStatus: HealthStatusKind
    var memoryPercent: Double
    var cpuPercent: Double
    var storagePercent: Double
    var batteryLevel: Double
    var batteryCharging: Bool
    var updatedAt: Date
}

extension DevicePerformanceWidgetPayload {
    static var placeholder: DevicePerformanceWidgetPayload {
        DevicePerformanceWidgetPayload(
            healthScore: 82,
            healthStatus: .good,
            memoryPercent: 45,
            cpuPercent: 28,
            storagePercent: 62,
            batteryLevel: 0.75,
            batteryCharging: false,
            updatedAt: Date()
        )
    }
}
