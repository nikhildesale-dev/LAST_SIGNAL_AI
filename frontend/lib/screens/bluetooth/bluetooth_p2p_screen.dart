import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/animations/pulsing_widget.dart';
import '../../models/bluetooth_message.dart';
import '../../models/hazard_report.dart';
import '../../models/notification_item.dart';
import '../../providers/bluetooth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/status_badge.dart';

class BluetoothP2PScreen extends StatefulWidget {
  const BluetoothP2PScreen({super.key});

  @override
  State<BluetoothP2PScreen> createState() => _BluetoothP2PScreenState();
}

class _BluetoothP2PScreenState extends State<BluetoothP2PScreen> {
  String _sourceDevice = 'Device A (Recon Beacon)';
  String _targetDevice = 'Device B (Community Relay Hub)';

  @override
  Widget build(BuildContext context) {
    final bt = context.watch<BluetoothProvider>();
    final reports = context.watch<ReportProvider>();
    final notifs = context.read<NotificationProvider>();

    return Scaffold(
      backgroundColor: AppColors.deepOceanNavy,
      appBar: AppBar(
        title: const Text('BLUETOOTH P2P MESH SIMULATION'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.icyBlue, width: 0.8),
            ),
            child: const Row(
              children: [
                Icon(Icons.bluetooth, color: AppColors.icyBlue, size: 14),
                SizedBox(width: 4),
                Text(
                  'BLE SIMULATED',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.icyBlue),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Prominent Simulation Disclaimer
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.darkOceanBlue,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderNavy),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.warningAmber, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bluetooth Demo Simulation: Illustrates store-and-forward mesh packet transfer, TTL expiry, and duplicate detection. No actual RF hardware required.',
                        style: TextStyle(fontSize: 11, color: AppColors.lightMutedText, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Visual Simulated Mesh Nodes Diagram (Device A -> Device B -> Device C)
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'ACTIVE SIMULATED MESH TOPOLOGY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: AppColors.icyBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNodeVisual('Device A', 'Drone Beacon', Icons.podcasts, AppColors.icyBlue),
                        _buildTransferPulse(bt.isTransferring),
                        _buildNodeVisual('Device B', 'Community Relay', Icons.hub, AppColors.teal),
                        _buildTransferPulse(bt.isTransferring),
                        _buildNodeVisual('Device C', 'This Terminal', Icons.smartphone, AppColors.successGreen),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (bt.isTransferring) ...[
                      const SizedBox(
                        width: 160,
                        child: LinearProgressIndicator(
                          backgroundColor: AppColors.deepOceanNavy,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.icyBlue),
                          minHeight: 2,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      bt.transferStatusMessage,
                      style: AppTypography.code.copyWith(fontSize: 11, color: AppColors.lightMutedText),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // FLOW F TRIGGER: Simulate P2P Packet Transfer
              const Text(
                'SIMULATE PACKET DISPATCH (FLOW F)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: AppColors.lightMutedText,
                ),
              ),
              const SizedBox(height: 8),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Relay Hazard Report via BLE Mesh',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sends an emergency report packet between simulated nodes. Demonstrates duplicate prevention when the same packet is received twice.',
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _sourceDevice,
                            dropdownColor: AppColors.darkOceanBlue,
                            decoration: const InputDecoration(labelText: 'Source Device'),
                            style: const TextStyle(fontSize: 12, color: AppColors.white),
                            items: bt.availableDevices.map((d) {
                              return DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 11)));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _sourceDevice = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _targetDevice,
                            dropdownColor: AppColors.darkOceanBlue,
                            decoration: const InputDecoration(labelText: 'Target Node'),
                            style: const TextStyle(fontSize: 12, color: AppColors.white),
                            items: bt.availableDevices.map((d) {
                              return DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 11)));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _targetDevice = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    PrimaryButton(
                      label: bt.isTransferring ? 'Relaying Packet...' : 'Transmit Test Packet (Device A -> Device B)',
                      icon: Icons.send_to_mobile,
                      isLoading: bt.isTransferring,
                      onPressed: () async {
                        final sampleReport = reports.allReports.isNotEmpty
                            ? reports.allReports.first
                            : HazardReport(
                                id: 'REP-BT-DEMO',
                                hazardType: 'Flood',
                                description: 'Tidal surge rising at 4th Avenue Underpass',
                                severity: 'Critical',
                                sampleLocation: '4th Avenue Underpass',
                                latitude: 18.9300,
                                longitude: 72.8330,
                                timestamp: DateTime.now(),
                                status: 'Pending Sync',
                                syncStatus: SyncStatus.localOnly,
                                reporterEmail: 'mesh-drone@p2p.node',
                              );

                        final msg = await bt.simulateP2PTransfer(
                          report: sampleReport,
                          sourceDevice: _sourceDevice,
                          targetDevice: _targetDevice,
                        );

                        if (msg != null && !msg.isDuplicate) {
                          await notifs.addNotification(
                            title: 'P2P Hazard Packet Received',
                            message: 'Received report ${msg.reportId} (${msg.hazardType}) from ${msg.sourceDevice}.',
                            type: NotificationType.bluetoothReceived,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // P2P MESSAGE HISTORY & STORE-AND-FORWARD QUEUE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'P2P PACKET CACHE & DEDUPLICATION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: AppColors.lightMutedText,
                    ),
                  ),
                  Text(
                    '${bt.transferHistory.length} Packets',
                    style: const TextStyle(fontSize: 11, color: AppColors.icyBlue),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (bt.transferHistory.isEmpty)
                const AppCard(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No P2P packets received yet.', style: AppTypography.bodySmall),
                    ),
                  ),
                )
              else
                ...bt.transferHistory.map((msg) {
                  final isAlreadyInReports = reports.allReports.any((r) => r.id == msg.reportId);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      borderColor: msg.isDuplicate ? AppColors.warningAmber : AppColors.borderNavy,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    msg.reportId,
                                    style: AppTypography.code.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  StatusBadge(label: msg.hazardType, isSeverity: false),
                                ],
                              ),
                              if (msg.isDuplicate)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.warningAmber.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColors.warningAmber, width: 0.8),
                                  ),
                                  child: const Text(
                                    'DUPLICATE FILTERED',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.warningAmber,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.successGreen.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    msg.status.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.successGreen,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${msg.sourceDevice} ➔ ${msg.targetDevice}',
                            style: const TextStyle(fontSize: 11, color: AppColors.icyBlue, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            msg.payloadSummary,
                            style: AppTypography.bodySmall.copyWith(color: AppColors.white),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TTL Expiry: ${Formatters.timeAgo(msg.expiryTime)}',
                                style: const TextStyle(fontSize: 10, color: AppColors.mutedText),
                              ),
                              if (!msg.isDuplicate && !isAlreadyInReports)
                                TextButton.icon(
                                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                  icon: const Icon(Icons.add_to_photos_outlined, size: 14, color: AppColors.icyBlue),
                                  label: const Text(
                                    'Queue for Sync',
                                    style: TextStyle(fontSize: 11, color: AppColors.icyBlue),
                                  ),
                                  onPressed: () async {
                                    final pendingReport = bt.convertToPendingReport(msg);
                                    final imported = await reports.importExternalReport(pendingReport);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            imported
                                                ? 'Imported ${msg.reportId} to local pending sync queue.'
                                                : 'Report was already queued.',
                                          ),
                                          backgroundColor: AppColors.teal,
                                        ),
                                      );
                                    }
                                  },
                                )
                              else if (isAlreadyInReports)
                                const Text(
                                  '✓ Queued in Local Store',
                                  style: TextStyle(fontSize: 10, color: AppColors.successGreen, fontWeight: FontWeight.bold),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNodeVisual(String name, String role, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(role, style: const TextStyle(fontSize: 9, color: AppColors.mutedText)),
      ],
    );
  }

  Widget _buildTransferPulse(bool active) {
    if (!active) {
      return const Icon(Icons.arrow_forward, color: AppColors.borderNavy, size: 18);
    }
    return const PulsingWidget(
      pulseColor: AppColors.icyBlue,
      child: Icon(Icons.forward, color: AppColors.icyBlue, size: 20),
    );
  }
}
