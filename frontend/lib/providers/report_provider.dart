import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../data/mock_reports.dart';
import '../models/hazard_report.dart';
import '../services/local_storage_service.dart';

class ReportProvider extends ChangeNotifier {
  final LocalStorageService _storage;
  List<HazardReport> _reports = [];
  DateTime _lastSyncTime = DateTime.now();

  ReportProvider(this._storage);

  List<HazardReport> get allReports => List.unmodifiable(_reports);
  DateTime get lastSyncTime => _lastSyncTime;

  // Citizen view: sees all their own reports (both local drafts/pending and synced) plus verified reports from community
  List<HazardReport> getCitizenReports(String userEmail) {
    return _reports.where((r) => r.reporterEmail.toLowerCase() == userEmail.toLowerCase()).toList();
  }

  // Pending Synchronization Queue: only local-only reports waiting for network connectivity
  List<HazardReport> get pendingSyncReports =>
      _reports.where((r) => r.syncStatus == SyncStatus.localOnly && !r.isDraft).toList();

  int get pendingSyncCount => pendingSyncReports.length;

  // Responder Received Queue: ONLY sees reports that have actually entered the shared demo collection (synced)
  // Pending local-only citizen reports MUST NOT appear here until synced!
  List<HazardReport> get responderQueue =>
      _reports.where((r) => r.syncStatus == SyncStatus.synced && !r.isDraft).toList();

  int get totalReceivedCount => responderQueue.length;
  int get unreviewedCount => responderQueue.where((r) => r.status == AppConstants.statusSubmitted).length;
  int get verifiedCount => responderQueue.where((r) => r.status == AppConstants.statusVerified).length;
  int get resolvedCount => responderQueue.where((r) => r.status == AppConstants.statusResolved).length;

  Future<void> init() async {
    final savedReports = await _storage.getReports();
    if (savedReports != null && savedReports.isNotEmpty) {
      _reports = savedReports;
    } else {
      _reports = List.from(MockReports.initialReports);
      await _storage.saveReports(_reports);
    }
    notifyListeners();
  }

  /// Submit report:
  /// If online: becomes 'Submitted', syncStatus = synced -> immediately visible to responders
  /// If offline/weak: becomes 'Pending Sync', syncStatus = localOnly -> kept strictly out of responder queue
  Future<HazardReport> submitReport({
    required String hazardType,
    required String description,
    required String severity,
    required String sampleLocation,
    required double latitude,
    required double longitude,
    required String reporterEmail,
    required bool isOnline,
    bool isDraft = false,
  }) async {
    final reportId = 'REP-${hazardType.substring(0, 3).toUpperCase()}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final newReport = HazardReport(
      id: reportId,
      hazardType: hazardType,
      description: description,
      severity: severity,
      sampleLocation: sampleLocation,
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      status: isDraft
          ? 'Draft'
          : (isOnline ? AppConstants.statusSubmitted : AppConstants.statusPendingSync),
      syncStatus: isOnline && !isDraft ? SyncStatus.synced : SyncStatus.localOnly,
      reporterEmail: reporterEmail,
      isDraft: isDraft,
    );

    _reports.insert(0, newReport);
    await _storage.saveReports(_reports);
    notifyListeners();
    return newReport;
  }

  /// Flow C: Simulate Reconnection -> Syncs eligible pending reports into the shared queue
  Future<int> syncPendingReports() async {
    int syncedCount = 0;
    _reports = _reports.map((report) {
      if (report.syncStatus == SyncStatus.localOnly && !report.isDraft) {
        syncedCount++;
        return report.copyWith(
          syncStatus: SyncStatus.synced,
          status: AppConstants.statusSubmitted,
        );
      }
      return report;
    }).toList();

    _lastSyncTime = DateTime.now();
    await _storage.saveReports(_reports);
    notifyListeners();
    return syncedCount;
  }

  /// Authorized responder actions (Flow D)
  Future<void> verifyReport({
    required String reportId,
    required String responderName,
    String? responderNote,
  }) async {
    _reports = _reports.map((r) {
      if (r.id == reportId) {
        return r.copyWith(
          status: AppConstants.statusVerified,
          verifiedBy: responderName,
          responderNotes: responderNote ?? r.responderNotes,
        );
      }
      return r;
    }).toList();

    await _storage.saveReports(_reports);
    notifyListeners();
  }

  Future<void> markUnderReview({
    required String reportId,
    String? responderNote,
  }) async {
    _reports = _reports.map((r) {
      if (r.id == reportId) {
        return r.copyWith(
          status: AppConstants.statusUnderReview,
          responderNotes: responderNote ?? r.responderNotes,
        );
      }
      return r;
    }).toList();

    await _storage.saveReports(_reports);
    notifyListeners();
  }

  Future<void> rejectReport({
    required String reportId,
    required String reason,
  }) async {
    _reports = _reports.map((r) {
      if (r.id == reportId) {
        return r.copyWith(
          status: AppConstants.statusRejected,
          responderNotes: reason,
        );
      }
      return r;
    }).toList();

    await _storage.saveReports(_reports);
    notifyListeners();
  }

  Future<void> markResolved({
    required String reportId,
    String? resolutionNote,
  }) async {
    _reports = _reports.map((r) {
      if (r.id == reportId) {
        return r.copyWith(
          status: AppConstants.statusResolved,
          responderNotes: resolutionNote ?? r.responderNotes,
        );
      }
      return r;
    }).toList();

    await _storage.saveReports(_reports);
    notifyListeners();
  }

  /// Import an external report (e.g. from Bluetooth P2P packet)
  Future<bool> importExternalReport(HazardReport report) async {
    if (_reports.any((r) => r.id == report.id)) {
      return false; // Already present
    }
    _reports.insert(0, report);
    await _storage.saveReports(_reports);
    notifyListeners();
    return true;
  }
}
