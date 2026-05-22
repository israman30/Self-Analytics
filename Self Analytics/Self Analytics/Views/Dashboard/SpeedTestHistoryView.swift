//
//  SpeedTestHistoryView.swift
//  Self Analytics
//
//  Created by Israel Manzo on 5/21/26.
//

import SwiftUI

// MARK: - Speed Test History View
struct SpeedTestHistoryView: View {
    let history: [(download: Double, upload: Double, timestamp: Date)]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(history.enumerated().reversed()), id: \.offset) { index, test in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Test #\(history.count - index)")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text(test.timestamp, style: .relative)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(SpeedTestViewLabels.download)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(String(format: "%.1f", test.download)) Mbps")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(SpeedTestViewLabels.upload)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(String(format: "%.1f", test.upload)) Mbps")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        HStack {
                            Text(speedDescription(for: test.download))
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(speedColor(for: test.download).opacity(0.2))
                                .foregroundColor(speedColor(for: test.download))
                                .cornerRadius(8)
                            
                            Spacer()
                            
                            Text(speedDescription(for: test.upload))
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(speedColor(for: test.upload).opacity(0.2))
                                .foregroundColor(speedColor(for: test.upload))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Test \(history.count - index): Download \(String(format: "%.1f", test.download)) Mbps, Upload \(String(format: "%.1f", test.upload)) Mbps")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle(SpeedTestViewLabels.testHistory)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(SpeedTestViewLabels.done) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func speedDescription(for speed: Double) -> String {
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
    
    private func speedColor(for speed: Double) -> Color {
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

#Preview("Speed Test History") {
    let now = Date()
    let mockHistory: [(download: Double, upload: Double, timestamp: Date)] = [
        (download: 96.4, upload: 24.7, timestamp: now.addingTimeInterval(-5 * 60)),
        (download: 42.1, upload: 18.3, timestamp: now.addingTimeInterval(-35 * 60)),
        (download: 22.8, upload: 9.6, timestamp: now.addingTimeInterval(-2 * 60 * 60)),
        (download: 8.2, upload: 1.1, timestamp: now.addingTimeInterval(-8 * 60 * 60)),
        (download: 3.9, upload: 0.6, timestamp: now.addingTimeInterval(-26 * 60 * 60))
    ]
    
    SpeedTestHistoryView(history: mockHistory)
}
