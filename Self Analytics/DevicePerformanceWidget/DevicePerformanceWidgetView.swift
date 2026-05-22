//
//  DevicePerformanceWidgetView.swift
//  DevicePerformanceWidgetExtension
//

import SwiftUI
import WidgetKit

/// Renders a `DevicePerformanceEntry` for small/medium widget families.
///
/// **Data conventions**
/// - Percent values are 0–100.
/// - `batteryLevel` is 0–1 (matching `UIDevice.batteryLevel`).
struct DevicePerformanceWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: DevicePerformanceEntry

    var body: some View {
        // Keep layout selection centralized so both families share formatting + accessibility behavior.
        switch family {
        case .systemMedium:
            mediumLayout
        default:
            smallLayout
        }
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Health")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formattedTime)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(entry.payload.healthScore)")
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(scoreColor)
                Text("/100")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Health score \(entry.payload.healthScore) out of 100, \(statusLabel)")
            Text(statusLabel)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(scoreColor)
            metricRow(title: "Memory", value: entry.payload.memoryPercent)
            metricRow(title: "CPU", value: entry.payload.cpuPercent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }

    private var mediumLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Device Performance")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(entry.payload.healthScore)")
                            .font(.system(.largeTitle, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(scoreColor)
                        Text("/100 · \(statusLabel)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    batteryLabel
                    Text(formattedTime)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                "Health score \(entry.payload.healthScore), \(statusLabel). Battery \(batteryPercentText). Updated \(formattedTime)."
            )

            HStack(spacing: 12) {
                metricBlock(title: "Memory", percent: entry.payload.memoryPercent)
                metricBlock(title: "CPU", percent: entry.payload.cpuPercent)
                metricBlock(title: "Storage", percent: entry.payload.storagePercent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }

    private func metricRow(title: String, value: Double) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(Int(value.rounded()))%")
                .font(.caption.monospacedDigit().weight(.medium))
        }
        .accessibilityLabel("\(title) \(Int(value.rounded())) percent")
    }

    private func metricBlock(title: String, percent: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Gauge(value: min(100, max(0, percent)), in: 0 ... 100) {
                Text(title)
            } currentValueLabel: {
                Text("\(Int(percent.rounded()))%")
                    .font(.caption2.monospacedDigit())
            }
            .gaugeStyle(.accessoryLinearCapacity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel("\(title) \(Int(percent.rounded())) percent")
    }

    private var batteryLabel: some View {
        HStack(spacing: 4) {
            Image(systemName: entry.payload.batteryCharging ? "battery.100percent.bolt" : "battery.100")
                .imageScale(.small)
                .foregroundStyle(.secondary)
            Text(batteryPercentText)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
        }
        .accessibilityLabel("Battery \(batteryPercentText)\(entry.payload.batteryCharging ? ", charging" : "")")
    }

    private var batteryPercentText: String {
        let level = entry.payload.batteryLevel
        if level < 0 {
            return "—"
        }
        let pct = Int(round(min(1, max(0, level)) * 100))
        return "\(pct)%"
    }

    private var formattedTime: String {
        entry.payload.updatedAt.formatted(date: .omitted, time: .shortened)
    }

    private var statusLabel: String {
        switch entry.payload.healthStatus {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        }
    }

    private var scoreColor: Color {
        switch entry.payload.healthScore {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .orange
        default: return .red
        }
    }
}
