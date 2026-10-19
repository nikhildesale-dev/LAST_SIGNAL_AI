import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/app_user.dart';
import '../models/emergency_contact.dart';
import '../models/hazard_report.dart';
import '../models/notification_item.dart';
import '../models/bluetooth_message.dart';

/// Local persistence service for offline-first architecture
/// Safely stores emergency pack data, checklist state, reports,
/// user sessions, and sync queues without requiring active internet.
class LocalStorageService {
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // --- User Session ---
  Future<void> saveUserSession(AppUser user) async {
    await init();
    final jsonStr = jsonEncode(user.toJson());
    await _prefs?.setString(AppConstants.keyUserSession, jsonStr);
  }

  Future<AppUser?> getUserSession() async {
    await init();
    final jsonStr = _prefs?.getString(AppConstants.keyUserSession);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return AppUser.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearUserSession() async {
    await init();
    await _prefs?.remove(AppConstants.keyUserSession);
  }

  // --- Emergency Contacts ---
  Future<void> saveContacts(List<EmergencyContact> contacts) async {
    await init();
    final list = contacts.map((c) => c.toJson()).toList();
    await _prefs?.setString(AppConstants.keyEmergencyContacts, jsonEncode(list));
  }

  Future<List<EmergencyContact>?> getContacts() async {
    await init();
    final jsonStr = _prefs?.getString(AppConstants.keyEmergencyContacts);
    if (jsonStr == null) return null;
    try {
      final list = jsonDecode(jsonStr) as List;
      return list.map((item) => EmergencyContact.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  // --- Emergency Instructions ---
  Future<void> saveInstructions(String instructions) async {
    await init();
    await _prefs?.setString(AppConstants.keyEmergencyInstructions, instructions);
  }

  Future<String?> getInstructions() async {
    await init();
    return _prefs?.getString(AppConstants.keyEmergencyInstructions);
  }

  // --- Checklist Completion Map ---
  Future<void> saveChecklistState(Map<String, bool> state) async {
    await init();
    await _prefs?.setString(AppConstants.keyChecklistState, jsonEncode(state));
  }

  Future<Map<String, bool>?> getChecklistState() async {
    await init();
    final jsonStr = _prefs?.getString(AppConstants.keyChecklistState);
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return map.map((key, value) => MapEntry(key, value as bool));
    } catch (_) {
      return null;
    }
  }

  // --- Reports (Local & Synced) ---
  Future<void> saveReports(List<HazardReport> reports) async {
    await init();
    final list = reports.map((r) => r.toJson()).toList();
    await _prefs?.setString(AppConstants.keyLocalReports, jsonEncode(list));
  }

  Future<List<HazardReport>?> getReports() async {
    await init();
    final jsonStr = _prefs?.getString(AppConstants.keyLocalReports);
    if (jsonStr == null) return null;
    try {
      final list = jsonDecode(jsonStr) as List;
      return list.map((item) => HazardReport.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  // --- Notifications ---
  Future<void> saveNotifications(List<NotificationItem> notifs) async {
    await init();
    final list = notifs.map((n) => n.toJson()).toList();
    await _prefs?.setString(AppConstants.keyNotifications, jsonEncode(list));
  }

  Future<List<NotificationItem>?> getNotifications() async {
    await init();
    final jsonStr = _prefs?.getString(AppConstants.keyNotifications);
    if (jsonStr == null) return null;
    try {
      final list = jsonDecode(jsonStr) as List;
      return list.map((item) => NotificationItem.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  // --- Approved Responders List ---
  Future<void> saveApprovedResponders(List<String> userIds) async {
    await init();
    await _prefs?.setStringList(AppConstants.keyApprovedResponders, userIds);
  }

  Future<List<String>?> getApprovedResponders() async {
    await init();
    return _prefs?.getStringList(AppConstants.keyApprovedResponders);
  }

  // --- Bluetooth History ---
  Future<void> saveBluetoothHistory(List<BluetoothMessage> messages) async {
    await init();
    final list = messages.map((m) => m.toJson()).toList();
    await _prefs?.setString(AppConstants.keyBluetoothHistory, jsonEncode(list));
  }

  Future<List<BluetoothMessage>?> getBluetoothHistory() async {
    await init();
    final jsonStr = _prefs?.getString(AppConstants.keyBluetoothHistory);
    if (jsonStr == null) return null;
    try {
      final list = jsonDecode(jsonStr) as List;
      return list.map((item) => BluetoothMessage.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }
}
