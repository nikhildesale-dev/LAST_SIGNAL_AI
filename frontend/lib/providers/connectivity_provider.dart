import 'package:flutter/material.dart';

enum NetworkStatus {
  online,
  weak,
  offline,
  reconnecting,
}

class ConnectivityProvider extends ChangeNotifier {
  NetworkStatus _status = NetworkStatus.online;
  DateTime _lastOnlineTime = DateTime.now();
  bool _isSyncing = false;

  NetworkStatus get status => _status;
  DateTime get lastOnlineTime => _lastOnlineTime;
  bool get isSyncing => _isSyncing;

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
}
