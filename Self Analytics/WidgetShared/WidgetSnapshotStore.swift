//
//  WidgetSnapshotStore.swift
//  Self Analytics
//
//  Persists the latest performance snapshot in the App Group for the widget.
//

import Foundation

enum WidgetSnapshotStore {
    private static let appGroupID = "group.com.israman.Self-Analytics"
    private static let storageKey = "device_performance_widget_snapshot_v1"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static func save(_ payload: DevicePerformanceWidgetPayload) {
        guard let data = try? JSONEncoder().encode(payload) else { return }
        defaults?.set(data, forKey: storageKey)
    }

    static func load() -> DevicePerformanceWidgetPayload? {
        guard let data = defaults?.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(DevicePerformanceWidgetPayload.self, from: data)
    }
}
