//
//  StatCard.swift
//  Self Analytics
//
//  Created by Israel Manzo on 5/22/26.
//

import SwiftUI

struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    let trend: TrendDirection
    
    enum TrendDirection {
        case up, down, stable
        
        var icon: String {
            switch self {
            case .up: return HistoryViewLabels.Icon.arrow_up
            case .down: return HistoryViewLabels.Icon.arrow_down
            case .stable: return HistoryViewLabels.Icon.minus
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .red
            case .down: return .green
            case .stable: return .blue
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                    .accessibilityHidden(true)
                
                Spacer()
                
                Image(systemName: trend.icon)
                    .foregroundColor(trend.color)
                    .font(.caption2)
                    .accessibilityHidden(true)
            }
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
        .accessibilityHint("Shows \(label.lowercased()) value with trend indicator")
    }
}

#Preview("StatCard • Trends") {
    HStack(spacing: 12) {
        StatCard(
            icon: HistoryViewLabels.Icon.chart_line_uptrend_xyaxis,
            label: HistoryViewLabels.average,
            value: "42.1%",
            color: .orange,
            trend: .stable
        )
        
        StatCard(
            icon: HistoryViewLabels.Icon.arrow_up_circle_fill,
            label: HistoryViewLabels.peak,
            value: "78.4%",
            color: .orange,
            trend: .up
        )
        
        StatCard(
            icon: HistoryViewLabels.Icon.clock_fill,
            label: HistoryViewLabels.current,
            value: "31.9%",
            color: .orange,
            trend: .down
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("StatCard • Trends (Dark)") {
    HStack(spacing: 12) {
        StatCard(
            icon: HistoryViewLabels.Icon.chart_line_uptrend_xyaxis,
            label: HistoryViewLabels.average,
            value: "6.2 GB",
            color: .blue,
            trend: .stable
        )
        
        StatCard(
            icon: HistoryViewLabels.Icon.arrow_up_circle_fill,
            label: HistoryViewLabels.peak,
            value: "9.8 GB",
            color: .blue,
            trend: .up
        )
        
        StatCard(
            icon: HistoryViewLabels.Icon.clock_fill,
            label: HistoryViewLabels.current,
            value: "4.1 GB",
            color: .blue,
            trend: .down
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
}
