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
    @StateObject private var metricsService: DeviceMetricsService
    @StateObject private var alertService: AlertService
    private let deviceInformation = DeviceInformation()
    
    @State private var activeSheet: ActiveSheet?
    @State private var speedTestResult: (download: Double, upload: Double)?
    @State private var alertsExpanded = true
    @State private var recommendationsExpanded = true
    
    init() {
        let metricsService = DeviceMetricsService()
        self._metricsService = StateObject(wrappedValue: metricsService)
        self._alertService = StateObject(
            wrappedValue: AlertService(metricsService: metricsService)
        )
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    deviceNameHeader
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    LazyVStack(spacing: 20) {
                        if let health = metricsService.currentHealth {
                            HealthScoreCard(score: health.overallScore, status: health.healthStatus)
                                .padding(.horizontal)
                        } else {
                            dashboardLoadingState
                                .padding(.horizontal)
                        }
                        
                        metricsSectionHeader
                        metricsGrid
                        
                        if !alertService.activeAlerts.isEmpty {
                            alertsSection
                        }
                        
                        if !alertService.recommendations.isEmpty {
                            recommendationsSection
                        }
                        
                        quickActionsSection
                        persistentNetworkTestSection
                    }
                    .padding(.vertical)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(DashboardViewLabels.deviceHealth)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            metricsService.updateMetrics()
                        } label: {
                            Label(DashboardViewLabels.refresh, systemImage: DashboardViewLabels.Icon.arrow_clockwise)
                        }
                        
                        Button {
                            activeSheet = .speedTest
                        } label: {
                            Label(DashboardViewLabels.speedTest, systemImage: DashboardViewLabels.Icon.speedometer)
                        }
                        
                        Button {
                            alertService.clearSafariCache()
                        } label: {
                            Label(DashboardViewLabels.clearCache, systemImage: DashboardViewLabels.Icon.trash)
                        }
                        
                        Button {
                            alertService.openSettings()
                        } label: {
                            Label(DashboardViewLabels.setting, systemImage: DashboardViewLabels.Icon.gear)
                        }
                    } label: {
                        Image(systemName: DashboardViewLabels.Icon.ellipsis_circle)
                            .accessibilityLabel(AccessibilityLabels.moreActions)
                    }
                }
            }
            .refreshable { metricsService.updateMetrics() }
            .sheet(item: $activeSheet) { sheet in
                sheetView(for: sheet)
            }
        }
    }
    
    private var deviceNameHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            // MARK: - Device Info
            VStack(alignment: .leading, spacing: 6) {
                // Device name
                Text(deviceInformation.getDeviceName())
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .accessibilityAddTraits(.isHeader)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                
                // Device model + network type
                HStack(spacing: 8) {
                    Text(deviceInformation.getDeviceModel())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    if let health = metricsService.currentHealth,
                       health.network.connectionType == .cellular {
                        Label {
                            Text(DashboardViewLabels.cellularData)
                        } icon: {
                            Image(systemName: DashboardViewLabels.Icon.antenna_radiowaves_left_and_right)
                        }
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.15))
                        .foregroundColor(.blue)
                        .cornerRadius(5)
                        .accessibilityLabel(AccessibilityLabels.cellularData)
                    }
                }
                
                if let timestamp = metricsService.currentHealth?.timestamp {
                    Label {
                        Text("\(DashboardViewLabels.updated) \(timestamp, style: .relative)")
                    } icon: {
                        Image(systemName: DashboardViewLabels.Icon.clock)
                            .accessibilityHidden(true)
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("\(DashboardViewLabels.updated) \(timestamp, style: .relative)")
                }
            }
            .accessibilityElement(children: .combine)
            
            Spacer()
            
            // MARK: - Device Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: DashboardViewLabels.Icon.iphone)
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .accessibilityHidden(true)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemGray6))
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
        )
        .accessibilityElement(children: .combine)
    }

    private var dashboardLoadingState: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ProgressView()
                Text(DashboardViewLabels.loadingMetrics)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            Text(DashboardViewLabels.pullToRefreshHint)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
        .accessibilityElement(children: .combine)
    }
    
    private var metricsSectionHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(DashboardViewLabels.metrics)
                .font(.headline)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)
            
            Text(DashboardViewLabels.tapAMetricForDetails)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
    }
    
    private var metricsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            if let health = metricsService.currentHealth {
                // Memory Card
                Button {
                    openMetric(.memory)
                } label: {
                    MetricCard(
                        title: DashboardViewLabels.MetricCard.memory,
                        value: ByteCountFormatter.string(fromByteCount: Int64(health.memory.usedMemory), countStyle: .memory),
                        subtitle: "of \(ByteCountFormatter.string(fromByteCount: Int64(health.memory.totalMemory), countStyle: .memory))",
                        percentage: health.memory.usagePercentage,
                        color: health.memory.isHighUsage ? .orange : .blue,
                        icon: DashboardViewLabels.Icon.memorychip,
                        isAlert: health.memory.isHighUsage
                    )
                }
                .buttonStyle(.plain)
                
                // CPU Card
                Button {
                    openMetric(.cpu)
                } label: {
                    MetricCard(
                        title: DashboardViewLabels.MetricCard.cpu,
                        value: "\(String(format: "%.1f", health.cpu.usagePercentage))%",
                        subtitle: health.cpu.isHighUsage ? DashboardViewLabels.MetricCard.highUsage : DashboardViewLabels.MetricCard.normal,
                        percentage: health.cpu.usagePercentage,
                        color: health.cpu.isHighUsage ? .orange : .green,
                        icon: DashboardViewLabels.Icon.cpu,
                        isAlert: health.cpu.isHighUsage
                    )
                }
                .buttonStyle(.plain)
                
                // Battery Card
                Button {
                    openMetric(.battery)
                } label: {
                    MetricCard(
                        title: DashboardViewLabels.MetricCard.battery,
                        value: "\(String(format: "%.0f", health.battery.level * 100))%",
                        subtitle: health.battery.isCharging ? DashboardViewLabels.MetricCard.charging : health.battery.isLowPowerMode ? DashboardViewLabels.MetricCard.lowPowerMode : health.battery.health.description,
                        percentage: Double(health.battery.level) * 100,
                        color: batteryColor(for: health.battery),
                        icon: batteryIcon(for: health.battery),
                        isAlert: health.battery.isLowBattery
                    )
                }
                .buttonStyle(.plain)
                
                // Storage Card
                Button {
                    openMetric(.storage)
                } label: {
                    MetricCard(
                        title: DashboardViewLabels.MetricCard.storage,
                        value: health.storage.formattedUsedSpace,
                        subtitle: "of \(health.storage.formattedTotalSpace)",
                        percentage: health.storage.usagePercentage,
                        color: health.storage.isLowStorage ? .red : .blue,
                        icon: DashboardViewLabels.Icon.externaldrive_fill,
                        isAlert: health.storage.isLowStorage
                    )
                }
                .buttonStyle(.plain)
                
                // Network Card
                Button {
                    openMetric(.network)
                } label: {
                    MetricCard(
                        title: DashboardViewLabels.MetricCard.network,
                        value: health.network.status.isConnected ? "\(String(format: "%.1f", health.network.downloadSpeed)) Mbps" : health.network.status.description,
                        subtitle: getNetworkSubtitle(for: health.network),
                        color: networkColor(for: health.network),
                        icon: networkIcon(for: health.network),
                        isAlert: !health.network.status.isConnected || health.network.isSlowConnection,
                        showCellularIndicator: health.network.connectionType == .cellular
                    )
                }
                .buttonStyle(.plain)
                
                // Available Storage Card
                Button {
                    openMetric(.available)
                } label: {
                    MetricCard(
                        title: DashboardViewLabels.MetricCard.available,
                        value: health.storage.formattedAvailableSpace,
                        subtitle: DashboardViewLabels.MetricCard.freeSpace,
                        color: health.storage.availableSpace < 5 * 1024 * 1024 * 1024 ? .red : .green,
                        icon: DashboardViewLabels.Icon.externaldrive,
                        isAlert: health.storage.availableSpace < 5 * 1024 * 1024 * 1024
                    )
                }
                .buttonStyle(.plain)
            } else {
                ForEach(0..<6, id: \.self) { _ in
                    MetricCard(
                        title: DashboardViewLabels.loading,
                        value: "—",
                        subtitle: nil,
                        percentage: nil,
                        color: .blue,
                        icon: DashboardViewLabels.Icon.circle_dotted,
                        isAlert: false
                    )
                    .redacted(reason: .placeholder)
                }
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
                    .accessibilityAddTraits(.isHeader)
                
                Spacer()
                
                Text("\(alertService.activeAlerts.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.2))
                    .foregroundColor(.red)
                    .cornerRadius(8)
                
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        alertsExpanded.toggle()
                    }
                } label: {
                    Image(systemName: alertsExpanded ? DashboardViewLabels.Icon.chevron_up : DashboardViewLabels.Icon.chevron_down)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(6)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
                .accessibilityLabel(alertsExpanded ? AccessibilityLabels.collapseAlerts : AccessibilityLabels.expandAlerts)
            }
            .accessibilityElement(children: .combine)
            
            ForEach(
                alertsExpanded ? alertService.activeAlerts : Array(alertService.activeAlerts.prefix(2)),
                id: \.id
            ) { alert in
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
            
            if !alertsExpanded, alertService.activeAlerts.count > 2 {
                Text(DashboardViewLabels.moreAlerts(alertService.activeAlerts.count - 2))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
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
                    .accessibilityAddTraits(.isHeader)
                
                Spacer()
                
                Text(
                    "\(alertService.recommendations.filter { !$0.isCompleted }.count)"
                )
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        recommendationsExpanded.toggle()
                    }
                } label: {
                    Image(systemName: recommendationsExpanded ? DashboardViewLabels.Icon.chevron_up : DashboardViewLabels.Icon.chevron_down)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(6)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
                .accessibilityLabel(recommendationsExpanded ? AccessibilityLabels.collapseRecommendations : AccessibilityLabels.expandRecommendations)
            }
            .accessibilityElement(children: .combine)
            
            ForEach(
                recommendationsExpanded ? alertService.recommendations : Array(alertService.recommendations.prefix(3)),
                id: \.id
            ) { recommendation in
                RecommendationCard(
                    recommendation: recommendation,
                    onComplete: {
                        handleRecommendationAction(recommendation)
                    }
                )
            }
            
            if !recommendationsExpanded, alertService.recommendations.count > 3 {
                Text(DashboardViewLabels.moreRecommendations(alertService.recommendations.count - 3))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
        .padding(.horizontal)
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(DashboardViewLabels.quickActions)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .accessibilityAddTraits(.isHeader)
                
                Spacer()
                
                Text("4")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
            .accessibilityElement(children: .combine)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                QuickActionButton(
                    title: DashboardViewLabels.speedTest,
                    icon: DashboardViewLabels.Icon.speedometer,
                    color: .blue
                ) {
                    activeSheet = .speedTest
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
                    .accessibilityAddTraits(.isHeader)
                
                Spacer()
                
                Image(systemName: DashboardViewLabels.Icon.wifi_fill)
                    .foregroundColor(.blue)
                    .font(.title3)
                    .accessibilityHidden(true)
            }
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(SpeedTestViewLabels.testAnyWiFiNetwork)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .accessibilityAddTraits(.isHeader)
                        
                        Text(SpeedTestViewLabels.checkCurrentNetworkPerformance)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    
                    Spacer()
                    
                    Button(action: {
                        activeSheet = .speedTest
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: DashboardViewLabels.Icon.speedometer)
                                .font(.caption)
                                .accessibilityHidden(true)
                            
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
                    .accessibilityLabel(SpeedTestViewLabels.testNow)
                    .accessibilityHint(AccessibilityLabels.tapToActivate)
                }
                
                if let health = metricsService.currentHealth {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(SpeedTestViewLabels.currentNetwork)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .accessibilityAddTraits(.isHeader)
                            
                            HStack(spacing: 4) {
                                Text(health.network.status.description)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(networkColor(for: health.network))
                                
                                if health.network.connectionType == .cellular {
                                    Text("📱")
                                        .font(.caption)
                                        .accessibilityLabel(AccessibilityLabels.cellularData)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(SpeedTestViewLabels.speed)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .accessibilityAddTraits(.isHeader)
                            
                            Text("\(String(format: "%.1f", health.network.downloadSpeed)) Mbps")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .accessibilityElement(children: .combine)
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
            return DashboardViewLabels.Icon.antenna_radiowaves_left_and_right_circle_fill
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
            return DashboardViewLabels.MetricCard.wifiConnected
        case .cellular:
            return "📱 \(DashboardViewLabels.MetricCard.usingCellularData)"
        case .ethernet:
            return DashboardViewLabels.MetricCard.ethernetConnected
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
            activeSheet = .speedTest
        }
    }
    
    private enum ActiveSheet: Identifiable, Equatable {
        case speedTest
        case metric(MetricKind)
        
        var id: String {
            switch self {
            case .speedTest:
                return "speedTest"
            case .metric(let kind):
                return "metric-\(kind.id)"
            }
        }
    }
    
    private enum MetricKind: String, Identifiable, CaseIterable {
        case memory
        case cpu
        case battery
        case storage
        case network
        case available
        
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .memory: return DashboardViewLabels.MetricCard.memory
            case .cpu: return DashboardViewLabels.MetricCard.cpu
            case .battery: return DashboardViewLabels.MetricCard.battery
            case .storage: return DashboardViewLabels.MetricCard.storage
            case .network: return DashboardViewLabels.MetricCard.network
            case .available: return DashboardViewLabels.MetricCard.available
            }
        }
        
        var systemImage: String {
            switch self {
            case .memory: return DashboardViewLabels.Icon.memorychip
            case .cpu: return DashboardViewLabels.Icon.cpu
            case .battery: return DashboardViewLabels.Icon.battery_100
            case .storage: return DashboardViewLabels.Icon.externaldrive_fill
            case .network: return DashboardViewLabels.Icon.wifi_fill
            case .available: return DashboardViewLabels.Icon.externaldrive
            }
        }
    }
    
    private func openMetric(_ kind: MetricKind) {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        activeSheet = .metric(kind)
    }
    
    @ViewBuilder
    private func sheetView(for sheet: ActiveSheet) -> some View {
        switch sheet {
        case .speedTest:
            SpeedTestView(result: $speedTestResult)
        case .metric(let kind):
            metricDetailView(kind: kind)
        }
    }
    
    private func metricDetailView(kind: MetricKind) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let health = metricsService.currentHealth {
                        MetricCard(
                            title: kind.title,
                            value: metricPrimaryValue(kind: kind, health: health),
                            subtitle: metricSubtitle(kind: kind, health: health),
                            percentage: metricPercentage(kind: kind, health: health),
                            color: metricTint(kind: kind, health: health),
                            icon: kind.systemImage,
                            isAlert: metricIsAlert(kind: kind, health: health),
                            showCellularIndicator: kind == .network && health.network.connectionType == .cellular
                        )
                        .padding(.horizontal)
                        
                        metricDetailRows(kind: kind, health: health)
                            .padding(.horizontal)
                    } else {
                        dashboardLoadingState
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(kind.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(SpeedTestViewLabels.done) {
                        activeSheet = nil
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
    
    @ViewBuilder
    private func metricDetailRows(kind: MetricKind, health: DeviceHealth) -> some View {
        VStack(spacing: 12) {
            GroupBox {
                VStack(alignment: .leading, spacing: 10) {
                    Label {
                        Text("\(DashboardViewLabels.updated) \(health.timestamp, style: .relative)")
                    } icon: {
                        Image(systemName: DashboardViewLabels.Icon.clock)
                            .accessibilityHidden(true)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    
                    Divider()
                    
                    switch kind {
                    case .memory:
                        metricRow(DashboardViewLabels.MetricDetail.used, ByteCountFormatter.string(fromByteCount: Int64(health.memory.usedMemory), countStyle: .memory))
                        metricRow(DashboardViewLabels.MetricDetail.available, ByteCountFormatter.string(fromByteCount: Int64(health.memory.availableMemory), countStyle: .memory))
                        metricRow(DashboardViewLabels.MetricDetail.pressure, memoryPressureText(health.memory.memoryPressure))
                    case .cpu:
                        metricRow(DashboardViewLabels.MetricDetail.usage, "\(String(format: "%.1f", health.cpu.usagePercentage))%")
                        metricRow(DashboardViewLabels.MetricDetail.status, health.cpu.isHighUsage ? DashboardViewLabels.MetricCard.highUsage : DashboardViewLabels.MetricCard.normal)
                    case .battery:
                        metricRow(DashboardViewLabels.MetricDetail.level, "\(String(format: "%.0f", health.battery.level * 100))%")
                        metricRow(DashboardViewLabels.MetricDetail.charging, health.battery.isCharging ? DashboardViewLabels.yes : DashboardViewLabels.no)
                        metricRow(DashboardViewLabels.MetricDetail.lowPowerMode, health.battery.isLowPowerMode ? DashboardViewLabels.yes : DashboardViewLabels.no)
                        metricRow(DashboardViewLabels.MetricDetail.health, health.battery.health.description)
                    case .storage:
                        metricRow(DashboardViewLabels.MetricDetail.used, health.storage.formattedUsedSpace)
                        metricRow(DashboardViewLabels.MetricDetail.available, health.storage.formattedAvailableSpace)
                        metricRow(DashboardViewLabels.MetricDetail.total, health.storage.formattedTotalSpace)
                    case .network:
                        metricRow(DashboardViewLabels.MetricDetail.status, health.network.status.description)
                        metricRow(DashboardViewLabels.MetricDetail.connection, health.network.connectionType.description)
                        metricRow(DashboardViewLabels.MetricDetail.download, "\(String(format: "%.1f", health.network.downloadSpeed)) Mbps")
                        metricRow(DashboardViewLabels.MetricDetail.upload, "\(String(format: "%.1f", health.network.uploadSpeed)) Mbps")
                    case .available:
                        metricRow(DashboardViewLabels.MetricDetail.freeSpace, health.storage.formattedAvailableSpace)
                        metricRow(DashboardViewLabels.MetricDetail.total, health.storage.formattedTotalSpace)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func memoryPressureText(_ pressure: MemoryPressure) -> String {
        switch pressure {
        case .normal: return "Normal"
        case .warning: return "Warning"
        case .critical: return "Critical"
        }
    }
    
    private func metricRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .accessibilityElement(children: .combine)
    }
    
    private func metricPrimaryValue(kind: MetricKind, health: DeviceHealth) -> String {
        switch kind {
        case .memory:
            return ByteCountFormatter.string(fromByteCount: Int64(health.memory.usedMemory), countStyle: .memory)
        case .cpu:
            return "\(String(format: "%.1f", health.cpu.usagePercentage))%"
        case .battery:
            return "\(String(format: "%.0f", health.battery.level * 100))%"
        case .storage:
            return health.storage.formattedUsedSpace
        case .network:
            return health.network.status.isConnected ? "\(String(format: "%.1f", health.network.downloadSpeed)) Mbps" : health.network.status.description
        case .available:
            return health.storage.formattedAvailableSpace
        }
    }
    
    private func metricSubtitle(kind: MetricKind, health: DeviceHealth) -> String? {
        switch kind {
        case .memory:
            return "of \(ByteCountFormatter.string(fromByteCount: Int64(health.memory.totalMemory), countStyle: .memory))"
        case .cpu:
            return health.cpu.isHighUsage ? DashboardViewLabels.MetricCard.highUsage : DashboardViewLabels.MetricCard.normal
        case .battery:
            return health.battery.isCharging ? DashboardViewLabels.MetricCard.charging : health.battery.isLowPowerMode ? DashboardViewLabels.MetricCard.lowPowerMode : health.battery.health.description
        case .storage:
            return "of \(health.storage.formattedTotalSpace)"
        case .network:
            return getNetworkSubtitle(for: health.network)
        case .available:
            return DashboardViewLabels.MetricCard.freeSpace
        }
    }
    
    private func metricPercentage(kind: MetricKind, health: DeviceHealth) -> Double? {
        switch kind {
        case .memory:
            return health.memory.usagePercentage
        case .cpu:
            return health.cpu.usagePercentage
        case .battery:
            return Double(health.battery.level) * 100
        case .storage:
            return health.storage.usagePercentage
        case .network, .available:
            return nil
        }
    }
    
    private func metricTint(kind: MetricKind, health: DeviceHealth) -> Color {
        switch kind {
        case .memory:
            return health.memory.isHighUsage ? .orange : .blue
        case .cpu:
            return health.cpu.isHighUsage ? .orange : .green
        case .battery:
            return batteryColor(for: health.battery)
        case .storage:
            return health.storage.isLowStorage ? .red : .blue
        case .network:
            return networkColor(for: health.network)
        case .available:
            return health.storage.availableSpace < 5 * 1024 * 1024 * 1024 ? .red : .green
        }
    }
    
    private func metricIsAlert(kind: MetricKind, health: DeviceHealth) -> Bool {
        switch kind {
        case .memory:
            return health.memory.isHighUsage
        case .cpu:
            return health.cpu.isHighUsage
        case .battery:
            return health.battery.isLowBattery
        case .storage:
            return health.storage.isLowStorage
        case .network:
            return !health.network.status.isConnected || health.network.isSlowConnection
        case .available:
            return health.storage.availableSpace < 5 * 1024 * 1024 * 1024
        }
    }
}

// MARK: - QuickActionButton setup
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Icon with background circle
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                        .accessibilityHidden(true)
                }
                
                // Title with better typography
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: color.opacity(0.1),
                        radius: isPressed ? 2 : 6,
                        x: 0,
                        y: isPressed ? 1 : 3
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            },
            perform: {})
        .accessibilityLabel(title)
        .accessibilityHint(AccessibilityLabels.tapToActivate)
        .accessibilityAddTraits(.isButton)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(String(format: "%.1f", speed)) Mbps, \(speedDescription)")
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

#Preview {
    DashboardView()
} 
