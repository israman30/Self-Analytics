//
//  SpeedTestView.swift
//  Self Analytics
//
//  Created by Israel Manzo on 5/21/26.
//

import SwiftUI

struct SpeedTestView: View {
    @Binding var result: (download: Double, upload: Double)?
    @Environment(\.dismiss) private var dismiss
    @State private var isRunning = false
    @State private var progress = 0.0
    @State private var testHistory: [(download: Double, upload: Double, timestamp: Date)] = []
    @State private var showingHistory = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    if isRunning {
                        speedTestRunningView
                    } else if let result = result {
                        speedTestResultView(result: result)
                    } else {
                        speedTestIdleView
                    }
                    
                    if !isRunning {
                        Button(result == nil ? SpeedTestViewLabels.startTest : SpeedTestViewLabels.testAgain) {
                            runSpeedTest()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .accessibilityLabel(result == nil ? SpeedTestViewLabels.startTest : SpeedTestViewLabels.testAgain)
                        .accessibilityHint("Starts the network speed test")
                    }
                }
                .padding(24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(SpeedTestViewLabels.speedTest)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(SpeedTestViewLabels.history) {
                        showingHistory = true
                    }
                    .disabled(testHistory.isEmpty)
                    .accessibilityLabel(SpeedTestViewLabels.history)
                    .accessibilityHint(testHistory.isEmpty ? "No test history available" : "View past speed test results")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(SpeedTestViewLabels.done) {
                        dismiss()
                    }
                    .accessibilityLabel(SpeedTestViewLabels.done)
                    .accessibilityHint("Closes the speed test view")
                }
            }
            .sheet(isPresented: $showingHistory) {
                SpeedTestHistoryView(history: testHistory)
            }
        }
    }
    
    private var speedTestRunningView: some View {
        VStack(spacing: 24) {
            ProgressView(value: progress, total: 100)
                .progressViewStyle(.linear)
                .tint(.blue)
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            Text(SpeedTestViewLabels.testingNetworkSpeed)
                .font(.headline)
            
            Text("\(String(format: "%.0f", progress))%")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(SpeedTestViewLabels.testingNetworkSpeed) \(String(format: "%.0f", progress)) percent complete")
    }
    
    private func speedTestResultView(result: (download: Double, upload: Double)) -> some View {
        VStack(spacing: 24) {
            Image(systemName: SpeedTestViewLabels.Icon.checkmark_circle_fill)
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text(SpeedTestViewLabels.speedTestComplete)
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                SpeedResultRow(
                    title: SpeedTestViewLabels.download,
                    speed: result.download,
                    icon: SpeedTestViewLabels.Icon.arrow_down_circle_fill,
                    color: .blue
                )
                
                SpeedResultRow(
                    title: SpeedTestViewLabels.upload,
                    speed: result.upload,
                    icon: SpeedTestViewLabels.Icon.arrow_up_circle_fill,
                    color: .green
                )
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(SpeedTestViewLabels.speedTestComplete). Download: \(String(format: "%.1f", result.download)) Mbps. Upload: \(String(format: "%.1f", result.upload)) Mbps")
    }
    
    private var speedTestIdleView: some View {
        VStack(spacing: 16) {
            Image(systemName: SpeedTestViewLabels.Icon.speedometer)
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text(SpeedTestViewLabels.networkSpeedTest)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(SpeedTestViewLabels.testInternetConnectionPerformance)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(SpeedTestViewLabels.networkSpeedTest). \(SpeedTestViewLabels.testInternetConnectionPerformance)")
    }
    
    private func runSpeedTest() {
        Task {
            isRunning = true
            progress = 0
            
            for i in 0...100 {
                progress = Double(i)
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
            
            let newResult = (
                download: Double.random(in: 10...100),
                upload: Double.random(in: 5...50)
            )
            
            result = newResult
            
            testHistory.append((
                download: newResult.download,
                upload: newResult.upload,
                timestamp: Date()
            ))
            
            if testHistory.count > 10 {
                testHistory.removeFirst()
            }
            
            isRunning = false
        }
    }
}
