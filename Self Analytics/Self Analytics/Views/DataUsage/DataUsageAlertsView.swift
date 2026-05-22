//
//  DataUsageAlertsView.swift
//  Self Analytics
//
//  Created by Israel Manzo on 7/10/25.
//

import SwiftUI

struct DataUsageAlertsView: View {
    @ObservedObject var dataUsageService: DataUsageService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAlert: DataUsageAlert?
    
    var body: some View {
        NavigationView {
            List {
                if dataUsageService.activeAlerts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("No Data Usage Alerts")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("You're within your data usage limits. Great job!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    Section {
                        ForEach(dataUsageService.activeAlerts.sorted { $0.timestamp > $1.timestamp }) { alert in
                            DataUsageAlertRow(alert: alert) {
                                dataUsageService.markAlertAsRead(alert)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let alert = dataUsageService.activeAlerts.sorted { $0.timestamp > $1.timestamp }[index]
                                dataUsageService.dismissAlert(alert)
                            }
                        }
                    } header: {
                        Text("Active Alerts")
                    } footer: {
                        Text("Swipe to dismiss alerts or tap to mark as read.")
                    }
                }
            }
            .navigationTitle("Data Usage Alerts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                if !dataUsageService.activeAlerts.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear All") {
                            dataUsageService.clearAllAlerts()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
    }
}

struct DataUsageAlertRow: View {
    let alert: DataUsageAlert
    let onRead: () -> Void
    
    private var alertColor: Color {
        alert.threshold.alertType == .critical ? .red : .orange
    }
    
    private var alertIcon: String {
        alert.threshold.alertType == .critical ? "exclamationmark.triangle.fill" : "exclamationmark.triangle"
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Alert Icon
            ZStack {
                Circle()
                    .fill(alertColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: alertIcon)
                    .foregroundColor(alertColor)
                    .font(.title3)
            }
            
            // Alert Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(alert.limitType.description)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if !alert.isRead {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                    }
                }
                
                Text(alert.alertMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text(alert.timestamp, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(alert.usagePercentage))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(alertColor.opacity(0.2))
                        .foregroundColor(alertColor)
                        .cornerRadius(8)
                }
            }
            
            // Progress Bar
            VStack {
                ProgressView(value: alert.usagePercentage / 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: alertColor))
                    .frame(width: 60)
                
                Text(alert.threshold.formattedThreshold)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .onTapGesture {
            if !alert.isRead {
                onRead()
            }
        }
        .opacity(alert.isRead ? 0.6 : 1.0)
    }
}

#Preview {
    DataUsageAlertsView(dataUsageService: DataUsageService())
}
