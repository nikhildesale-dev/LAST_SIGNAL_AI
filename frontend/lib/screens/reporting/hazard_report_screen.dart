import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../models/notification_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/status_badge.dart';

class HazardReportScreen extends StatefulWidget {
  const HazardReportScreen({super.key});

  @override
  State<HazardReportScreen> createState() => _HazardReportScreenState();
}

class _HazardReportScreenState extends State<HazardReportScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedHazardType = AppConstants.hazardTypes.first;
  String _selectedSeverity = 'High';
  final TextEditingController _locationController = TextEditingController(
    text: '4th Avenue Underpass & Shoreline Rd',
  );
  final TextEditingController _descriptionController = TextEditingController();
  bool _hasPhotoPlaceholder = false;
  bool _isSubmitting = false;

  final List<String> _samplePresets = [
    '4th Avenue Underpass & Shoreline Rd',
    'Hillview Drive, Near Mile Marker 4',
    'Coastal Highway, Pier 12 Junction',
    'Current GPS: Sector 3 Civic Plaza (18.9320, 72.8350)',
  ];

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport({required bool isDraft}) async {
    if (!isDraft && !_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final conn = context.read<ConnectivityProvider>();
    final reportProv = context.read<ReportProvider>();
    final auth = context.read<AuthProvider>();
    final notifs = context.read<NotificationProvider>();

    final userEmail = auth.currentUser?.email ?? AppConstants.demoCitizenEmail;

    final report = await reportProv.submitReport(
      hazardType: _selectedHazardType,
      description: _descriptionController.text.trim().isEmpty
          ? 'Notice of hazardous condition reported by citizen.'
          : _descriptionController.text.trim(),
      severity: _selectedSeverity,
      sampleLocation: _locationController.text.trim(),
      latitude: 18.9300,
      longitude: 72.8330,
      reporterEmail: userEmail,
      isOnline: conn.isOnline,
      isDraft: isDraft,
    );

    // Trigger realistic local notification
    if (isDraft) {
      await notifs.addNotification(
        title: 'Draft Saved Locally',
        message: 'Hazard draft for ${report.hazardType} saved to your offline device storage.',
        type: NotificationType.reportSavedLocally,
        relatedReportId: report.id,
      );
    } else if (conn.isOnline) {
      await notifs.addNotification(
        title: 'Demo Report Submitted to Prototype',
        message: 'Report ${report.id} (${report.hazardType}) submitted to shared responder queue.',
        type: NotificationType.reportSubmitted,
        relatedReportId: report.id,
      );
    } else {
      await notifs.addNotification(
        title: 'Offline Report Queued for Sync',
        message: 'Report ${report.id} saved locally. Marked Pending Sync until network is restored.',
        type: NotificationType.reportSavedLocally,
        relatedReportId: report.id,
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    // Show feedback dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkOceanBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isDraft
                  ? Icons.drafts_outlined
                  : (conn.isOnline ? Icons.check_circle : Icons.offline_pin),
              color: isDraft
                  ? AppColors.mutedText
                  : (conn.isOnline ? AppColors.successGreen : AppColors.warningAmber),
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              isDraft
                  ? 'Draft Saved'
                  : (conn.isOnline ? 'Report Submitted' : 'Offline Report Saved'),
              style: const TextStyle(color: AppColors.white, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isDraft
                  ? 'Report saved as a local draft. You can complete and submit it at any time.'
                  : (conn.isOnline
                      ? 'Demo report ${report.id} has been added to the shared demo report collection and is now visible in the first responder queue.'
                      : 'Saved locally. Marked "Pending Sync". It is kept out of the responder queue until network connectivity is simulated.'),
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.deepOceanNavy,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Text('Report ID: ', style: TextStyle(fontSize: 11, color: AppColors.mutedText)),
                  Text(report.id, style: AppTypography.code.copyWith(fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PrimaryButton(
            label: 'Done',
            height: 40,
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conn = context.watch<ConnectivityProvider>();

    return Scaffold(
      backgroundColor: AppColors.deepOceanNavy,
      appBar: AppBar(
        title: const Text('SUBMIT HAZARD REPORT'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Network Status Alert
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: (conn.isOnline ? AppColors.successGreen : AppColors.warningAmber)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (conn.isOnline ? AppColors.successGreen : AppColors.warningAmber)
                          .withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        conn.isOnline ? Icons.wifi : Icons.wifi_off,
                        color: conn.isOnline ? AppColors.successGreen : AppColors.warningAmber,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          conn.isOnline
                              ? 'Online Mode: Report will sync directly with the responder queue.'
                              : 'Offline Mode: Report will be cached locally and marked Pending Sync.',
                          style: const TextStyle(fontSize: 11, color: AppColors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Hazard Type Selector
                _buildSectionHeader('HAZARD CLASSIFICATION'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.hazardTypes.map((type) {
                    final isSelected = _selectedHazardType == type;
                    return ChoiceChip(
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) setState(() => _selectedHazardType = type);
                      },
                      label: Text(
                        type,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.white : AppColors.lightMutedText,
                        ),
                      ),
                      selectedColor: AppColors.teal,
                      backgroundColor: AppColors.darkOceanBlue,
                      side: BorderSide(color: isSelected ? AppColors.icyBlue : AppColors.borderNavy),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Severity Level Selector
                _buildSectionHeader('ESTIMATED SEVERITY'),
                const SizedBox(height: 8),
                Row(
                  children: AppConstants.severityLevels.map((sev) {
                    final isSelected = _selectedSeverity == sev;
                    final color = Formatters.getSeverityColor(sev);
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedSeverity = sev),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? color.withOpacity(0.25) : AppColors.darkOceanBlue,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? color : AppColors.borderNavy,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                sev,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? AppColors.white : AppColors.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Hazard Description
                _buildSectionHeader('HAZARD DETAILS & IMPACT'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  style: const TextStyle(color: AppColors.white),
                  decoration: const InputDecoration(
                    hintText:
                        'Describe observed conditions, estimated water depth, structural damages, or vehicle passage hazards...',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please provide a brief description of the hazard';
                    }
                    if (v.trim().length < 8) {
                      return 'Description must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Location / GPS Field with Presets
                _buildSectionHeader('SAMPLE LOCATION / GPS COORDINATES'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _locationController,
                  style: const TextStyle(color: AppColors.white),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.icyBlue),
                    hintText: 'Enter hazard location',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Location is required' : null,
                ),
                const SizedBox(height: 8),
                // Quick Presets
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _samplePresets.map((preset) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          backgroundColor: AppColors.darkOceanBlue,
                          side: const BorderSide(color: AppColors.borderNavy),
                          label: Text(
                            preset.split(',').first,
                            style: const TextStyle(fontSize: 10, color: AppColors.icyBlue),
                          ),
                          onPressed: () => setState(() => _locationController.text = preset),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // Optional Photo Placeholder
                _buildSectionHeader('OPTIONAL PHOTO ATTACHMENT'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    setState(() => _hasPhotoPlaceholder = !_hasPhotoPlaceholder);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: AppColors.darkOceanBlue,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _hasPhotoPlaceholder ? AppColors.teal : AppColors.borderNavy,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _hasPhotoPlaceholder ? Icons.image : Icons.add_a_photo_outlined,
                          size: 32,
                          color: _hasPhotoPlaceholder ? AppColors.icyBlue : AppColors.mutedText,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _hasPhotoPlaceholder
                              ? 'Hazard_Snapshot_Sector3.jpg (Demo Attachment Added)'
                              : 'Tap to attach simulated photo verification',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _hasPhotoPlaceholder ? FontWeight.bold : FontWeight.normal,
                            color: _hasPhotoPlaceholder ? AppColors.icyBlue : AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Submit & Save Draft Action Buttons
                PrimaryButton(
                  label: conn.isOnline ? 'Submit Report (Online)' : 'Save Report (Offline)',
                  icon: Icons.send_outlined,
                  isLoading: _isSubmitting,
                  onPressed: () => _submitReport(isDraft: false),
                ),
                const SizedBox(height: 10),

                PrimaryButton(
                  label: 'Save as Local Draft',
                  icon: Icons.save_alt_outlined,
                  variant: ButtonVariant.secondary,
                  onPressed: () => _submitReport(isDraft: true),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
        color: AppColors.icyBlue,
      ),
    );
  }
}
