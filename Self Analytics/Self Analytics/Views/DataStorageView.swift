//
//  DataStorageView.swift
//  Self Analytics
//
//  Created by Israel Manzo on 3/26/25.
//

import SwiftUI

struct DataStorageView: View {
    @ObservedObject var metricsService: DeviceMetricsService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let health = metricsService.currentHealth {
                        VStack(spacing: 12) {
                            MetricCard(
                                title: DashboardViewLabels.MetricCard.storage,
                                value: health.storage.formattedUsedSpace,
                                subtitle: "of \(health.storage.formattedTotalSpace)",
                                percentage: health.storage.usagePercentage,
                                color: health.storage.isLowStorage ? .red : .blue,
                                icon: DashboardViewLabels.Icon.externaldrive_fill,
                                isAlert: health.storage.isLowStorage
                            )
                            MetricCard(
                                title: DashboardViewLabels.MetricCard.available,
                                value: health.storage.formattedAvailableSpace,
                                subtitle: DashboardViewLabels.MetricCard.freeSpace,
                                color: health.storage.availableSpace < 5 * 1024 * 1024 * 1024 ? .red : .green,
                                icon: DashboardViewLabels.Icon.externaldrive,
                                isAlert: health.storage.availableSpace < 5 * 1024 * 1024 * 1024
                            )
                        }
                        .padding(.horizontal)
                        
                        storageDetailSection(health: health)
                            .padding(.horizontal)
                    } else {
                        VStack(spacing: 10) {
                            ProgressView()
                            Text(DashboardViewLabels.loadingMetrics)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(32)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(DashboardViewLabels.dataStorage)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(SpeedTestViewLabels.done) {
                        dismiss()
                    }
                    .accessibilityLabel(SpeedTestViewLabels.done)
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
    
    @ViewBuilder
    private func storageDetailSection(health: DeviceHealth) -> some View {
        VStack(spacing: 12) {
            GroupBox {
                VStack(alignment: .leading, spacing: 10) {
                    Label {
                        Text("\(DashboardViewLabels.updated) \(health.timestamp, style: .relative)")
                    } icon: {
                        Image(systemName: DashboardViewLabels.Icon.clock)
                            .accessibilityHidden(true)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    
                    Divider()
                    
                    storageMetricRow(DashboardViewLabels.MetricDetail.used, health.storage.formattedUsedSpace)
                    storageMetricRow(DashboardViewLabels.MetricDetail.available, health.storage.formattedAvailableSpace)
                    storageMetricRow(DashboardViewLabels.MetricDetail.total, health.storage.formattedTotalSpace)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
    
    private func storageMetricRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    DataStorageView(metricsService: DeviceMetricsService())
}
