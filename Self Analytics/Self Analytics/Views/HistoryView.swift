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
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                generateHistoricalData()
            }
            .onChange(of: selectedTimeRange) { _, _ in
                generateHistoricalData()
            }
        }
    }
    
    private var timeRangeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time Range")
                .font(.headline)
                .foregroundColor(.primary)
            
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding(.horizontal)
    }
    
    private var healthScoreChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Health Score Trend")
                .font(.headline)
                .foregroundColor(.primary)
            
            if #available(iOS 16.0, *) {
                Chart(historicalData) { health in
                    LineMark(
                        x: .value("Time", health.timestamp),
                        y: .value("Score", health.overallScore)
                    )
                    .foregroundStyle(health.overallScore >= 80 ? .green : 
                                   health.overallScore >= 60 ? .blue :
                                   health.overallScore >= 40 ? .orange : .red)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    AreaMark(
                        x: .value("Time", health.timestamp),
                        y: .value("Score", health.overallScore)
                    )
                    .foregroundStyle(health.overallScore >= 80 ? .green.opacity(0.2) : 
                                   health.overallScore >= 60 ? .blue.opacity(0.2) :
                                   health.overallScore >= 40 ? .orange.opacity(0.2) : .red.opacity(0.2))
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
            } else {
                // Fallback for older iOS versions
                Text("Charts require iOS 16 or later")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    private var metricsCharts: some View {
        VStack(spacing: 16) {
            // Memory Usage Chart
            MetricChartView(
                title: "Memory Usage",
                data: historicalData,
                valueKeyPath: \.memory.usagePercentage,
                color: .blue,
                unit: "%"
            )
            
            // CPU Usage Chart
            MetricChartView(
                title: "CPU Usage",
                data: historicalData,
                valueKeyPath: \.cpu.usagePercentage,
                color: .green,
                unit: "%"
            )
            
            // Battery Level Chart
            MetricChartView(
                title: "Battery Level",
                data: historicalData,
                valueKeyPath: { Double($0.battery.level * 100) },
                color: .orange,
                unit: "%"
            )
            
            // Storage Usage Chart
            MetricChartView(
                title: "Storage Usage",
                data: historicalData,
                valueKeyPath: \.storage.usagePercentage,
                color: .purple,
                unit: "%"
            )
        }
        .padding(.horizontal)
    }
    
    private var performanceSummary: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Summary")
                .font(.headline)
                .foregroundColor(.primary)
            
            if let summary = calculatePerformanceSummary() {
                VStack(spacing: 12) {
                    SummaryRow(
                        title: "Average Health Score",
                        value: "\(String(format: "%.1f", summary.averageScore))",
                        color: summary.averageScore >= 80 ? .green : 
                              summary.averageScore >= 60 ? .blue :
                              summary.averageScore >= 40 ? .orange : .red
                    )
                    
                    SummaryRow(
                        title: "Peak Memory Usage",
                        value: "\(String(format: "%.1f", summary.peakMemoryUsage))%",
                        color: summary.peakMemoryUsage > 80 ? .red : 
                              summary.peakMemoryUsage > 60 ? .orange : .green
                    )
                    
                    SummaryRow(
                        title: "Peak CPU Usage",
                        value: "\(String(format: "%.1f", summary.peakCPUUsage))%",
                        color: summary.peakCPUUsage > 80 ? .red : 
                              summary.peakCPUUsage > 60 ? .orange : .green
                    )
                    
                    SummaryRow(
                        title: "Lowest Battery Level",
                        value: "\(String(format: "%.0f", summary.lowestBatteryLevel))%",
                        color: summary.lowestBatteryLevel < 20 ? .red : 
                              summary.lowestBatteryLevel < 50 ? .orange : .green
                    )
                    
                    SummaryRow(
                        title: "Data Points",
                        value: "\(summary.dataPoints)",
                        color: .blue
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
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
                isConnected: true
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
            
            if #available(iOS 16.0, *) {
                Chart(data) { health in
                    LineMark(
                        x: .value("Time", health.timestamp),
                        y: .value("Value", valueKeyPath(health))
                    )
                    .foregroundStyle(color)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    AreaMark(
                        x: .value("Time", health.timestamp),
                        y: .value("Value", valueKeyPath(health))
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
            } else {
                // Fallback for older iOS versions
                Text("Charts require iOS 16 or later")
                    .foregroundColor(.secondary)
                    .frame(height: 150)
            }
            
            // Summary stats
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Average")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", averageValue))\(unit)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Peak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", peakValue))\(unit)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
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
