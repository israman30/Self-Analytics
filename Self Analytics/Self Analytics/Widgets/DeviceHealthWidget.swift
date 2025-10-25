import WidgetKit
import SwiftUI

struct DeviceHealthWidget: Widget {
    let kind: String = "DeviceHealthWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DeviceHealthTimelineProvider()) { entry in
            DeviceHealthWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Device Health")
        .description("Monitor your device's health at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct DeviceHealthTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> DeviceHealthEntry {
        DeviceHealthEntry(
            date: Date(),
            healthScore: 85,
            memoryUsage: 65,
            batteryLevel: 75,
            storageUsage: 70,
            isCharging: false,
            networkType: "Wi-Fi",
            isUsingCellular: false,
            cellularDataUsage: "1.2 GB",
            wifiDataUsage: "8.5 GB",
            totalDataUsage: "9.7 GB"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (DeviceHealthEntry) -> ()) {
        let entry = DeviceHealthEntry(
            date: Date(),
            healthScore: 85,
            memoryUsage: 65,
            batteryLevel: 75,
            storageUsage: 70,
            isCharging: false,
            networkType: "Wi-Fi",
            isUsingCellular: false,
            cellularDataUsage: "1.2 GB",
            wifiDataUsage: "8.5 GB",
            totalDataUsage: "9.7 GB"
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // Generate a timeline with entries every 5 minutes
        let currentDate = Date()
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
        
        let isUsingCellular = Bool.random()
        let networkType = isUsingCellular ? "Cellular" : "Wi-Fi"
        
        let entry = DeviceHealthEntry(
            date: currentDate,
            healthScore: Int.random(in: 70...95),
            memoryUsage: Double.random(in: 50...80),
            batteryLevel: Double.random(in: 20...100),
            storageUsage: Double.random(in: 60...90),
            isCharging: Bool.random(),
            networkType: networkType,
            isUsingCellular: isUsingCellular,
            cellularDataUsage: String(format: "%.1f GB", Double.random(in: 0.5...3.0)),
            wifiDataUsage: String(format: "%.1f GB", Double.random(in: 2.0...15.0)),
            totalDataUsage: String(format: "%.1f GB", Double.random(in: 3.0...18.0))
        )
        
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
}

struct DeviceHealthEntry: TimelineEntry {
    let date: Date
    let healthScore: Int
    let memoryUsage: Double
    let batteryLevel: Double
    let storageUsage: Double
    let isCharging: Bool
    let networkType: String
    let isUsingCellular: Bool
    let cellularDataUsage: String
    let wifiDataUsage: String
    let totalDataUsage: String
}

struct DeviceHealthWidgetEntryView: View {
    var entry: DeviceHealthTimelineProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: DeviceHealthEntry
    
    var body: some View {
        VStack(spacing: 8) {
            // Health Score
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                    .frame(width: 60, height: 60)
                    .accessibilityHidden(true)
                
                Circle()
                    .trim(from: 0, to: CGFloat(entry.healthScore) / 100)
                    .stroke(healthScoreColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .accessibilityHidden(true)
                
                VStack(spacing: 2) {
                    Text("\(entry.healthScore)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(healthScoreColor)
                        .accessibilityLabel("Health Score: \(entry.healthScore) out of 100")
                        .accessibilityAddTraits(.isHeader)
                    
                    Text("Score")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Device Health Score: \(entry.healthScore) out of 100, \(healthScoreDescription)")
            .accessibilityHint("Shows overall device health performance")
            
            // Battery Status
            HStack(spacing: 4) {
                Image(systemName: batteryIcon)
                    .foregroundColor(batteryColor)
                    .font(.caption)
                    .accessibilityHidden(true)
                
                Text("\(Int(entry.batteryLevel))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(batteryColor)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Battery Level: \(Int(entry.batteryLevel)) percent\(entry.isCharging ? ", charging" : "")")
            .accessibilityHint("Current battery status")
            
            // Memory Usage
            HStack(spacing: 4) {
                Image(systemName: "memorychip")
                    .foregroundColor(memoryColor)
                    .font(.caption)
                    .accessibilityHidden(true)
                
                Text("\(Int(entry.memoryUsage))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(memoryColor)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Memory Usage: \(Int(entry.memoryUsage)) percent")
            .accessibilityHint("Current memory consumption")
            
            // Network Status
            HStack(spacing: 4) {
                Image(systemName: entry.isUsingCellular ? "antenna.radiowaves.left.and.right.circle.fill" : "wifi")
                    .foregroundColor(entry.isUsingCellular ? .blue : .green)
                    .font(.caption)
                    .accessibilityHidden(true)
                
                Text(entry.isUsingCellular ? "📱" : entry.networkType)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(entry.isUsingCellular ? .blue : .green)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Network: \(entry.isUsingCellular ? "Cellular Data" : entry.networkType)")
            .accessibilityHint("Current network connection type")
        }
        .padding()
        .background(Color(.systemBackground))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Device Health Widget")
        .accessibilityHint("Shows key device metrics including health score, battery, memory, and network status")
    }
    
    private var healthScoreColor: Color {
        if entry.healthScore >= 80 { return .green }
        else if entry.healthScore >= 60 { return .blue }
        else if entry.healthScore >= 40 { return .orange }
        else { return .red }
    }
    
    private var healthScoreDescription: String {
        if entry.healthScore >= 80 { return "Excellent" }
        else if entry.healthScore >= 60 { return "Good" }
        else if entry.healthScore >= 40 { return "Fair" }
        else { return "Poor" }
    }
    
    private var batteryColor: Color {
        if entry.isCharging { return .green }
        else if entry.batteryLevel < 20 { return .red }
        else if entry.batteryLevel < 50 { return .orange }
        else { return .blue }
    }
    
    private var batteryIcon: String {
        if entry.isCharging { return "battery.100.bolt" }
        else if entry.batteryLevel < 20 { return "battery.25" }
        else if entry.batteryLevel < 50 { return "battery.50" }
        else { return "battery.75" }
    }
    
    private var memoryColor: Color {
        if entry.memoryUsage > 80 { return .red }
        else if entry.memoryUsage > 60 { return .orange }
        else { return .green }
    }
}

struct MediumWidgetView: View {
    let entry: DeviceHealthEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // Health Score
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 80, height: 80)
                        .accessibilityHidden(true)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(entry.healthScore) / 100)
                        .stroke(healthScoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .accessibilityHidden(true)
                    
                    VStack(spacing: 2) {
                        Text("\(entry.healthScore)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(healthScoreColor)
                            .accessibilityLabel("Health Score: \(entry.healthScore) out of 100")
                            .accessibilityAddTraits(.isHeader)
                        
                        Text("Score")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .accessibilityHidden(true)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Device Health Score: \(entry.healthScore) out of 100, \(healthScoreDescription)")
                .accessibilityHint("Shows overall device health performance")
                
                Text("Device Health")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }
            
            // Metrics
            VStack(spacing: 12) {
                MetricRow(
                    icon: batteryIcon,
                    title: "Battery",
                    value: "\(Int(entry.batteryLevel))%",
                    color: batteryColor,
                    accessibilityLabel: "Battery Level: \(Int(entry.batteryLevel)) percent\(entry.isCharging ? ", charging" : "")",
                    accessibilityHint: "Current battery status"
                )
                
                MetricRow(
                    icon: "memorychip",
                    title: "Memory",
                    value: "\(Int(entry.memoryUsage))%",
                    color: memoryColor,
                    accessibilityLabel: "Memory Usage: \(Int(entry.memoryUsage)) percent",
                    accessibilityHint: "Current memory consumption"
                )
                
                MetricRow(
                    icon: "externaldrive.fill",
                    title: "Storage",
                    value: "\(Int(entry.storageUsage))%",
                    color: storageColor,
                    accessibilityLabel: "Storage Usage: \(Int(entry.storageUsage)) percent",
                    accessibilityHint: "Current storage consumption"
                )
                
                MetricRow(
                    icon: entry.isUsingCellular ? "antenna.radiowaves.left.and.right.circle.fill" : "wifi",
                    title: "Network",
                    value: entry.isUsingCellular ? "📱 Cellular" : entry.networkType,
                    color: entry.isUsingCellular ? .blue : .green,
                    accessibilityLabel: "Network: \(entry.isUsingCellular ? "Cellular Data" : entry.networkType)",
                    accessibilityHint: "Current network connection type"
                )
                
                MetricRow(
                    icon: "network",
                    title: "Data Usage",
                    value: entry.totalDataUsage,
                    color: .blue,
                    accessibilityLabel: "Total Data Usage: \(entry.totalDataUsage)",
                    accessibilityHint: "Current total data usage"
                )
                
                if entry.isUsingCellular {
                    MetricRow(
                        icon: "antenna.radiowaves.left.and.right",
                        title: "Cellular",
                        value: entry.cellularDataUsage,
                        color: .red,
                        accessibilityLabel: "Cellular Data Usage: \(entry.cellularDataUsage)",
                        accessibilityHint: "Current cellular data usage"
                    )
                } else {
                    MetricRow(
                        icon: "wifi",
                        title: "Wi-Fi",
                        value: entry.wifiDataUsage,
                        color: .green,
                        accessibilityLabel: "Wi-Fi Data Usage: \(entry.wifiDataUsage)",
                        accessibilityHint: "Current Wi-Fi data usage"
                    )
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Device Metrics")
            .accessibilityHint("Shows detailed device metrics including battery, memory, storage, and network")
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Device Health Widget")
        .accessibilityHint("Comprehensive device health monitoring with detailed metrics")
    }
    
    private var healthScoreColor: Color {
        if entry.healthScore >= 80 { return .green }
        else if entry.healthScore >= 60 { return .blue }
        else if entry.healthScore >= 40 { return .orange }
        else { return .red }
    }
    
    private var healthScoreDescription: String {
        if entry.healthScore >= 80 { return "Excellent" }
        else if entry.healthScore >= 60 { return "Good" }
        else if entry.healthScore >= 40 { return "Fair" }
        else { return "Poor" }
    }
    
    private var batteryColor: Color {
        if entry.isCharging { return .green }
        else if entry.batteryLevel < 20 { return .red }
        else if entry.batteryLevel < 50 { return .orange }
        else { return .blue }
    }
    
    private var batteryIcon: String {
        if entry.isCharging { return "battery.100.bolt" }
        else if entry.batteryLevel < 20 { return "battery.25" }
        else if entry.batteryLevel < 50 { return "battery.50" }
        else { return "battery.75" }
    }
    
    private var memoryColor: Color {
        if entry.memoryUsage > 80 { return .red }
        else if entry.memoryUsage > 60 { return .orange }
        else { return .green }
    }
    
    private var storageColor: Color {
        if entry.storageUsage > 90 { return .red }
        else if entry.storageUsage > 80 { return .orange }
        else { return .green }
    }
}

struct MetricRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let accessibilityLabel: String
    let accessibilityHint: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
                .frame(width: 16)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
                
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }
}

#Preview(as: .systemSmall) {
    DeviceHealthWidget()
} timeline: {
    DeviceHealthEntry(
        date: Date(),
        healthScore: 85,
        memoryUsage: 65,
        batteryLevel: 75,
        storageUsage: 70,
        isCharging: false,
        networkType: "Wi-Fi",
        isUsingCellular: false,
        cellularDataUsage: "1.2 GB",
        wifiDataUsage: "8.5 GB",
        totalDataUsage: "9.7 GB"
    )
}

#Preview(as: .systemMedium) {
    DeviceHealthWidget()
} timeline: {
    DeviceHealthEntry(
        date: Date(),
        healthScore: 85,
        memoryUsage: 65,
        batteryLevel: 75,
        storageUsage: 70,
        isCharging: false,
        networkType: "Cellular",
        isUsingCellular: true,
        cellularDataUsage: "2.8 GB",
        wifiDataUsage: "5.2 GB",
        totalDataUsage: "8.0 GB"
    )
} 