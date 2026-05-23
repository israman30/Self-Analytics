//
//  SecurityScanScoreCard.swift
//  Self Analytics
//
//  Created by Israel Manzo on 5/22/26.
//

import SwiftUI

// MARK: - SecurityScanScoreCard
struct SecurityScanScoreCard: View {
    let score: Int
    
    private var scoreColor: Color {
        score >= 85 ? .green : score >= 60 ? .orange : .red
    }
    
    private var statusIcon: String {
        score >= 85 ? "checkmark.shield.fill" : score >= 60 ? "exclamationmark.shield.fill" : "xmark.shield.fill"
    }
    
    var body: some View {
        HStack(spacing: 18) {
            Image(systemName: statusIcon)
                .font(.system(size: 44))
                .foregroundColor(scoreColor)
            VStack(alignment: .leading, spacing: 4) {
                Text("Security Score")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("\(score) / 100")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(scoreColor)
            }
            Spacer()
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Security score \(score) out of 100")
    }
}

#Preview("SecurityScanScoreCard • States") {
    VStack(spacing: 16) {
        SecurityScanScoreCard(score: 92)
        SecurityScanScoreCard(score: 72)
        SecurityScanScoreCard(score: 41)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("SecurityScanScoreCard • Dark") {
    VStack(spacing: 16) {
        SecurityScanScoreCard(score: 92)
        SecurityScanScoreCard(score: 72)
        SecurityScanScoreCard(score: 41)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
}
