# LAST SIGNAL AI 📡🌊
### AI-Driven Predictive Emergency Routing & Offline P2P Disaster Management System
*Built with Flutter & Dart • Material 3 • Dual Light/Dark Oceanic Design System • Offline-First Architecture*

---

## 1. Project Overview & Mission

**LAST SIGNAL AI** is an emergency-response intelligence platform designed for catastrophic scenarios where traditional telecommunications, internet service providers, and power grids fail.

> *"WHEN THE NETWORK FAILS, PREPAREDNESS MUST CONTINUE."*

The application coordinates three core stakeholders during disaster events:
1. **Citizens:** Monitor real-time disaster threat levels, receive AI predictive risk scores, compute hazard-avoiding evacuation corridors, maintain an offline 72-hour emergency pack, and report local road/flood hazards.
2. **First Responders (CERT / Search & Rescue):** Access an incident triage queue, verify hazard reports, append on-site operational notes, and divert evacuation traffic.
3. **Emergency Administrators:** Review municipal telemetry, inspect responder access authorization requests, and audit system-wide event logs.

---

## 2. Technical Stack & Architecture

- **Framework:** Flutter 3.47.7 (Channel Stable)
- **Language:** Dart 3.13.5 (Sound Null Safety)
- **Design Tokens:** Deep Ocean Navy (`#0B2538`), Ocean Blue (`#123D53`), Vibrant Teal (`#1D6177`), Icy Blue (`#BDE7F2`), Emergency Red (`#D95757`), Warning Amber (`#E5A84B`), and Safe Green (`#398B77`).
- **Theming:** Dual Light & Dark themes with in-app toggle (`ThemeProvider`).
- **State Management:** `provider` (MultiProvider / ChangeNotifier pattern).
- **Local Persistence:** `shared_preferences` with offline queue synchronization.
- **Networking & API:** `http` with configurable base URL, timeout protection, health check latency telemetry, and automatic offline heuristic fallback.
- **Rendering & Vector Maps:** High-performance native `CustomPainter` vector canvas (zero CDN or external map-tile dependencies, fully functional offline).

---

## 3. Key Upgrades & Features

### 🌟 3.1 Premium UI & Design System
- **Dual Theming:** Seamless toggle between **Deep Ocean Dark Mode** (low-light disaster environment) and **Coastal Daylight Light Mode** (high-glare outdoors).
- **Animated Splash Screen:** Rotating 3D-perspective Earth globe with orbital satellite telemetry nodes.
- **Micro-Animations:** Concentric pulsing radar sweeps, dynamic risk gauge needle animations, and smooth fade-and-slide page transitions.
- **Responsive Layouts:** Adaptive layouts that scale gracefully across mobile screens, tablets, and desktop browsers.

### 📊 3.2 Upgraded Citizen Dashboard
- **Emergency Advisory Banner:** High-priority tactical alert strip with pulsating beacon and rapid SOS mode trigger.
- **Dual-Engine AI Risk Score:**
  - Evaluates multi-factor disaster threats on a 0–100 scale.
  - Queries live backend API (`POST /api/predict-risk`) when online; automatically falls back to offline deterministic heuristics when disconnected.
  - Transparent badges: `● LIVE BACKEND AI` vs `○ OFFLINE HEURISTIC (DEMO)`.
  - Interactive **Risk Factor Breakdown Modal** detailing weighted factors:
    - Tidal Storm Surge Inundation (42% weight — Critical)
    - Arterial Drainage Conduit Saturation (28% weight — Severe)
    - P2P Hazard Report Cluster Density (18% weight — Elevated)
    - Low-Lying Infrastructure Vulnerability (12% weight — Moderate)
- **Recommended Evacuation Corridor:** Displays destination, calculated travel time, obstacle avoidance notices, and one-tap navigation.
- **Nearby Hospitals & Shelters:** Horizontal preview with occupancy capacity (e.g. 84/120), distance in km, and direct routing shortcut.
- **Offline Direct-Dial Emergency Contacts:** One-tap copy/call for National Emergency (112), Disaster Management (1077), Medical EMS (108), and personal ICE contacts.
- **Connectivity & Local Queue Card:** Live status (Online, Weak, Offline) with simulation chips and "Sync Now" trigger.

### 📝 3.3 Complete Hazard Reporting
- **Hazard Types:** Flood, Fire, Earthquake, Landslide, Blocked Road, Damaged Infrastructure, and Other.
- **Severity Levels:** Low, Moderate, High, Critical with color-coded selectors.
- **Location & GPS:** One-tap GPS fix (`18.9320° N, 72.8350° E`), manual address entry, and quick coastal presets. Gracefully handles denied location permissions.
- **Timestamps:** Real-time formatted timestamps on every report.
- **Verification Photo:** Simulated photo attachment and removal.
- **Offline Queueing:** Reports filed without internet are saved locally as `Pending Sync` (`SyncStatus.localOnly`), strictly kept out of responder queues until synced.
- **Searchable Report History:** Filterable by status (`All`, `Pending Sync`, `Submitted`, `Under Review`, `Verified`, `Rejected`, `Resolved`).

### 🗺️ 3.4 Tactical Emergency Maps & Routing
- **Offline Vector Canvas:** Custom-painted nautical coastline, arterial highways, grid networks, and hazard exclusion danger zones.
- **Dynamic ETA Calculation:** Toggle between **Foot Evacuation (~4 km/h)** and **Convoy Vehicle (~24 km/h)** modes with real-time ETA updates.
- **Hazard Bypass Routing:** Automatically diverts route waypoints away from verified flood and road blockage zones (e.g., diverting via High Ridge Flyover).
- **Turn-by-Turn Guidance:** Dedicated drawer showing step-by-step navigation directives and caution warnings.
- **Map Filters:** Filter markers by All, Hospitals, Shelters, or Hazards.

### 🎒 3.5 72-Hour Offline Emergency Pack
- **Interactive Checklist:** Pre-populated disaster readiness kit categorized into Water & Food, Medical, Power & Lighting, and Emergency Documents.
- **Offline Contacts Manager:** Add, edit, or delete family and emergency contacts with ICE (In Case of Emergency) designation.
- **Emergency Survival Directives:** Offline guides for water purification, flood evacuation rules, and emergency radio frequencies (NOAA 162.550 MHz).
- **Persistent Data:** State persists across app restarts using local non-volatile storage.

### 📡 3.6 Peer-to-Peer Mesh Simulation
- **Mesh Topology:** Visualizes packet relay across simulated nodes: Device A (Recon Drone/Beacon) ➔ Device B (Community Hub) ➔ Device C (Terminal).
- **Packet Lifecycle:** Store-and-forward transmission with Hop count and Time-To-Live (TTL) countdown.
- **Deduplication:** Verifies that duplicate reports transmitted across multiple mesh paths are detected and ignored.
- **Transparent Labelling:** Explicitly labelled as a software simulation demonstrating protocol concepts.

### 🔌 3.7 Clean Backend & AI/ML Service Layer
- **`ApiService`:**
  - Configurable base URL (default: `http://localhost:8000` or `http://10.0.2.2:8000`).
  - Connection health check ping with millisecond round-trip latency measurement.
  - Connects to `/api/predict-risk` and `/api/reports`.
  - Non-blocking 4-second timeouts to guarantee app responsiveness offline.
  - Safe configuration UI in Profile Settings with real-time connection tester.
  - Zero hardcoded credentials or secrets.

---

## 4. Demo Accounts & Credentials

The app includes one-tap quick-fill demo buttons on the Welcome/Sign-In screen, as well as an instant **Role Switcher** in Profile Settings:

| Role | Demo Email | Password | Access Capabilities |
| :--- | :--- | :--- | :--- |
| **Citizen** | `citizen@lastsignal.demo` | `citizen123` | Dashboard, Map, Hazard Reporting, Offline Pack, SOS Mode |
| **First Responder** | `responder@lastsignal.demo` | `responder123` | Incident Triage Queue, Verification Notes, Resolution Status |
| **Administrator** | `admin@lastsignal.demo` | `admin123` | Responder Account Approvals, System Telemetry, Audit Logs |
| **Pending Responder** | `jordan.kelly@coastal-rescue.org` | *Pending Approval* | Evaluates the Administrator authorization approval workflow |

---

## 5. How to Run the Application

### 5.1 Run in Google Chrome (Web)
```bash
cd c:\Users\dhira\Desktop\LAST_SIGNAL_AI\frontend
flutter run -d chrome
```

### 5.2 Run on Windows Desktop
```bash
flutter run -d windows
```

### 5.3 Run on Android Emulator or Physical Device
```bash
flutter run -d android
```

### 5.4 Run Static Analysis
```bash
flutter analyze
# or
dart analyze --no-fatal-warnings
```

### 5.5 Run Automated Test Suite
```bash
flutter test
```
*All 12 automated unit and flow tests pass with 100% success.*

---

## 6. Real Offline Behavior vs. Simulated Capabilities

To ensure complete honesty and transparency during evaluation:

| Feature | Real Implementation Status | Details |
| :--- | :--- | :--- |
| **Local Storage & Persistence** | **Real** | Emergency contacts, go-bag checklists, and hazard reports persist locally using `shared_preferences`. |
| **Offline Sync Queue** | **Real** | Reports filed offline enter the local `Pending Sync` queue and do not enter responder queues until network synchronization occurs. |
| **Dual Theme System** | **Real** | Dark and Light themes persist across app restarts. |
| **Backend API Service** | **Real** | Configurable HTTP service with health check, ping latency telemetry, and timeout handling. |
| **AI Risk Prediction** | **Hybrid** | If a real FastAPI backend is connected at the configured base URL, live AI results are displayed. If disconnected, it falls back to a deterministic local heuristic model clearly tagged as `OFFLINE HEURISTIC (DEMO)`. |
| **Interactive Map** | **Simulated Vector** | Vector graphics map custom-painted on canvas. Uses simulated Sector 3 coordinates (`18.9320° N, 72.8350° E`) to ensure complete offline functionality without external map API keys. |
| **Bluetooth P2P Mesh** | **Simulated** | Demonstrates the store-and-forward routing logic, TTL countdown, and packet deduplication in software without requiring multiple physical RF devices. |

---

## 7. Project Structure

```text
lib/
├── app.dart                                # MultiProvider & dynamic ThemeProvider root
├── main.dart                               # App bootstrap & system UI styles
├── core/
│   ├── animations/                         # Page transitions & pulsing effects
│   ├── constants/                          # Hazard types, severities, demo credentials
│   ├── theme/                              # Dual Dark/Light themes, colors, typography
│   └── utils/                              # Formatters for timestamps and distance
├── data/                                   # Seed mock data for offline demo
├── models/                                 # AppUser, HazardReport, EmergencyLocation, etc.
├── providers/                              # Auth, Connectivity, Report, Pack, Theme, Bluetooth
├── services/
│   ├── api_service.dart                    # Configurable backend REST API & health telemetry
│   ├── auth_service.dart                   # Role authentication engine
│   ├── bluetooth_service.dart              # P2P mesh relay simulation contract
│   ├── local_storage_service.dart          # Local device persistence
│   ├── risk_service.dart                   # Dual-engine AI risk prediction
│   └── routing_service.dart                # Hazard-avoiding emergency routing
├── widgets/                                # Reusable UI components & CustomPainters
└── screens/                                # 14 modular screens across Citizen, Responder & Admin
```
