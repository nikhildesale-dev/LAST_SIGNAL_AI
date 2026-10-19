import 'package:flutter/material.dart';
import '../models/bluetooth_message.dart';
import '../models/hazard_report.dart';
import '../services/bluetooth_service.dart';
import '../services/local_storage_service.dart';

class BluetoothProvider extends ChangeNotifier {
  final BluetoothService _bluetoothService;
  final LocalStorageService _storage;

  List<BluetoothMessage> _transferHistory = [];
  bool _isTransferring = false;
  String _transferStatusMessage = 'Idle';
  String? _lastError;

  BluetoothProvider(this._bluetoothService, this._storage);

  List<BluetoothMessage> get transferHistory => List.unmodifiable(_transferHistory);
  bool get isTransferring => _isTransferring;
  String get transferStatusMessage => _transferStatusMessage;
  String? get lastError => _lastError;

  List<String> get availableDevices => _bluetoothService.availableDevices;

  Future<void> init() async {
    final savedHistory = await _storage.getBluetoothHistory();
    if (savedHistory != null && savedHistory.isNotEmpty) {
      _transferHistory = savedHistory;
    } else {
      _transferHistory = List.from(BluetoothService.samplePackets);
      await _storage.saveBluetoothHistory(_transferHistory);
    }
    notifyListeners();
  }

  /// Simulate Flow F: Sending a hazard report between simulated devices
  Future<BluetoothMessage?> simulateP2PTransfer({
    required HazardReport report,
    required String sourceDevice,
    required String targetDevice,
  }) async {
    _isTransferring = true;
    _lastError = null;
    _transferStatusMessage = 'Broadcasting packet from $sourceDevice...';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 650));
    _transferStatusMessage = 'Relaying through BLE mesh nodes...';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 650));

    // Duplicate detection check
    final isDup = _bluetoothService.isDuplicate(report.id, _transferHistory);

    final newMessage = BluetoothMessage(
      id: 'BT-MSG-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      reportId: report.id,
      sourceDevice: sourceDevice,
      targetDevice: targetDevice,
      hazardType: report.hazardType,
      severity: report.severity,
      location: report.sampleLocation,
      payloadSummary: report.description,
      timestamp: DateTime.now(),
      expiryTime: DateTime.now().add(const Duration(hours: 12)),
      isDuplicate: isDup,
      status: isDup ? 'Duplicate Ignored' : 'Received',
    );

    _transferHistory.insert(0, newMessage);
    await _storage.saveBluetoothHistory(_transferHistory);

    _isTransferring = false;
    _transferStatusMessage = isDup
        ? 'Duplicate detected! Message ${report.id} was already cached.'
        : 'Packet received successfully by $targetDevice.';
    notifyListeners();

    return newMessage;
  }

  /// Import received Bluetooth message into local pending sync queue
  HazardReport convertToPendingReport(BluetoothMessage msg) {
    return HazardReport(
      id: msg.reportId,
      hazardType: msg.hazardType,
      description: '${msg.payloadSummary} [Relayed via P2P Mesh]',
      severity: msg.severity,
      sampleLocation: msg.location,
      latitude: 18.9300,
      longitude: 72.8330,
      timestamp: msg.timestamp,
      status: 'Pending Sync',
      syncStatus: SyncStatus.localOnly,
      reporterEmail: 'mesh-relay@p2p.node',
    );
  }
}
