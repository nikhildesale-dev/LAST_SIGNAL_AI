import 'package:flutter/material.dart';
import '../data/mock_notifications.dart';
import '../models/notification_item.dart';
import '../services/local_storage_service.dart';

class NotificationProvider extends ChangeNotifier {
  final LocalStorageService _storage;
  List<NotificationItem> _notifications = [];

  NotificationProvider(this._storage);

  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> init() async {
    final savedNotifs = await _storage.getNotifications();
    if (savedNotifs != null && savedNotifs.isNotEmpty) {
      _notifications = savedNotifs;
    } else {
      _notifications = List.from(MockNotifications.initialNotifications);
      await _storage.saveNotifications(_notifications);
    }
    notifyListeners();
  }

  Future<void> addNotification({
    required String title,
    required String message,
    required NotificationType type,
    String? relatedReportId,
  }) async {
    final newNotif = NotificationItem(
      id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      title: title,
      message: message,
      type: type,
      timestamp: DateTime.now(),
      isRead: false,
      relatedReportId: relatedReportId,
    );

    _notifications.insert(0, newNotif);
    await _storage.saveNotifications(_notifications);
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    _notifications = _notifications.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();

    await _storage.saveNotifications(_notifications);
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    await _storage.saveNotifications(_notifications);
    notifyListeners();
  }
}
