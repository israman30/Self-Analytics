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
            isCharging: false
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (DeviceHealthEntry) -> ()) {
        let entry = DeviceHealthEntry(
            date: Date(),
            healthScore: 85,
            memoryUsage: 65,
            batteryLevel: 75,
            storageUsage: 70,
            isCharging: false
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // Generate a timeline with entries every 5 minutes
        let currentDate = Date()
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
        
        let entry = DeviceHealthEntry(
            date: currentDate,
            healthScore: Int.random(in: 70...95),
            memoryUsage: Double.random(in: 50...80),
            batteryLevel: Double.random(in: 20...100),
            storageUsage: Double.random(in: 60...90),
            isCharging: Bool.random()
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
                
                Circle()
                    .trim(from: 0, to: CGFloat(entry.healthScore) / 100)
                    .stroke(healthScoreColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 2) {
                    Text("\(entry.healthScore)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(healthScoreColor)
                    
                    Text("Score")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Battery Status
            HStack(spacing: 4) {
                Image(systemName: batteryIcon)
                    .foregroundColor(batteryColor)
                    .font(.caption)
                
                Text("\(Int(entry.batteryLevel))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(batteryColor)
            }
            
            // Memory Usage
            HStack(spacing: 4) {
                Image(systemName: "memorychip")
                    .foregroundColor(memoryColor)
                    .font(.caption)
                
                Text("\(Int(entry.memoryUsage))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(memoryColor)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var healthScoreColor: Color {
        if entry.healthScore >= 80 { return .green }
        else if entry.healthScore >= 60 { return .blue }
        else if entry.healthScore >= 40 { return .orange }
        else { return .red }
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
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(entry.healthScore) / 100)
                        .stroke(healthScoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 2) {
                        Text("\(entry.healthScore)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(healthScoreColor)
                        
                        Text("Score")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text("Device Health")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Metrics
            VStack(spacing: 12) {
                MetricRow(
                    icon: batteryIcon,
                    title: "Battery",
                    value: "\(Int(entry.batteryLevel))%",
                    color: batteryColor
                )
                
                MetricRow(
                    icon: "memorychip",
                    title: "Memory",
                    value: "\(Int(entry.memoryUsage))%",
                    color: memoryColor
                )
                
                MetricRow(
                    icon: "externaldrive.fill",
                    title: "Storage",
                    value: "\(Int(entry.storageUsage))%",
                    color: storageColor
                )
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var healthScoreColor: Color {
        if entry.healthScore >= 80 { return .green }
        else if entry.healthScore >= 60 { return .blue }
        else if entry.healthScore >= 40 { return .orange }
        else { return .red }
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
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            Spacer()
        }
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
        isCharging: false
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
        isCharging: false
    )
} 