import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/animations/page_transitions.dart';
import '../../models/notification_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/primary_button.dart';
import '../reports/my_reports_screen.dart';

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
  bool _isLocatingGps = false;
  bool _gpsPermissionGranted = true;
  double _currentLat = 18.9300;
  double _currentLon = 72.8330;
  final DateTime _reportTimestamp = DateTime.now();

  final List<Map<String, dynamic>> _samplePresets = [
    {
      'label': '4th Ave Underpass',
      'address': '4th Avenue Underpass & Shoreline Rd',
      'lat': 18.9300,
      'lon': 72.8330,
    },
    {
      'label': 'Hillview Drive',
      'address': 'Hillview Drive, Near Mile Marker 4',
      'lat': 18.9380,
      'lon': 72.8290,
    },
    {
      'label': 'Pier 12 Junction',
      'address': 'Coastal Highway, Pier 12 Junction',
      'lat': 18.9240,
      'lon': 72.8390,
    },
    {
      'label': 'Sector 3 Civic Plaza',
      'address': 'Sector 3 Civic Plaza & Ring Rd',
      'lat': 18.9320,
      'lon': 72.8350,
    },
  ];

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _acquireGpsLocation() async {
    setState(() => _isLocatingGps = true);
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    if (_gpsPermissionGranted) {
      setState(() {
        _isLocatingGps = false;
        _currentLat = 18.9320;
        _currentLon = 72.8350;
        _locationController.text =
            'GPS Fix: 18.9320° N, 72.8350° E (Sector 3 Civic Corridor)';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS coordinates acquired successfully.'),
          backgroundColor: AppColors.teal,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      setState(() => _isLocatingGps = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Location permission denied. Please enter address manually.'),
          backgroundColor: AppColors.emergencyRed,
          action: SnackBarAction(
            label: 'Grant',
            textColor: Colors.white,
            onPressed: () => setState(() => _gpsPermissionGranted = true),
          ),
        ),
      );
    }
  }

  IconData _getHazardIcon(String type) {
    switch (type.toLowerCase()) {
      case 'flood':
        return Icons.water_drop;
      case 'fire':
        return Icons.local_fire_department;
      case 'earthquake':
        return Icons.vibration;
      case 'landslide':
        return Icons.landslide;
      case 'blocked road':
        return Icons.block;
      case 'damaged infrastructure':
        return Icons.foundation;
      default:
        return Icons.warning_amber_rounded;
    }
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
      latitude: _currentLat,
      longitude: _currentLon,
      reporterEmail: userEmail,
      isOnline: conn.isOnline,
      isDraft: isDraft,
    );

    // Trigger realistic notification
    if (isDraft) {
      await notifs.addNotification(
        title: 'Draft Saved Locally',
        message: 'Hazard draft for ${report.hazardType} saved to your offline device storage.',
        type: NotificationType.reportSavedLocally,
        relatedReportId: report.id,
      );
    } else if (conn.isOnline) {
      await notifs.addNotification(
        title: 'Report Submitted (Online)',
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
                      ? 'Report ${report.id} has been transmitted to the emergency network and is visible to responders in the triage queue.'
                      : 'Network unavailable. Report ${report.id} is stored in your offline queue with status "Pending Sync". It will automatically synchronize when connectivity is restored.'),
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.deepOceanNavy,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderNavy),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Report ID:', style: TextStyle(fontSize: 11, color: AppColors.mutedText)),
                      Text(report.id, style: AppTypography.code.copyWith(fontSize: 11, color: AppColors.icyBlue)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Status:', style: TextStyle(fontSize: 11, color: AppColors.mutedText)),
                      Text(report.status, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.white)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Timestamp:', style: TextStyle(fontSize: 11, color: AppColors.mutedText)),
                      Text(DateFormat('MMM dd, HH:mm').format(report.timestamp), style: const TextStyle(fontSize: 10, color: AppColors.lightMutedText)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                FadeSlidePageRoute(page: const MyReportsScreen()),
              );
            },
            child: const Text('View All Reports', style: TextStyle(color: AppColors.icyBlue)),
          ),
          PrimaryButton(
            label: 'Done',
            height: 38,
            width: 80,
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
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.list_alt, size: 16, color: AppColors.icyBlue),
            label: const Text('My Reports', style: TextStyle(fontSize: 12, color: AppColors.icyBlue)),
            onPressed: () {
              Navigator.push(
                context,
                FadeSlidePageRoute(page: const MyReportsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Network Status & Offline Queue Notice Banner
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
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          conn.isOnline
                              ? 'Online Mode: Report transmits directly to the first responder triage queue.'
                              : 'Offline Mode: Report will be securely saved locally and marked Pending Sync.',
                          style: const TextStyle(fontSize: 11, color: AppColors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Report Timestamp
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader('REPORT TIMESTAMP'),
                    Text(
                      DateFormat('EEE, MMM dd, yyyy • HH:mm:ss').format(_reportTimestamp),
                      style: const TextStyle(fontSize: 10, color: AppColors.lightMutedText),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

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
                      avatar: Icon(
                        _getHazardIcon(type),
                        size: 16,
                        color: isSelected ? Colors.white : AppColors.icyBlue,
                      ),
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

                // Location / GPS Field with Presets & GPS Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader('LOCATION / GPS COORDINATES'),
                    InkWell(
                      onTap: _isLocatingGps ? null : _acquireGpsLocation,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.icyBlue, width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isLocatingGps)
                              const SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.icyBlue),
                              )
                            else
                              const Icon(Icons.my_location, size: 12, color: AppColors.icyBlue),
                            const SizedBox(width: 4),
                            Text(
                              _isLocatingGps ? 'Locating...' : 'Use GPS Fix',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.icyBlue),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _locationController,
                  style: const TextStyle(color: AppColors.white),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.icyBlue),
                    hintText: 'Enter hazard location or address',
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
                            preset['label'] as String,
                            style: const TextStyle(fontSize: 10, color: AppColors.icyBlue),
                          ),
                          onPressed: () {
                            setState(() {
                              _locationController.text = preset['address'] as String;
                              _currentLat = preset['lat'] as double;
                              _currentLon = preset['lon'] as double;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
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
                        'Describe observed conditions, estimated water depth, structural damages, downed power lines, or impassable road sections...',
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

                // Optional Photo Placeholder
                _buildSectionHeader('PHOTO VERIFICATION ATTACHMENT'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    setState(() => _hasPhotoPlaceholder = !_hasPhotoPlaceholder);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
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
                              ? 'Hazard_Verification_Snapshot.jpg (Demo Photo Attached)'
                              : 'Tap to attach simulated on-site photo',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _hasPhotoPlaceholder ? FontWeight.bold : FontWeight.normal,
                            color: _hasPhotoPlaceholder ? AppColors.icyBlue : AppColors.mutedText,
                          ),
                        ),
                        if (_hasPhotoPlaceholder)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text('Tap again to remove attachment', style: TextStyle(fontSize: 10, color: AppColors.mutedText)),
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
