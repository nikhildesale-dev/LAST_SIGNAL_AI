import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/animations/page_transitions.dart';
import '../../core/animations/pulsing_widget.dart';
import '../../models/notification_item.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/emergency_pack_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/primary_button.dart';
import '../bluetooth/bluetooth_p2p_screen.dart';
import '../map/interactive_map_screen.dart';
import '../reporting/hazard_report_screen.dart';

class EmergencyModeScreen extends StatelessWidget {
  const EmergencyModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final conn = context.watch<ConnectivityProvider>();
    final pack = context.watch<EmergencyPackProvider>();
    final reports = context.watch<ReportProvider>();
    final notifs = context.read<NotificationProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF07141E), // Ultra-deep navy background
      appBar: AppBar(
        backgroundColor: AppColors.emergencyRed,
        title: const Row(
          children: [
            PulsingWidget(
              pulseColor: Colors.white,
              child: Icon(Icons.emergency, color: Colors.white, size: 22),
            ),
            SizedBox(width: 8),
            Text(
              'EMERGENCY MODE ACTIVE',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // High-Contrast Network Status & Offline Notice Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: conn.isOnline
                      ? AppColors.teal.withOpacity(0.3)
                      : AppColors.emergencyRed.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: conn.isOnline ? AppColors.teal : AppColors.emergencyRed,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      conn.isOnline ? Icons.cell_tower : Icons.portable_wifi_off,
                      color: conn.isOnline ? AppColors.icyBlue : AppColors.emergencyRed,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            conn.statusLabel.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            conn.isOnline
                                ? 'Cellular telemetry active. All live updates enabled.'
                                : 'Network disrupted. Operating on local cache & P2P relay.',
                            style: const TextStyle(fontSize: 10, color: AppColors.lightMutedText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Network Simulation Quick Switcher Bar
              const Text(
                'NETWORK SIMULATION CONTROLS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: AppColors.lightMutedText,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildNetworkBtn(
                      label: 'Online',
                      color: AppColors.successGreen,
                      isSelected: conn.isOnline,
                      onTap: () => conn.simulateOnline(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildNetworkBtn(
                      label: 'Weak 2G',
                      color: AppColors.warningAmber,
                      isSelected: conn.isWeak,
                      onTap: () => conn.simulateWeak(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildNetworkBtn(
                      label: 'Offline',
                      color: AppColors.emergencyRed,
                      isSelected: conn.isOffline,
                      onTap: () => conn.simulateOffline(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildNetworkBtn(
                      label: 'Re-sync',
                      color: AppColors.icyBlue,
                      isSelected: conn.isReconnecting,
                      onTap: () async {
                        await conn.simulateReconnection(onReconnected: () async {
                          final count = await reports.syncPendingReports();
                          if (count > 0) {
                            await notifs.addNotification(
                              title: 'Reconnection Sync Completed',
                              message: 'Successfully delivered $count pending reports to emergency responder team.',
                              type: NotificationType.connectivityChanged,
                            );
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Pending Reports Alert (Flow B & C demonstration)
              if (reports.pendingSyncCount > 0) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warningAmber.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warningAmber),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.upload_file, color: AppColors.warningAmber, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${reports.pendingSyncCount} LOCAL REPORT(S) PENDING SYNC',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: AppColors.warningAmber,
                              ),
                            ),
                            const Text(
                              'Saved locally. Hidden from responders until reconnection or P2P transfer.',
                              style: TextStyle(fontSize: 10, color: AppColors.lightMutedText),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await conn.simulateReconnection(onReconnected: () async {
                            await reports.syncPendingReports();
                          });
                        },
                        child: const Text('Sync Now', style: TextStyle(color: AppColors.icyBlue, fontSize: 11)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // EMERGENCY DIRECT ACTIONS
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'Report Hazard',
                      icon: Icons.add_alert,
                      variant: ButtonVariant.emergency,
                      height: 48,
                      onPressed: () {
                        Navigator.push(
                          context,
                          FadeSlidePageRoute(page: const HazardReportScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Bluetooth P2P',
                      icon: Icons.bluetooth_audio,
                      variant: ButtonVariant.secondary,
                      height: 48,
                      onPressed: () {
                        Navigator.push(
                          context,
                          FadeSlidePageRoute(page: const BluetoothP2PScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // PRIMARY EMERGENCY CONTACT (ONE-TAP CALL/DISPATCH)
              const Text(
                'PRIMARY EMERGENCY CONTACT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: AppColors.lightMutedText,
                ),
              ),
              const SizedBox(height: 8),
              if (pack.contacts.isNotEmpty)
                AppCard(
                  padding: const EdgeInsets.all(14),
                  backgroundColor: AppColors.darkOceanBlue,
                  borderColor: AppColors.emergencyRed.withOpacity(0.5),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.emergencyRed.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.phone_in_talk, color: AppColors.emergencyRed, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pack.contacts.first.name,
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 15),
                            ),
                            Text(
                              '${pack.contacts.first.relationship} • ${pack.contacts.first.phone}',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emergencyRed,
                          minimumSize: const Size(60, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Simulating emergency call to ${pack.contacts.first.phone}...'),
                              backgroundColor: AppColors.emergencyRed,
                            ),
                          );
                        },
                        child: const Text('DIAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),

              // NEAREST SAVED DESTINATIONS (OFFLINE READY)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'NEAREST EMERGENCY DESTINATION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: AppColors.lightMutedText,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        FadeSlidePageRoute(page: const InteractiveMapScreen()),
                      );
                    },
                    child: const Text('View Corridors', style: TextStyle(fontSize: 11, color: AppColors.icyBlue)),
                  ),
                ],
              ),
              if (pack.savedLocations.isNotEmpty)
                AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            pack.savedLocations.first.name,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            '${pack.savedLocations.first.distanceKm} km',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.icyBlue),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(pack.savedLocations.first.sampleAddress, style: AppTypography.bodySmall),
                      const SizedBox(height: 10),
                      PrimaryButton(
                        label: 'Navigate to Destination',
                        icon: Icons.navigation_outlined,
                        height: 38,
                        onPressed: () {
                          Navigator.push(
                            context,
                            FadeSlidePageRoute(
                              page: InteractiveMapScreen(initialDestination: pack.savedLocations.first),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkBtn({
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.25) : AppColors.darkOceanBlue,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : AppColors.borderNavy,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            color: isSelected ? color : AppColors.lightMutedText,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
