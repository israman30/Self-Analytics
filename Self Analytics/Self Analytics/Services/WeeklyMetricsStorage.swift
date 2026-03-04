//
//  WeeklyMetricsStorage.swift
//  Self Analytics
//
//  Persists daily metrics for the Weekly Health Summary notification.
//  Compares this week vs last week to generate messages like "Your device ran 15% cooler!"
//

import Foundation

struct DailyMetricsSnapshot: Codable {
    let date: Date
    let memoryUsagePercent: Double
    let cpuUsagePercent: Double
    let storageUsagePercent: Double
}

/// Stores daily metrics for weekly comparison. Keeps last 14 days.
final class WeeklyMetricsStorage {
    static let shared = WeeklyMetricsStorage()
    
    private let userDefaults = UserDefaults.standard
    private let key = "weekly_metrics_history"
    private let maxDays = 14
    
    private init() {}
    
    func recordSnapshot(memoryPercent: Double, cpuPercent: Double, storagePercent: Double) {
        let snapshot = DailyMetricsSnapshot(
            date: Date(),
            memoryUsagePercent: memoryPercent,
            cpuUsagePercent: cpuPercent,
            storageUsagePercent: storagePercent
        )
        var history = loadHistory()
        history.append(snapshot)
        pruneToLastDays(&history, days: maxDays)
        saveHistory(history)
    }
    
    /// Returns (thisWeek, lastWeek) averages. Each is (memory, cpu, storage) percent.
    func weeklyComparison() -> (thisWeek: (memory: Double, cpu: Double, storage: Double), lastWeek: (memory: Double, cpu: Double, storage: Double))? {
        let history = loadHistory()
        let calendar = Calendar.current
        let now = Date()
        let thisWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart) ?? now
        
        let thisWeekData = history.filter { $0.date >= thisWeekStart }
        let lastWeekData = history.filter { $0.date >= lastWeekStart && $0.date < thisWeekStart }
        
        guard !thisWeekData.isEmpty, !lastWeekData.isEmpty else { return nil }
        
        let avg = { (snapshots: [DailyMetricsSnapshot]) -> (Double, Double, Double) in
            let count = Double(snapshots.count)
            guard count > 0 else { return (0, 0, 0) }
            let m = snapshots.reduce(0.0) { $0 + $1.memoryUsagePercent } / count
            let c = snapshots.reduce(0.0) { $0 + $1.cpuUsagePercent } / count
            let s = snapshots.reduce(0.0) { $0 + $1.storageUsagePercent } / count
            return (m, c, s)
        }
        
        return (
            thisWeek: avg(thisWeekData),
            lastWeek: avg(lastWeekData)
        )
    }
    
    private func loadHistory() -> [DailyMetricsSnapshot] {
        guard let data = userDefaults.data(forKey: key) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([DailyMetricsSnapshot].self, from: data)) ?? []
    }
    
    private func saveHistory(_ history: [DailyMetricsSnapshot]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(history) else { return }
        userDefaults.set(data, forKey: key)
    }
    
    private func pruneToLastDays(_ history: inout [DailyMetricsSnapshot], days: Int) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        history = history.filter { $0.date >= cutoff }
    }
}
