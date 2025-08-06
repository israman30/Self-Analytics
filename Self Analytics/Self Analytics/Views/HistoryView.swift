//
//  HistoryView.swift
//  Self Analytics
//
//  Created by Israel Manzo on 7/9/25.
//

import SwiftUI
import Charts

struct HistoryView: View {
    @StateObject private var metricsService = DeviceMetricsService()
    @State private var selectedTimeRange: TimeRange = .day
    @State private var historicalData: [DeviceHealth] = []
    
    enum TimeRange: String, CaseIterable {
        case hour = "1 Hour"
        case day = "24 Hours"
        case week = "7 Days"
        case month = "30 Days"
        
        var hours: Int {
            switch self {
            case .hour: return 1
            case .day: return 24
            case .week: return 24 * 7
            case .month: return 24 * 30
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Time Range Selector
                    timeRangeSelector
                    
                    // Health Score Chart
                    healthScoreChart
                    
                    // Metrics Charts
                    metricsCharts
                    
                    // Performance Summary
                    performanceSummary
                }
                .padding(.vertical)
            }
            .navigationTitle(HistoryViewLabels.history)
            .navigationBarTitleDisplayMode(.large)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(AccessibilityLabels.deviceHistory)
            .accessibilityHint(
                AccessibilityLabels.view_historical_device_performance_data_and_trends
            )
            .onAppear {
                generateHistoricalData()
            }
            .onChange(of: selectedTimeRange) { _, _ in
                generateHistoricalData()
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private var timeRangeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(HistoryViewLabels.timeRange)
                .font(.headline)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)
            
            Picker(HistoryViewLabels.timeRange, selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .accessibilityLabel(HistoryViewLabels.timeRange)
            .accessibilityHint(
                AccessibilityLabels.select_the_time_period_for_historical_data
            )
        }
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
    }
    
    // MARK: - Health Score Chart setup
    private var healthScoreChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(HistoryViewLabels.healthScoreTrend)
                .font(.headline)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)
            
            if #available(iOS 16.0, *) {
                Chart(historicalData) { health in
                    // LineMark Chart
                    LineMark(
                        x: .value(HistoryViewLabels.time, health.timestamp),
                        y: .value(HistoryViewLabels.score, health.overallScore)
                    )
                    .foregroundStyle(
                        health.overallScore >= 80 ? .green : 
                            health.overallScore >= 60 ? .blue :
                            health.overallScore >= 40 ? .orange : .red
                    )
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    // AreaMark Chart
                    AreaMark(
                        x: .value(HistoryViewLabels.time, health.timestamp),
                        y: .value(HistoryViewLabels.score, health.overallScore)
                    )
                    .foregroundStyle(
                        health.overallScore >= 80 ? .green.opacity(0.2) :
                            health.overallScore >= 60 ? .blue.opacity(0.2) :
                            health.overallScore >= 40 ? .orange.opacity(0.2) : .red.opacity(0.2)
                    )
                }
                .frame(height: 200)
                .chartYScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.hour())
                    }
                }
                .chartYAxis {
                    AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .accessibilityLabel(AccessibilityLabels.healthScoreTrendChart)
                .accessibilityHint(AccessibilityLabels.shows_health_score_trends_over_the_selected_time_period)
            } else {
                // Fallback for older iOS versions
                Text(HistoryViewLabels.chartRequiresiOS16OrLater)
                    .foregroundColor(.secondary)
                    .frame(height: 200)
                    .accessibilityLabel(AccessibilityLabels.chartNotAvailable)
                    .accessibilityHint(AccessibilityLabels.chartsRequireiOS16OrLater)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
        .accessibilityElement(children: .contain)
    }
    
    // MARK: - Metrics Chart setup
    private var metricsCharts: some View {
        VStack(spacing: 16) {
            /// `Memory Usage Chart
            MetricChartView(
                title: HistoryViewLabels.MetricChart.memoryUsage,
                data: historicalData,
                valueKeyPath: \.memory.usagePercentage,
                color: .blue,
                unit: "%"
            )
            
            /// `CPU Usage Chart
            MetricChartView(
                title: HistoryViewLabels.MetricChart.cpuUsage,
                data: historicalData,
                valueKeyPath: \.cpu.usagePercentage,
                color: .green,
                unit: "%"
            )
            
            /// `Battery Level Chart
            MetricChartView(
                title: HistoryViewLabels.MetricChart.batteryLevel,
                data: historicalData,
                valueKeyPath: { Double($0.battery.level * 100) },
                color: .orange,
                unit: "%"
            )
            
            /// `Storage Usage Chart
            MetricChartView(
                title: HistoryViewLabels.MetricChart.storageUsage,
                data: historicalData,
                valueKeyPath: \.storage.usagePercentage,
                color: .purple,
                unit: "%"
            )
        }
        .padding(.horizontal)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(AccessibilityLabels.performanceMetricsCharts)
        .accessibilityHint(
            AccessibilityLabels.detailed_charts_showing_memory_CPU_battery_and_storage_usage_over_time
        )
    }
    
    // MARK: - Performance Summary setup
    private var performanceSummary: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(HistoryViewLabels.performanceSummary)
                .font(.headline)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)
            
            if let summary = calculatePerformanceSummary() {
                VStack(spacing: 12) {
                    SummaryRow(
                        title: HistoryViewLabels.SummaryRow.averageHealthScore,
                        value: "\(String(format: "%.1f", summary.averageScore))",
                        color: summary.averageScore >= 80 ? .green : 
                              summary.averageScore >= 60 ? .blue :
                              summary.averageScore >= 40 ? .orange : .red
                    )
                    
                    SummaryRow(
                        title: HistoryViewLabels.SummaryRow.peakMemoryUsage,
                        value: "\(String(format: "%.1f", summary.peakMemoryUsage))%",
                        color: summary.peakMemoryUsage > 80 ? .red : 
                              summary.peakMemoryUsage > 60 ? .orange : .green
                    )
                    
                    SummaryRow(
                        title: HistoryViewLabels.SummaryRow.peakCPUUsage,
                        value: "\(String(format: "%.1f", summary.peakCPUUsage))%",
                        color: summary.peakCPUUsage > 80 ? .red : 
                              summary.peakCPUUsage > 60 ? .orange : .green
                    )
                    
                    SummaryRow(
                        title: HistoryViewLabels.SummaryRow.lowestBatteryLevel,
                        value: "\(String(format: "%.0f", summary.lowestBatteryLevel))%",
                        color: summary.lowestBatteryLevel < 20 ? .red : 
                              summary.lowestBatteryLevel < 50 ? .orange : .green
                    )
                    
                    SummaryRow(
                        title: HistoryViewLabels.SummaryRow.dataPoints,
                        value: "\(summary.dataPoints)",
                        color: .blue
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel(AccessibilityLabels.performanceSummary)
                .accessibilityHint(
                    AccessibilityLabels.summary_of_key_performance_metrics_including_average_health_score_peak_usage_and_data_points
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
        .accessibilityElement(children: .contain)
    }
    
    // MARK: - Helper Methods
    private func generateHistoricalData() {
        historicalData = []
        let now = Date()
        let interval = TimeInterval(selectedTimeRange.hours * 3600)
        let dataPoints = min(selectedTimeRange.hours, 100) // Limit data points
        
        for i in 0..<dataPoints {
            let timestamp = now.addingTimeInterval(-Double(i) * interval / Double(dataPoints))
            
            // Generate realistic historical data with some variation
            let baseMemoryUsage = 60.0 + Double.random(in: -20...20)
            let baseCPUUsage = 30.0 + Double.random(in: -15...25)
            let baseBatteryLevel = 0.7 + Double.random(in: -0.3...0.2)
            let baseStorageUsage = 75.0 + Double.random(in: -10...15)
            
            let memory = MemoryMetrics(
                usedMemory: UInt64(baseMemoryUsage * 1024 * 1024 * 1024 / 100),
                totalMemory: 6 * 1024 * 1024 * 1024,
                availableMemory: UInt64((100 - baseMemoryUsage) * 1024 * 1024 * 1024 / 100),
                memoryPressure: baseMemoryUsage > 80 ? .critical : baseMemoryUsage > 70 ? .warning : .normal
            )
            
            let cpu = CPUMetrics(usagePercentage: max(0, min(100, baseCPUUsage)))
            
            let battery = BatteryMetrics(
                level: max(0, min(1, baseBatteryLevel)),
                isCharging: Bool.random(),
                isLowPowerMode: baseBatteryLevel < 0.3,
                health: baseBatteryLevel > 0.8 ? .excellent : baseBatteryLevel > 0.6 ? .good : baseBatteryLevel > 0.4 ? .fair : .poor,
                cycleCount: nil
            )
            
            let storage = StorageMetrics(
                totalSpace: 64 * 1024 * 1024 * 1024,
                usedSpace: UInt64(baseStorageUsage * 64 * 1024 * 1024 * 1024 / 100),
                availableSpace: UInt64((100 - baseStorageUsage) * 64 * 1024 * 1024 * 1024 / 100),
                systemSpace: 6 * 1024 * 1024 * 1024
            )
            
            let network = NetworkMetrics(
                downloadSpeed: Double.random(in: 20...100),
                uploadSpeed: Double.random(in: 10...50),
                connectionType: .wifi,
                isConnected: true,
                status: .wifiConnected
            )
            
            let health = DeviceHealth(
                memory: memory,
                cpu: cpu,
                battery: battery,
                storage: storage,
                network: network,
                timestamp: timestamp
            )
            
            historicalData.append(health)
        }
        
        // Sort by timestamp
        historicalData.sort { $0.timestamp < $1.timestamp }
    }
    
    private func calculatePerformanceSummary() -> PerformanceSummary? {
        guard !historicalData.isEmpty else { return nil }
        
        let scores = historicalData.map { $0.overallScore }
        let memoryUsages = historicalData.map { $0.memory.usagePercentage }
        let cpuUsages = historicalData.map { $0.cpu.usagePercentage }
        let batteryLevels = historicalData.map { $0.battery.level * 100 }
        
        return PerformanceSummary(
            averageScore: Double(scores.reduce(0, +) / scores.count),
            peakMemoryUsage: memoryUsages.max() ?? 0,
            peakCPUUsage: cpuUsages.max() ?? 0,
            lowestBatteryLevel: batteryLevels.min() ?? 0,
            dataPoints: historicalData.count
        )
    }
}

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
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
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

struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    let trend: TrendDirection
    
    enum TrendDirection {
        case up, down, stable
        
        var icon: String {
            switch self {
            case .up: return HistoryViewLabels.Icon.arrow_up
            case .down: return HistoryViewLabels.Icon.arrow_down
            case .stable: return HistoryViewLabels.Icon.minus
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .red
            case .down: return .green
            case .stable: return .blue
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                    .accessibilityHidden(true)
                
                Spacer()
                
                Image(systemName: trend.icon)
                    .foregroundColor(trend.color)
                    .font(.caption2)
                    .accessibilityHidden(true)
            }
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
        .accessibilityHint("Shows \(label.lowercased()) value with trend indicator")
    }
}

struct SummaryRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

struct PerformanceSummary {
    let averageScore: Double
    let peakMemoryUsage: Double
    let peakCPUUsage: Double
    let lowestBatteryLevel: Double
    let dataPoints: Int
}

#Preview {
    HistoryView()
} 
