import '../models/notification_item.dart';

class MockNotifications {
  MockNotifications._();

  static final List<NotificationItem> initialNotifications = [
    NotificationItem(
      id: 'NOTIF-01',
      title: 'Risk Estimate Updated: 68/100 (High)',
      message: 'Cyclone coastal surge model (v2.4) indicates rising water levels in low-lying sectors.',
      type: NotificationType.riskUpdate,
      timestamp: DateTime.now().subtract(const Duration(minutes: 18)),
      isRead: false,
    ),
    NotificationItem(
      id: 'NOTIF-02',
      title: 'Hazard Report Verified',
      message: 'Your report REP-FLD-01 (Flood at 4th Avenue) has been verified by CERT Responder Capt. Marcus Vance.',
      type: NotificationType.reportVerified,
      timestamp: DateTime.now().subtract(const Duration(minutes: 35)),
      isRead: false,
      relatedReportId: 'REP-FLD-01',
    ),
    NotificationItem(
      id: 'NOTIF-03',
      title: 'Emergency Pack Offline Ready',
      message: 'All 5 hospital profiles, emergency contacts, and disaster instructions are cached locally.',
      type: NotificationType.emergencyPackReminder,
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      isRead: true,
    ),
    NotificationItem(
      id: 'NOTIF-04',
      title: 'Network Advisory: Simulated Mesh Active',
      message: 'P2P Bluetooth Relay mode is active. Nearby reports can be exchanged without cellular towers.',
      type: NotificationType.connectivityChanged,
      timestamp: DateTime.now().subtract(const Duration(hours: 6)),
      isRead: true,
    ),
  ];
}
