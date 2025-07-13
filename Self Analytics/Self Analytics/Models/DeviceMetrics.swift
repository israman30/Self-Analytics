
//
//  MemoryMetrics.swift
//  Self Analytics
//
//  Created by Israel Manzo on 7/9/25.
//

import Foundation
import UIKit

// MARK: - Device Metrics Models
struct MemoryMetrics: Codable {
    let usedMemory: UInt64
    let totalMemory: UInt64
    let availableMemory: UInt64
    let memoryPressure: MemoryPressure
    
    var usagePercentage: Double {
        guard totalMemory > 0 else { return 0 }
        return Double(usedMemory) / Double(totalMemory) * 100
    }
    
    var isHighUsage: Bool {
        return usagePercentage > 80
    }
}

enum MemoryPressure: Codable {
    case normal
    case warning
    case critical
    
    var color: String {
        switch self {
        case .normal: return "green"
        case .warning: return "orange"
        case .critical: return "red"
        }
    }
}

struct CPUMetrics: Codable {
    let usagePercentage: Double
    let temperature: Double?
    let isHighUsage: Bool
    
    init(usagePercentage: Double, temperature: Double? = nil) {
        self.usagePercentage = usagePercentage
        self.temperature = temperature
        self.isHighUsage = usagePercentage > 70
    }
}

struct BatteryMetrics: Codable {
    let level: Double
    let isCharging: Bool
    let isLowPowerMode: Bool
    let health: BatteryHealth
    let cycleCount: Int?
    
    var isLowBattery: Bool {
        return level < 0.2
    }
}

enum BatteryHealth: Codable {
    case excellent
    case good
    case fair
    case poor
    
    var description: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        }
    }
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .fair: return "orange"
        case .poor: return "red"
        }
    }
}

struct StorageMetrics: Codable {
    let totalSpace: UInt64
    let usedSpace: UInt64
    let availableSpace: UInt64
    let systemSpace: UInt64
    
    var usagePercentage: Double {
        guard totalSpace > 0 else { return 0 }
        return Double(usedSpace) / Double(totalSpace) * 100
    }
    
    var isLowStorage: Bool {
        return usagePercentage > 90
    }
    
    var formattedTotalSpace: String {
        return ByteCountFormatter.string(fromByteCount: Int64(totalSpace), countStyle: .file)
    }
    
    var formattedUsedSpace: String {
        return ByteCountFormatter.string(fromByteCount: Int64(usedSpace), countStyle: .file)
    }
    
    var formattedAvailableSpace: String {
        return ByteCountFormatter.string(fromByteCount: Int64(availableSpace), countStyle: .file)
    }
}

enum NetworkStatus: Codable {
    case unknown
    case connected
    case wifiConnected
    case cellularConnected
    case ethernetConnected
    case disconnected
    case restored
    case notFound
    
    var description: String {
        switch self {
        case .unknown: return "Unknown"
        case .connected: return "Connected"
        case .wifiConnected: return "Wi-Fi Connected"
        case .cellularConnected: return "Cellular Connected"
        case .ethernetConnected: return "Ethernet Connected"
        case .disconnected: return "Disconnected"
        case .restored: return "Connection Restored"
        case .notFound: return "No Network Found"
        }
    }
    
    var isConnected: Bool {
        switch self {
        case .connected, .wifiConnected, .cellularConnected, .ethernetConnected, .restored:
            return true
        case .unknown, .disconnected, .notFound:
            return false
        }
    }
}

struct NetworkMetrics: Codable {
    let downloadSpeed: Double // Mbps
    let uploadSpeed: Double // Mbps
    let connectionType: NetworkConnectionType
    let isConnected: Bool
    let status: NetworkStatus
    
    var isSlowConnection: Bool {
        return downloadSpeed < 5.0 || uploadSpeed < 1.0
    }
}

enum NetworkConnectionType: Codable {
    case wifi
    case cellular
    case ethernet
    case none
    
    var description: String {
        switch self {
        case .wifi: return "Wi-Fi"
        case .cellular: return "Cellular"
        case .ethernet: return "Ethernet"
        case .none: return "No Connection"
        }
    }
}

struct DeviceHealth: Identifiable, Codable {
    let memory: MemoryMetrics
    let cpu: CPUMetrics
    let battery: BatteryMetrics
    let storage: StorageMetrics
    let network: NetworkMetrics
    let timestamp: Date
    
    var id: Date { timestamp }
    
    var overallScore: Int {
        var score = 100
        
        // Memory impact
        if memory.isHighUsage { score -= 20 }
        
        // CPU impact
        if cpu.isHighUsage { score -= 15 }
        
        // Battery impact
        if battery.isLowBattery { score -= 10 }
        if battery.health == .poor { score -= 15 }
        
        // Storage impact
        if storage.isLowStorage { score -= 20 }
        
        // Network impact
        if network.isSlowConnection { score -= 10 }
        
        return max(0, score)
    }
    
    var healthStatus: HealthStatus {
        switch overallScore {
        case 80...100: return .excellent
        case 60..<80: return .good
        case 40..<60: return .fair
        default: return .poor
        }
    }
}

enum HealthStatus: Codable {
    case excellent
    case good
    case fair
    case poor
    
    var description: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        }
    }
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .fair: return "orange"
        case .poor: return "red"
        }
    }
}

// MARK: - Historical Data Models
struct MetricsHistory {
    let deviceHealth: [DeviceHealth]
    let dateRange: DateInterval
    
    var averageScore: Double {
        guard !deviceHealth.isEmpty else { return 0 }
        let total = deviceHealth.reduce(0) { $0 + $1.overallScore }
        return Double(total) / Double(deviceHealth.count)
    }
}

// MARK: - Alert Models
struct DeviceAlert: Codable {
    var id = UUID()
    let type: AlertType
    let title: String
    let message: String
    let severity: AlertSeverity
    let timestamp: Date
    let isResolved: Bool
    
    enum AlertType: Codable {
        case lowStorage
        case highMemoryUsage
        case highCPUUsage
        case lowBattery
        case poorBatteryHealth
        case slowNetwork
        case securityUpdate
    }
    
    enum AlertSeverity: Codable {
        case low
        case medium
        case high
        case critical
        
        var color: String {
            switch self {
            case .low: return "blue"
            case .medium: return "orange"
            case .high: return "red"
            case .critical: return "purple"
            }
        }
    }
}

// MARK: - Recommendation Models

struct DeviceRecommendation: Codable {
    var id = UUID()
    let type: RecommendationType
    let title: String
    let description: String
    let action: String
    let impact: RecommendationImpact
    let isCompleted: Bool
    
    enum RecommendationType: Codable {
        case clearCache
        case deleteLargeFiles
        case updateApps
        case optimizeBattery
        case checkPermissions
        case runSpeedTest
    }
    
    enum RecommendationImpact: Codable {
        case low
        case medium
        case high
        
        var description: String {
            switch self {
            case .low: return "Low Impact"
            case .medium: return "Medium Impact"
            case .high: return "High Impact"
            }
        }
    }
} 
