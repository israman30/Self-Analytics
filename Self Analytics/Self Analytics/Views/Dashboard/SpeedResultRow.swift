//
//  SpeedResultRow.swift
//  Self Analytics
//
//  Created by Israel Manzo on 5/21/26.
//

import SwiftUI

// Speed Result Row
struct SpeedResultRow: View {
    let title: String
    let speed: Double
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(String(format: "%.1f", speed)) Mbps")
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            Spacer()
            
            Text(speedDescription)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(speedColor.opacity(0.2))
                .foregroundColor(speedColor)
                .cornerRadius(8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(String(format: "%.1f", speed)) Mbps, \(speedDescription)")
    }
    // Speed Description helper
    private var speedDescription: String {
        if speed >= 50 {
            return SpeedTestViewLabels.fast
        } else if speed >= 25 {
            return SpeedTestViewLabels.good
        } else if speed >= 10 {
            return SpeedTestViewLabels.fair
        } else {
            return SpeedTestViewLabels.slow
        }
    }
    // Speed Color helper
    private var speedColor: Color {
        if speed >= 50 {
            return .green
        } else if speed >= 25 {
            return .blue
        } else if speed >= 10 {
            return .orange
        } else {
            return .red
        }
    }
}

#Preview("SpeedResultRow") {
    VStack(spacing: 12) {
        SpeedResultRow(
            title: SpeedTestViewLabels.download,
            speed: 96.4,
            icon: "arrow.down.circle.fill",
            color: .blue
        )

        SpeedResultRow(
            title: SpeedTestViewLabels.upload,
            speed: 18.7,
            icon: "arrow.up.circle.fill",
            color: .purple
        )

        SpeedResultRow(
            title: SpeedTestViewLabels.speed,
            speed: 4.9,
            icon: "speedometer",
            color: .orange
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
