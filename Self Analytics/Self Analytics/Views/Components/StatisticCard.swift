//
//  StatisticCard.swift
//  Self Analytics
//
//  Created by Israel Manzo on 5/22/26.
//

import SwiftUI

struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
    }
}

#Preview("StatisticCard • Light") {
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    return LazyVGrid(columns: columns, spacing: 12) {
        StatisticCard(title: "Avg / Day", value: "1.4 GB", icon: "chart.bar.fill", color: .blue)
        StatisticCard(title: "Peak", value: "3.2 GB", icon: "flame.fill", color: .orange)
        StatisticCard(title: "Apps", value: "27", icon: "square.grid.2x2.fill", color: .purple)
        StatisticCard(title: "Most Used", value: "Safari", icon: "safari.fill", color: .green)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("StatisticCard • Dark") {
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    return LazyVGrid(columns: columns, spacing: 12) {
        StatisticCard(title: "Avg / Day", value: "1.4 GB", icon: "chart.bar.fill", color: .blue)
        StatisticCard(title: "Peak", value: "3.2 GB", icon: "flame.fill", color: .orange)
        StatisticCard(title: "Apps", value: "27", icon: "square.grid.2x2.fill", color: .purple)
        StatisticCard(title: "Most Used", value: "Really Long App Name", icon: "safari.fill", color: .green)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
}
