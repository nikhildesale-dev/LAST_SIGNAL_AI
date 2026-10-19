import '../models/hazard_report.dart';

class MockReports {
  MockReports._();

  static final List<HazardReport> initialReports = [
    HazardReport(
      id: 'REP-FLD-01',
      hazardType: 'Flood',
      description: 'Rapid storm surge flooding across 4th Avenue Underpass. Water depth estimated at 1.2 meters. Inundating electrical sub-boxes.',
      severity: 'Critical',
      sampleLocation: '4th Avenue Underpass & Shoreline Rd',
      latitude: 18.9280,
      longitude: 72.8310,
      timestamp: DateTime.now().subtract(const Duration(minutes: 42)),
      status: 'Verified',
      syncStatus: SyncStatus.synced,
      reporterEmail: 'citizen@lastsignal.demo',
      responderNotes: 'CERT Team 9 confirmed impassable. Diverted traffic toward North Ridge Bypass.',
      verifiedBy: 'Capt. Marcus Vance',
    ),

    HazardReport(
      id: 'REP-ROD-02',
      hazardType: 'Blocked Road',
      description: 'Uprooted banyan tree and downed utility poles blocking both lanes on Hillview Drive. High risk of energized power lines.',
      severity: 'High',
      sampleLocation: 'Hillview Drive, Near Mile Marker 4',
      latitude: 18.9390,
      longitude: 72.8270,
      timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
      status: 'Under Review',
      syncStatus: SyncStatus.synced,
      reporterEmail: 'elena.rostova@metro.org',
      responderNotes: 'Municipal power crew dispatched for electrical isolation.',
      verifiedBy: null,
    ),

    HazardReport(
      id: 'REP-LND-03',
      hazardType: 'Landslide',
      description: 'Partial embankment collapse along Coastal Highway Sector 5. Mud and boulders on shoulder, one lane restricted.',
      severity: 'Moderate',
      sampleLocation: 'Coastal Highway, Pier 12 Junction',
      latitude: 18.9180,
      longitude: 72.8450,
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      status: 'Verified',
      syncStatus: SyncStatus.synced,
      reporterEmail: 'citizen@lastsignal.demo',
      responderNotes: 'Heavy earth-moving excavator on site. Caution flags placed.',
      verifiedBy: 'Capt. Marcus Vance',
    ),

    HazardReport(
      id: 'REP-INF-04',
      hazardType: 'Damaged Infrastructure',
      description: 'Cracked expansion joint on South Pedestrian Overpass. Shaking under heavy pedestrian evacuation load.',
      severity: 'High',
      sampleLocation: 'South Pedestrian Overpass, Rail Terminal',
      latitude: 18.9240,
      longitude: 72.8380,
      timestamp: DateTime.now().subtract(const Duration(hours: 9)),
      status: 'Resolved',
      syncStatus: SyncStatus.synced,
      reporterEmail: 'citizen@lastsignal.demo',
      responderNotes: 'Structural engineers completed temporary shoring. Pedestrian flow stabilized.',
      verifiedBy: 'Capt. Marcus Vance',
    ),
  ];
}
