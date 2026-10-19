import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/animations/page_transitions.dart';
import '../../models/notification_item.dart';
import '../../providers/notification_provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../reports/report_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final notifs = context.watch<NotificationProvider>();
    final reports = context.watch<ReportProvider>();

    final filtered = notifs.notifications.where((n) {
      if (_selectedFilter == 'Unread') return !n.isRead;
      if (_selectedFilter == 'Risk') return n.type == NotificationType.riskUpdate;
      if (_selectedFilter == 'Reports') {
        return n.type == NotificationType.reportSubmitted ||
            n.type == NotificationType.reportVerified ||
            n.type == NotificationType.reportSavedLocally;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.deepOceanNavy,
      appBar: AppBar(
        title: const Text('NOTIFICATION CENTER'),
        actions: [
          if (notifs.unreadCount > 0)
            TextButton(
              onPressed: () => notifs.markAllAsRead(),
              child: const Text('Mark all read', style: TextStyle(color: AppColors.icyBlue, fontSize: 12)),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Notice banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.darkOceanBlue,
              child: const Text(
                'Prototype Local Event Stream • No real SMS or federal push alerts active',
                style: TextStyle(fontSize: 10, color: AppColors.mutedText),
                textAlign: TextAlign.center,
              ),
            ),

            // Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: ['All', 'Unread', 'Risk', 'Reports'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) setState(() => _selectedFilter = filter);
                      },
                      label: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.white : AppColors.lightMutedText,
                        ),
                      ),
                      selectedColor: AppColors.teal,
                      backgroundColor: AppColors.darkOceanBlue,
                      side: BorderSide(color: isSelected ? AppColors.icyBlue : AppColors.borderNavy),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Notifications List
            Expanded(
              child: filtered.isEmpty
                  ? const EmptyState(
                      icon: Icons.notifications_off_outlined,
                      title: 'No Notifications',
                      message: 'You have no alerts matching this filter category.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final notif = filtered[index];
                        return _buildNotificationCard(notif, reports, notifs);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    NotificationItem notif,
    ReportProvider reports,
    NotificationProvider notifs,
  ) {
    IconData icon;
    Color iconColor;

    switch (notif.type) {
      case NotificationType.riskUpdate:
        icon = Icons.auto_graph;
        iconColor = AppColors.warningAmber;
        break;
      case NotificationType.reportVerified:
        icon = Icons.verified;
        iconColor = AppColors.successGreen;
        break;
      case NotificationType.reportSavedLocally:
        icon = Icons.save_alt;
        iconColor = AppColors.icyBlue;
        break;
      case NotificationType.reportSubmitted:
        icon = Icons.cloud_upload_outlined;
        iconColor = AppColors.infoBlue;
        break;
      case NotificationType.connectivityChanged:
        icon = Icons.cell_tower;
        iconColor = AppColors.icyBlue;
        break;
      case NotificationType.emergencyPackReminder:
        icon = Icons.backpack;
        iconColor = AppColors.teal;
        break;
      case NotificationType.bluetoothReceived:
        icon = Icons.bluetooth_audio;
        iconColor = AppColors.successGreen;
        break;
      default:
        icon = Icons.notifications_outlined;
        iconColor = AppColors.icyBlue;
    }

    return AppCard(
      borderColor: notif.isRead ? AppColors.borderNavy : AppColors.icyBlue.withOpacity(0.5),
      onTap: () {
        if (!notif.isRead) notifs.markAsRead(notif.id);

        if (notif.relatedReportId != null) {
          final matched = reports.allReports.where((r) => r.id == notif.relatedReportId).firstOrNull;
          if (matched != null) {
            Navigator.push(
              context,
              FadeSlidePageRoute(page: ReportDetailScreen(report: matched)),
            );
          }
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notif.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: notif.isRead ? FontWeight.bold : FontWeight.w900,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    if (!notif.isRead)
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.icyBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  notif.message,
                  style: AppTypography.bodySmall.copyWith(
                    color: notif.isRead ? AppColors.lightMutedText : Colors.white70,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      Formatters.timeAgo(notif.timestamp),
                      style: const TextStyle(fontSize: 10, color: AppColors.mutedText),
                    ),
                    if (notif.relatedReportId != null)
                      const Text(
                        'View Report ➔',
                        style: TextStyle(fontSize: 10, color: AppColors.icyBlue, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
