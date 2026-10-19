import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:last_signal_ai/services/local_storage_service.dart';
import 'package:last_signal_ai/services/auth_service.dart';
import 'package:last_signal_ai/services/bluetooth_service.dart';
import 'package:last_signal_ai/services/risk_service.dart';
import 'package:last_signal_ai/services/routing_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:last_signal_ai/providers/auth_provider.dart';
import 'package:last_signal_ai/providers/connectivity_provider.dart';
import 'package:last_signal_ai/providers/report_provider.dart';
import 'package:last_signal_ai/providers/emergency_pack_provider.dart';
import 'package:last_signal_ai/screens/welcome/welcome_screen.dart';
import 'package:last_signal_ai/data/mock_locations.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('TEST 1: Launch and verify LAST SIGNAL AI branding and Welcome Screen',
      (WidgetTester tester) async {
    final storage = LocalStorageService();
    final authService = AuthService(storage);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ConnectivityProvider>(create: (_) => ConnectivityProvider()),
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider(authService, storage)),
        ],
        child: const MaterialApp(home: WelcomeScreen()),
      ),
    );
    await tester.pump();

    // Verify brand title and welcome headline
    expect(find.text('LAST SIGNAL'), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);
    expect(find.text('WHEN THE NETWORK FAILS, PREPAREDNESS MUST CONTINUE.'), findsOneWidget);
    expect(find.text('Predict Risk'), findsOneWidget);
    expect(find.text('Stay Connected Offline'), findsNothing); // Subtitle is 'Device mesh exchange'
    expect(find.text('Offline P2P'), findsOneWidget);
  });

  test('TEST 2: Offline Emergency Pack persistence and checklist', () async {
    final storage = LocalStorageService();
    final pack = EmergencyPackProvider(storage);
    await pack.init();

    expect(pack.contacts.isNotEmpty, true);
    expect(pack.checklistItems.isNotEmpty, true);

    // Toggle checklist item
    final firstItem = pack.checklistItems.first;
    final initialState = firstItem.isCompleted;
    await pack.toggleChecklistItem(firstItem.id);

    final updatedItem = pack.checklistItems.firstWhere((i) => i.id == firstItem.id);
    expect(updatedItem.isCompleted, !initialState);
  });

  test('TEST 3 & 4: Online report in responder queue vs Offline pending sync queue',
      () async {
    final storage = LocalStorageService();
    final reports = ReportProvider(storage);
    await reports.init();

    // Online submission (Flow A)
    final onlineRep = await reports.submitReport(
      hazardType: 'Flood',
      description: 'Major flooding on 4th Ave',
      severity: 'Critical',
      sampleLocation: 'Sector 3',
      latitude: 18.9300,
      longitude: 72.8330,
      reporterEmail: 'citizen@lastsignal.demo',
      isOnline: true,
    );
    expect(onlineRep.status, 'Submitted');
    expect(reports.responderQueue.any((r) => r.id == onlineRep.id), true);

    // Offline submission (Flow B)
    final offlineRep = await reports.submitReport(
      hazardType: 'Blocked Road',
      description: 'Downed banyan tree',
      severity: 'High',
      sampleLocation: 'Hillview Dr',
      latitude: 18.9350,
      longitude: 72.8250,
      reporterEmail: 'citizen@lastsignal.demo',
      isOnline: false,
    );
    expect(offlineRep.status, 'Pending Sync');
    // Responder queue MUST NOT contain offline pending report!
    expect(reports.responderQueue.any((r) => r.id == offlineRep.id), false);
    // Pending sync queue MUST contain it!
    expect(reports.pendingSyncReports.any((r) => r.id == offlineRep.id), true);

    // Reconnection sync (Flow C)
    final syncedCount = await reports.syncPendingReports();
    expect(syncedCount >= 1, true);
    expect(reports.responderQueue.any((r) => r.id == offlineRep.id), true);
  });

  test('TEST 6: First responder verifies report and updates status', () async {
    final storage = LocalStorageService();
    final reports = ReportProvider(storage);
    await reports.init();

    await reports.verifyReport(
      reportId: 'REP-FLD-01',
      responderName: 'Capt. Marcus Vance',
      responderNote: 'Confirmed impassable. Diverted traffic.',
    );

    final updated = reports.allReports.firstWhere((r) => r.id == 'REP-FLD-01');
    expect(updated.status, 'Verified');
    expect(updated.verifiedBy, 'Capt. Marcus Vance');
  });

  test('TEST 7: Administrator approves pending responder authorization', () async {
    final storage = LocalStorageService();
    final authService = AuthService(storage);
    await authService.init();

    // Verify initial pending responder
    final initialPending =
        authService.allUsers.firstWhere((u) => u.email == 'jordan.kelly@coastal-rescue.org');
    expect(initialPending.isApproved, false);

    // Admin approves
    await authService.approveResponder(initialPending.id);

    final approved =
        authService.allUsers.firstWhere((u) => u.email == 'jordan.kelly@coastal-rescue.org');
    expect(approved.isApproved, true);
  });

  test('TEST 8: Bluetooth P2P deduplication and store-and-forward', () async {
    final btService = BluetoothService();
    final history = await btService.scanSamplePackets();

    // Testing duplicate detection
    final isDup = btService.isDuplicate('REP-FLD-01', history);
    expect(isDup, true);

    final isNew = btService.isDuplicate('REP-BRAND-NEW-99', history);
    expect(isNew, false);
  });

  test('TEST 9: AI Risk Service & Maps Routing Service Contracts', () async {
    final riskService = RiskService();
    final risk = await riskService.getAreaRiskEstimate();
    expect(risk.score, 68);
    expect(risk.category, 'High');

    final routingService = RoutingService();
    final route = await routingService.calculateEmergencyRoute(
      destination: MockLocations.sampleLocations.first,
      knownHazards: [],
    );
    expect(route.navigationDirectives.isNotEmpty, true);
  });
}
