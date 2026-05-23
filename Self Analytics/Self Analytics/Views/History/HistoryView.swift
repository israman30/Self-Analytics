//
//  HistoryView.swift
//  Self Analytics
//
//  Created by Israel Manzo on 7/9/25.
//

import SwiftUI
import Charts

struct PerformanceSummary {
    let averageScore: Double
    let peakMemoryUsage: Double
    let peakCPUUsage: Double
    let lowestBatteryLevel: Double
    let dataPoints: Int
}

struct HistoryView: View {
    var body: some View {
        NavigationStack {
            HistoryMainContent()
                .navigationTitle(HistoryViewLabels.history)
                .navigationBarTitleDisplayMode(.large)
        }
    }
}

/// Device metrics history UI; embed inside a `NavigationStack` (see `HistoryView` or `UsageAndHistoryView`).
struct HistoryMainContent: View {
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
        ScrollView {
            LazyVStack(spacing: 20) {
                timeRangeSelector
                batteryAgingChart
                healthScoreChart
                metricsCharts
                performanceSummary
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .refreshable { refreshHistory() }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    refreshHistory()
                } label: {
                    Image(systemName: DashboardViewLabels.Icon.arrow_clockwise)
                        .accessibilityLabel(DashboardViewLabels.refresh)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(AccessibilityLabels.deviceHistory)
        .accessibilityHint(
            AccessibilityLabels.view_historical_device_performance_data_and_trends
        )
        .onAppear { generateHistoricalData() }
        .onChange(of: selectedTimeRange) { _, _ in
            withAnimation(.easeInOut(duration: 0.25)) { generateHistoricalData() }
        }
    }
    
    private var timeRangeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(HistoryViewLabels.timeRange)
                .font(.headline)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTimeRange = range
                            }
                        } label: {
                            Text(range.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(selectedTimeRange == range ? Color.accentColor : Color(.systemGray6))
                                )
                                .foregroundColor(selectedTimeRange == range ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(range.rawValue)
                        .accessibilityAddTraits(selectedTimeRange == range ? [.isButton, .isSelected] : .isButton)
                    }
                }
                .padding(.horizontal, 4)
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(HistoryViewLabels.timeRange)
            .accessibilityHint(
                AccessibilityLabels.select_the_time_period_for_historical_data
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 2)
        .accessibilityElement(children: .combine)
    }
    
    // MARK: - Battery Aging Chart (30 days)
    private var batteryAgingSnapshots: [BatteryCapacitySnapshot] {
        BatteryMetricsHistoryService.shared.snapshotsForLast30Days()
    }
    
    private var batteryAgingChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(HistoryViewLabels.MetricChart.batteryAging)
                .font(.headline)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)
            
            if batteryAgingSnapshots.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "battery.100")
                        .foregroundStyle(.secondary)
                    Text("Open the app daily to build your battery capacity trend.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .accessibilityLabel("No battery aging data yet. Open the app daily to build your trend.")
            } else if #available(iOS 16.0, *) {
                Chart(batteryAgingSnapshots) { snapshot in
                    LineMark(
                        x: .value(HistoryViewLabels.time, snapshot.date),
                        y: .value("Capacity %", snapshot.estimatedCapacity)
                    )
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    AreaMark(
                        x: .value(HistoryViewLabels.time, snapshot.date),
                        y: .value("Capacity %", snapshot.estimatedCapacity)
                    )
                    .foregroundStyle(.green.opacity(0.2))
                }
                .frame(height: 180)
                .chartYScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .chartYAxis {
                    AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .accessibilityLabel("Battery maximum capacity trend over last 30 days")
                .accessibilityHint("Shows how estimated battery capacity has changed over time")
            } else {
                Text(HistoryViewLabels.chartRequiresiOS16OrLater)
                    .foregroundColor(.secondary)
                    .frame(height: 180)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 2)
        .accessibilityElement(children: .contain)
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
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 2)
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
            
            if historicalData.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .foregroundStyle(.secondary)
                    Text(DashboardViewLabels.loadingMetrics)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else if let summary = calculatePerformanceSummary() {
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
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 2)
        .accessibilityElement(children: .contain)
    }
    
    // MARK: - Helper Methods
    private func refreshHistory() {
        generateHistoricalData()
    }
    
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

#Preview {
    HistoryView()
}

