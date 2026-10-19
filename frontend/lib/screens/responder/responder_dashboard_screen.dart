import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/animations/page_transitions.dart';
import '../../models/hazard_report.dart';
import '../../models/notification_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/connectivity_indicator.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/status_badge.dart';
import '../map/interactive_map_screen.dart';
import '../welcome/welcome_screen.dart';

class ResponderDashboardScreen extends StatefulWidget {
  const ResponderDashboardScreen({super.key});

  @override
  State<ResponderDashboardScreen> createState() => _ResponderDashboardScreenState();
}

class _ResponderDashboardScreenState extends State<ResponderDashboardScreen> {
  String _selectedStatusFilter = 'All';
  final String _selectedSeverityFilter = 'All';

  void _openReviewModal(HazardReport report) {
    final noteController = TextEditingController(text: report.responderNotes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkOceanBlue,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TRIAGE REPORT ${report.id}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.icyBlue,
                        letterSpacing: 0.8,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.mutedText),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${report.hazardType} • ${report.sampleLocation}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(report.description, style: AppTypography.bodySmall),
                const SizedBox(height: 16),

                // Note input
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  style: const TextStyle(color: AppColors.white),
                  decoration: const InputDecoration(
                    labelText: 'Responder Field Notes / Action Directives',
                    hintText: 'Enter dispatch orders or physical road barriers erected...',
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: 'Mark Under Review',
                          icon: Icons.search,
                          variant: ButtonVariant.secondary,
                          height: 40,
                          onPressed: () async {
                            final reportProv = context.read<ReportProvider>();
                            final notifs = context.read<NotificationProvider>();
                            await reportProv.markUnderReview(
                              reportId: report.id,
                              responderNote: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                            );
                            await notifs.addNotification(
                              title: 'Report Under Review',
                              message: 'Report ${report.id} is now being evaluated by first responders.',
                              type: NotificationType.reportVerified,
                              relatedReportId: report.id,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                        ),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Verify Report',
                        icon: Icons.verified,
                        variant: ButtonVariant.primary,
                        height: 40,
                        onPressed: () async {
                          final reportProv = context.read<ReportProvider>();
                          final notifs = context.read<NotificationProvider>();
                          final auth = context.read<AuthProvider>();
                          await reportProv.verifyReport(
                            reportId: report.id,
                            responderName: auth.currentUser?.name ?? 'CERT Commander',
                            responderNote: noteController.text.trim().isEmpty
                                ? 'Hazard confirmed on site. Corridors updated.'
                                : noteController.text.trim(),
                          );
                          await notifs.addNotification(
                            title: 'Hazard Report Verified!',
                            message: 'Report ${report.id} (${report.hazardType}) has been officially verified.',
                            type: NotificationType.reportVerified,
                            relatedReportId: report.id,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: 'Reject Report',
                        icon: Icons.cancel_outlined,
                        variant: ButtonVariant.ghost,
                        height: 38,
                        onPressed: () async {
                          final reportProv = context.read<ReportProvider>();
                          await reportProv.rejectReport(
                            reportId: report.id,
                            reason: noteController.text.trim().isEmpty ? 'Unsubstantiated hazard condition.' : noteController.text.trim(),
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Mark Resolved',
                        icon: Icons.task_alt,
                        variant: ButtonVariant.outlined,
                        height: 38,
                        onPressed: () async {
                          final reportProv = context.read<ReportProvider>();
                          await reportProv.markResolved(
                            reportId: report.id,
                            resolutionNote: noteController.text.trim().isEmpty ? 'Hazard cleared by emergency crews.' : noteController.text.trim(),
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final reports = context.watch<ReportProvider>();

    final queue = reports.responderQueue.where((r) {
      if (_selectedStatusFilter != 'All' && r.status != _selectedStatusFilter) return false;
      if (_selectedSeverityFilter != 'All' && r.severity != _selectedSeverityFilter) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.deepOceanNavy,
      appBar: AppBar(
        title: const Text('RESPONDER COMMAND'),
        actions: [
          const ConnectivityIndicator(compact: true),
          IconButton(
            icon: const Icon(Icons.map_outlined, color: AppColors.icyBlue),
            onPressed: () {
              Navigator.push(
                context,
                FadeSlidePageRoute(page: const InteractiveMapScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.mutedText),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  FadeSlidePageRoute(page: const WelcomeScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Responder ID Card
              AppCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield, color: AppColors.icyBlue, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Capt. Marcus Vance',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            user?.organization ?? 'Coastal Emergency Response Team (CERT-9)',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'AUTHORIZED',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.successGreen),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Operational Metrics Counters
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard('RECEIVED', reports.totalReceivedCount.toString(), AppColors.icyBlue),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard('UNREVIEWED', reports.unreviewedCount.toString(), AppColors.warningAmber),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard('VERIFIED', reports.verifiedCount.toString(), AppColors.successGreen),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard('RESOLVED', reports.resolvedCount.toString(), AppColors.mutedBlue),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Filters Bar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('STATUS: ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.mutedText)),
                    ...['All', 'Submitted', 'Under Review', 'Verified', 'Resolved'].map((st) {
                      final isSel = _selectedStatusFilter == st;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          selected: isSel,
                          onSelected: (val) {
                            if (val) setState(() => _selectedStatusFilter = st);
                          },
                          label: Text(st, style: TextStyle(fontSize: 10, color: isSel ? Colors.white : AppColors.lightMutedText)),
                          selectedColor: AppColors.teal,
                          backgroundColor: AppColors.darkOceanBlue,
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Triage Queue List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'DISASTER HAZARD TRIAGE QUEUE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: AppColors.lightMutedText,
                    ),
                  ),
                  Text(
                    '${queue.length} Reports In Queue',
                    style: const TextStyle(fontSize: 11, color: AppColors.icyBlue),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (queue.isEmpty)
                const AppCard(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'No reports in triage queue. Pending local citizen reports only appear here after simulated reconnection sync.',
                        style: AppTypography.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else
                ...queue.map((report) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      onTap: () => _openReviewModal(report),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    report.id,
                                    style: AppTypography.code.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 6),
                                  StatusBadge(label: report.severity, isSeverity: true),
                                ],
                              ),
                              StatusBadge(label: report.status, isSeverity: false),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            report.hazardType,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            report.description,
                            style: AppTypography.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 12, color: AppColors.icyBlue),
                                  const SizedBox(width: 4),
                                  Text(
                                    report.sampleLocation.split(',').first,
                                    style: const TextStyle(fontSize: 11, color: AppColors.lightMutedText),
                                  ),
                                ],
                              ),
                              const Row(
                                children: [
                                  Text('Review', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.icyBlue)),
                                  Icon(Icons.chevron_right, size: 14, color: AppColors.icyBlue),
                                ],
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

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.darkOceanBlue,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderNavy),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.lightMutedText),
          ),
        ],
      ),
    );
  }
}
