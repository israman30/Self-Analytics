//
//  DataLimitsSettingsView.swift
//  Self Analytics
//
//  Created by Israel Manzo on 7/10/25.
//

import SwiftUI

struct DataLimitsSettingsView: View {
    @ObservedObject var dataUsageService: DataUsageService
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddLimit = false
    @State private var editingLimit: DataUsageLimit?
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(dataUsageService.dataUsageLimits) { limit in
                        DataLimitSettingsRow(limit: limit) {
                            editingLimit = limit
                        } onToggle: {
                            dataUsageService.toggleDataLimit(limit)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let limit = dataUsageService.dataUsageLimits[index]
                            dataUsageService.deleteDataLimit(limit)
                        }
                    }
                } header: {
                    Text(DataLimitsSettingsViewLabels.dataLimits)
                } footer: {
                    Text(DataLimitsSettingsViewLabels.setDataUsageLimitsToReceiveAlertsWhenYouApproachYourMonthlyAllowance)
                }
                
                Section {
                    Button(DataLimitsSettingsViewLabels.addNewLimit) {
                        showingAddLimit = true
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle(DataLimitsSettingsViewLabels.dataLimits)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(DataLimitsSettingsViewLabels.done) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddLimit) {
                AddDataLimitView(dataUsageService: dataUsageService)
            }
            .sheet(item: $editingLimit) { limit in
                EditDataLimitView(dataUsageService: dataUsageService, limit: limit)
            }
        }
    }
}

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
                }
            }
            
            Spacer()
            
            VStack {
                Toggle("", isOn: .constant(limit.isEnabled))
                    .onChange(of: limit.isEnabled) { _ , _ in
                        onToggle()
                    }
                
                Button("Edit") {
                    onEdit()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

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
        ("Cellular Data", .cellular),
        ("Wi-Fi Data", .wifi),
        ("Total Data", .total)
    ]
    
    private let periodOptions: [(String, DataUsagePeriod.PeriodType)] = [
        ("Daily", .today),
        ("Weekly", .thisWeek),
        ("Monthly", .thisMonth)
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("Limit Type", selection: $limitType) {
                        ForEach(limitOptions, id: \.1) { option in
                            Text(option.0).tag(option.1)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Data Type")
                } footer: {
                    Text("Choose which type of data usage to limit.")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Limit Amount")
                            Spacer()
                            Text("\(String(format: "%.1f", limitValue)) GB")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $limitValue, in: 0.1...100, step: 0.1)
                            .accentColor(.blue)
                    }
                } header: {
                    Text("Limit Value")
                } footer: {
                    Text("Set the maximum amount of data usage allowed.")
                }
                
                Section {
                    Picker("Reset Period", selection: $periodType) {
                        ForEach(periodOptions, id: \.1) { option in
                            Text(option.0).tag(option.1)
                        }
                    }
                } header: {
                    Text("Reset Period")
                } footer: {
                    Text("How often the limit resets.")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        // Warning Threshold
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Toggle("Warning Alert", isOn: $isWarningEnabled)
                                    .foregroundColor(.orange)
                            }
                            
                            if isWarningEnabled {
                                HStack {
                                    Text("At")
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
                                Toggle("Critical Alert", isOn: $isCriticalEnabled)
                                    .foregroundColor(.red)
                            }
                            
                            if isCriticalEnabled {
                                HStack {
                                    Text("At")
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
                    Text("Alert Thresholds")
                } footer: {
                    Text("Set when to receive alerts about approaching your data limit.")
                }
            }
            .navigationTitle("Add Data Limit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
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
        ("Daily", .today),
        ("Weekly", .thisWeek),
        ("Monthly", .thisMonth)
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Limit Amount")
                            Spacer()
                            Text("\(String(format: "%.1f", limitValue)) GB")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $limitValue, in: 0.1...100, step: 0.1)
                            .accentColor(.blue)
                    }
                } header: {
                    Text("Limit Value")
                }
                
                Section {
                    Picker("Reset Period", selection: $periodType) {
                        ForEach(periodOptions, id: \.1) { option in
                            Text(option.0).tag(option.1)
                        }
                    }
                } header: {
                    Text("Reset Period")
                }
                
                Section {
                    Toggle("Enable Limit", isOn: $isEnabled)
                } header: {
                    Text("Status")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        // Warning Threshold
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Toggle("Warning Alert", isOn: $isWarningEnabled)
                                    .foregroundColor(.orange)
                            }
                            
                            if isWarningEnabled {
                                HStack {
                                    Text("At")
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
                                Toggle("Critical Alert", isOn: $isCriticalEnabled)
                                    .foregroundColor(.red)
                            }
                            
                            if isCriticalEnabled {
                                HStack {
                                    Text("At")
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
                    Text("Alert Thresholds")
                }
            }
            .navigationTitle("Edit Data Limit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
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

#Preview {
    DataLimitsSettingsView(dataUsageService: DataUsageService())
}
