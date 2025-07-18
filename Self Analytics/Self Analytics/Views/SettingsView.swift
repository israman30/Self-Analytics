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
    private var deviceInformation = DeviceInformation()
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Text(SettingViewLabels.deviceModel)
                        Spacer()
                        Text(deviceInformation.getDeviceName())
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    
                    HStack {
                        Text(SettingViewLabels.systemVersion)
                        Spacer()
                        Text(deviceInformation.getDeviceModel())
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    
                } header: {
                    Text(SettingViewLabels.currentDevice)
                        .accessibilityAddTraits(.isHeader)
                }
                
                Section {
                    Toggle(SettingViewLabels.enableNotifications, isOn: $notificationsEnabled)
                    
                    if notificationsEnabled {
                        Toggle(SettingViewLabels.showAlerts, isOn: $showAlerts)
                    }
                } header: {
                    Text(SettingViewLabels.notifications)
                        .accessibilityAddTraits(.isHeader)
                }
                
                Section {
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
                    
                } header: {
                    Text(SettingViewLabels.appSettings)
                        .accessibilityAddTraits(.isHeader)
                }
                
                Section {
                    HStack {
                        Text(SettingViewLabels.version)
                        Spacer()
                        Text(SettingViewLabels.version_number)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    
                    HStack {
                        Text(SettingViewLabels.build)
                        Spacer()
                        Text(SettingViewLabels.build_number)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                } header: {
                    Text(SettingViewLabels.about)
                        .accessibilityAddTraits(.isHeader)
                }
                // SUPPORT SECTION
                Section {
                    Button(SettingViewLabels.privacyPolicy) {
                        // Open privacy policy
                        activeSheet = .privacyPolicy
                    }
                    .accessibilityHint("Tap to view our privacy policy.")
                    
                    Button(SettingViewLabels.termsOfService) {
                        // Open terms of service
                        activeSheet = .termsOfService
                    }
                    .accessibilityHint("Tap to view our terms of service.")
                    
                    Button(SettingViewLabels.contactSupport) {
                        // Open support contact
                        activeSheet = .contactSupport
                    }
                    .accessibilityHint("Tap to contact our support team.")
                } header: {
                    Text(SettingViewLabels.support)
                        .accessibilityAddTraits(.isHeader)
                }
                
                // DATA SECTION
                Section {
                    Button(SettingViewLabels.exportData) {
                        Task {
                            await exportData()
                        }
                    }
                    .disabled(dataManagementService.isExporting)
                    .accessibilityHint("Tap to export your data.")
                    
                    if dataManagementService.isExporting {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text(SettingViewLabels.exportInProgress)
                                .foregroundColor(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                    
                    Button(SettingViewLabels.clearAllData, role: .destructive) {
                        showingClearDataAlert = true
                    }
                    .disabled(dataManagementService.isClearing)
                    .accessibilityHint("Tap to clear all your data. This action cannot be undone.")
                    
                    if dataManagementService.isClearing {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text(SettingViewLabels.clearingData)
                                .foregroundColor(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                } header: {
                    Text(SettingViewLabels.data)
                        .accessibilityAddTraits(.isHeader)
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
        .navigationViewStyle(.stack)
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
