import '../models/bluetooth_message.dart';
import '../models/hazard_report.dart';

/// Abstract contract for Team Member 4 (Offline & Bluetooth P2P)
abstract class IBluetoothService {
  List<String> get availableDevices;
  Future<List<BluetoothMessage>> scanSamplePackets();
  Future<BluetoothMessage> transmitReport({
    required HazardReport report,
    required String targetDevice,
  });
  bool isDuplicate(String reportId, List<BluetoothMessage> history);
}

/// Simulated Bluetooth P2P mesh service with duplicate detection and store-and-forward queue
class BluetoothService implements IBluetoothService {
  @override
  List<String> get availableDevices => const [
        'Device A (Recon Beacon)',
        'Device B (Community Relay Hub)',
        'Device C (Field Citizen Node)',
      ];

  static final List<BluetoothMessage> samplePackets = [
    BluetoothMessage(
      id: 'BT-MSG-001',
      reportId: 'REP-FLD-01',
      sourceDevice: 'Device A (Recon Beacon)',
      targetDevice: 'Device B (Community Relay Hub)',
      hazardType: 'Flood',
      severity: 'Critical',
      location: '4th Avenue Underpass',
      payloadSummary: 'Tidal surge 1.2m depth. Electrical conduit inundated.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
      expiryTime: DateTime.now().add(const Duration(hours: 12)),
      isDuplicate: false,
      status: 'Received',
    ),
    BluetoothMessage(
      id: 'BT-MSG-002',
      reportId: 'REP-BT-092',
      sourceDevice: 'Device B (Community Relay Hub)',
      targetDevice: 'Device C (Field Citizen Node)',
      hazardType: 'Blocked Road',
      severity: 'High',
      location: 'Oakridge Overpass Mile 2',
      payloadSummary: 'Overturned cargo container blocking westbound lane.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      expiryTime: DateTime.now().add(const Duration(hours: 8)),
      isDuplicate: false,
      status: 'Received',
    ),
  ];

  @override
  Future<List<BluetoothMessage>> scanSamplePackets() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return List.from(samplePackets);
  }

  @override
  bool isDuplicate(String reportId, List<BluetoothMessage> history) {
    return history.any((msg) => msg.reportId == reportId);
  }

  @override
  Future<BluetoothMessage> transmitReport({
    required HazardReport report,
    required String targetDevice,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return BluetoothMessage(
      id: 'BT-TX-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      reportId: report.id,
      sourceDevice: 'Device C (This Terminal)',
      targetDevice: targetDevice,
      hazardType: report.hazardType,
      severity: report.severity,
      location: report.sampleLocation,
      payloadSummary: report.description,
      timestamp: DateTime.now(),
      expiryTime: DateTime.now().add(const Duration(hours: 24)),
      isDuplicate: false,
      status: 'Delivered',
    );
  }
}
