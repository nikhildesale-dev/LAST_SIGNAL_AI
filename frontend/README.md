# LAST SIGNAL AI 📡🌊
### AI-Driven Predictive Emergency Routing & Offline P2P Disaster Management System
*Built with Flutter & Dart • Material 3 • Offline-First Architecture • Advanced Native Canvas Animations*

---

## 1. Project Overview & Mission

**LAST SIGNAL AI** is an emergency-response intelligence mobile application engineered for crisis environments where traditional cellular telecommunications, electric power grids, and internet backbones are disrupted or destroyed.

> *"WHEN THE NETWORK FAILS, PREPAREDNESS MUST CONTINUE."*

The application bridges three key stakeholders during climate emergencies:
1. **Citizens:** Receive early predictive storm surge risk scores, view hazard-avoiding evacuation corridors, maintain a persistent 72-hour offline emergency pack, and file field reports.
2. **First Responders (CERT / Search & Rescue):** Prioritize unreviewed field reports, triage hazards, log verification notes, and designate impassable roads.
3. **Emergency Administrators:** Authorize responder credential requests, manage municipal permissions, and inspect system-wide audit telemetry.

---

## 2. Technical Stack & Architecture

- **Framework:** Flutter 3.47.7 (Channel Stable)
- **Language:** Dart 3.13.5 (Sound Null Safety)
- **UI Design System:** Material 3 with custom Deep Ocean Palette (`#0B2538`, `#123D53`, `#1D6177`, `#BDE7F2`, `#E5A84B`, `#D95757`, `#398B77`)
- **State Management:** `provider` (MultiProvider / ChangeNotifier pattern)
- **Local Persistence:** `shared_preferences` with non-volatile local serialization
- **Rendering & Animations:** Flutter Native `CustomPainter`, `AnimationController`, `TweenAnimationBuilder`, and Vector Paths (Zero external CDN or tile-server dependencies for offline reliability).

### Directory Structure

```text
lib/
├── app.dart                                # MultiProvider and MaterialApp root
├── main.dart                               # App entry point & system UI overlays
├── core/
│   ├── animations/
│   │   ├── page_transitions.dart           # Smooth fade & slide transitions
│   │   └── pulsing_widget.dart             # Pulsing beacons & signal nodes
│   ├── constants/
│   │   └── app_constants.dart              # Hazards, severities, demo credentials
│   ├── theme/
│   │   ├── app_colors.dart                 # Ocean color tokens & gradients
│   │   ├── app_theme.dart                  # Material 3 dark oceanic ThemeData
│   │   └── app_typography.dart             # Typography scale & monospace code
│   └── utils/
│       └── formatters.dart                 # Relative timestamps, distance & colors
├── data/
│   ├── mock_checklist.dart                 # 72-hour emergency preparedness items
│   ├── mock_locations.dart                 # Pre-cached hospitals, shelters & command hubs
│   ├── mock_notifications.dart             # Initial system notifications
│   ├── mock_reports.dart                   # Seed hazard reports
│   └── mock_users.dart                     # Citizen, Responder & Administrator accounts
├── models/
│   ├── activity_entry.dart                 # System audit history model
│   ├── app_user.dart                       # User identity and role authorization
│   ├── bluetooth_message.dart              # P2P mesh relay packets with TTL
│   ├── checklist_item.dart                 # Disaster readiness item
│   ├── emergency_contact.dart              # Offline family/rescue contacts
│   ├── emergency_location.dart             # Medical facilities and shelters
│   ├── hazard_report.dart                  # Field observation & triage report
│   └── notification_item.dart              # In-app actionable notifications
├── providers/
│   ├── auth_provider.dart                  # Authentication session & admin approvals
│   ├── bluetooth_provider.dart             # P2P packet dispatch & deduplication
│   ├── connectivity_provider.dart          # Network simulation & reconnection sync
│   ├── emergency_pack_provider.dart        # Non-volatile emergency pack store
│   ├── notification_provider.dart          # Notification center & unread badges
│   └── report_provider.dart                # Report lifecycle & triage queue
├── services/
│   ├── auth_service.dart                   # Role authentication & approval engine
│   ├── bluetooth_service.dart              # Member 4 Bluetooth contract & simulation
│   ├── local_storage_service.dart          # Local storage persistence
│   ├── risk_service.dart                   # Member 1 AI/ML predictive risk contract
│   └── routing_service.dart                # Member 2 Maps/GPS routing contract
├── widgets/
│   ├── animated_background.dart            # Atmospheric particles & mesh canvas
│   ├── app_card.dart                       # Responsive rounded card container
│   ├── app_logo.dart                       # CustomPainter rotating radar & signal arcs
│   ├── confirmation_dialog.dart            # Destructive action modal
│   ├── connectivity_indicator.dart         # Interactive network state switcher
│   ├── empty_state.dart                    # Polished empty state with action
│   ├── loading_view.dart                   # Animated loading state
│   ├── primary_button.dart                 # Tactile button with loading & emergency styles
│   ├── risk_gauge.dart                     # CustomPainter circular risk gauge
│   └── status_badge.dart                   # Color-coded severity & status pills
└── screens/
    ├── administrator/
    │   └── admin_dashboard_screen.dart     # System telemetry & responder approval (Flow E)
    ├── authentication/
    │   ├── login_screen.dart               # Role switcher with demo presets
    │   └── register_screen.dart            # Citizen onboarding & emergency contacts
    ├── bluetooth/
    │   └── bluetooth_p2p_screen.dart       # P2P mesh packet transfer & deduplication (Flow F)
    ├── citizen/
    │   └── citizen_dashboard_screen.dart   # Gauge, nearby shelters & critical actions
    ├── emergency_mode/
    │   └── emergency_mode_screen.dart      # High-visibility emergency command UI
    ├── emergency_pack/
    │   └── emergency_pack_screen.dart      # Offline contacts, checklist & directives (Flow G)
    ├── map/
    │   └── interactive_map_screen.dart     # CustomPainter vector map & route assessment
    ├── notifications/
    │   └── notifications_screen.dart       # Filterable notification center
    ├── profile/
    │   └── profile_settings_screen.dart    # Permissions audit & communication preferences
    ├── reporting/
    │   └── hazard_report_screen.dart       # Field reporting with offline queueing (Flow A/B)
    ├── reports/
    │   ├── my_reports_screen.dart          # Searchable, filterable citizen report history
    │   └── report_detail_screen.dart       # Status progression timeline & triage notes
    ├── responder/
    │   └── responder_dashboard_screen.dart # Triage queue, verification & notes (Flow D)
    ├── splash/
    │   └── splash_screen.dart              # Rotating Earth globe with orbiting nodes
    └── welcome/
        └── welcome_screen.dart             # Capabilities, entry points & disclaimer
```

---

## 3. Demo Accounts & Credentials

The application provides convenient quick-fill presets directly on the **Sign In** screen:

| Role | Email | Password | Access Capabilities |
| :--- | :--- | :--- | :--- |
| **Citizen** | `citizen@lastsignal.demo` | `citizen123` | Dashboard, Map, Report Hazard, Emergency Pack, Emergency Mode |
| **First Responder** | `responder@lastsignal.demo` | `responder123` | Triage Queue, Report Verification, Status Resolution, Review Notes |
| **Administrator** | `admin@lastsignal.demo` | `admin123` | Responder Account Approvals, User Deactivation, System Telemetry |
| **Pending Responder** | `jordan.kelly@coastal-rescue.org` | *Requires Approval* | Used to test **Flow E** (Admin Approval workflow) |

---

## 4. How to Run & Build

### Prerequisites
- Flutter SDK 3.10+ (Tested on Flutter 3.47.7, Dart 3.13.5)
- Git

### Installation
```bash
# Clone or navigate to the workspace
cd c:\Users\dhira\Desktop\LAST_SIGNAL_AI\frontend

# Install dependencies
flutter pub get

# Run static analysis
flutter analyze

# Run all 8 automated acceptance & flow tests
flutter test
```

### Running on Devices & Platforms
```bash
# Run on Chrome
flutter run -d chrome

# Run on Android (if emulator or device connected)
flutter run -d android

# Run on Windows Desktop
flutter run -d windows

# Build Production Web Release
flutter build web

# Build Android APK
flutter build apk --release
```

---

## 5. Judge Demonstration Guide: Testing the 7 Core Flows

### Flow A: Citizen Submits Report Online ➔ Appears in Responder Queue
1. Log in as **Citizen** (`citizen@lastsignal.demo` / `citizen123`).
2. Verify top network badge shows **ONLINE**.
3. Tap **Report Hazard**, select *Blocked Road*, choose severity *High*, enter description: *"Downed oak tree on Shoreline Rd"*, and tap **Submit Report (Online)**.
4. Log out via Profile and sign in as **Responder** (`responder@lastsignal.demo` / `responder123`).
5. Notice the new report appears immediately in the **DISASTER HAZARD TRIAGE QUEUE**.

### Flow B: Citizen Submits Report Offline ➔ Report Remains Local & Hidden from Responders
1. In Citizen Dashboard, tap the **Connectivity Indicator** (top right) and select **Offline Mode**.
2. Tap **Report Hazard**, select *Flood*, severity *Critical*, enter: *"Surge water 1m depth"*, and tap **Save Report (Offline)**.
3. Notice status badge shows **PENDING SYNC**.
4. Switch to Responder portal: confirm the offline report is **NOT** present in the responder queue.

### Flow C: Citizen Simulates Reconnection ➔ Pending Report Synchronizes
1. Tap the Connectivity Indicator and select **Simulate Reconnection & Sync**.
2. Watch the animated handshake progress.
3. The pending report transitions from `localOnly` to `synced` and enters status **Submitted**.
4. Log into Responder Command: the report is now visible for triage!

### Flow D: Responder Verifies Report ➔ Citizen Sees Updated Status
1. From Responder Command, tap the report card.
2. Enter review note: *"CERT Unit 9 deployed. Traffic diverted to bypass."*
3. Tap **Verify Report**.
4. Return to Citizen portal ➔ open **My Reports** / **Notifications**: report status shows green **VERIFIED** with the responder's official review notes attached.

### Flow E: Administrator Approves Responder Request
1. Attempt to log in with `jordan.kelly@coastal-rescue.org` ➔ Notice message: *"Responder authorization pending administrative verification."*
2. Log in as **Administrator** (`admin@lastsignal.demo` / `admin123`).
3. Locate **Lt. Jordan Kelly** under *RESPONDER AUTHORIZATION REQUESTS*.
4. Tap **Approve Responder** ➔ state updates in local non-volatile store.
5. Log out and sign in as `jordan.kelly@coastal-rescue.org` ➔ **Access is now granted** directly to Responder Command!

### Flow F: Bluetooth P2P Mesh Relay & Deduplication
1. Navigate to **Bluetooth P2P** from Citizen Dashboard or Emergency Mode.
2. Select *Device A (Recon Beacon)* as source and *Device B (Relay Hub)* as target.
3. Tap **Transmit Test Packet**.
4. Observe the animated transmission across the visual mesh nodes.
5. Tap **Transmit Test Packet** a second time with the same report ID ➔ Watch the deduplication filter flag the packet as **DUPLICATE FILTERED** (preventing queue bloat).
6. Tap **Queue for Sync** on any non-duplicate packet to import it into your device's pending upload queue.

### Flow G: Offline Emergency Pack Persistence
1. Navigate to **Emergency Pack** from Citizen Dashboard.
2. Tap **+** on the Contacts tab to add a custom emergency contact.
3. Go to **Directives** tab, tap **Edit**, modify family evacuation instructions, and tap **Save**.
4. Go to **Checklist** tab and check off items.
5. Fully restart the application (`flutter run` or reload) ➔ open Emergency Pack: **all contacts, instructions, and checklist states persist intact**.

---

## 6. Team Integration Contracts (5-Member Architecture)

The frontend is architected with strict abstraction barriers so team members can replace the deterministic mock services with real backend and hardware drivers without rewriting UI components:

### Member 1 — AI/ML Lead
- **Interface:** `lib/services/risk_service.dart` (`IRiskService`)
- **Data Model:** `RiskEstimate`, `RiskFactor`
- **Future Integration:** Replace `getAreaRiskEstimate({double? lat, double? lon})` with an HTTP/gRPC call to your FastAPI ML inference model. The UI automatically consumes the returned `score`, `category`, `modelVersion`, and `contributingFactors`.

### Member 2 — Maps & GPS Lead
- **Interface:** `lib/services/routing_service.dart` (`IRoutingService`)
- **Data Model:** `RouteResult`, `GeoPoint`
- **Future Integration:** Replace the sample vector coordinates in `RoutingService` with `geolocator` for hardware GPS and Mapbox / OpenStreetMap routing API. The custom canvas map (`_MapCanvasPainter`) is already decoupled and accepts dynamic waypoints.

### Member 3 — Flutter Frontend Lead
- **Responsibilities:** Core UI, theme system (`AppTheme`), state management (`ChangeNotifierProvider`), animations (`AppLogo`, `RiskGauge`, `AnimatedBackground`), and form validation.

### Member 4 — Offline & Bluetooth P2P Lead
- **Interface:** `lib/services/bluetooth_service.dart` (`IBluetoothService`)
- **Data Model:** `BluetoothMessage`
- **Future Integration:** Replace `BluetoothService` with `flutter_reactive_ble` or `nearby_connections`. The packet schema, TTL expiry calculation, and `isDuplicate()` checks are already implemented in `BluetoothProvider`.

### Member 5 — Backend & FastAPI Lead
- **Endpoints to implement:**
  - `POST /api/v1/auth/login` ➔ `{ access_token, user_profile }`
  - `POST /api/v1/hazards/report` ➔ `{ id, status, timestamp }`
  - `POST /api/v1/hazards/sync-batch` ➔ Accepts offline pending report array
  - `PATCH /api/v1/responder/verify/{report_id}` ➔ Updates triage status
  - `GET /api/v1/risk/predict?lat={lat}&lon={lon}` ➔ Returns `RiskEstimate`

---

## 7. Automated Acceptance Test Results

All 8 automated test suites execute cleanly via `flutter test`:

```text
00:00 +0: test/flow_test.dart: END-TO-END DEMO FLOW: Submit Offline -> Reconnect Sync -> Responder Verify
00:01 +1: test/widget_test.dart: TEST 1: Launch and verify LAST SIGNAL AI branding and Welcome Screen
00:01 +2: test/widget_test.dart: TEST 2: Offline Emergency Pack persistence and checklist
00:01 +3: test/widget_test.dart: TEST 3 & 4: Online report in responder queue vs Offline pending sync queue
00:01 +4: test/widget_test.dart: TEST 6: First responder verifies report and updates status
00:01 +5: test/widget_test.dart: TEST 7: Administrator approves pending responder authorization
00:01 +6: test/widget_test.dart: TEST 8: Bluetooth P2P deduplication and store-and-forward
00:01 +7: test/widget_test.dart: TEST 9: AI Risk Service & Maps Routing Service Contracts
00:01 +8: All tests passed!
```

---

## 8. Disclaimer & Limitations

- **Prototype Disclaimer:** This software is a functional prototype built for hackathon demonstration. Risk estimates and corridors are simulated for safety illustration. Follow official municipal civil defense authorities during real disaster events.
- **Hardware Simulation:** Bluetooth P2P mesh relay and GPS coordinates are currently simulated via software store-and-forward queues. Physical deployment requires enabling Android runtime permissions (`ACCESS_FINE_LOCATION`, `BLUETOOTH_SCAN`, `BLUETOOTH_ADVERTISE`).
