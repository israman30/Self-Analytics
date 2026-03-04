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
    @AppStorage(StorageProperties.weeklyHealthSummaryEnabled) private var weeklyHealthSummaryEnabled = true
    
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
        NavigationStack {
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
                    Label(SettingViewLabels.currentDevice, systemImage: "iphone")
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
                        
                        Toggle("Weekly Health Summary", isOn: $weeklyHealthSummaryEnabled)
                            .onChange(of: weeklyHealthSummaryEnabled) { _, _ in
                                ProactiveNotificationService.shared.scheduleWeeklyHealthSummaryIfNeeded()
                            }
                            .accessibilityLabel("Weekly Health Summary")
                            .accessibilityHint("Sunday morning notification with your device health summary")
                    }
                } header: {
                    Label(SettingViewLabels.notifications, systemImage: "bell.badge")
                        .accessibilityAddTraits(.isHeader)
                }
                
                Section {
                    Picker(SettingViewLabels.autorefreshInterval, selection: $autoRefreshInterval) {
                        Text(SettingViewLabels.TimeIntervar.two_seconds)
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
                    Label(SettingViewLabels.appSettings, systemImage: "slider.horizontal.3")
                        .accessibilityAddTraits(.isHeader)
                }
                
                Section {
                    Button {
                        activeSheet = .dataUsageSettings
                    } label: {
                        HStack {
                            Label("Data Usage Settings", systemImage: "antenna.radiowaves.left.and.right")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
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
                    Label("Data Usage", systemImage: "chart.bar.doc.horizontal")
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
                    Label(SettingViewLabels.about, systemImage: "info.circle")
                        .accessibilityAddTraits(.isHeader)
                }
                
                Section {
                    Button {
                        activeSheet = .privacyPolicy
                    } label: {
                        HStack {
                            Label(SettingViewLabels.privacyPolicy, systemImage: "hand.raised")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(SettingViewLabels.privacyPolicy)
                    .accessibilityHint(AccessibilityLabels.tapToViewOurPrivacyPolicy)
                    .accessibilityAddTraits(.isButton)
                    
                    Button {
                        activeSheet = .termsOfService
                    } label: {
                        HStack {
                            Label(SettingViewLabels.termsOfService, systemImage: "doc.text")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(SettingViewLabels.termsOfService)
                    .accessibilityHint(AccessibilityLabels.tapToViewOurTermsOfService)
                    .accessibilityAddTraits(.isButton)
                    
                    Button {
                        activeSheet = .contactSupport
                    } label: {
                        HStack {
                            Label(SettingViewLabels.contactSupport, systemImage: "envelope")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(SettingViewLabels.contactSupport)
                    .accessibilityHint(AccessibilityLabels.tapToContactOurSupportTeam)
                    .accessibilityAddTraits(.isButton)
                } header: {
                    Label(SettingViewLabels.support, systemImage: "questionmark.circle")
                        .accessibilityAddTraits(.isHeader)
                }
                
                Section {
                    Button {
                        Task { await exportData() }
                    } label: {
                        Label(SettingViewLabels.exportData, systemImage: "square.and.arrow.up")
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
                    Label(SettingViewLabels.data, systemImage: "externaldrive")
                        .accessibilityAddTraits(.isHeader)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
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
