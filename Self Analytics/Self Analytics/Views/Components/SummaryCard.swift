//
//  SummaryCard.swift
//  Self Analytics
//
//  Created by Israel Manzo on 5/22/26.
//

import SwiftUI

struct SummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

#Preview("SummaryCard • Light") {
    SummaryCard(
        title: "Today",
        value: "1.2 GB",
        subtitle: "Used • 3 apps",
        color: .blue,
        icon: "antenna.radiowaves.left.and.right"
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("SummaryCard • Dark") {
    SummaryCard(
        title: "Battery",
        value: "7h 42m",
        subtitle: "Screen-on time",
        color: .green,
        icon: "bolt.fill"
    )
    .padding()
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
}
