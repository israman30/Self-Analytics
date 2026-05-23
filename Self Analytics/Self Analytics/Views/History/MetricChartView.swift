//
//  MetricChartView.swift
//  Self Analytics
//
//  Created by Israel Manzo on 5/22/26.
//

import SwiftUI
import Charts

struct MetricChartView: View {
    let title: String
    let data: [DeviceHealth]
    let valueKeyPath: (DeviceHealth) -> Double
    let color: Color
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)
            
            if #available(iOS 16.0, *) {
                Chart(data) { health in
                    LineMark(
                        x: .value(HistoryViewLabels.time, health.timestamp),
                        y: .value(HistoryViewLabels.value, valueKeyPath(health))
                    )
                    .foregroundStyle(color)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    AreaMark(
                        x: .value(HistoryViewLabels.time, health.timestamp),
                        y: .value(HistoryViewLabels.value, valueKeyPath(health))
                    )
                    .foregroundStyle(color.opacity(0.2))
                }
                .frame(height: 150)
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.hour())
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .accessibilityLabel("\(title) Chart")
                .accessibilityHint("Shows \(title.lowercased()) trends over time")
            } else {
                // Fallback for older iOS versions
                Text(HistoryViewLabels.chartRequiresiOS16OrLater)
                    .foregroundColor(.secondary)
                    .frame(height: 150)
                    .accessibilityLabel(AccessibilityLabels.chartNotAvailable)
                    .accessibilityHint(AccessibilityLabels.chartsRequireiOS16OrLater)
            }
            
            // Enhanced Chart Footer Stats
            VStack(spacing: 12) {
                // Main stats row
                HStack(spacing: 16) {
                    // Average stat
                    StatCard(
                        icon: HistoryViewLabels.Icon.chart_line_uptrend_xyaxis,
                        label: HistoryViewLabels.average,
                        value: "\(String(format: "%.1f", averageValue))\(unit)",
                        color: color,
                        trend: getTrendDirection(for: averageValue, comparedTo: peakValue)
                    )
                    
                    // Peak stat
                    StatCard(
                        icon: HistoryViewLabels.Icon.arrow_up_circle_fill,
                        label: HistoryViewLabels.peak,
                        value: "\(String(format: "%.1f", peakValue))\(unit)",
                        color: color,
                        trend: .up
                    )
                    
                    // Current stat
                    StatCard(
                        icon: HistoryViewLabels.Icon.clock_fill,
                        label: HistoryViewLabels.current,
                        value: "\(String(format: "%.1f", currentValue))\(unit)",
                        color: color,
                        trend: getTrendDirection(for: currentValue, comparedTo: averageValue)
                    )
                }
                
                // Performance indicator
                performanceIndicator
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 2)
        .accessibilityElement(children: .contain)
    }
    
    private var averageValue: Double {
        guard !data.isEmpty else { return 0 }
        let values = data.map(valueKeyPath)
        return values.reduce(0, +) / Double(values.count)
    }
    
    private var peakValue: Double {
        guard !data.isEmpty else { return 0 }
        return data.map(valueKeyPath).max() ?? 0
    }
    
    private var currentValue: Double {
        guard !data.isEmpty else { return 0 }
        return valueKeyPath(data.last!)
    }
    
    private var performanceIndicator: some View {
        HStack(spacing: 8) {
            // Performance status icon
            Image(systemName: performanceStatusIcon)
                .foregroundColor(performanceStatusColor)
                .font(.caption)
                .accessibilityHidden(true)
            
            // Performance status text
            Text(performanceStatusText)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(performanceStatusColor)
            
            Spacer()
            
            // Data points info
            HStack(spacing: 4) {
                Image(systemName: HistoryViewLabels.Icon.chart_bar_doc_horizontal)
                    .foregroundColor(.secondary)
                    .font(.caption2)
                    .accessibilityHidden(true)
                
                Text("\(data.count) points")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Performance Status: \(performanceStatusText), \(data.count) data points")
    }
    
    private var performanceStatusIcon: String {
        let current = currentValue
        let avg = averageValue
        
        if current > avg * 1.2 {
            return HistoryViewLabels.Icon.exclamationmark_triangle_fill
        } else if current < avg * 0.8 {
            return HistoryViewLabels.Icon.checkmark_circle_fill
        } else {
            return HistoryViewLabels.Icon.minus_circle_fill
        }
    }
    
    private var performanceStatusColor: Color {
        let current = currentValue
        let avg = averageValue
        
        if current > avg * 1.2 {
            return .orange
        } else if current < avg * 0.8 {
            return .green
        } else {
            return .blue
        }
    }
    
    private var performanceStatusText: String {
        let current = currentValue
        let avg = averageValue
        
        if current > avg * 1.2 {
            return HistoryViewLabels.aboveAverage
        } else if current < avg * 0.8 {
            return HistoryViewLabels.belowAverage
        } else {
            return HistoryViewLabels.normalRange
        }
    }
    
    private func getTrendDirection(for value: Double, comparedTo reference: Double) -> StatCard.TrendDirection {
        let threshold = 0.05 // 5% threshold for change
        let difference = abs(value - reference) / reference
        
        if difference < threshold {
            return .stable
        } else if value > reference {
            return .up
        } else {
            return .down
        }
    }
}

#Preview("MetricChartView • CPU") {
    let now = Date()
    
    func healthPoint(minutesAgo: Int, cpu: Double) -> DeviceHealth {
        DeviceHealth(
            memory: MemoryMetrics(
                usedMemory: 4_200_000_000,
                totalMemory: 8_000_000_000,
                availableMemory: 3_800_000_000,
                memoryPressure: .normal
            ),
            cpu: CPUMetrics(usagePercentage: cpu),
            battery: BatteryMetrics(
                level: 0.62,
                isCharging: false,
                isLowPowerMode: false,
                health: .good,
                cycleCount: 320
            ),
            storage: StorageMetrics(
                totalSpace: 256_000_000_000,
                usedSpace: 198_000_000_000,
                availableSpace: 58_000_000_000,
                systemSpace: 22_000_000_000
            ),
            network: NetworkMetrics(
                downloadSpeed: 120,
                uploadSpeed: 25,
                connectionType: .wifi,
                isConnected: true,
                status: .wifiConnected
            ),
            timestamp: Calendar.current.date(byAdding: .minute, value: -minutesAgo, to: now) ?? now
        )
    }
    
    let series: [DeviceHealth] = [
        healthPoint(minutesAgo: 300, cpu: 18),
        healthPoint(minutesAgo: 270, cpu: 26),
        healthPoint(minutesAgo: 240, cpu: 22),
        healthPoint(minutesAgo: 210, cpu: 35),
        healthPoint(minutesAgo: 180, cpu: 41),
        healthPoint(minutesAgo: 150, cpu: 38),
        healthPoint(minutesAgo: 120, cpu: 52),
        healthPoint(minutesAgo: 90, cpu: 47),
        healthPoint(minutesAgo: 60, cpu: 64),
        healthPoint(minutesAgo: 30, cpu: 58),
        healthPoint(minutesAgo: 0, cpu: 44)
    ]
    .sorted { $0.timestamp < $1.timestamp }
    
    return MetricChartView(
        title: "CPU Usage",
        data: series,
        valueKeyPath: { $0.cpu.usagePercentage },
        color: .orange,
        unit: "%"
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("MetricChartView • CPU (Dark)") {
    MetricChartView(
        title: "CPU Usage",
        data: (0..<10).map { idx in
            let t = Date().addingTimeInterval(TimeInterval(-idx * 1800))
            return DeviceHealth(
                memory: MemoryMetrics(
                    usedMemory: 5_000_000_000,
                    totalMemory: 8_000_000_000,
                    availableMemory: 3_000_000_000,
                    memoryPressure: .warning
                ),
                cpu: CPUMetrics(usagePercentage: Double(30 + (idx * 4 % 35))),
                battery: BatteryMetrics(
                    level: 0.48,
                    isCharging: false,
                    isLowPowerMode: true,
                    health: .fair,
                    cycleCount: 410
                ),
                storage: StorageMetrics(
                    totalSpace: 256_000_000_000,
                    usedSpace: 214_000_000_000,
                    availableSpace: 42_000_000_000,
                    systemSpace: 22_000_000_000
                ),
                network: NetworkMetrics(
                    downloadSpeed: 8,
                    uploadSpeed: 1.2,
                    connectionType: .cellular,
                    isConnected: true,
                    status: .cellularConnected
                ),
                timestamp: t
            )
        }
        .sorted { $0.timestamp < $1.timestamp },
        valueKeyPath: { $0.cpu.usagePercentage },
        color: .orange,
        unit: "%"
    )
    .padding()
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
}
