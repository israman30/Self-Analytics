import SwiftUI
import Charts

struct DashboardView: View {
    @StateObject private var metricsService = DeviceMetricsService()
    @StateObject private var alertService: AlertService
    @State private var showingSpeedTest = false
    @State private var speedTestResult: (download: Double, upload: Double)?
    
    init() {
        let metricsService = DeviceMetricsService()
        self._alertService = StateObject(wrappedValue: AlertService(metricsService: metricsService))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Health Score Section
                    if let health = metricsService.currentHealth {
                        HealthScoreCard(score: health.overallScore, status: health.healthStatus)
                            .padding(.horizontal)
                    }
                    
                    // Metrics Grid
                    metricsGrid
                    
                    // Alerts Section
                    if !alertService.activeAlerts.isEmpty {
                        alertsSection
                    }
                    
                    // Recommendations Section
                    if !alertService.recommendations.isEmpty {
                        recommendationsSection
                    }
                    
                    // Quick Actions
                    quickActionsSection
                }
                .padding(.vertical)
            }
            .navigationTitle("Device Health")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                metricsService.updateMetrics()
            }
            .sheet(isPresented: $showingSpeedTest) {
                SpeedTestView(result: $speedTestResult)
            }
        }
    }
    
    private var metricsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            if let health = metricsService.currentHealth {
                // Memory Card
                MetricCard(
                    title: "Memory",
                    value: ByteCountFormatter.string(fromByteCount: Int64(health.memory.usedMemory), countStyle: .memory),
                    subtitle: "of \(ByteCountFormatter.string(fromByteCount: Int64(health.memory.totalMemory), countStyle: .memory))",
                    percentage: health.memory.usagePercentage,
                    color: health.memory.isHighUsage ? .orange : .blue,
                    icon: "memorychip",
                    isAlert: health.memory.isHighUsage
                )
                
                // CPU Card
                MetricCard(
                    title: "CPU",
                    value: "\(String(format: "%.1f", health.cpu.usagePercentage))%",
                    subtitle: health.cpu.isHighUsage ? "High Usage" : "Normal",
                    percentage: health.cpu.usagePercentage,
                    color: health.cpu.isHighUsage ? .orange : .green,
                    icon: "cpu",
                    isAlert: health.cpu.isHighUsage
                )
                
                // Battery Card
                MetricCard(
                    title: "Battery",
                    value: "\(String(format: "%.0f", health.battery.level * 100))%",
                    subtitle: health.battery.isCharging ? "Charging" : health.battery.isLowPowerMode ? "Low Power Mode" : health.battery.health.description,
                    percentage: Double(health.battery.level) * 100,
                    color: batteryColor(for: health.battery),
                    icon: batteryIcon(for: health.battery),
                    isAlert: health.battery.isLowBattery
                )
                
                // Storage Card
                MetricCard(
                    title: "Storage",
                    value: health.storage.formattedUsedSpace,
                    subtitle: "of \(health.storage.formattedTotalSpace)",
                    percentage: health.storage.usagePercentage,
                    color: health.storage.isLowStorage ? .red : .blue,
                    icon: "externaldrive.fill",
                    isAlert: health.storage.isLowStorage
                )
                
                // Network Card
                MetricCard(
                    title: "Network",
                    value: "\(String(format: "%.1f", health.network.downloadSpeed)) Mbps",
                    subtitle: health.network.connectionType.description,
                    color: health.network.isSlowConnection ? .orange : .green,
                    icon: networkIcon(for: health.network.connectionType),
                    isAlert: health.network.isSlowConnection
                )
                
                // Available Storage Card
                MetricCard(
                    title: "Available",
                    value: health.storage.formattedAvailableSpace,
                    subtitle: "Free Space",
                    color: health.storage.availableSpace < 5 * 1024 * 1024 * 1024 ? .red : .green,
                    icon: "externaldrive",
                    isAlert: health.storage.availableSpace < 5 * 1024 * 1024 * 1024
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var alertsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Alerts")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(alertService.activeAlerts.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.2))
                    .foregroundColor(.red)
                    .cornerRadius(8)
            }
            
            ForEach(alertService.activeAlerts, id: \.id) { alert in
                AlertCard(
                    alert: alert,
                    onResolve: {
                        alertService.resolveAlert(alert)
                    },
                    onDismiss: {
                        alertService.dismissAlert(alert)
                    }
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recommendations")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(alertService.recommendations.filter { !$0.isCompleted }.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
            
            ForEach(alertService.recommendations, id: \.id) { recommendation in
                RecommendationCard(
                    recommendation: recommendation,
                    onComplete: {
                        handleRecommendationAction(recommendation)
                    }
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionButton(
                    title: "Speed Test",
                    icon: "speedometer",
                    color: .blue
                ) {
                    showingSpeedTest = true
                }
                
                QuickActionButton(
                    title: "Clear Cache",
                    icon: "trash",
                    color: .orange
                ) {
                    alertService.clearSafariCache()
                }
                
                QuickActionButton(
                    title: "Settings",
                    icon: "gear",
                    color: .gray
                ) {
                    alertService.openSettings()
                }
                
                QuickActionButton(
                    title: "App Store",
                    icon: "apple.logo",
                    color: .blue
                ) {
                    alertService.openAppStore()
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Helper Methods
    
    private func batteryColor(for battery: BatteryMetrics) -> Color {
        if battery.isCharging {
            return .green
        } else if battery.isLowBattery {
            return .red
        } else if battery.level < 0.5 {
            return .orange
        } else {
            return .blue
        }
    }
    
    private func batteryIcon(for battery: BatteryMetrics) -> String {
        if battery.isCharging {
            return "battery.100.bolt"
        } else if battery.isLowBattery {
            return "battery.25"
        } else if battery.level < 0.5 {
            return "battery.50"
        } else {
            return "battery.75"
        }
    }
    
    private func networkIcon(for connectionType: NetworkConnectionType) -> String {
        switch connectionType {
        case .wifi:
            return "wifi"
        case .cellular:
            return "antenna.radiowaves.left.and.right"
        case .ethernet:
            return "network"
        case .none:
            return "wifi.slash"
        }
    }
    
    private func handleRecommendationAction(_ recommendation: DeviceRecommendation) {
        switch recommendation.type {
        case .clearCache:
            alertService.clearSafariCache()
        case .deleteLargeFiles:
            // In a real app, you'd navigate to a file browser
            alertService.completeRecommendation(recommendation)
        case .updateApps:
            alertService.openAppStore()
        case .optimizeBattery:
            alertService.openSettings()
        case .checkPermissions:
            alertService.openSettings()
        case .runSpeedTest:
            showingSpeedTest = true
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SpeedTestView: View {
    @Binding var result: (download: Double, upload: Double)?
    @Environment(\.dismiss) private var dismiss
    @State private var isRunning = false
    @State private var progress = 0.0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                if isRunning {
                    VStack(spacing: 20) {
                        ProgressView(value: progress, total: 100)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                        
                        Text("Testing network speed...")
                            .font(.headline)
                        
                        Text("\(String(format: "%.0f", progress))%")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                } else if let result = result {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Speed Test Complete")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 16) {
                            SpeedResultRow(
                                title: "Download",
                                speed: result.download,
                                icon: "arrow.down.circle.fill",
                                color: .blue
                            )
                            
                            SpeedResultRow(
                                title: "Upload",
                                speed: result.upload,
                                icon: "arrow.up.circle.fill",
                                color: .green
                            )
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "speedometer")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Network Speed Test")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Test your internet connection speed to check performance")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Spacer()
                
                if !isRunning {
                    Button(result == nil ? "Start Test" : "Test Again") {
                        startSpeedTest()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding()
            .navigationTitle("Speed Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func startSpeedTest() async {
        isRunning = true
        progress = 0
        
        // Simulate progress
        for i in 0...100 {
            progress = Double(i)
            try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        }
        
        // Simulate speed test result
        result = (
            download: Double.random(in: 10...100),
            upload: Double.random(in: 5...50)
        )
        
        isRunning = false
    }
    
    private func startSpeedTest() {
        Task {
            await startSpeedTest()
        }
    }
}

struct SpeedResultRow: View {
    let title: String
    let speed: Double
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(String(format: "%.1f", speed)) Mbps")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            Text(speedDescription)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(speedColor.opacity(0.2))
                .foregroundColor(speedColor)
                .cornerRadius(8)
        }
    }
    
    private var speedDescription: String {
        if speed >= 50 {
            return "Fast"
        } else if speed >= 25 {
            return "Good"
        } else if speed >= 10 {
            return "Fair"
        } else {
            return "Slow"
        }
    }
    
    private var speedColor: Color {
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

#Preview {
    DashboardView()
} 
