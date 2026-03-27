//
//  UsageAndHistoryView.swift
//  Self Analytics
//
//  Data Usage tab root; device history opens in a full-screen cover.
//

import SwiftUI

struct UsageAndHistoryView: View {
    @State private var showDeviceHistory = false

    var body: some View {
        NavigationStack {
            DataUsageMainContent()
                .navigationTitle(DataUsageLabels.dataUsage)
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showDeviceHistory = true
                        } label: {
                            Label(
                                HistoryViewLabels.history,
                                systemImage: MainTabViewLabels.Icon.chart_line_uptrend_xyaxis
                            )
                        }
                        .accessibilityHint(
                            MainTabViewLabels.view_historical_device_performance_data_and_trends
                        )
                    }
                }
        }
        .fullScreenCover(isPresented: $showDeviceHistory) {
            DeviceHistoryFullScreenView()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(MainTabViewLabels.view_data_usage_tracking_and_limits)
        .accessibilityHint(MainTabViewLabels.view_data_usage_tracking_and_limits)
    }
}

// MARK: - Full-screen history

private struct DeviceHistoryFullScreenView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            HistoryMainContent()
                .navigationTitle(HistoryViewLabels.history)
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(SpeedTestViewLabels.done) {
                            dismiss()
                        }
                        .accessibilityLabel(SpeedTestViewLabels.done)
                    }
                }
        }
    }
}

#Preview {
    UsageAndHistoryView()
}
