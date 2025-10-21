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
                    .accessibilityHidden(true) // Decorative icon
                
                Spacer()
                
                HStack(spacing: 4) {
                    if showCellularIndicator {
                        Text("📱")
                            .font(.caption)
                            .accessibilityLabel(AccessibilityLabels.cellularData)
                    }
                    
                    if isAlert {
                        Image(systemName: MetricCardLabels.Icon.exclamationmark_triangle_fill)
                            .foregroundColor(.orange)
                            .font(.caption)
                            .accessibilityLabel(AccessibilityLabels.alert)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .accessibilityAddTraits(.isHeader)
                
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
                    .scaleEffect(
                        x: 1,
                        y: 2,
                        anchor: .center
                    )
                    .accessibilityLabel(
                        "Progress: \(Int(percentage)) \(AccessibilityLabels.percent)"
                    )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(
            color: .black.opacity(0.1),
            radius: 2,
            x: 0,
            y: 1
        )
        .accessibilityElement(children: .combine)
    }
}

struct HealthScoreCard: View {
    let score: Int
    let status: HealthStatus
    
    @State private var isPressed = false
    @State private var showDetails = false
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Enhanced header with interactive elements
            HStack {
                // Animated health icon with pulse effect
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.1))
                        .frame(width: 44, height: 44)
                        .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseAnimation)
                    
                    Image(systemName: HealthScoreCardLabels.Icon.heart_fill)
                        .font(.title2)
                        .foregroundColor(statusColor)
                        .accessibilityHidden(true)
                }
                .onAppear {
                    pulseAnimation = true
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(HealthScoreCardLabels.deviceHealth)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .accessibilityAddTraits(.isHeader)
                    
                    Text(HealthScoreCardLabels.overallSystemPerformance)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Enhanced status badge with tap interaction
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showDetails.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(status.description)
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .rotationEffect(.degrees(showDetails ? 180 : 0))
                            .animation(.easeInOut(duration: 0.2), value: showDetails)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(statusColor.opacity(0.15))
                    .foregroundColor(statusColor)
                    .cornerRadius(12)
                }
                .accessibilityLabel("Health status: \(status.description). Tap to \(showDetails ? "hide" : "show") details")
                .accessibilityHint("Double tap to toggle detailed information")
            }
            
            // Enhanced circular progress indicator with haptic feedback
            ZStack {
                // Background circle with enhanced gradient
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                .gray.opacity(0.1),
                                .gray.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .accessibilityHidden(true)
                
                // Progress circle with enhanced gradient and glow effect
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100)
                    .stroke(
                        LinearGradient(
                            colors: [statusColor, statusColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.5).delay(0.2), value: score)
                    .shadow(color: statusColor.opacity(0.3), radius: 4, x: 0, y: 2)
                    .accessibilityHidden(true)
                
                // Center content with enhanced styling and animation
                VStack(spacing: 8) {
                    Text("\(score)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(statusColor)
                        .scaleEffect(isPressed ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: isPressed)
                        .accessibilityLabel("Health Score: \(score)")
                        .accessibilityAddTraits(.isHeader)
                    
                    Text(HealthScoreCardLabels.score)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(1)
                }
            }
            .onTapGesture {
                // Haptic feedback on tap
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showDetails.toggle()
                }
            }
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            }, perform: {})
            
            // Enhanced status details with expandable information
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Image(systemName: statusIcon)
                            .font(.title3)
                            .foregroundColor(statusColor)
                            .accessibilityHidden(true)
                        
                        Text(status.description)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(statusColor)
                            .accessibilityAddTraits(.isHeader)
                    }
                    
                    Spacer()
                    
                    // Enhanced performance indicator dots with animation
                    HStack(spacing: 6) {
                        ForEach(0..<4) { index in
                            Circle()
                                .fill(index < performanceLevel ? statusColor : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(index < performanceLevel ? 1.2 : 1.0)
                                .animation(
                                    .easeInOut(duration: 0.3).delay(Double(index) * 0.1),
                                    value: performanceLevel
                                )
                                .accessibilityHidden(true)
                        }
                    }
                }
                
                // Expandable details section
                if showDetails {
                    VStack(spacing: 8) {
                        Divider()
                            .background(statusColor.opacity(0.3))
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Performance Level")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(performanceDescription)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Last Updated")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(Date(), style: .time)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Quick action buttons
                        HStack(spacing: 12) {
                            Button(action: {
                                // Action for refresh
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.caption)
                                    Text("Refresh")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                            }
                            .accessibilityLabel("Refresh health score")
                            
                            Spacer()
                            
                            Button(action: {
                                // Action for more details
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "info.circle")
                                        .font(.caption)
                                    Text("Details")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(statusColor.opacity(0.1))
                                .foregroundColor(statusColor)
                                .cornerRadius(8)
                            }
                            .accessibilityLabel("View detailed health information")
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(.systemBackground),
                            Color(.systemBackground).opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [statusColor.opacity(0.2), statusColor.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(
            color: statusColor.opacity(0.1),
            radius: 8,
            x: 0,
            y: 4
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Double tap to toggle detailed information")
    }
    
    private var statusColor: Color {
        switch status {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        }
    }
    
    private var statusIcon: String {
        switch status {
        case .excellent:
            return DashboardViewLabels.Icon.star_fill
        case .good:
            return DashboardViewLabels.Icon.checkmark_circle_fill
        case .fair:
            return DashboardViewLabels.Icon.exclamationmark_triangle_fill
        case .poor:
            return DashboardViewLabels.Icon.xmark_circle_fill
        }
    }
    
    private var performanceLevel: Int {
        switch status {
        case .excellent: return 4
        case .good: return 3
        case .fair: return 2
        case .poor: return 1
        }
    }
    
    private var performanceDescription: String {
        switch status {
        case .excellent: return "Optimal performance with all systems running smoothly"
        case .good: return "Good performance with minor optimizations possible"
        case .fair: return "Fair performance, some improvements recommended"
        case .poor: return "Poor performance, immediate attention needed"
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
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(alert.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .accessibilityAddTraits(.isHeader)
                    
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
            .accessibilityElement(children: .combine)
            
            HStack {
                Button {
                    onResolve()
                } label: {
                    Text(AlertCardLabels.resolve)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .accessibilityLabel(AlertCardLabels.resolve)
                .accessibilityHint(AccessibilityLabels.tapToActivate)
                
                Spacer()
                
                Button {
                    onDismiss()
                } label: {
                    Text(AlertCardLabels.dismiss)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityLabel(AlertCardLabels.dismiss)
                .accessibilityHint(AccessibilityLabels.tapToActivate)
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
            return AlertCardLabels.Icon.antenna_radiowaves_left_and_right_circle_fill
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
                        .accessibilityAddTraits(.isHeader)
                    
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
                        .accessibilityLabel(AccessibilityLabels.completed)
                }
            }
            .accessibilityElement(children: .combine)
            
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
                    .accessibilityLabel("\(recommendation.action)")
                    .accessibilityHint(AccessibilityLabels.tapToActivate)
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
