//
//  SettingsView.swift
//  Self Analytics
//
//  Created by Israel Manzo on 7/10/25.
//

import SwiftUI
import UIKit

enum SettingsSheet: Identifiable {
    case privacyPolicy
    case termsOfService
    case contactSupport
    case dataUsageSettings

    var id: Int {
        switch self {
        case .privacyPolicy: return 0
        case .termsOfService: return 1
        case .contactSupport: return 2
        case .dataUsageSettings: return 3
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
    @StateObject private var dataUsageService = DataUsageService()
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
                    .accessibilityLabel(
                        "Device Model: \(deviceInformation.getDeviceName())"
                    )
                    
                    HStack {
                        Text(SettingViewLabels.systemVersion)
                        Spacer()
                        Text(deviceInformation.getDeviceModel())
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(
                        "System Version: \(deviceInformation.getDeviceModel())"
                    )
                    
                } header: {
                    Text(SettingViewLabels.currentDevice)
                        .accessibilityAddTraits(.isHeader)
                }
                
                Section {
                    Toggle(SettingViewLabels.enableNotifications, isOn: $notificationsEnabled)
                        .accessibilityLabel(SettingViewLabels.enableNotifications)
                        .accessibilityHint(
                            AccessibilityHints.enable_or_disable_push_notifications_for_device_alerts
                        )
                    
                    if notificationsEnabled {
                        Toggle(SettingViewLabels.showAlerts, isOn: $showAlerts)
                            .accessibilityLabel(SettingViewLabels.showAlerts)
                            .accessibilityHint(
                                AccessibilityHints.show_or_hide_alert_notifications_in_the_app
                            )
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
                    .accessibilityLabel(SettingViewLabels.autorefreshInterval)
                    .accessibilityHint(
                        AccessibilityHints.select_how_often_the_app_should_refresh_device_metrics
                    )
                    
                } header: {
                    Text(SettingViewLabels.appSettings)
                        .accessibilityAddTraits(.isHeader)
                }
                
                Section {
                    Button("Data Usage Settings") {
                        activeSheet = .dataUsageSettings
                    }
                    .accessibilityLabel("Data Usage Settings")
                    .accessibilityHint("Configure data usage limits and alerts")
                    .accessibilityAddTraits(.isButton)
                    
                    HStack {
                        Text("Active Limits")
                        Spacer()
                        Text("\(dataUsageService.dataUsageLimits.filter { $0.isEnabled }.count)")
                            .foregroundColor(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Active data usage limits: \(dataUsageService.dataUsageLimits.filter { $0.isEnabled }.count)")
                    
                    HStack {
                        Text("Active Alerts")
                        Spacer()
                        Text("\(dataUsageService.activeAlerts.filter { !$0.isRead }.count)")
                            .foregroundColor(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Active data usage alerts: \(dataUsageService.activeAlerts.filter { !$0.isRead }.count)")
                    
                } header: {
                    Text("Data Usage")
                        .accessibilityAddTraits(.isHeader)
                } footer: {
                    Text("Configure data usage limits and alerts to monitor your cellular and Wi-Fi data consumption.")
                }
                
                Section {
                    HStack {
                        Text(SettingViewLabels.version)
                        Spacer()
                        Text(SettingViewLabels.version_number)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("App Version: \(SettingViewLabels.version_number)")
                    
                    HStack {
                        Text(SettingViewLabels.build)
                        Spacer()
                        Text(SettingViewLabels.build_number)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Build Number: \(SettingViewLabels.build_number)")
                } header: {
                    Text(SettingViewLabels.about)
                        .accessibilityAddTraits(.isHeader)
                }
                
                Section {
                    Button(SettingViewLabels.privacyPolicy) {
                        // Open privacy policy
                        activeSheet = .privacyPolicy
                    }
                    .accessibilityLabel(SettingViewLabels.privacyPolicy)
                    .accessibilityHint(AccessibilityLabels.tapToViewOurPrivacyPolicy)
                    .accessibilityAddTraits(.isButton)
                    
                    Button(SettingViewLabels.termsOfService) {
                        // Open terms of service
                        activeSheet = .termsOfService
                    }
                    .accessibilityLabel(SettingViewLabels.termsOfService)
                    .accessibilityHint(AccessibilityLabels.tapToViewOurTermsOfService)
                    .accessibilityAddTraits(.isButton)
                    
                    Button(SettingViewLabels.contactSupport) {
                        // Open support contact
                        activeSheet = .contactSupport
                    }
                    .accessibilityLabel(SettingViewLabels.contactSupport)
                    .accessibilityHint(AccessibilityLabels.tapToContactOurSupportTeam)
                    .accessibilityAddTraits(.isButton)
                } header: {
                    Text(SettingViewLabels.support)
                        .accessibilityAddTraits(.isHeader)
                }
                
                Section {
                    Button(SettingViewLabels.exportData) {
                        Task {
                            await exportData()
                        }
                    }
                    .disabled(dataManagementService.isExporting)
                    .accessibilityLabel(SettingViewLabels.exportData)
                    .accessibilityHint(AccessibilityLabels.tapToExportYourData)
                    .accessibilityAddTraits(.isButton)
                    
                    if dataManagementService.isExporting {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                                .accessibilityLabel(AccessibilityLabels.exportInProgress)
                            Text(SettingViewLabels.exportInProgress)
                                .foregroundColor(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(AccessibilityLabels.exportingDataPleaseWait)
                    }
                    
                    Button(SettingViewLabels.clearAllData, role: .destructive) {
                        showingClearDataAlert = true
                    }
                    .disabled(dataManagementService.isClearing)
                    .accessibilityLabel(SettingViewLabels.clearAllData)
                    .accessibilityHint(AccessibilityLabels.tapToClearAllYourData_thisActionCannotBeUndone)
                    .accessibilityAddTraits(.isButton)
                    
                    if dataManagementService.isClearing {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                                .accessibilityLabel(AccessibilityLabels.clearingInProgress)
                            Text(SettingViewLabels.clearingData)
                                .foregroundColor(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(AccessibilityLabels.clearingInProgress)
                    }
                } header: {
                    Text(SettingViewLabels.data)
                        .accessibilityAddTraits(.isHeader)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(SettingViewLabels.settings)
            .accessibilityHint(AccessibilityHints.configure_app_preferences_and_manage_data)
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .privacyPolicy:
                    PrivacyPolicyView()
                case .termsOfService:
                    TermsOfServiceView()
                case .contactSupport:
                    ContactSupport()
                case .dataUsageSettings:
                    DataLimitsSettingsView(dataUsageService: dataUsageService)
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
