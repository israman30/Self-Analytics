//
//  SummaryRow.swift
//  Self Analytics
//
//  Created by Israel Manzo on 5/22/26.
//

import SwiftUI

struct SummaryRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

#Preview("SummaryRow • Light") {
    VStack(alignment: .leading, spacing: 12) {
        SummaryRow(title: "Average Score", value: "82.4", color: .green)
        Divider()
        SummaryRow(title: "Peak CPU", value: "78.4%", color: .orange)
        Divider()
        SummaryRow(title: "Peak Memory", value: "91.2%", color: .red)
        Divider()
        SummaryRow(title: "Lowest Battery", value: "18%", color: .orange)
    }
    .padding()
    .background(Color(.systemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("SummaryRow • Dark") {
    VStack(alignment: .leading, spacing: 12) {
        SummaryRow(title: "Average Score", value: "66.0", color: .orange)
        Divider()
        SummaryRow(title: "Peak CPU", value: "92.1%", color: .red)
        Divider()
        SummaryRow(title: "Peak Memory", value: "74.5%", color: .green)
        Divider()
        SummaryRow(title: "Lowest Battery", value: "12%", color: .red)
    }
    .padding()
    .background(Color(.systemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    .padding()
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
}
