//
//  AddDataLimitView.swift
//  Self Analytics
//
//  Created by Israel Manzo on 5/22/26.
//

import SwiftUI

struct AddDataLimitView: View {
    @ObservedObject var dataUsageService: DataUsageService
    @Environment(\.dismiss) private var dismiss
    
    @State private var limitType: DataUsageLimit.LimitType = .cellular
    @State private var limitValue: Double = 5.0 // GB
    @State private var periodType: DataUsagePeriod.PeriodType = .thisMonth
    @State private var warningThreshold: Double = 75
    @State private var criticalThreshold: Double = 90
    @State private var isWarningEnabled = true
    @State private var isCriticalEnabled = true
    
    private let limitOptions: [(String, DataUsageLimit.LimitType)] = [
        (DataLimitsSettingsViewLabels.cellularData, .cellular),
        (DataLimitsSettingsViewLabels.wiFiData, .wifi),
        (DataLimitsSettingsViewLabels.totalData, .total)
    ]
    
    private let periodOptions: [(String, DataUsagePeriod.PeriodType)] = [
        (DataLimitsSettingsViewLabels.daily, .today),
        (DataLimitsSettingsViewLabels.weekly, .thisWeek),
        (DataLimitsSettingsViewLabels.monthly, .thisMonth)
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker(DataLimitsSettingsViewLabels.limitType, selection: $limitType) {
                        ForEach(limitOptions, id: \.1) { option in
                            Text(option.0).tag(option.1)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text(DataLimitsSettingsViewLabels.dataType)
                } footer: {
                    Text(DataLimitsSettingsViewLabels.chooseWhichTypeOfDataUsageToLimit)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(DataLimitsSettingsViewLabels.limitAmount)
                            Spacer()
                            Text("\(String(format: "%.1f", limitValue)) GB")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $limitValue, in: 0.1...100, step: 0.1)
                            .accentColor(.blue)
                    }
                } header: {
                    Text(DataLimitsSettingsViewLabels.limitValue)
                } footer: {
                    Text(DataLimitsSettingsViewLabels.setTheMaximumAmountOfDataUsageAllowed)
                }
                
                Section {
                    Picker(DataLimitsSettingsViewLabels.resetPeriod, selection: $periodType) {
                        ForEach(periodOptions, id: \.1) { option in
                            Text(option.0).tag(option.1)
                        }
                    }
                } header: {
                    Text(DataLimitsSettingsViewLabels.resetPeriod)
                } footer: {
                    Text(DataLimitsSettingsViewLabels.howOftenTheLimitResets)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        // Warning Threshold
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Toggle(DataLimitsSettingsViewLabels.warningAlert, isOn: $isWarningEnabled)
                                    .foregroundColor(.orange)
                            }
                            
                            if isWarningEnabled {
                                HStack {
                                    Text(DataLimitsSettingsViewLabels.at)
                                    Spacer()
                                    Text("\(Int(warningThreshold))%")
                                        .foregroundColor(.secondary)
                                }
                                
                                Slider(value: $warningThreshold, in: 50...95, step: 5)
                                    .accentColor(.orange)
                            }
                        }
                        
                        // Critical Threshold
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Toggle(DataLimitsSettingsViewLabels.criticalAlert, isOn: $isCriticalEnabled)
                                    .foregroundColor(.red)
                            }
                            
                            if isCriticalEnabled {
                                HStack {
                                    Text(DataLimitsSettingsViewLabels.at)
                                    Spacer()
                                    Text("\(Int(criticalThreshold))%")
                                        .foregroundColor(.secondary)
                                }
                                
                                Slider(value: $criticalThreshold, in: warningThreshold...99, step: 5)
                                    .accentColor(.red)
                            }
                        }
                    }
                } header: {
                    Text(DataLimitsSettingsViewLabels.alertThresholds)
                } footer: {
                    Text(DataLimitsSettingsViewLabels.setWhenToReceiveAlertsAboutApproachingYourDataLimit)
                }
            }
            .navigationTitle(DataLimitsSettingsViewLabels.addDataLimit)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(DataLimitsSettingsViewLabels.cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(DataLimitsSettingsViewLabels.save) {
                        saveLimit()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func saveLimit() {
        var thresholds: [AlertThreshold] = []
        
        if isWarningEnabled {
            thresholds.append(AlertThreshold(
                percentage: warningThreshold,
                isEnabled: true,
                alertType: .warning
            ))
        }
        
        if isCriticalEnabled {
            thresholds.append(AlertThreshold(
                percentage: criticalThreshold,
                isEnabled: true,
                alertType: .critical
            ))
        }
        
        let limit = DataUsageLimit(
            limitType: limitType,
            limitValue: UInt64(limitValue * 1024 * 1024 * 1024), // Convert GB to bytes
            periodType: periodType,
            isEnabled: true,
            alertThresholds: thresholds,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        dataUsageService.addDataLimit(limit)
        dismiss()
    }
}

#Preview("Add Data Limit") {
    let service = DataUsageService(startMonitoring: false)
    AddDataLimitView(dataUsageService: service)
}
