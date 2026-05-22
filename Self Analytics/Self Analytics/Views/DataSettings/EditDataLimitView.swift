//
//  EditDataLimitView.swift
//  Self Analytics
//
//  Created by Israel Manzo on 5/22/26.
//

import SwiftUI

struct EditDataLimitView: View {
    @ObservedObject var dataUsageService: DataUsageService
    let limit: DataUsageLimit
    @Environment(\.dismiss) private var dismiss
    
    @State private var limitValue: Double
    @State private var periodType: DataUsagePeriod.PeriodType
    @State private var isEnabled: Bool
    @State private var warningThreshold: Double
    @State private var criticalThreshold: Double
    @State private var isWarningEnabled: Bool
    @State private var isCriticalEnabled: Bool
    
    init(dataUsageService: DataUsageService, limit: DataUsageLimit) {
        self.dataUsageService = dataUsageService
        self.limit = limit
        
        self._limitValue = State(initialValue: Double(limit.limitValue) / (1024 * 1024 * 1024)) // Convert bytes to GB
        self._periodType = State(initialValue: limit.periodType)
        self._isEnabled = State(initialValue: limit.isEnabled)
        
        let warningThreshold = limit.alertThresholds.first { $0.alertType == .warning }
        let criticalThreshold = limit.alertThresholds.first { $0.alertType == .critical }
        
        self._warningThreshold = State(initialValue: warningThreshold?.percentage ?? 75)
        self._criticalThreshold = State(initialValue: criticalThreshold?.percentage ?? 90)
        self._isWarningEnabled = State(initialValue: warningThreshold?.isEnabled ?? true)
        self._isCriticalEnabled = State(initialValue: criticalThreshold?.isEnabled ?? true)
    }
    
    private let periodOptions: [(String, DataUsagePeriod.PeriodType)] = [
        (DataLimitsSettingsViewLabels.daily, .today),
        (DataLimitsSettingsViewLabels.weekly, .thisWeek),
        (DataLimitsSettingsViewLabels.monthly, .thisMonth)
    ]
    
    var body: some View {
        NavigationView {
            Form {
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
                }
                
                Section {
                    Picker(DataLimitsSettingsViewLabels.resetPeriod, selection: $periodType) {
                        ForEach(periodOptions, id: \.1) { option in
                            Text(option.0).tag(option.1)
                        }
                    }
                } header: {
                    Text(DataLimitsSettingsViewLabels.resetPeriod)
                }
                
                Section {
                    Toggle(DataLimitsSettingsViewLabels.enableLimit, isOn: $isEnabled)
                } header: {
                    Text(DataLimitsSettingsViewLabels.status)
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
                }
            }
            .navigationTitle(DataLimitsSettingsViewLabels.editAlertLimit)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(DataLimitsSettingsViewLabels.cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(DataLimitsSettingsViewLabels.save) {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func saveChanges() {
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
        
        let updatedLimit = DataUsageLimit(
            limitType: limit.limitType,
            limitValue: UInt64(limitValue * 1024 * 1024 * 1024), // Convert GB to bytes
            periodType: periodType,
            isEnabled: isEnabled,
            alertThresholds: thresholds,
            createdAt: limit.createdAt,
            updatedAt: Date()
        )
        
        dataUsageService.updateDataLimit(updatedLimit)
        dismiss()
    }
}

#Preview("Edit Data Limit") {
    let service = DataUsageService(startMonitoring: false)
    let limit = DataUsageLimit(
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
    
    EditDataLimitView(dataUsageService: service, limit: limit)
}
