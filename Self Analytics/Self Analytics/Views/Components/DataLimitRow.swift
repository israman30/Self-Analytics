//
//  DataLimitRow.swift
//  Self Analytics
//
//  Created by Israel Manzo on 5/22/26.
//

import SwiftUI

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

#Preview("DataLimitRow") {
    let now = Date()
    let thresholds = [
        AlertThreshold(percentage: 80, isEnabled: true, alertType: .warning),
        AlertThreshold(percentage: 95, isEnabled: true, alertType: .critical)
    ]
    
    let cellularLimit = DataUsageLimit(
        limitType: .cellular,
        limitValue: 2_000 * 1_024 * 1_024,
        periodType: .thisMonth,
        isEnabled: true,
        alertThresholds: thresholds,
        createdAt: now,
        updatedAt: now
    )
    
    let wifiLimit = DataUsageLimit(
        limitType: .wifi,
        limitValue: 10_000 * 1_024 * 1_024,
        periodType: .thisWeek,
        isEnabled: true,
        alertThresholds: thresholds,
        createdAt: now,
        updatedAt: now
    )
    
    let totalLimit = DataUsageLimit(
        limitType: .total,
        limitValue: 15_000 * 1_024 * 1_024,
        periodType: .today,
        isEnabled: true,
        alertThresholds: thresholds,
        createdAt: now,
        updatedAt: now
    )
    
    return List {
        Section("Healthy") {
            DataLimitRow(limit: cellularLimit, currentUsage: 650 * 1_024 * 1_024)
        }
        
        Section("Warning") {
            DataLimitRow(limit: wifiLimit, currentUsage: 7_800 * 1_024 * 1_024)
        }
        
        Section("Critical") {
            DataLimitRow(limit: totalLimit, currentUsage: 13_800 * 1_024 * 1_024)
        }
    }
    .listStyle(.insetGrouped)
}
