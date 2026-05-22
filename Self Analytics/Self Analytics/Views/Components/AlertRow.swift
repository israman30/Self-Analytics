//
//  AlertRow.swift
//  Self Analytics
//
//  Created by Israel Manzo on 5/22/26.
//

import SwiftUI

struct AlertRow: View {
    let alert: DataUsageAlert
    let onRead: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: alert.threshold.alertType == .critical ? DataUsageLabels.Icon.exclamationmark_triangle_fill : DataUsageLabels.Icon.exclamationmark_triangle)
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

#Preview("AlertRow") {
    let warning = DataUsageAlert(
        limitType: .cellular,
        currentUsage: 850 * 1_024 * 1_024,
        limitValue: 1_000 * 1_024 * 1_024,
        threshold: AlertThreshold(percentage: 80, isEnabled: true, alertType: .warning),
        timestamp: .now,
        isRead: false
    )
    
    let critical = DataUsageAlert(
        limitType: .total,
        currentUsage: 9_750 * 1_024 * 1_024,
        limitValue: 10_000 * 1_024 * 1_024,
        threshold: AlertThreshold(percentage: 95, isEnabled: true, alertType: .critical),
        timestamp: .now.addingTimeInterval(-3_600),
        isRead: true
    )
    
    return List {
        Section("Unread") {
            AlertRow(alert: warning, onRead: {})
        }
        
        Section("Read") {
            AlertRow(alert: critical, onRead: {})
        }
    }
    .listStyle(.insetGrouped)
}
