//
//  SettingsView.swift
//  Self Analytics
//
//  Created by Israel Manzo on 7/10/25.
//

import SwiftUI
import UIKit

enum SettingsSheet: Identifiable {
    case privacyPolicy, termsOfService, contactSupport

    var id: Int {
        switch self {
        case .privacyPolicy: return 0
        case .termsOfService: return 1
        case .contactSupport: return 2
        }
    }
}

struct SettingsView: View {
    @AppStorage(StorageProperties.notificationsEnabled) private var notificationsEnabled = true
    @AppStorage(StorageProperties.autoRefreshInterval) private var autoRefreshInterval = 5.0
    @AppStorage(StorageProperties.showAlerts) private var showAlerts = true
    
    @State private var activeSheet: SettingsSheet?
    @StateObject private var dataManagementService = DataManagementService()
    @State private var showingClearDataAlert = false
    @State private var showingExportSheet = false
    @State private var exportURL: URL?
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(SettingViewLabels.notifications) {
                    Toggle(SettingViewLabels.enableNotifications, isOn: $notificationsEnabled)
                    
                    if notificationsEnabled {
                        Toggle(SettingViewLabels.showAlerts, isOn: $showAlerts)
                    }
                }
                
                Section(SettingViewLabels.appSettings) {
                    Picker(SettingViewLabels.autorefreshInterval, selection: $autoRefreshInterval) {
                        Text(SettingViewLabels.TimeIntervar.ten_seconds)
                            .tag(2.0)
                        Text(SettingViewLabels.TimeIntervar.five_seconds)
                            .tag(5.0)
                        Text(SettingViewLabels.TimeIntervar.ten_seconds)
                            .tag(10.0)
                        Text(SettingViewLabels.TimeIntervar.thirty_seonconds)
                            .tag(30.0)
                    }
                    
                }
                
                Section(SettingViewLabels.about) {
                    HStack {
                        Text(SettingViewLabels.version)
                        Spacer()
                        Text(SettingViewLabels.version_number)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text(SettingViewLabels.build)
                        Spacer()
                        Text(SettingViewLabels.build_number)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(SettingViewLabels.support) {
                    Button(SettingViewLabels.privacyPolicy) {
                        // Open privacy policy
                        activeSheet = .privacyPolicy
                    }
                    
                    Button(SettingViewLabels.termsOfService) {
                        // Open terms of service
                        activeSheet = .termsOfService
                    }
                    
                    Button(SettingViewLabels.contactSupport) {
                        // Open support contact
                        activeSheet = .contactSupport
                    }
                }
                
                Section(SettingViewLabels.data) {
                    Button(SettingViewLabels.exportData) {
                        Task {
                            await exportData()
                        }
                    }
                    .disabled(dataManagementService.isExporting)
                    
                    if dataManagementService.isExporting {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text(SettingViewLabels.exportInProgress)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(SettingViewLabels.clearAllData, role: .destructive) {
                        showingClearDataAlert = true
                    }
                    .disabled(dataManagementService.isClearing)
                    
                    if dataManagementService.isClearing {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text(SettingViewLabels.clearingData)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .privacyPolicy:
                    PrivacyPolicyView()
                case .termsOfService:
                    TermsOfServiceView()
                case .contactSupport:
                    ContactSupport()
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .alert(SettingViewLabels.clearDataTitle, isPresented: $showingClearDataAlert) {
                Button(SettingViewLabels.clearDataCancel, role: .cancel) { }
                Button(SettingViewLabels.clearDataConfirm, role: .destructive) {
                    Task {
                        await clearAllData()
                    }
                }
            } message: {
                Text(SettingViewLabels.clearDataMessage)
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .navigationTitle(SettingViewLabels.settings)
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Helper Methods
    
    private func exportData() async {
        do {
            let url = try await dataManagementService.exportData()
            exportURL = url
            showingExportSheet = true
        } catch {
            errorMessage = "Failed to export data: \(error.localizedDescription)"
            showingErrorAlert = true
        }
    }
    
    private func clearAllData() async {
        await dataManagementService.clearAllData()
        // Reset local state
        notificationsEnabled = true
        autoRefreshInterval = 5.0
        showAlerts = true
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
}
