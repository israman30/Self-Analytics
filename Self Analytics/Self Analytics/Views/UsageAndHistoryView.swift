//
//  UsageAndHistoryView.swift
//  Self Analytics
//
//  Unified data usage and device history in one tab with a segmented control.
//

import SwiftUI

struct UsageAndHistoryView: View {
    private enum Segment: Hashable {
        case dataUsage
        case deviceHistory
    }

    @State private var segment: Segment = .dataUsage

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $segment) {
                    Text(MainTabViewLabels.dataUsage).tag(Segment.dataUsage)
                    Text(MainTabViewLabels.history).tag(Segment.deviceHistory)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .accessibilityLabel(MainTabViewLabels.usageHistorySegmentAccessibility)

                Group {
                    switch segment {
                    case .dataUsage:
                        DataUsageMainContent()
                    case .deviceHistory:
                        HistoryMainContent()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeInOut(duration: 0.2), value: segment)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.large)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }

    private var navigationTitle: String {
        switch segment {
        case .dataUsage:
            return DataUsageLabels.dataUsage
        case .deviceHistory:
            return HistoryViewLabels.history
        }
    }

    private var accessibilityLabel: String {
        switch segment {
        case .dataUsage:
            return MainTabViewLabels.view_data_usage_tracking_and_limits
        case .deviceHistory:
            return AccessibilityLabels.deviceHistory
        }
    }

    private var accessibilityHint: String {
        switch segment {
        case .dataUsage:
            return MainTabViewLabels.view_data_usage_tracking_and_limits
        case .deviceHistory:
            return AccessibilityLabels.view_historical_device_performance_data_and_trends
        }
    }
}

#Preview {
    UsageAndHistoryView()
}
