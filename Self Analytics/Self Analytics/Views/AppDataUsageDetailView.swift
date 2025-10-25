//
//  AppDataUsageDetailView.swift
//  Self Analytics
//
//  Created by Israel Manzo on 7/10/25.
//

import SwiftUI
import Charts

struct AppDataUsageDetailView: View {
    let app: AppDataUsage
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPeriod: DataUsagePeriod.PeriodType = .today
    @StateObject private var dataUsageService = DataUsageService()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // App Header
                    appHeader
                    
                    // Period Selector
                    periodSelector
                    
                    // Usage Summary
                    usageSummary
                    
                    // Usage Chart
                    usageChart
                    
                    // Usage Breakdown
                    usageBreakdown
                    
                    // Usage History
                    usageHistory
                }
                .padding()
            }
            .navigationTitle(app.appName)
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
    
    // MARK: - App Header
    
    private var appHeader: some View {
        VStack(spacing: 16) {
            // App Icon
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.2))
                .frame(width: 80, height: 80)
                .overlay(
                    VStack {
                        Text(String(app.appName.prefix(1)))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        Text(app.bundleIdentifier.components(separatedBy: ".").last?.capitalized ?? "App")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                )
            
            // App Info
            VStack(spacing: 8) {
                Text(app.appName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(app.bundleIdentifier)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Total Usage
            VStack(spacing: 4) {
                Text("Total Usage")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(app.formattedTotalUsage)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
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
    
    // MARK: - Usage Summary
    
    private var usageSummary: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            // Cellular Usage
            UsageSummaryCard(
                title: "Cellular",
                value: app.formattedCellularUsage,
                percentage: app.cellularPercentage,
                color: .red,
                icon: "antenna.radiowaves.left.and.right.circle.fill"
            )
            
            // Wi-Fi Usage
            UsageSummaryCard(
                title: "Wi-Fi",
                value: app.formattedWifiUsage,
                percentage: app.wifiPercentage,
                color: .green,
                icon: "wifi"
            )
        }
    }
    
    // MARK: - Usage Chart
    
    private var usageChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Usage Breakdown")
                .font(.headline)
                .foregroundColor(.primary)
            
            if #available(iOS 16.0, *) {
                Chart([
                    ("Cellular", app.cellularBytes, Color.red),
                    ("Wi-Fi", app.wifiBytes, Color.green)
                ], id: \.0) { data in
                    SectorMark(
                        angle: .value("Usage", data.1),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(data.2)
                    .opacity(0.8)
                }
                .frame(height: 200)
                .chartBackground { chartProxy in
                    VStack {
                        Text("Total")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(app.formattedTotalUsage)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                }
                .chartLegend(position: .bottom) {
                    HStack {
                        HStack {
                            Circle()
                                .fill(.red)
                                .frame(width: 8, height: 8)
                            Text("Cellular (\(String(format: "%.1f", app.cellularPercentage))%)")
                                .font(.caption)
                        }
                        
                        HStack {
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)
                            Text("Wi-Fi (\(String(format: "%.1f", app.wifiPercentage))%)")
                                .font(.caption)
                        }
                    }
                }
            } else {
                // Fallback for iOS < 16
                VStack(spacing: 16) {
                    HStack(spacing: 20) {
                        // Cellular
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .stroke(Color.red.opacity(0.2), lineWidth: 8)
                                    .frame(width: 80, height: 80)
                                
                                Circle()
                                    .trim(from: 0, to: app.cellularPercentage / 100)
                                    .stroke(Color.red, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                    .frame(width: 80, height: 80)
                                    .rotationEffect(.degrees(-90))
                                
                                VStack {
                                    Text("\(String(format: "%.1f", app.cellularPercentage))%")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.red)
                                }
                            }
                            
                            Text("Cellular")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(app.formattedCellularUsage)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        
                        // Wi-Fi
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .stroke(Color.green.opacity(0.2), lineWidth: 8)
                                    .frame(width: 80, height: 80)
                                
                                Circle()
                                    .trim(from: 0, to: app.wifiPercentage / 100)
                                    .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                    .frame(width: 80, height: 80)
                                    .rotationEffect(.degrees(-90))
                                
                                VStack {
                                    Text("\(String(format: "%.1f", app.wifiPercentage))%")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                }
                            }
                            
                            Text("Wi-Fi")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(app.formattedWifiUsage)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Usage Breakdown
    
    private var usageBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detailed Breakdown")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                // Cellular Usage Detail
                UsageBreakdownRow(
                    title: "Cellular Data",
                    value: app.formattedCellularUsage,
                    percentage: app.cellularPercentage,
                    color: .red,
                    icon: "antenna.radiowaves.left.and.right.circle.fill"
                )
                
                // Wi-Fi Usage Detail
                UsageBreakdownRow(
                    title: "Wi-Fi Data",
                    value: app.formattedWifiUsage,
                    percentage: app.wifiPercentage,
                    color: .green,
                    icon: "wifi"
                )
                
                // Total Usage
                UsageBreakdownRow(
                    title: "Total Usage",
                    value: app.formattedTotalUsage,
                    percentage: 100,
                    color: .blue,
                    icon: "network"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Usage History
    
    private var usageHistory: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Usage History")
                .font(.headline)
                .foregroundColor(.primary)
            
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
                            Text("Usage History Chart")
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
}

// MARK: - Supporting Views

struct UsageSummaryCard: View {
    let title: String
    let value: String
    let percentage: Double
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("\(String(format: "%.1f", percentage))% of total")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct UsageBreakdownRow: View {
    let title: String
    let value: String
    let percentage: Double
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("\(String(format: "%.1f", percentage))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    AppDataUsageDetailView(app: AppDataUsage(
        bundleIdentifier: "com.example.app",
        appName: "Example App",
        iconData: nil,
        cellularBytes: 100 * 1024 * 1024,
        wifiBytes: 500 * 1024 * 1024
    ))
}
