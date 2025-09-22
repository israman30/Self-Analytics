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
    
    private let SCOPED_KEY = "__SCOPED__"
    private let tap = "tap"
    private let tun = "tun"
    private let ppp = "ppp"
    private let applicationsPath = "/Applications/Cydia.app"
    private let libraryPath = "/Library/MobileSubstrate/MobileSubstrate.dylib"
    private let bin_bash = "/bin/bash"
    
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
                    title: SecurityLabels.connectedToAnOpenWiFiNetwork,
                    description: SecurityLabels.your_current_WiFi_network_appears_to_lack_encryption_this_puts_your_data_at_risk,
                    iconName: SecurityLabels.Icon.wifi_slash,
                    severityColor: .red
                ),
                SecurityRecommendation(
                    title: SecurityLabels.avoidOpenWiFiNetworks,
                    description: SecurityLabels.switch_to_a_secure_WiFi_network_with_WPA2_WPA3_encryption_to_protectYour_data,
                    iconName: SecurityLabels.Icon.lock_slash,
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
        if let scopes = settings?[SCOPED_KEY] as? [String: Any],
           scopes.keys.contains(where: { $0.contains(tap) || $0.contains(tun) || $0.contains(ppp) }) {
            // VPN is active
            return (nil, nil, 0)
        } else {
            return (
                SecurityFinding(
                    title: SecurityLabels.noVPNConnectionDetected,
                    description: SecurityLabels.your_device_is_not_connected_to_a_VPN_public_networks_may_expose_your_information,
                    iconName: SecurityLabels.Icon.lock_shield,
                    severityColor: .yellow
                ),
                SecurityRecommendation(
                    title: SecurityLabels.enableAVPNService,
                    description: SecurityLabels.consider_using_a_trusted_VPN_when_on_public_or_untrusted_networks_for_enhanced_privacy,
                    iconName: SecurityLabels.Icon.network,
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
        if FileManager.default.fileExists(atPath: applicationsPath) ||
            FileManager.default.fileExists(atPath: libraryPath) ||
            FileManager.default.fileExists(atPath: bin_bash) {
            return (
                SecurityFinding(
                    title: SecurityLabels.deviceAppearsJailbroken,
                    description: SecurityLabels.this_device_seems_to_be_jailbroken_which_exposes_it_to_security_risks,
                    iconName: SecurityLabels.Icon.exclamationmark_triangle_fill,
                    severityColor: .orange
                ),
                SecurityRecommendation(
                    title: SecurityLabels.avoidJailbrokenDevices,
                    description: SecurityLabels.restore_your_device_to_factory_settings_to_ensure_maximum_protection,
                    iconName: SecurityLabels.Icon.arrow_uturn_backward,
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
                    title: SecurityLabels.devicePasscodeNotSet,
                    description: SecurityLabels.no_passcode_is_set_Anyone_with_your_device_can_access_your_data,
                    iconName: SecurityLabels.Icon.lock_open,
                    severityColor: .red
                ),
                SecurityRecommendation(
                    title: SecurityLabels.setAPasscode,
                    description: SecurityLabels.enable_a_passcode_to_protect_your_device_from_unauthorized_access,
                    iconName: SecurityLabels.Icon.lock,
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
                    title: SecurityLabels.outdatediOSVersion,
                    description: SecurityLabels.your_device_is_running_an_older_version_of_iOS_Newer_versions_fix_known_vulnerabilities,
                    iconName: SecurityLabels.Icon.exclamationmark_circle_fill,
                    severityColor: .yellow
                ),
                SecurityRecommendation(
                    title: SecurityLabels.updateiOS,
                    description: SecurityLabels.update_your_device_to_the_latest_iOS_version_for_maximum_protection,
                    iconName: SecurityLabels.Icon.arrow_down_circle_fill,
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
