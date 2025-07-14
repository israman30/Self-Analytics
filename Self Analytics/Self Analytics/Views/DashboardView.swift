//
//  DashboardView.swift
//  Self Analytics
//
//  Created by Israel Manzo on 7/9/25.
//

import SwiftUI
import Charts

class DeviceInformation {
    
    func getDeviceName() -> String {
        return UIDevice.current.name
    }
    
    func getDeviceModel() -> String {
        let device = UIDevice.current
        let systemName = device.systemName
        let systemVersion = device.systemVersion
        
        return "\(systemName) \(systemVersion)"
    }
}

struct DashboardView: View {
    @StateObject private var metricsService = DeviceMetricsService()
    @StateObject private var alertService: AlertService
    private var deviceInformation = DeviceInformation()
    @State private var showingSpeedTest = false
    @State private var speedTestResult: (download: Double, upload: Double)?
    
    init() {
        let metricsService = DeviceMetricsService()
        self._alertService = StateObject(wrappedValue: AlertService(metricsService: metricsService))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Device Name Header
                    deviceNameHeader
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
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
                    
                    // Persistent Network Test Section
                    persistentNetworkTestSection
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle(DashboardViewLabels.deviceHealth)
            .refreshable {
                metricsService.updateMetrics()
            }
            .sheet(isPresented: $showingSpeedTest) {
                SpeedTestView(result: $speedTestResult)
            }
        }
    }
    
    private var deviceNameHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(deviceInformation.getDeviceName())
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Text(deviceInformation.getDeviceModel())
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let health = metricsService.currentHealth, health.network.connectionType == .cellular {
                        Text("📱 Cellular Data")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: DashboardViewLabels.Icon.iphone)
                .font(.title2)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var metricsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            if let health = metricsService.currentHealth {
                // Memory Card
                MetricCard(
                    title: DashboardViewLabels.MetricCard.memory,
                    value: ByteCountFormatter.string(fromByteCount: Int64(health.memory.usedMemory), countStyle: .memory),
                    subtitle: "of \(ByteCountFormatter.string(fromByteCount: Int64(health.memory.totalMemory), countStyle: .memory))",
                    percentage: health.memory.usagePercentage,
                    color: health.memory.isHighUsage ? .orange : .blue,
                    icon: DashboardViewLabels.Icon.memorychip,
                    isAlert: health.memory.isHighUsage
                )
                
                // CPU Card
                MetricCard(
                    title: DashboardViewLabels.MetricCard.cpu,
                    value: "\(String(format: "%.1f", health.cpu.usagePercentage))%",
                    subtitle: health.cpu.isHighUsage ? DashboardViewLabels.MetricCard.highUsage : DashboardViewLabels.MetricCard.normal,
                    percentage: health.cpu.usagePercentage,
                    color: health.cpu.isHighUsage ? .orange : .green,
                    icon: DashboardViewLabels.Icon.cpu,
                    isAlert: health.cpu.isHighUsage
                )
                
                // Battery Card
                MetricCard(
                    title: DashboardViewLabels.MetricCard.battery,
                    value: "\(String(format: "%.0f", health.battery.level * 100))%",
                    subtitle: health.battery.isCharging ? DashboardViewLabels.MetricCard.charging : health.battery.isLowPowerMode ? DashboardViewLabels.MetricCard.lowPowerMode : health.battery.health.description,
                    percentage: Double(health.battery.level) * 100,
                    color: batteryColor(for: health.battery),
                    icon: batteryIcon(for: health.battery),
                    isAlert: health.battery.isLowBattery
                )
                
                // Storage Card
                MetricCard(
                    title: DashboardViewLabels.MetricCard.storage,
                    value: health.storage.formattedUsedSpace,
                    subtitle: "of \(health.storage.formattedTotalSpace)",
                    percentage: health.storage.usagePercentage,
                    color: health.storage.isLowStorage ? .red : .blue,
                    icon: DashboardViewLabels.Icon.externaldrive_fill,
                    isAlert: health.storage.isLowStorage
                )
                
                // Network Card
                MetricCard(
                    title: DashboardViewLabels.MetricCard.network,
                    value: health.network.status.isConnected ? "\(String(format: "%.1f", health.network.downloadSpeed)) Mbps" : health.network.status.description,
                    subtitle: getNetworkSubtitle(for: health.network),
                    color: networkColor(for: health.network),
                    icon: networkIcon(for: health.network),
                    isAlert: !health.network.status.isConnected || health.network.isSlowConnection,
                    showCellularIndicator: health.network.connectionType == .cellular
                )
                
                // Available Storage Card
                MetricCard(
                    title: DashboardViewLabels.MetricCard.available,
                    value: health.storage.formattedAvailableSpace,
                    subtitle: DashboardViewLabels.MetricCard.freeSpace,
                    color: health.storage.availableSpace < 5 * 1024 * 1024 * 1024 ? .red : .green,
                    icon: DashboardViewLabels.Icon.externaldrive,
                    isAlert: health.storage.availableSpace < 5 * 1024 * 1024 * 1024
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var alertsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(DashboardViewLabels.alerts)
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
                Text(DashboardViewLabels.recommendations)
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
            Text(DashboardViewLabels.quickActions)
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionButton(
                    title: DashboardViewLabels.speedTest,
                    icon: DashboardViewLabels.Icon.speedometer,
                    color: .blue
                ) {
                    showingSpeedTest = true
                }
                
                QuickActionButton(
                    title: DashboardViewLabels.clearCache,
                    icon: DashboardViewLabels.Icon.trash,
                    color: .orange
                ) {
                    alertService.clearSafariCache()
                }
                
                QuickActionButton(
                    title: DashboardViewLabels.setting,
                    icon: DashboardViewLabels.Icon.gear,
                    color: .gray
                ) {
                    alertService.openSettings()
                }
                
                QuickActionButton(
                    title: DashboardViewLabels.appStore,
                    icon: DashboardViewLabels.Icon.apple_logo,
                    color: .blue
                ) {
                    alertService.openAppStore()
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Persistent Network Test Section
    private var persistentNetworkTestSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(SpeedTestViewLabels.networkTesting)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: DashboardViewLabels.Icon.wifi_fill)
                    .foregroundColor(.blue)
                    .font(.title3)
            }
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(SpeedTestViewLabels.testAnyWiFiNetwork)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(SpeedTestViewLabels.checkCurrentNetworkPerformance)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showingSpeedTest = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: DashboardViewLabels.Icon.speedometer)
                                .font(.caption)
                            
                            Text(SpeedTestViewLabels.testNow)
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                
                if let health = metricsService.currentHealth {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(SpeedTestViewLabels.currentNetwork)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 4) {
                                Text(health.network.status.description)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(networkColor(for: health.network))
                                
                                if health.network.connectionType == .cellular {
                                    Text("📱")
                                        .font(.caption)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(SpeedTestViewLabels.speed)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(String(format: "%.1f", health.network.downloadSpeed)) Mbps")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
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
            return DashboardViewLabels.Icon.battery_100_bolt
        } else if battery.isLowBattery {
            return DashboardViewLabels.Icon.battery_25
        } else if battery.level < 0.5 {
            return DashboardViewLabels.Icon.battery_50
        } else {
            return DashboardViewLabels.Icon.battery_75
        }
    }
    
    private func networkIcon(for network: NetworkMetrics) -> String {
        switch network.status {
        case .wifiConnected:
            return DashboardViewLabels.Icon.wifi_fill
        case .cellularConnected:
            return "antenna.radiowaves.left.and.right.circle.fill"
        case .ethernetConnected:
            return DashboardViewLabels.Icon.network
        case .connected, .restored:
            return DashboardViewLabels.Icon.checkmark_circle
        case .disconnected, .notFound:
            return DashboardViewLabels.Icon.wifi_slash
        case .unknown:
            return DashboardViewLabels.Icon.exclamationmark_triangle
        }
    }
    
    private func getNetworkSubtitle(for network: NetworkMetrics) -> String {
        if !network.status.isConnected {
            return DashboardViewLabels.MetricCard.noInternetConnection
        }
        
        switch network.connectionType {
        case .wifi:
            return "Wi-Fi Connected"
        case .cellular:
            return "📱 Using Cellular Data"
        case .ethernet:
            return "Ethernet Connected"
        case .none:
            return DashboardViewLabels.MetricCard.noInternetConnection
        }
    }
    
    private func networkColor(for network: NetworkMetrics) -> Color {
        if !network.status.isConnected {
            return .red
        } else if network.isSlowConnection {
            return .orange
        } else {
            switch network.status {
            case .wifiConnected, .ethernetConnected:
                return .green
            case .cellularConnected:
                return .blue
            case .connected, .restored:
                return .green
            case .disconnected, .notFound, .unknown:
                return .red
            }
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

// MARK: - QuickActionButton setup
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
    @State private var testHistory: [(download: Double, upload: Double, timestamp: Date)] = []
    @State private var showingHistory = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                if isRunning {
                    VStack(spacing: 20) {
                        ProgressView(value: progress, total: 100)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                        
                        Text(SpeedTestViewLabels.testingNetworkSpeed)
                            .font(.headline)
                        
                        Text("\(String(format: "%.0f", progress))%")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                } else if let result = result {
                    VStack(spacing: 20) {
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
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                } else {
                    VStack(spacing: 20) {
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
                }
                
                Spacer()
                
                if !isRunning {
                    Button(result == nil ? SpeedTestViewLabels.startTest : SpeedTestViewLabels.testAgain) {
                        startSpeedTest()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding()
            .navigationTitle(SpeedTestViewLabels.speedTest)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("History") {
                        showingHistory = true
                    }
                    .disabled(testHistory.isEmpty)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(SpeedTestViewLabels.done) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingHistory) {
                SpeedTestHistoryView(history: testHistory)
            }
        }
    }
    
    // Speed Start helper
    private func startSpeedTest() async {
        isRunning = true
        progress = 0
        
        // Simulate progress
        for i in 0...100 {
            progress = Double(i)
            try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        }
        
        // Simulate speed test result
        let newResult = (
            download: Double.random(in: 10...100),
            upload: Double.random(in: 5...50)
        )
        
        result = newResult
        
        // Add to history
        testHistory.append((
            download: newResult.download,
            upload: newResult.upload,
            timestamp: Date()
        ))
        
        // Keep only last 10 tests
        if testHistory.count > 10 {
            testHistory.removeFirst()
        }
        
        isRunning = false
    }
    
    private func startSpeedTest() {
        Task {
            await startSpeedTest()
        }
    }
}

// Speed Result Row
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
    // Speed Description helper
    private var speedDescription: String {
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
    // Speed Color helper
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

// MARK: - Speed Test History View
struct SpeedTestHistoryView: View {
    let history: [(download: Double, upload: Double, timestamp: Date)]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
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
                                Text("Download")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(String(format: "%.1f", test.download)) Mbps")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Upload")
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
                }
            }
            .navigationTitle(SpeedTestViewLabels.testHistory)
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
    
    private func speedDescription(for speed: Double) -> String {
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

#Preview {
    DashboardView()
} 
