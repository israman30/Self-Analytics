//
//  DeviceInformation.swift
//  Self Analytics
//
//  Created by Israel Manzo on 5/21/26.
//

import SwiftUI

/// Lightweight device-identifying strings for the dashboard header.
///
/// This is intentionally UI-focused (name + OS version) and does not attempt to perform hardware model lookups.
struct DeviceInformation {
    
    static let shared = DeviceInformation()
    
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
