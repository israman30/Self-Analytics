//  SecurityScanView.swift
//  Self Analytics
//
//  Created by Israel Manzo on 9/21/25.
//

import SwiftUI

struct SecurityScanView: View {
    @StateObject private var scanner = DeviceSecurityScanner()
    @State private var isScanning = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    SecurityScanScoreCard(score: scanner.securityScore)

                    scanButtonSection

                    if !scanner.securityFindings.isEmpty {
                        scannedBody
                    } else if !isScanning {
                        safeStateCard
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .refreshable { await runScanAsync() }
            .navigationTitle("Security Scan")
            .navigationBarTitleDisplayMode(.large)
            .onAppear(perform: runScan)
        }
    }
    
    private var scanButtonSection: some View {
        Button(action: runScan) {
            HStack(spacing: 10) {
                if isScanning {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "arrow.clockwise")
                }
                Text(isScanning ? "Scanning..." : "Scan Now")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isScanning)
        .animation(.easeInOut(duration: 0.2), value: isScanning)
    }
    
    private var safeStateCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 40))
                .foregroundStyle(.green)
            Text("All Clear")
                .font(.headline)
                .foregroundColor(.primary)
            Text("No security risks detected. Your device and network are safe.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private func runScan() {
        isScanning = true
        Task {
            await runScanAsync()
        }
    }
    
    private func runScanAsync() async {
        isScanning = true
        await scanner.performSecurityScan()
        isScanning = false
    }
    
    private var scannedBody: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !scanner.securityFindings.isEmpty {
                findingsSection
            }
            if !scanner.recommendations.isEmpty {
                recommendationsSection
            }
        }
    }
    
    private var findingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Findings")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 0) {
                ForEach(Array(scanner.securityFindings.enumerated()), id: \.element.title) { index, finding in
                    findingRow(finding)
                    if index < scanner.securityFindings.count - 1 {
                        Divider()
                            .padding(.leading, 44)
                    }
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
    
    private func findingRow(_ finding: SecurityFinding) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: finding.iconName)
                .font(.title3)
                .foregroundColor(Color(finding.severityColor))
                .frame(width: 28, alignment: .center)
            VStack(alignment: .leading, spacing: 4) {
                Text(finding.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text(finding.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
    }
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendations")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 0) {
                ForEach(Array(scanner.recommendations.enumerated()), id: \.element.title) { index, rec in
                    recommendationRow(rec)
                    if index < scanner.recommendations.count - 1 {
                        Divider()
                            .padding(.leading, 44)
                    }
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
    
    private func recommendationRow(_ rec: SecurityRecommendation) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: rec.iconName)
                .font(.title3)
                .foregroundColor(Color(rec.impactColor))
                .frame(width: 28, alignment: .center)
            VStack(alignment: .leading, spacing: 4) {
                Text(rec.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text(rec.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
    }
}

#Preview {
    SecurityScanView()
}

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
