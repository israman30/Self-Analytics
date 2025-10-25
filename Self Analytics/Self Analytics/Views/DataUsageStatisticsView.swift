//
//  DataUsageStatisticsView.swift
//  Self Analytics
//
//  Created by Israel Manzo on 7/10/25.
//

import SwiftUI
import Charts

struct DataUsageStatisticsView: View {
    @ObservedObject var dataUsageService: DataUsageService
    let period: DataUsagePeriod.PeriodType
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTimeRange: DataUsagePeriod.PeriodType = .thisMonth
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Time Range Selector
                    timeRangeSelector
                    
                    // Statistics Summary
                    if let statistics = dataUsageService.getStatistics(for: DataUsagePeriod(
                        startDate: selectedTimeRange.dateRange.start,
                        endDate: selectedTimeRange.dateRange.end,
                        periodType: selectedTimeRange
                    )) {
                        statisticsSummary(statistics)
                    }
                    
                    // Usage Chart
                    usageChart
                    
                    // Top Apps Chart
                    topAppsChart
                    
                    // Network Type Breakdown
                    networkBreakdown
                }
                .padding()
            }
            .navigationTitle("Data Usage Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Time Range Selector
    
    private var timeRangeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time Range")
                .font(.headline)
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(DataUsagePeriod.PeriodType.allCases, id: \.self) { timeRange in
                        Button(action: {
                            selectedTimeRange = timeRange
                        }) {
                            Text(timeRange.description)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(selectedTimeRange == timeRange ? Color.blue : Color(.systemGray6))
                                )
                                .foregroundColor(selectedTimeRange == timeRange ? .white : .primary)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Statistics Summary
    
    private func statisticsSummary(_ statistics: DataUsageStatistics) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Summary")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatisticDetailCard(
                    title: "Average Daily",
                    value: statistics.formattedAverageDaily,
                    subtitle: "per day",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue
                )
                
                StatisticDetailCard(
                    title: "Peak Usage",
                    value: statistics.formattedPeakUsage,
                    subtitle: statistics.formattedPeakDate,
                    icon: "arrow.up.circle.fill",
                    color: .red
                )
                
                StatisticDetailCard(
                    title: "Total Apps",
                    value: "\(statistics.totalApps)",
                    subtitle: "tracked",
                    icon: "apps.iphone",
                    color: .green
                )
                
                StatisticDetailCard(
                    title: "Most Used",
                    value: statistics.mostUsedApp?.appName ?? "N/A",
                    subtitle: statistics.mostUsedApp?.formattedTotalUsage ?? "0 B",
                    icon: "star.fill",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Usage Chart
    
    private var usageChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Usage Over Time")
                .font(.headline)
                .foregroundColor(.primary)
            
            if #available(iOS 16.0, *) {
                Chart(dataUsageService.getChartData(for: selectedTimeRange)) { data in
                    AreaMark(
                        x: .value("Time", data.date),
                        y: .value("Cellular", data.cellularBytes)
                    )
                    .foregroundStyle(.red.opacity(0.3))
                    
                    AreaMark(
                        x: .value("Time", data.date),
                        y: .value("Wi-Fi", data.wifiBytes)
                    )
                    .foregroundStyle(.green.opacity(0.3))
                    
                    LineMark(
                        x: .value("Time", data.date),
                        y: .value("Total", data.totalBytes)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
                .frame(height: 200)
                .chartLegend(position: .bottom) {
                    HStack {
                        HStack {
                            Circle()
                                .fill(.red.opacity(0.6))
                                .frame(width: 8, height: 8)
                            Text("Cellular")
                                .font(.caption)
                        }
                        
                        HStack {
                            Circle()
                                .fill(.green.opacity(0.6))
                                .frame(width: 8, height: 8)
                            Text("Wi-Fi")
                                .font(.caption)
                        }
                        
                        HStack {
                            Circle()
                                .fill(.blue)
                                .frame(width: 8, height: 8)
                            Text("Total")
                                .font(.caption)
                        }
                    }
                }
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
    
    // MARK: - Top Apps Chart
    
    private var topAppsChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Apps by Usage")
                .font(.headline)
                .foregroundColor(.primary)
            
            if let summary = dataUsageService.getDataUsageForPeriod(DataUsagePeriod(
                startDate: selectedTimeRange.dateRange.start,
                endDate: selectedTimeRange.dateRange.end,
                periodType: selectedTimeRange
            )) {
                let topApps = summary.topApps.prefix(5)
                
                if #available(iOS 16.0, *) {
                    Chart(Array(topApps), id: \.bundleIdentifier) { app in
                        BarMark(
                            x: .value("Usage", app.totalBytes),
                            y: .value("App", app.appName)
                        )
                        .foregroundStyle(.blue)
                    }
                    .frame(height: 200)
                    .chartXAxis {
                        AxisMarks { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let bytes = value.as(UInt64.self) {
                                    Text(ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file))
                                        .font(.caption)
                                }
                            }
                        }
                    }
                } else {
                    // Fallback for iOS < 16
                    VStack(spacing: 8) {
                        ForEach(Array(topApps), id: \.bundleIdentifier) { app in
                            HStack {
                                Text(app.appName)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text(app.formattedTotalUsage)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Network Breakdown
    
    private var networkBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Network Type Breakdown")
                .font(.headline)
                .foregroundColor(.primary)
            
            if let summary = dataUsageService.getDataUsageForPeriod(DataUsagePeriod(
                startDate: selectedTimeRange.dateRange.start,
                endDate: selectedTimeRange.dateRange.end,
                periodType: selectedTimeRange
            )) {
                HStack(spacing: 20) {
                    // Cellular Usage
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .stroke(Color.red.opacity(0.2), lineWidth: 8)
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .trim(from: 0, to: summary.cellularPercentage / 100)
                                .stroke(Color.red, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(-90))
                            
                            VStack {
                                Text("\(String(format: "%.1f", summary.cellularPercentage))%")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                                
                                Text("Cellular")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text(summary.formattedTotalCellular)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    // Wi-Fi Usage
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .stroke(Color.green.opacity(0.2), lineWidth: 8)
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .trim(from: 0, to: summary.wifiPercentage / 100)
                                .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(-90))
                            
                            VStack {
                                Text("\(String(format: "%.1f", summary.wifiPercentage))%")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                                
                                Text("Wi-Fi")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text(summary.formattedTotalWifi)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct StatisticDetailCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    DataUsageStatisticsView(dataUsageService: DataUsageService(), period: .thisMonth)
}
