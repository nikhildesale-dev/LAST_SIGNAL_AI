/// Application constants for LAST SIGNAL AI
class AppConstants {
  AppConstants._();

  static const String appName = 'LAST SIGNAL AI';
  static const String appTagline =
      'AI-Driven Predictive Emergency Routing & Offline P2P Disaster Management';

  static const String welcomeHeadline =
      'WHEN THE NETWORK FAILS, PREPAREDNESS MUST CONTINUE.';
  static const String welcomeSubheadline =
      'Prepare for uncertainty. Access essential information. Share local hazards. Stay informed when connectivity is disrupted.';

  static const String prototypeDisclaimer =
      'Prototype for preparedness and coordination. Risk estimates and routes are not guarantees of safety. Follow official emergency instructions.';

  // Hazard Types
  static const List<String> hazardTypes = [
    'Flood',
    'Fire',
    'Earthquake',
    'Landslide',
    'Blocked Road',
    'Damaged Infrastructure',
    'Other',
  ];

  // Severity Levels
  static const List<String> severityLevels = [
    'Low',
    'Moderate',
    'High',
    'Critical',
  ];

  // Report Statuses
  static const String statusPendingSync = 'Pending Sync';
  static const String statusSubmitted = 'Submitted';
  static const String statusUnderReview = 'Under Review';
  static const String statusVerified = 'Verified';
  static const String statusRejected = 'Rejected';
  static const String statusResolved = 'Resolved';

  static const List<String> allReportStatuses = [
    statusPendingSync,
    statusSubmitted,
    statusUnderReview,
    statusVerified,
    statusRejected,
    statusResolved,
  ];

  // Demo Credentials
  static const String demoCitizenEmail = 'citizen@lastsignal.demo';
  static const String demoCitizenPass = 'citizen123';

  static const String demoResponderEmail = 'responder@lastsignal.demo';
  static const String demoResponderPass = 'responder123';

  static const String demoAdminEmail = 'admin@lastsignal.demo';
  static const String demoAdminPass = 'admin123';

  // Persistence Storage Keys
  static const String keyUserSession = 'ls_user_session';
  static const String keyEmergencyContacts = 'ls_emergency_contacts';
  static const String keyEmergencyInstructions = 'ls_emergency_instructions';
  static const String keyChecklistState = 'ls_checklist_state';
  static const String keyLocalReports = 'ls_local_reports';
  static const String keyNotifications = 'ls_notifications';
  static const String keyApprovedResponders = 'ls_approved_responders';
  static const String keyBluetoothHistory = 'ls_bluetooth_history';
}
