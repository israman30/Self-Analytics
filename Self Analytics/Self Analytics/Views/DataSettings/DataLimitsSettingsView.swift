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

#Preview {
    DataLimitsSettingsView(dataUsageService: DataUsageService())
}
