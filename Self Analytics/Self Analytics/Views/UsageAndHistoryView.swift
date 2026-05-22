//
//  UsageAndHistoryView.swift
//  Self Analytics
//
//  Data Usage tab root; device history opens in a full-screen cover.
//

import SwiftUI

/// Root for the Data Usage tab.
///
/// **Usage**
/// - Shows the data-usage dashboard (`DataUsageMainContent`).
/// - Presents device history as a full-screen cover so it can own its own navigation stack and lifecycle.
///
/// **Why full-screen?**
/// History tends to be a "deep dive" experience; using a full-screen cover also ensures any `@StateObject`
/// services created inside history are torn down when dismissed.
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

/// Wraps `HistoryMainContent` in its own navigation stack with a dedicated Done action.
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
