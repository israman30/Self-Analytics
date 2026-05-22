//
//  WidgetSnapshotStore.swift
//  Self Analytics
//
//  Persists the latest performance snapshot in the App Group for the widget.
//

import Foundation

/// Persists the latest widget snapshot in the app group's shared `UserDefaults`.
///
/// **Setup**
/// - Ensure the app target and widget extension share the same App Group capability.
/// - `appGroupID` must match the configured App Group identifier.
///
/// **Versioning**
/// `storageKey` is versioned so schema changes can be introduced without crashing older builds.
enum WidgetSnapshotStore {
    /// App Group identifier used by both the app and widget extension.
    private static let appGroupID = "group.com.israman.Self-Analytics"
    /// Current payload key (bump suffix when payload shape changes).
    private static let storageKey = "device_performance_widget_snapshot_v1"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    /// Writes a snapshot for the widget extension to read.
    static func save(_ payload: DevicePerformanceWidgetPayload) {
        guard let data = try? JSONEncoder().encode(payload) else { return }
        defaults?.set(data, forKey: storageKey)
    }

    /// Loads the most recent snapshot, if one has been written by the app.
    static func load() -> DevicePerformanceWidgetPayload? {
        guard let data = defaults?.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(DevicePerformanceWidgetPayload.self, from: data)
    }
}
