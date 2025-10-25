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
        NavigationView {
            VStack(spacing: 20) {
                SecurityScanScoreCard(score: scanner.securityScore)

                if isScanning {
                    ProgressView("Scanning for vulnerabilities...")
                        .padding()
                } else {
                    Button(action: runScan) {
                        Label("Scan Now", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom)
                }

                if !scanner.securityFindings.isEmpty {
                    scannedBody
                } else {
                    Text("No security risks detected. Your device and network are safe.")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .padding()
                }
            }
            .padding()
            .navigationTitle("Security Scan")
        }
        .navigationViewStyle(.stack)
        .onAppear(perform: runScan)
    }
    
    private func runScan() {
        isScanning = true
        Task {
            await scanner.performSecurityScan()
            isScanning = false
        }
    }
    
    private var scannedBody: some View {
        List {
            Section(header: Text("Findings")) {
                ForEach(scanner.securityFindings, id: \.title) { finding in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: finding.iconName)
                                .foregroundColor(Color(finding.severityColor))
                            Text(finding.title)
                                .fontWeight(.semibold)
                        }
                        Text(finding.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }

            if !scanner.recommendations.isEmpty {
                Section(header: Text("Recommendations")) {
                    ForEach(scanner.recommendations, id: \.title) { rec in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: rec.iconName)
                                .foregroundColor(Color(rec.impactColor))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(rec.title)
                                    .fontWeight(.semibold)
                                Text(rec.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .listStyle(.automatic)
    }
}

#Preview {
    SecurityScanView()
}

// MARK: - SecurityScanScoreCard
struct SecurityScanScoreCard: View {
    let score: Int
    var body: some View {
        HStack(spacing: 18) {
            Image(systemName: score >= 85 ? "checkmark.shield.fill" : score >= 60 ? "exclamationmark.shield.fill" : "xmark.shield.fill")
                .font(.largeTitle)
                .foregroundColor(score >= 85 ? .green : score >= 60 ? .yellow : .red)
            VStack(alignment: .leading, spacing: 2) {
                Text("Security Score")
                    .font(.headline)
                Text("\(score) / 100")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(score >= 85 ? .green : score >= 60 ? .yellow : .red)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .accessibilityElement(children: .combine)
    }
}
