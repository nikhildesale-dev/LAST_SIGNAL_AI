import 'package:flutter/material.dart';
import '../services/api_service.dart';

enum NetworkStatus {
  online,
  weak,
  offline,
  reconnecting,
}

class ConnectivityProvider extends ChangeNotifier {
  final ApiService _apiService;
  NetworkStatus _status = NetworkStatus.online;
  DateTime _lastOnlineTime = DateTime.now();
  bool _isSyncing = false;
  BackendHealthResult? _lastHealthResult;

  ConnectivityProvider([ApiService? apiService])
      : _apiService = apiService ?? ApiService();

  NetworkStatus get status => _status;
  DateTime get lastOnlineTime => _lastOnlineTime;
  bool get isSyncing => _isSyncing;
  ApiService get apiService => _apiService;
  BackendHealthResult? get lastHealthResult => _lastHealthResult;
  String get backendUrl => _apiService.baseUrl;

  bool get isOnline => _status == NetworkStatus.online;
  bool get isWeak => _status == NetworkStatus.weak;
  bool get isOffline => _status == NetworkStatus.offline;
  bool get isReconnecting => _status == NetworkStatus.reconnecting;

  String get statusLabel {
    switch (_status) {
      case NetworkStatus.online:
        return 'Online (Cellular / High Bandwidth)';
      case NetworkStatus.weak:
        return 'Weak Connection (Intermittent / 2G)';
      case NetworkStatus.offline:
        return 'Offline Mode (Local P2P Relay Active)';
      case NetworkStatus.reconnecting:
        return 'Reconnecting & Synchronizing...';
    }
  }

  void simulateOnline() {
    _status = NetworkStatus.online;
    _lastOnlineTime = DateTime.now();
    notifyListeners();
  }

  void simulateWeak() {
    _status = NetworkStatus.weak;
    notifyListeners();
  }

  void simulateOffline() {
    _status = NetworkStatus.offline;
    notifyListeners();
  }

  Future<void> simulateReconnection({Future<void> Function()? onReconnected}) async {
    _status = NetworkStatus.reconnecting;
    _isSyncing = true;
    notifyListeners();

    // Simulated network handshake and payload upload
    await Future.delayed(const Duration(milliseconds: 1400));

    if (onReconnected != null) {
      await onReconnected();
    }

    _status = NetworkStatus.online;
    _lastOnlineTime = DateTime.now();
    _isSyncing = false;
    notifyListeners();
  }

  Future<BackendHealthResult> checkBackend() async {
    _status = NetworkStatus.reconnecting;
    notifyListeners();

    final result = await _apiService.checkBackendHealth();
    _lastHealthResult = result;
    if (result.isHealthy) {
      _status = NetworkStatus.online;
      _lastOnlineTime = DateTime.now();
    } else {
      _status = NetworkStatus.offline;
    }
    notifyListeners();
    return result;
  }

  Future<void> updateBackendUrl(String newUrl) async {
    await _apiService.setBaseUrl(newUrl);
    notifyListeners();
  }
}
