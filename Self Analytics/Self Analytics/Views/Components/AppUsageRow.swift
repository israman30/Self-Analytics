//
//  AppUsageRow.swift
//  Self Analytics
//
//  Created by Israel Manzo on 5/22/26.
//

import SwiftUI

struct AppUsageRow: View {
    let app: AppDataUsage
    
    var body: some View {
        HStack(spacing: 12) {
            // App Icon Placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(app.appName.prefix(1)))
                        .font(.headline)
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(app.appName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    if app.cellularBytes > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: DataUsageLabels.Icon.antenna_radiowaves_left_and_right)
                                .foregroundColor(.red)
                                .font(.caption)
                            Text(app.formattedCellularUsage)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    if app.wifiBytes > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: DataUsageLabels.Icon.wifi)
                                .foregroundColor(.green)
                                .font(.caption)
                            Text(app.formattedWifiUsage)
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(app.formattedTotalUsage)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(DataUsageLabels.total)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview("AppUsageRow") {
    let apps: [AppDataUsage] = [
        AppDataUsage(
            bundleIdentifier: "com.apple.Maps",
            appName: "Maps",
            iconData: nil,
            cellularBytes: 220 * 1_024 * 1_024,
            wifiBytes: 980 * 1_024 * 1_024
        ),
        AppDataUsage(
            bundleIdentifier: "com.apple.Music",
            appName: "Music",
            iconData: nil,
            cellularBytes: 0,
            wifiBytes: 1_450 * 1_024 * 1_024
        ),
        AppDataUsage(
            bundleIdentifier: "com.apple.mobilemail",
            appName: "Mail",
            iconData: nil,
            cellularBytes: 35 * 1_024 * 1_024,
            wifiBytes: 0
        )
    ]
    
    return List(apps) { app in
        AppUsageRow(app: app)
    }
    .listStyle(.insetGrouped)
}
