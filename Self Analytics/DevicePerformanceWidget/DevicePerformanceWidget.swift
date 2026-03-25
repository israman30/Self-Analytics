//
//  DevicePerformanceWidget.swift
//  DevicePerformanceWidgetExtension
//

import SwiftUI
import WidgetKit

struct DevicePerformanceWidget: Widget {
    private let kind = "DevicePerformanceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DevicePerformanceTimelineProvider()) { entry in
            DevicePerformanceWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Device Performance")
        .description("Health score, memory, CPU, storage, and battery at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct DevicePerformanceEntry: TimelineEntry {
    let date: Date
    let payload: DevicePerformanceWidgetPayload
}

struct DevicePerformanceTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> DevicePerformanceEntry {
        DevicePerformanceEntry(date: Date(), payload: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (DevicePerformanceEntry) -> Void) {
        let payload = WidgetSnapshotStore.load() ?? .placeholder
        completion(DevicePerformanceEntry(date: Date(), payload: payload))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DevicePerformanceEntry>) -> Void) {
        let payload = WidgetSnapshotStore.load() ?? .placeholder
        let entry = DevicePerformanceEntry(date: Date(), payload: payload)
        let refresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}
