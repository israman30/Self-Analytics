# Self Analytics - iOS Device Health Monitor

Copyright © 2025–2026 Self Analytics. All rights reserved.

A comprehensive iOS app for monitoring device health, performance metrics, cellular and Wi‑Fi data usage patterns, and security-oriented checks—with smart alerts, optional proactive notifications, and home screen widgets.

**Current release (app target):** 1.3

> Note: In Xcode the app’s display name is set to **“Device Health”** (repo/project name: **Self Analytics**).

## Features

### Real-Time Device Metrics
- **Memory usage**: RAM usage with pressure indicators
- **CPU usage**: Processor utilization and performance
- **Storage analytics**: Breakdown with available space monitoring
- **Battery health**: Level, charging status, and aging trend (historical capacity snapshots)
- **Network**: Connection type and speed testing

### Data Usage
- **Usage overview**: Cellular vs Wi‑Fi summaries and trends
- **Per-app style breakdown**: Usage by app (illustrative data; iOS does not expose per-app bytes to third-party apps without restricted entitlements)
- **Limits and alerts**: Configurable thresholds and in-app alerts
- **Statistics**: Aggregated views for understanding patterns over time

### Smart Alerts & Recommendations
- **In-app alerts**: Storage, performance, and battery-related notices
- **Proactive notifications**: Optional local notifications (with cooldowns + background refresh scheduling) for low storage, RAM pressure, high CPU, rapid battery drain, network changes (Wi‑Fi loss / disconnect), low health score drops, iOS update recommendations, and weekly health summaries (requires notification permission and Background App Refresh)
- **Recommendations**: Storage cleanup, performance, battery, and security-oriented tips

### Welcome & Onboarding
- **Welcome screen**: Shown on first launch
- **Notifications opt-in**: After onboarding, the app can prompt to enable notifications (if the in-app setting is enabled) and guides the user to iOS Settings if authorization is denied

### Security Scan
- **Device security scanner**: On-demand scan with a security score and findings
- **Pull to refresh**: Rescan from the Security Scan tab

### Dashboard & Visualization
- **Health score**: Overall device health (0–100)
- **Trend analysis**: Historical performance including battery capacity over time
- **Color-coded indicators**: Quick visual status
- **Live updates**: Periodic refresh on the dashboard
- **Data storage sheet**: From the dashboard overflow menu (`⋯`), open a dedicated **Data Storage** view with storage and free-space cards plus detail (medium/large sheet)

### Localization
- **String Catalog** (`Localizable.xcstrings`): English (base), Spanish (US and Latin America), French, Japanese, Chinese (Simplified and Traditional), and Arabic

### Widgets
- **Device Performance** (app extension): Home screen widget (small and medium) showing health score, memory, CPU, storage, and battery from the latest snapshot written when you use the app
- Shared payload types live under `WidgetShared/` (e.g. `WidgetSnapshotStore`, `DevicePerformanceWidgetPayload`)

<p align="center">
<img src="/img/one.png" width="250"> <img src="/img/two.png" width="250"> <img src="/img/three.png" width="250">
</p>

## Architecture

### App structure
- **Tabs** (`MainTabView.swift`): Dashboard, **Data Usage**, Security Scan, Settings
- **History access**: From the Data Usage screen, tap **History** in the navigation bar to open Device History full-screen.

### Models
- `DeviceMetrics.swift` — core health models (`DeviceHealth`, memory, CPU, battery, storage, network, alerts, recommendations)
- `DataUsageMetrics.swift` — data usage summaries, limits, and alerts
- `DeviceHealth+WidgetPayload.swift` — maps `DeviceHealth` to widget snapshot payload

### Services (`Services/`)
- `DeviceMetricsService` — collects device metrics via iOS APIs
- `AlertService` — alerts and recommendations
- `DataUsageService` — data usage monitoring and mock/illustrative app usage
- `ProactiveNotificationService` — background checks and local notifications
- `NotificationCenterDelegate` — presents notifications while the app is in the foreground
- `BatteryMetricsHistoryService` — persists battery capacity history for charts
- `WeeklyMetricsStorage` — daily snapshots for weekly comparison summaries
- `DataManagementService` — data export and maintenance hooks

### Views (`Views/`)
- `DashboardView`, `SettingsView`
- `UsageAndHistoryView` — Data Usage tab root; shows `DataUsageMainContent` and opens `HistoryMainContent` in a full-screen cover via a toolbar button
- `DataStorageView` — storage breakdown sheet presented from the dashboard menu
- `NotificationPermissionPromptView` — optional in-app screen to request notification permission and provide “Open iOS Settings” recovery when denied
- `AppDataUsageDetailView`, `DataUsageStatisticsView`, `DataUsageAlertsView`, `DataLimitsSettingsView`
- `SecurityScanView` + `DeviceSecurityScanner`
- `ContactSupport`, `PrivacyPolicyView`, `TermsOfServiceView`

### Components (`Views/Components/`)
- `MetricCard`, health and alert/recommendation cards as used by the dashboard

### Widget extension (`DevicePerformanceWidget/`)
- `DevicePerformanceWidget` / `DevicePerformanceWidgetBundle` — WidgetKit extension target embedded in the main app

## Technical Implementation

### iOS APIs and frameworks
- `ProcessInfo`, `UIDevice`, `FileManager`, `SystemConfiguration`, `Network`
- `Charts` for history and trends
- `UserNotifications` and `BackgroundTasks` for proactive notifications (when enabled)
- `WidgetKit` for the Device Performance extension

### Behaviors
- Dashboard-oriented refresh intervals for live metrics
- Local persistence for history, battery samples, and weekly aggregates
- Widget reads the latest shared snapshot so opening the app keeps the widget meaningful

## Installation & Setup

### Requirements
- iOS **17.0**+
- **Xcode 16**+ (project created with Xcode 16.4)
- Swift toolchain bundled with Xcode 16

### Setup
1. Clone the repository.
2. Open `Self Analytics/Self Analytics.xcodeproj` in Xcode.
3. Select your development team for the **Self Analytics** app and the **DevicePerformanceWidgetExtension** target (App Group / signing as configured in your Apple Developer setup).
4. Build and run on a device or simulator.

### Permissions and capabilities
- **Battery monitoring** — battery metrics
- **Network access** — connectivity and speed tests
- **File system** — storage free space (sandbox-allowed APIs)
- **Notifications** — optional proactive alerts and weekly summary
- **Background App Refresh** — supports scheduled background metric checks when the user allows it
- **Background tasks** — uses `BGTaskScheduler` with identifier `com.selfanalytics.metrics.refresh` (listed in `Info.plist`) to periodically evaluate thresholds when notifications are enabled
- **More detail**: See [`PERMISSIONS_AUDIT.md`](Self%20Analytics/Self%20Analytics/PERMISSIONS_AUDIT.md)

## Usage Guide

### First launch
On first launch you’ll see a Welcome screen. After you tap **Get Started**, the app may offer to enable notifications (optional) so it can send proactive health alerts (including network change and iOS update recommendations) and weekly summaries.

### Dashboard
Health score, metric cards, alerts, recommendations, and quick actions. Use the trailing **⋯** menu for refresh, speed test, **Data Storage** (detail sheet), cache clearing, and jumping to system Settings.

### Data Usage + History
- **Data Usage tab**: Totals, per-app-style breakdown (illustrative), statistics, limits, and alerts.
- **History**: From the Data Usage screen, tap **History** (top-right) to open full-screen history with time ranges, trend charts, and summaries (including battery aging where data exists).

### Security Scan
Run a scan, review score and findings, pull to refresh.

### Settings
Notifications, refresh behavior, data management, legal and support links.

### Widgets
1. Long-press the Home Screen → tap **+**
2. Search for **Self Analytics** / **Device Performance**
3. Choose small or medium and add the widget
4. Open the app periodically so the extension can read an up-to-date snapshot

## Privacy & Security

- **On-device**: Health and history data are stored locally; there is no required cloud sync for core features.
- **Minimal permissions**: Only what the feature set needs (see above).
- **Sandbox**: Subject to iOS privacy and sandbox limits (e.g. no unrestricted system telemetry).

## Limitations

- **iOS sandbox**: No root-level or private system APIs.
- **CPU metrics**: Approximate where the platform does not expose a direct per-process API for third parties.
- **Network speed tests**: Depend on implementation details (may be simulated or simplified in places).
- **Per-app data usage**: True per-app cellular/Wi‑Fi totals are not available to typical App Store apps; the Data Usage experience may use representative or mock values for demonstration.

## Future Enhancements

- Deeper OS integrations where Apple exposes safe public APIs (e.g. Screen Time–style analytics if ever available to partners)
- Siri Shortcuts and richer automations
- Optional iCloud backup for user-owned exports
- Additional languages and accessibility polish

## Contributing

- Prefer **SwiftUI** patterns consistent with the existing codebase.
- Keep **accessibility** in mind (VoiceOver, Dynamic Type).
- Add or update **String Catalog** (`Localizable.xcstrings`) entries for localized UI copy; many tab labels and keys also live in `Utils/Constants.swift`—keep naming and usage aligned when you change navigation or feature titles.

## Support & Feedback

- Use **Settings →** support / contact flows in the app where available.
- For platform limits, see Apple’s developer documentation for the APIs in use.

## License

MIT License.

## Acknowledgments

- iOS development community, SwiftUI, Apple Developer Documentation, and open source contributors.

---

**Self Analytics** — keep your device informed, on your terms.
