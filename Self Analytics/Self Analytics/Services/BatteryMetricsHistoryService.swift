//
//  BatteryMetricsHistoryService.swift
//  Self Analytics
//
//  Persists battery capacity estimates over time for the Battery Aging graph.
//  iOS doesn't expose maximum capacity directly; we use BatteryHealth as a proxy.
//

import Foundation

/// A single snapshot of estimated battery capacity for charting.
struct BatteryCapacitySnapshot: Codable, Identifiable {
    let id: Date
    let date: Date
    let estimatedCapacity: Double  // 0–100, from BatteryHealth
    
    init(date: Date, estimatedCapacity: Double) {
        self.id = date
        self.date = date
        self.estimatedCapacity = estimatedCapacity
    }
}

/// Persists and retrieves battery capacity history for the 30-day aging chart.
final class BatteryMetricsHistoryService: ObservableObject {
    static let shared = BatteryMetricsHistoryService()
    
    private let userDefaults = UserDefaults.standard
    private let key = "battery_capacity_history"
    private let maxDays = 30
    
    private init() {}
    
    /// Record a capacity snapshot. Call when metrics are updated (e.g., when charging or daily).
    func recordSnapshot(health: BatteryHealth) {
        let snapshot = BatteryCapacitySnapshot(
            date: Date(),
            estimatedCapacity: health.estimatedMaximumCapacity
        )
        var history = loadHistory()
        history.append(snapshot)
        pruneToLastDays(&history, days: maxDays)
        saveHistory(history)
    }
    
    /// Snapshots for the last 30 days, sorted by date ascending.
    func snapshotsForLast30Days() -> [BatteryCapacitySnapshot] {
        let history = loadHistory()
        let cutoff = Calendar.current.date(byAdding: .day, value: -maxDays, to: Date()) ?? Date()
        return history
            .filter { $0.date >= cutoff }
            .sorted { $0.date < $1.date }
    }
    
    // MARK: - Persistence
    
    private func loadHistory() -> [BatteryCapacitySnapshot] {
        guard let data = userDefaults.data(forKey: key) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([BatteryCapacitySnapshot].self, from: data)) ?? []
    }
    
    private func saveHistory(_ history: [BatteryCapacitySnapshot]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(history) else { return }
        userDefaults.set(data, forKey: key)
    }
    
    private func pruneToLastDays(_ history: inout [BatteryCapacitySnapshot], days: Int) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        history = history.filter { $0.date >= cutoff }
    }
}
