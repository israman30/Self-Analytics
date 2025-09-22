//  DeviceSecurityScanner.swift
//  Self Analytics
//
//  Created by Israel Manzo on 9/21/25.
//

import Foundation
import UIKit
import Network
import LocalAuthentication

@MainActor
class DeviceSecurityScanner: ObservableObject {
    @Published var securityFindings: [SecurityFinding] = []
    @Published var recommendations: [SecurityRecommendation] = []
    @Published var securityScore: Int = 100
    
    func performSecurityScan() async {
        var findings: [SecurityFinding] = []
        var recs: [SecurityRecommendation] = []
        var score: Int = 100

        // 1. Wi-Fi Encryption
        let (wifiFinding, wifiRec, wifiScore) = await checkWiFiEncryption()
        if let finding = wifiFinding { findings.append(finding) }
        if let rec = wifiRec { recs.append(rec) }
        score -= wifiScore

        // 2. VPN Enabled
        let (vpnFinding, vpnRec, vpnScore) = checkVPNStatus()
        if let finding = vpnFinding { findings.append(finding) }
        if let rec = vpnRec { recs.append(rec) }
        score -= vpnScore

        // 3. Jailbreak Detection
        let (jbFinding, jbRec, jbScore) = checkForJailbreak()
        if let finding = jbFinding { findings.append(finding) }
        if let rec = jbRec { recs.append(rec) }
        score -= jbScore

        // 4. Device Passcode
        let (pwFinding, pwRec, pwScore) = checkPasscodeStatus()
        if let finding = pwFinding { findings.append(finding) }
        if let rec = pwRec { recs.append(rec) }
        score -= pwScore

        // 5. iOS Version
        let (osFinding, osRec, osScore) = checkOSVersion()
        if let finding = osFinding { findings.append(finding) }
        if let rec = osRec { recs.append(rec) }
        score -= osScore

        // Clamp score
        score = max(0, min(score, 100))

        // Apply to UI
        self.securityFindings = findings
        self.recommendations = recs
        self.securityScore = score
    }

    // MARK: - Security Checks
    private func checkWiFiEncryption() async -> (SecurityFinding?, SecurityRecommendation?, Int) {
        // iOS doesn't give direct Wi-Fi encryption info to apps, but we can infer open network by lack of Wi-Fi interface or known SSID
        let monitor = NWPathMonitor(requiredInterfaceType: .wifi)
        let group = DispatchGroup()
        var isConnectedToWiFi = false
        var isOpenNetwork = false
        group.enter()
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                isConnectedToWiFi = path.status == .satisfied
                isOpenNetwork = path.gateways.isEmpty // If no gateway, likely open/unprotected
            }
            group.leave()
        }
        monitor.start(queue: DispatchQueue.global())
        monitor.cancel()
        if !isConnectedToWiFi {
            return (nil, nil, 0) // Not using Wi-Fi, so can't evaluate encryption
        }
        if isOpenNetwork {
            return (
                SecurityFinding(
                    title: "Connected to an Open Wi-Fi Network",
                    description: "Your current Wi-Fi network appears to lack encryption. This puts your data at risk.",
                    iconName: "wifi.slash",
                    severityColor: .red
                ),
                SecurityRecommendation(
                    title: "Avoid Open Wi-Fi Networks",
                    description: "Switch to a secure Wi-Fi network with WPA2/WPA3 encryption to protect your data.",
                    iconName: "lock.slash",
                    impactColor: .red
                ),
                25
            )
        }
        // We can't check WPA type, but if not open, assume secure
        return (nil, nil, 0)
    }
    
    private func checkVPNStatus() -> (SecurityFinding?, SecurityRecommendation?, Int) {
        // Check if VPN is enabled
        let settings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any]
        if let scopes = settings?["__SCOPED__"] as? [String: Any], scopes.keys.contains(where: { $0.contains("tap") || $0.contains("tun") || $0.contains("ppp") }) {
            // VPN is active
            return (nil, nil, 0)
        } else {
            return (
                SecurityFinding(
                    title: "No VPN Connection Detected",
                    description: "Your device is not connected to a VPN. Public networks may expose your information.",
                    iconName: "lock.shield",
                    severityColor: .yellow
                ),
                SecurityRecommendation(
                    title: "Enable a VPN Service",
                    description: "Consider using a trusted VPN when on public or untrusted networks for enhanced privacy.",
                    iconName: "network",
                    impactColor: .yellow
                ),
                10
            )
        }
    }
    
    private func checkForJailbreak() -> (SecurityFinding?, SecurityRecommendation?, Int) {
        #if targetEnvironment(simulator)
        return (nil, nil, 0) // Can't check on simulator
        #else
        if FileManager.default.fileExists(atPath: "/Applications/Cydia.app") ||
            FileManager.default.fileExists(atPath: "/Library/MobileSubstrate/MobileSubstrate.dylib") ||
            FileManager.default.fileExists(atPath: "/bin/bash") {
            return (
                SecurityFinding(
                    title: "Device Appears Jailbroken",
                    description: "This device seems to be jailbroken, which exposes it to security risks.",
                    iconName: "exclamationmark.triangle.fill",
                    severityColor: .orange
                ),
                SecurityRecommendation(
                    title: "Avoid Jailbroken Devices",
                    description: "Restore your device to factory settings to ensure maximum protection.",
                    iconName: "arrow.uturn.backward",
                    impactColor: .orange
                ),
                30
            )
        }
        #endif
        return (nil, nil, 0)
    }

    private func checkPasscodeStatus() -> (SecurityFinding?, SecurityRecommendation?, Int) {
        // iOS doesn't expose passcode status directly; can infer by keychain write
        let laContext = LAContext()
        let hasPasscode = laContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        if !hasPasscode {
            return (
                SecurityFinding(
                    title: "Device Passcode Not Set",
                    description: "No passcode is set. Anyone with your device can access your data.",
                    iconName: "lock.open",
                    severityColor: .red
                ),
                SecurityRecommendation(
                    title: "Set a Passcode",
                    description: "Enable a passcode to protect your device from unauthorized access.",
                    iconName: "lock",
                    impactColor: .red
                ),
                20
            )
        }
        return (nil, nil, 0)
    }

    private func checkOSVersion() -> (SecurityFinding?, SecurityRecommendation?, Int) {
        let systemVersion = ProcessInfo.processInfo.operatingSystemVersion
        let major = systemVersion.majorVersion
        let minimumSafeVersion = 18 // For example, iOS 18 as recent
        if major < minimumSafeVersion {
            return (
                SecurityFinding(
                    title: "Outdated iOS Version",
                    description: "Your device is running an older version of iOS. Newer versions fix known vulnerabilities.",
                    iconName: "exclamationmark.circle.fill",
                    severityColor: .yellow
                ),
                SecurityRecommendation(
                    title: "Update iOS",
                    description: "Update your device to the latest iOS version for maximum protection.",
                    iconName: "arrow.down.circle.fill",
                    impactColor: .yellow
                ),
                15
            )
        }
        return (nil, nil, 0)
    }
}

// MARK: - Models
struct SecurityFinding: Identifiable, Equatable {
    var id: String { title }
    let title: String
    let description: String
    let iconName: String
    let severityColor: UIColor
}

struct SecurityRecommendation: Identifiable, Equatable {
    var id: String { title }
    let title: String
    let description: String
    let iconName: String
    let impactColor: UIColor
}
