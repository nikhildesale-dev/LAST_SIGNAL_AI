import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../models/hazard_report.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';

class ReportDetailScreen extends StatelessWidget {
  final HazardReport report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepOceanNavy,
      appBar: AppBar(
        title: Text('REPORT ${report.id}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          report.id,
                          style: AppTypography.code.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            StatusBadge(label: report.severity, isSeverity: true),
                            const SizedBox(width: 6),
                            StatusBadge(label: report.status, isSeverity: false),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      report.hazardType,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.white),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: AppColors.icyBlue),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            report.sampleLocation,
                            style: const TextStyle(fontSize: 13, color: AppColors.lightMutedText),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: AppColors.mutedText),
                        const SizedBox(width: 4),
                        Text(
                          Formatters.formatDateTime(report.timestamp),
                          style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Status Progression Timeline
              const Text(
                'INCIDENT STATUS PROGRESSION',
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
                  children: [
                    _buildTimelineStep(
                      title: 'Report Logged / Queued',
                      subtitle: report.syncStatus == SyncStatus.synced
                          ? 'Synchronized with shared emergency registry'
                          : 'Saved in offline local storage',
                      isCompleted: true,
                      icon: Icons.check_circle,
                    ),
                    _buildTimelineDivider(report.status != AppConstants.statusSubmitted && report.status != AppConstants.statusPendingSync),
                    _buildTimelineStep(
                      title: 'Under Review',
                      subtitle: 'First responders triaging hazard severity and location',
                      isCompleted: report.status == AppConstants.statusUnderReview ||
                          report.status == AppConstants.statusVerified ||
                          report.status == AppConstants.statusResolved,
                      icon: Icons.search,
                    ),
                    _buildTimelineDivider(report.status == AppConstants.statusVerified || report.status == AppConstants.statusResolved),
                    _buildTimelineStep(
                      title: 'Verified Incident',
                      subtitle: report.verifiedBy != null
                          ? 'Verified by ${report.verifiedBy}'
                          : 'Awaiting field reconnaissance team',
                      isCompleted: report.status == AppConstants.statusVerified ||
                          report.status == AppConstants.statusResolved,
                      icon: Icons.verified,
                    ),
                    _buildTimelineDivider(report.status == AppConstants.statusResolved),
                    _buildTimelineStep(
                      title: 'Incident Resolved',
                      subtitle: 'Hazard cleared or corridor shored up',
                      isCompleted: report.status == AppConstants.statusResolved,
                      icon: Icons.task_alt,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Description Details
              const Text(
                'FIELD OBSERVATION NARRATIVE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: AppColors.lightMutedText,
                ),
              ),
              const SizedBox(height: 8),
              AppCard(
                child: Text(
                  report.description,
                  style: const TextStyle(fontSize: 14, color: AppColors.white, height: 1.5),
                ),
              ),
              const SizedBox(height: 16),

              // Responder Notes
              if (report.responderNotes != null) ...[
                const Text(
                  'FIRST RESPONDER ASSESSMENT NOTES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppColors.icyBlue,
                  ),
                ),
                const SizedBox(height: 8),
                AppCard(
                  borderColor: AppColors.teal,
                  backgroundColor: AppColors.teal.withOpacity(0.12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.security, color: AppColors.icyBlue, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.verifiedBy ?? 'CERT Incident Commander',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              report.responderNotes!,
                              style: const TextStyle(fontSize: 12, color: AppColors.lightMutedText, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Role Notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.deepOceanNavy,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderNavy),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 16, color: AppColors.mutedText),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Citizens cannot alter official response statuses. First responder actions are logged for civic transparency.',
                        style: TextStyle(fontSize: 10, color: AppColors.mutedText),
                      ),
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

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required bool isCompleted,
    required IconData icon,
  }) {
    final color = isCompleted ? AppColors.successGreen : AppColors.mutedText;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? AppColors.white : AppColors.mutedText,
                ),
              ),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.lightMutedText)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineDivider(bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(left: 14, top: 4, bottom: 4),
      alignment: Alignment.centerLeft,
      height: 16,
      width: 2,
      color: isCompleted ? AppColors.successGreen : AppColors.borderNavy,
    );
  }
}
