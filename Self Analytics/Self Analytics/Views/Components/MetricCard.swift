//
//  MetricCard.swift
//  Self Analytics
//
//  Created by Israel Manzo on 7/9/25.
//

import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let percentage: Double?
    let color: Color
    let icon: String
    let isAlert: Bool
    let showCellularIndicator: Bool
    
    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        percentage: Double? = nil,
        color: Color = .blue,
        icon: String,
        isAlert: Bool = false,
        showCellularIndicator: Bool = false
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.percentage = percentage
        self.color = color
        self.icon = icon
        self.isAlert = isAlert
        self.showCellularIndicator = showCellularIndicator
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
                
                HStack(spacing: 4) {
                    if showCellularIndicator {
                        Text("📱")
                            .font(.caption)
                    }
                    
                    if isAlert {
                        Image(systemName: MetricCardLabels.Icon.exclamationmark_triangle_fill)
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let percentage = percentage {
                ProgressView(value: min(max(percentage, 0), 100), total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: color))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct HealthScoreCard: View {
    let score: Int
    let status: HealthStatus
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100)
                    .stroke(statusColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1), value: score)
                
                VStack(spacing: 4) {
                    Text("\(score)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(statusColor)
                    
                    Text(HealthScoreCardLabels.score)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(spacing: 4) {
                Text(status.description)
                    .font(.headline)
                    .foregroundColor(statusColor)
                
                Text(HealthScoreCardLabels.deviceHealth)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var statusColor: Color {
        switch status {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        }
    }
}

struct AlertCard: View {
    let alert: DeviceAlert
    let onResolve: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: alertIcon)
                    .foregroundColor(severityColor)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(alert.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(alert.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Text(alert.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Button(AlertCardLabels.resolve) {
                    onResolve()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Spacer()
                
                Button(AlertCardLabels.dismiss) {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(severityColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var alertIcon: String {
        switch alert.type {
        case .lowStorage: 
            return AlertCardLabels.Icon.externaldrive_fill
        case .highMemoryUsage: 
            return AlertCardLabels.Icon.memorychip
        case .highCPUUsage:
            return AlertCardLabels.Icon.cpu
        case .lowBattery:
            return AlertCardLabels.Icon.battery_25
        case .poorBatteryHealth:
            return AlertCardLabels.Icon.battery_100
        case .slowNetwork:
            return AlertCardLabels.Icon.wifi
        case .cellularDataUsage:
            return "antenna.radiowaves.left.and.right.circle.fill"
        case .securityUpdate:
            return AlertCardLabels.Icon.shield
        }
    }
    
    private var severityColor: Color {
        switch alert.severity {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}

struct RecommendationCard: View {
    let recommendation: DeviceRecommendation
    let onComplete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(recommendation.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if recommendation.isCompleted {
                    Image(systemName: RecommendationCardLabels.Icon.checkmark_circle_fill)
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }
            
            HStack {
                Text(recommendation.impact.description)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(impactColor.opacity(0.2))
                    .foregroundColor(impactColor)
                    .cornerRadius(8)
                
                Spacer()
                
                if !recommendation.isCompleted {
                    Button(recommendation.action) {
                        onComplete()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .opacity(recommendation.isCompleted ? 0.6 : 1.0)
    }
    
    private var impactColor: Color {
        switch recommendation.impact {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        MetricCard(
            title: "Memory Usage",
            value: "4.2 GB",
            subtitle: "of 6 GB",
            percentage: 70,
            color: .blue,
            icon: "memorychip"
        )
        
        HealthScoreCard(score: 85, status: .excellent)
        
        AlertCard(
            alert: DeviceAlert(
                type: .lowStorage,
                title: "Storage Almost Full",
                message: "Your device storage is 95% full. Consider freeing up space.",
                severity: .high,
                timestamp: Date(),
                isResolved: false
            ),
            onResolve: {},
            onDismiss: {}
        )
        
        RecommendationCard(
            recommendation: DeviceRecommendation(
                type: .clearCache,
                title: "Clear App Cache",
                description: "Free up space by clearing cached data from apps",
                action: "Clear Cache",
                impact: .medium,
                isCompleted: false
            ),
            onComplete: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
} 
