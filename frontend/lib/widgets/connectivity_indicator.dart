import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../providers/connectivity_provider.dart';
import '../providers/report_provider.dart';
import '../providers/notification_provider.dart';
import '../models/notification_item.dart';

class ConnectivityIndicator extends StatelessWidget {
  final bool compact;

  const ConnectivityIndicator({super.key, this.compact = false});

  void _showSimulationDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkOceanBlue,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final conn = context.watch<ConnectivityProvider>();
        final reports = context.read<ReportProvider>();
        final notifs = context.read<NotificationProvider>();

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'NETWORK SIMULATION CONTROLS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: AppColors.icyBlue,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.mutedText),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Switch network states to test offline report queueing, P2P mesh fallback, and cloud reconnection sync.',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 20),
                _buildModeTile(
                  context: sheetContext,
                  title: 'Online (Cellular / High-Speed)',
                  subtitle: 'Immediate sync with shared emergency database.',
                  icon: Icons.wifi,
                  color: AppColors.successGreen,
                  isSelected: conn.isOnline,
                  onTap: () {
                    conn.simulateOnline();
                    Navigator.pop(sheetContext);
                  },
                ),
                const SizedBox(height: 10),
                _buildModeTile(
                  context: sheetContext,
                  title: 'Weak Connection (Intermittent / 2G)',
                  subtitle: 'High packet loss; queues reports locally if timeout occurs.',
                  icon: Icons.network_check,
                  color: AppColors.warningAmber,
                  isSelected: conn.isWeak,
                  onTap: () {
                    conn.simulateWeak();
                    Navigator.pop(sheetContext);
                  },
                ),
                const SizedBox(height: 10),
                _buildModeTile(
                  context: sheetContext,
                  title: 'Offline Mode (Local P2P Relay Active)',
                  subtitle: 'No internet access. Reports saved to pending local queue.',
                  icon: Icons.wifi_off,
                  color: AppColors.emergencyRed,
                  isSelected: conn.isOffline,
                  onTap: () {
                    conn.simulateOffline();
                    Navigator.pop(sheetContext);
                  },
                ),
                const SizedBox(height: 10),
                _buildModeTile(
                  context: sheetContext,
                  title: 'Simulate Reconnection & Sync',
                  subtitle: 'Transfers pending local reports to shared responder collection.',
                  icon: Icons.sync,
                  color: AppColors.icyBlue,
                  isSelected: conn.isReconnecting,
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await conn.simulateReconnection(onReconnected: () async {
                      final count = await reports.syncPendingReports();
                      if (count > 0) {
                        await notifs.addNotification(
                          title: 'Reconnection Sync Complete',
                          message: 'Successfully synchronized $count pending hazard reports with the shared responder queue.',
                          type: NotificationType.connectivityChanged,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Synchronized $count reports to shared responder queue!'),
                              backgroundColor: AppColors.successGreen,
                            ),
                          );
                        }
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : AppColors.deepOceanNavy,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : AppColors.borderNavy,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? color : AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.bodySmall),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conn = context.watch<ConnectivityProvider>();

    Color statusColor;
    IconData statusIcon;
    String label;

    switch (conn.status) {
      case NetworkStatus.online:
        statusColor = AppColors.successGreen;
        statusIcon = Icons.wifi;
        label = 'ONLINE';
        break;
      case NetworkStatus.weak:
        statusColor = AppColors.warningAmber;
        statusIcon = Icons.network_check;
        label = 'WEAK 2G';
        break;
      case NetworkStatus.offline:
        statusColor = AppColors.emergencyRed;
        statusIcon = Icons.wifi_off;
        label = 'OFFLINE';
        break;
      case NetworkStatus.reconnecting:
        statusColor = AppColors.icyBlue;
        statusIcon = Icons.sync;
        label = 'SYNCING';
        break;
    }

    if (compact) {
      return InkWell(
        onTap: () => _showSimulationDialog(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withOpacity(0.6), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (conn.isReconnecting)
                SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                )
              else
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => _showSimulationDialog(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.darkOceanBlue,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: statusColor.withOpacity(0.6), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '(Tap to toggle)',
                        style: TextStyle(fontSize: 10, color: AppColors.mutedText),
                      ),
                    ],
                  ),
                  Text(
                    conn.statusLabel,
                    style: AppTypography.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.tune, color: AppColors.icyBlue, size: 16),
          ],
        ),
      ),
    );
  }
}
