//
//  DataUsageView.swift
//  Self Analytics
//
//  Created by Israel Manzo on 7/10/25.
//

import SwiftUI
import Charts

struct DataUsageView: View {
    @StateObject private var dataUsageService = DataUsageService()
    @State private var selectedPeriod: DataUsagePeriod.PeriodType = .today
    @State private var showingLimitsSettings = false
    @State private var showingAlerts = false
    @State private var showingStatistics = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Period Selector
                    periodSelector
                    
                    // Data Usage Summary Cards
                    if let summary = dataUsageService.currentSummary {
                        summaryCards(summary: summary)
                    }
                    
                    // Usage Chart
                    usageChart
                    
                    // Alerts Section
                    if !dataUsageService.activeAlerts.isEmpty {
                        alertsSection
                    }
                    
                    // Top Apps Section
                    if let summary = dataUsageService.currentSummary {
                        topAppsSection(summary: summary)
                    }
                    
                    // Data Limits Section
                    dataLimitsSection
                    
                    // Statistics Section
                    statisticsSection
                }
                .padding()
            }
            .navigationTitle("Data Usage")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Data Limits", systemImage: "exclamationmark.triangle") {
                            showingLimitsSettings = true
                        }
                        
                        Button("Reset Data", systemImage: "arrow.clockwise") {
                            dataUsageService.resetDataUsage()
                        }
                        
                        Button("Statistics", systemImage: "chart.bar.xaxis") {
                            showingStatistics = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingLimitsSettings) {
                DataLimitsSettingsView(dataUsageService: dataUsageService)
            }
            .sheet(isPresented: $showingAlerts) {
                DataUsageAlertsView(dataUsageService: dataUsageService)
            }
            .sheet(isPresented: $showingStatistics) {
                DataUsageStatisticsView(dataUsageService: dataUsageService, period: selectedPeriod)
            }
        }
    }
    
    // MARK: - Period Selector
    
    private var periodSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time Period")
                .font(.headline)
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(DataUsagePeriod.PeriodType.allCases, id: \.self) { period in
                        Button(action: {
                            selectedPeriod = period
                        }) {
                            Text(period.description)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(selectedPeriod == period ? Color.blue : Color(.systemGray6))
                                )
                                .foregroundColor(selectedPeriod == period ? .white : .primary)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Summary Cards
    
    private func summaryCards(summary: DataUsageSummary) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            // Total Usage Card
            SummaryCard(
                title: "Total Usage",
                value: summary.formattedTotalUsage,
                subtitle: "All Networks",
                color: .blue,
                icon: "network"
            )
            
            // Cellular Usage Card
            SummaryCard(
                title: "Cellular",
                value: summary.formattedTotalCellular,
                subtitle: "\(String(format: "%.1f", summary.cellularPercentage))% of total",
                color: .red,
                icon: "antenna.radiowaves.left.and.right.circle.fill"
            )
            
            // Wi-Fi Usage Card
            SummaryCard(
                title: "Wi-Fi",
                value: summary.formattedTotalWifi,
                subtitle: "\(String(format: "%.1f", summary.wifiPercentage))% of total",
                color: .green,
                icon: "wifi"
            )
            
            // Apps Count Card
            SummaryCard(
                title: "Active Apps",
                value: "\(summary.appUsages.filter { $0.totalBytes > 0 }.count)",
                subtitle: "Using Data",
                color: .orange,
                icon: "apps.iphone"
            )
        }
    }
    
    // MARK: - Usage Chart
    
    private var usageChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Usage Trend")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if dataUsageService.activeAlerts.count > 0 {
                    Button(action: {
                        showingAlerts = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                            
                            Text("\(dataUsageService.activeAlerts.count)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            
            if #available(iOS 16.0, *) {
                Chart(dataUsageService.getChartData(for: selectedPeriod)) { data in
                    AreaMark(
                        x: .value("Time", data.date),
                        y: .value("Usage", data.totalBytes)
                    )
                    .foregroundStyle(.blue.opacity(0.3))
                    
                    LineMark(
                        x: .value("Time", data.date),
                        y: .value("Usage", data.totalBytes)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let bytes = value.as(UInt64.self) {
                                Text(ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file))
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(date, format: .dateTime.hour().minute())
                                    .font(.caption)
                            }
                        }
                    }
                }
            } else {
                // Fallback for iOS < 16
                VStack {
                    Text("Charts require iOS 16 or later")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
                        .overlay(
                            Text("Chart Preview")
                                .foregroundColor(.secondary)
                        )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Alerts Section
    
    private var alertsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Data Usage Alerts")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("View All") {
                    showingAlerts = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            ForEach(dataUsageService.activeAlerts.prefix(3)) { alert in
                AlertRow(alert: alert) {
                    dataUsageService.markAlertAsRead(alert)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Top Apps Section
    
    private func topAppsSection(summary: DataUsageSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Apps by Usage")
                .font(.headline)
                .foregroundColor(.primary)
            
            ForEach(summary.topApps.prefix(5)) { app in
                AppUsageRow(app: app)
            }
            
            if summary.appUsages.count > 5 {
                Button("View All Apps") {
                    // Navigate to full apps list
                }
                .font(.subheadline)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Data Limits Section
    
    private var dataLimitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Data Limits")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Manage") {
                    showingLimitsSettings = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            ForEach(dataUsageService.dataUsageLimits.filter { $0.isEnabled }) { limit in
                DataLimitRow(limit: limit, currentUsage: getCurrentUsage(for: limit))
            }
            
            if dataUsageService.dataUsageLimits.filter({ $0.isEnabled }).isEmpty {
                Text("No data limits set")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Statistics Section
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Statistics")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("View Details") {
                    showingStatistics = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            if let statistics = dataUsageService.getStatistics(for: DataUsagePeriod(
                startDate: selectedPeriod.dateRange.start,
                endDate: selectedPeriod.dateRange.end,
                periodType: selectedPeriod
            )) {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    StatisticCard(
                        title: "Average Daily",
                        value: statistics.formattedAverageDaily,
                        icon: "chart.line.uptrend.xyaxis",
                        color: .blue
                    )
                    
                    StatisticCard(
                        title: "Peak Usage",
                        value: statistics.formattedPeakUsage,
                        icon: "arrow.up.circle.fill",
                        color: .red
                    )
                    
                    StatisticCard(
                        title: "Total Apps",
                        value: "\(statistics.totalApps)",
                        icon: "apps.iphone",
                        color: .green
                    )
                    
                    StatisticCard(
                        title: "Most Used",
                        value: statistics.mostUsedApp?.appName ?? "N/A",
                        icon: "star.fill",
                        color: .orange
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentUsage(for limit: DataUsageLimit) -> UInt64 {
        guard let summary = dataUsageService.currentSummary else { return 0 }
        
        switch limit.limitType {
        case .cellular:
            return summary.totalCellularBytes
        case .wifi:
            return summary.totalWifiBytes
        case .total:
            return summary.totalBytes
        }
    }
}

// MARK: - Supporting Views

struct SummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct AlertRow: View {
    let alert: DataUsageAlert
    let onRead: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: alert.threshold.alertType == .critical ? "exclamationmark.triangle.fill" : "exclamationmark.triangle")
                .foregroundColor(alert.threshold.alertType == .critical ? .red : .orange)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.limitType.description)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(alert.alertMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(alert.usagePercentage))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(alert.threshold.alertType == .critical ? .red : .orange)
                
                if !alert.isRead {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(.vertical, 8)
        .onTapGesture {
            onRead()
        }
    }
}

struct AppUsageRow: View {
    let app: AppDataUsage
    
    var body: some View {
        HStack(spacing: 12) {
            // App Icon Placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(app.appName.prefix(1)))
                        .font(.headline)
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(app.appName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    if app.cellularBytes > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .foregroundColor(.red)
                                .font(.caption)
                            Text(app.formattedCellularUsage)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    if app.wifiBytes > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "wifi")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text(app.formattedWifiUsage)
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(app.formattedTotalUsage)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Total")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct DataLimitRow: View {
    let limit: DataUsageLimit
    let currentUsage: UInt64
    
    private var progress: Double {
        guard limit.limitValue > 0 else { return 0 }
        return Double(currentUsage) / Double(limit.limitValue)
    }
    
    private var progressColor: Color {
        if progress >= 0.9 {
            return .red
        } else if progress >= 0.75 {
            return .orange
        } else {
            return .green
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: limit.limitType.icon)
                    .foregroundColor(.blue)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(limit.limitType.description)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(limit.periodType.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(progressColor)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                .scaleEffect(x: 1, y: 1.5, anchor: .center)
            
            HStack {
                Text(ByteCountFormatter.string(fromByteCount: Int64(currentUsage), countStyle: .file))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(limit.formattedLimit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

#Preview {
    DataUsageView()
}
