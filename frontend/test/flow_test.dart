import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:last_signal_ai/services/local_storage_service.dart';
import 'package:last_signal_ai/providers/report_provider.dart';
import 'package:last_signal_ai/providers/connectivity_provider.dart';
import 'package:last_signal_ai/models/hazard_report.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('END-TO-END DEMO FLOW: Submit Offline -> Reconnect Sync -> Responder Verify',
      () async {
    final storage = LocalStorageService();
    final reports = ReportProvider(storage);
    final conn = ConnectivityProvider();

    await reports.init();

    // 1. Citizen switches to Offline Mode
    conn.simulateOffline();
    expect(conn.isOffline, true);

    // 2. Citizen submits hazard report while offline
    final offlineReport = await reports.submitReport(
      hazardType: 'Flood',
      description: 'Rapid storm surge flooding in low-lying underpass',
      severity: 'Critical',
      sampleLocation: '4th Avenue Underpass',
      latitude: 18.9300,
      longitude: 72.8330,
      reporterEmail: 'citizen@lastsignal.demo',
      isOnline: false,
    );

    expect(offlineReport.status, 'Pending Sync');
    expect(offlineReport.syncStatus, SyncStatus.localOnly);

    // 3. Confirm responder CANNOT see it yet
    expect(
      reports.responderQueue.any((r) => r.id == offlineReport.id),
      false,
      reason: 'Offline report must stay out of responder queue until synced',
    );
    expect(
      reports.pendingSyncReports.any((r) => r.id == offlineReport.id),
      true,
      reason: 'Offline report must be present in citizen local pending sync queue',
    );

    // 4. Citizen simulates reconnection & sync
    await conn.simulateReconnection(onReconnected: () async {
      final syncedCount = await reports.syncPendingReports();
      expect(syncedCount >= 1, true);
    });

    expect(conn.isOnline, true);
    expect(reports.pendingSyncReports.isEmpty, true);

    // 5. Responder CAN now see it in the triage queue!
    final queuedReport =
        reports.responderQueue.firstWhere((r) => r.id == offlineReport.id);
    expect(queuedReport.status, 'Submitted');
    expect(queuedReport.syncStatus, SyncStatus.synced);

    // 6. Responder verifies the report and appends notes
    await reports.verifyReport(
      reportId: queuedReport.id,
      responderName: 'Capt. Marcus Vance (CERT-9)',
      responderNote: 'Verified on-site. Field marshals diverting traffic.',
    );

    // 7. Verify updated status across the entire application
    final verifiedReport =
        reports.allReports.firstWhere((r) => r.id == queuedReport.id);
    expect(verifiedReport.status, 'Verified');
    expect(verifiedReport.verifiedBy, 'Capt. Marcus Vance (CERT-9)');
    expect(
      verifiedReport.responderNotes,
      'Verified on-site. Field marshals diverting traffic.',
    );
  });
}
