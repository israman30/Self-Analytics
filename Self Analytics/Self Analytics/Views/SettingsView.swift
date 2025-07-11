//
//  SettingsView.swift
//  Self Analytics
//
//  Created by Israel Manzo on 7/10/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage(StorageProperties.notificationsEnabled) private var notificationsEnabled = true
    @AppStorage(StorageProperties.autoRefreshInterval) private var autoRefreshInterval = 5.0
    @AppStorage(StorageProperties.showAlerts) private var showAlerts = true
    @AppStorage(StorageProperties.darkModeEnabled) private var darkModeEnabled = false
    
    @State private var showAlert = false
    
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
                    
                    Toggle(SettingViewLabels.darkMode, isOn: $darkModeEnabled)
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
                        showAlert.toggle()
                    }
                    
                    Button(SettingViewLabels.termsOfService) {
                        // Open terms of service
                    }
                    
                    Button(SettingViewLabels.contactSupport) {
                        // Open support contact
                    }
                }
                
                Section(SettingViewLabels.data) {
                    Button(SettingViewLabels.exportData) {
                        // Export functionality
                    }
                    
                    Button(SettingViewLabels.clearAllData, role: .destructive) {
                        // Clear data functionality
                    }
                }
            }
            .sheet(isPresented: $showAlert) {
                PrivacyPolicyView()
            }
            .navigationTitle(SettingViewLabels.settings)
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    SettingsView()
}
