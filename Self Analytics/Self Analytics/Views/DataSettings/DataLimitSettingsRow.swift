//
//  DataLimitSettingsRow.swift
//  Self Analytics
//
//  Created by Israel Manzo on 5/22/26.
//

import SwiftUI

struct DataLimitSettingsRow: View {
    let limit: DataUsageLimit
    let onEdit: () -> Void
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: limit.limitType.icon)
                        .foregroundColor(limit.isEnabled ? .blue : .gray)
                        .font(.title3)
                    
                    Text(limit.limitType.description)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(limit.isEnabled ? .primary : .secondary)
                }
                
                Text("Limit: \(limit.formattedLimit) • \(limit.periodType.description)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if limit.isEnabled {
                    HStack {
                        ForEach(limit.alertThresholds, id: \.id) { threshold in
                            thresholdView(threshold: threshold)
                        }
                    }
                }
            }
            
            Spacer()
            
            VStack {
                Toggle("", isOn: .constant(limit.isEnabled))
                    .onChange(of: limit.isEnabled) { _ , _ in
                        onToggle()
                    }
                
                Button(DataLimitsSettingsViewLabels.edit) {
                    onEdit()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func thresholdView(threshold: AlertThreshold) -> some View {
        if threshold.isEnabled {
            Text("\(Int(threshold.percentage))%")
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(threshold.alertType == .critical ? Color.red.opacity(0.2) : Color.orange.opacity(0.2))
                )
                .foregroundColor(threshold.alertType == .critical ? .red : .orange)
        }
    }
}

#Preview("DataLimitSettingsRow") {
    let enabledLimit = DataUsageLimit(
        limitType: .cellular,
        limitValue: 5 * 1024 * 1024 * 1024, // 5GB
        periodType: .thisMonth,
        isEnabled: true,
        alertThresholds: [
            AlertThreshold(percentage: 75, isEnabled: true, alertType: .warning),
            AlertThreshold(percentage: 90, isEnabled: true, alertType: .critical)
        ],
        createdAt: Date().addingTimeInterval(-7 * 24 * 60 * 60),
        updatedAt: Date().addingTimeInterval(-2 * 24 * 60 * 60)
    )

    let disabledLimit = DataUsageLimit(
        limitType: .wifi,
        limitValue: 100 * 1024 * 1024 * 1024, // 100GB
        periodType: .thisMonth,
        isEnabled: false,
        alertThresholds: [
            AlertThreshold(percentage: 80, isEnabled: true, alertType: .warning),
            AlertThreshold(percentage: 95, isEnabled: true, alertType: .critical)
        ],
        createdAt: Date().addingTimeInterval(-30 * 24 * 60 * 60),
        updatedAt: Date().addingTimeInterval(-30 * 24 * 60 * 60)
    )

    List {
        Section("Enabled") {
            DataLimitSettingsRow(limit: enabledLimit, onEdit: {}, onToggle: {})
        }
        Section("Disabled") {
            DataLimitSettingsRow(limit: disabledLimit, onEdit: {}, onToggle: {})
        }
    }
}
