//
//  NotificationPermissionPromptView.swift
//  Self Analytics
//
//  Created by Cursor on 4/22/26.
//

import SwiftUI
import UIKit

struct NotificationPermissionPromptView: View {
    @Binding var isPresented: Bool
    @Binding var notificationsEnabled: Bool
    
    @Environment(\.openURL) private var openURL
    @State private var isRequesting = false
    @State private var authorizationDenied = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(spacing: 10) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                    
                    Text("Enable Notifications")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Get alerts for low storage, high memory pressure, and unusual battery drain. You can change this any time in Settings.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)
                
                if authorizationDenied {
                    VStack(spacing: 8) {
                        Text("Notifications are currently disabled for Self Analytics.")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("To turn them on, open iOS Settings → Notifications → Self Analytics.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Open iOS Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                openURL(url)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 4)
                }
                
                Spacer()
                
                VStack(spacing: 10) {
                    Button {
                        requestPermission()
                    } label: {
                        HStack(spacing: 10) {
                            if isRequesting {
                                ProgressView()
                            }
                            Text(isRequesting ? "Requesting…" : "Enable Notifications")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isRequesting)
                    
                    Button("Not Now") {
                        notificationsEnabled = false
                        ProactiveNotificationService.shared.handleUserDisabledNotifications()
                        isPresented = false
                    }
                    .buttonStyle(.bordered)
                    .disabled(isRequesting)
                }
            }
            .padding(24)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { isPresented = false }
                        .disabled(isRequesting)
                }
            }
        }
    }
    
    private func requestPermission() {
        authorizationDenied = false
        isRequesting = true
        Task {
            let granted = await ProactiveNotificationService.shared.handleUserEnabledNotifications()
            await MainActor.run {
                isRequesting = false
                if granted {
                    isPresented = false
                } else {
                    authorizationDenied = true
                }
            }
        }
    }
}

#Preview {
    NotificationPermissionPromptView(
        isPresented: .constant(true),
        notificationsEnabled: .constant(true)
    )
}

