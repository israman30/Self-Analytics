//
//  WelcomeView.swift
//  Self Analytics
//
//  Created by Cursor on 4/23/26.
//

import SwiftUI

struct WelcomeView: View {
    var onGetStarted: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 44))
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                    
                    Text("Welcome to Device Health")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Monitor device health, track data usage, and review security signals in one place. Get clear trends, alerts, and recommendations to help keep your iPhone running smoothly.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)
                
                Spacer()
                
                Button("Get Started") {
                    onGetStarted()
                }
                .buttonStyle(.borderedProminent)
                .fontWeight(.semibold)
            }
            .padding(24)
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { onGetStarted() }
                }
            }
        }
    }
}

#Preview {
    WelcomeView { }
}

