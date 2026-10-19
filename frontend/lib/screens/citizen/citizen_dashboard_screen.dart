import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/animations/page_transitions.dart';
import '../../models/emergency_location.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/emergency_pack_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/report_provider.dart';
import '../../services/risk_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/connectivity_indicator.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/risk_gauge.dart';
import '../../widgets/status_badge.dart';
import '../bluetooth/bluetooth_p2p_screen.dart';
import '../emergency_mode/emergency_mode_screen.dart';
import '../emergency_pack/emergency_pack_screen.dart';
import '../map/interactive_map_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_settings_screen.dart';
import '../reporting/hazard_report_screen.dart';
import '../reports/my_reports_screen.dart';
import '../reports/report_detail_screen.dart';

class CitizenDashboardScreen extends StatefulWidget {
  const CitizenDashboardScreen({super.key});

  @override
  State<CitizenDashboardScreen> createState() => _CitizenDashboardScreenState();
}

class _CitizenDashboardScreenState extends State<CitizenDashboardScreen> {
  final RiskService _riskService = RiskService();
  RiskEstimate? _riskEstimate;
  bool _isLoadingRisk = true;

  @override
  void initState() {
    super.initState();
    _loadRiskData();
  }

  Future<void> _loadRiskData() async {
    final estimate = await _riskService.getAreaRiskEstimate();
    if (mounted) {
      setState(() {
        _riskEstimate = estimate;
        _isLoadingRisk = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final conn = context.watch<ConnectivityProvider>();
    final reports = context.watch<ReportProvider>();
    final pack = context.watch<EmergencyPackProvider>();
    final notifs = context.watch<NotificationProvider>();

    final userReports = reports.getCitizenReports(user?.email ?? AppConstants.demoCitizenEmail);

    return Scaffold(
      backgroundColor: AppColors.deepOceanNavy,
      appBar: AppBar(
        titleSpacing: 16,
        title: const AppLogo(size: 34, showText: true),
        actions: [
          // Connectivity Indicator in header
          const ConnectivityIndicator(compact: true),
          const SizedBox(width: 8),

          // Notification Bell with Badge
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppColors.icyBlue),
                onPressed: () {
                  Navigator.push(
                    context,
                    FadeSlidePageRoute(page: const NotificationsScreen()),
                  );
                },
              ),
              if (notifs.unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.emergencyRed,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${notifs.unreadCount}',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),

          // Profile Avatar
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  FadeSlidePageRoute(page: const ProfileSettingsScreen()),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.teal,
                child: Text(
                  user?.name.isNotEmpty == true ? user!.name.substring(0, 1).toUpperCase() : 'C',
                  style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRiskData,
          color: AppColors.icyBlue,
          backgroundColor: AppColors.darkOceanBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Personalized Greeting & Current Location Banner
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${user?.name ?? "Citizen"}',
                          style: AppTypography.titleMedium.copyWith(color: AppColors.white),
                        ),
                        const SizedBox(height: 2),
                        const Row(
                          children: [
                            Icon(Icons.location_on, size: 13, color: AppColors.icyBlue),
                            SizedBox(width: 4),
                            Text(
                              'Sector 3 • Coastal Maritime Zone (Demo)',
                              style: TextStyle(fontSize: 12, color: AppColors.lightMutedText),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // High-Priority Emergency Mode Floating Trigger
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          FadeSlidePageRoute(page: const EmergencyModeScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.emergencyRed,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.emergencyRed.withOpacity(0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'EMERGENCY MODE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // FEATURED RISK CARD (AI ESTIMATE)
                AppCard(
                  padding: const EdgeInsets.all(16),
                  gradient: AppColors.cardGradient,
                  borderColor: AppColors.borderNavy,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_graph_outlined, color: AppColors.icyBlue, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'AI PREDICTIVE DISASTER ESTIMATE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.icyBlue,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.deepOceanNavy,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'SIMULATED MODEL',
                              style: TextStyle(fontSize: 9, color: AppColors.mutedText, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          RiskGauge(
                            targetScore: _riskEstimate?.score ?? 68,
                            category: _riskEstimate?.category ?? 'High',
                            size: 140,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _riskEstimate?.summary ??
                                      'Rising storm surge inundation risk across lower coastal highway.',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: const Color(0xFFD4E2EB),
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Model: ${_riskEstimate?.modelVersion ?? "v2.4-flood"}',
                                  style: AppTypography.code.copyWith(fontSize: 10),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Updated: ${_riskEstimate != null ? Formatters.timeAgo(_riskEstimate!.lastUpdated) : "Just now"}',
                                  style: const TextStyle(fontSize: 10, color: AppColors.mutedText),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // CONNECTIVITY & PENDING SYNC STATUS CARD
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (conn.isOnline ? AppColors.successGreen : AppColors.warningAmber).withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          conn.isOnline ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                          color: conn.isOnline ? AppColors.successGreen : AppColors.warningAmber,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              conn.statusLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                            Text(
                              reports.pendingSyncCount > 0
                                  ? '${reports.pendingSyncCount} report(s) queued for sync'
                                  : 'Emergency database up-to-date',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (reports.pendingSyncCount > 0)
                        PrimaryButton(
                          label: 'Sync',
                          width: 65,
                          height: 32,
                          onPressed: () async {
                            await conn.simulateReconnection(onReconnected: () async {
                              await reports.syncPendingReports();
                            });
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // QUICK ACTION BUTTONS GRID
                const Text(
                  'CRITICAL ACTIONS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppColors.lightMutedText,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionTile(
                        icon: Icons.map_outlined,
                        label: 'Interactive Map',
                        color: AppColors.icyBlue,
                        onTap: () {
                          Navigator.push(
                            context,
                            FadeSlidePageRoute(page: const InteractiveMapScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionTile(
                        icon: Icons.add_alert_outlined,
                        label: 'Report Hazard',
                        color: AppColors.warningAmber,
                        onTap: () {
                          Navigator.push(
                            context,
                            FadeSlidePageRoute(page: const HazardReportScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionTile(
                        icon: Icons.inventory_2_outlined,
                        label: 'Emergency Pack',
                        color: AppColors.teal,
                        onTap: () {
                          Navigator.push(
                            context,
                            FadeSlidePageRoute(page: const EmergencyPackScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionTile(
                        icon: Icons.bluetooth_audio,
                        label: 'P2P Relay',
                        color: AppColors.successGreen,
                        onTap: () {
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

                // EMERGENCY PACK STATUS CARD
                AppCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      FadeSlidePageRoute(page: const EmergencyPackScreen()),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.backpack_outlined, color: AppColors.icyBlue, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'OFFLINE EMERGENCY PACK',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.white,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.successGreen.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${pack.completedChecklistCount}/${pack.totalChecklistCount} PREPARED',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.successGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pack.checklistProgress,
                          backgroundColor: AppColors.deepOceanNavy,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.successGreen),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${pack.contacts.length} Contacts • ${pack.savedLocations.length} Offline Locations',
                            style: AppTypography.bodySmall,
                          ),
                          const Row(
                            children: [
                              Text(
                                'Open Pack',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.icyBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(Icons.chevron_right, size: 16, color: AppColors.icyBlue),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // NEARBY EMERGENCY DESTINATIONS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'NEARBY EMERGENCY DESTINATIONS',
                      style: TextStyle(
                        fontSize: 12,
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
                      child: const Text('View on Map', style: TextStyle(fontSize: 12, color: AppColors.icyBlue)),
                    ),
                  ],
                ),
                SizedBox(
                  height: 140,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: pack.savedLocations.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final loc = pack.savedLocations[index];
                      return _buildLocationCard(loc);
                    },
                  ),
                ),
                const SizedBox(height: 18),

                // RECENT HAZARD ACTIVITY & MY REPORTS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'MY HAZARD REPORTS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: AppColors.lightMutedText,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          FadeSlidePageRoute(page: const MyReportsScreen()),
                        );
                      },
                      child: const Text('All Reports', style: TextStyle(fontSize: 12, color: AppColors.icyBlue)),
                    ),
                  ],
                ),
                if (userReports.isEmpty)
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle_outline, size: 32, color: AppColors.successGreen),
                          const SizedBox(height: 6),
                          const Text('No Active Reports Filed', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 2),
                          const Text('Report local road blockages or flooding to assist first responders.', style: AppTypography.bodySmall, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  )
                else
                  ...userReports.take(2).map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          onTap: () {
                            Navigator.push(
                              context,
                              FadeSlidePageRoute(page: ReportDetailScreen(report: r)),
                            );
                          },
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.deepOceanNavy,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  r.hazardType == 'Flood' ? Icons.water_drop : Icons.warning_amber_rounded,
                                  color: AppColors.warningAmber,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.hazardType,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                                    ),
                                    Text(
                                      r.sampleLocation,
                                      style: AppTypography.bodySmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              StatusBadge(label: r.status),
                            ],
                          ),
                        ),
                      )),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.darkOceanBlue,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderNavy),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(EmergencyLocation loc) {
    final isHospital = loc.type == LocationType.hospital;
    return Container(
      width: 210,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkOceanBlue,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderNavy),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isHospital ? AppColors.emergencyRed : AppColors.teal).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isHospital ? 'HOSPITAL' : 'SHELTER',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: isHospital ? AppColors.emergencyRed : AppColors.icyBlue,
                  ),
                ),
              ),
              Text(
                '${loc.distanceKm} km',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.icyBlue,
                ),
              ),
            ],
          ),
          Text(
            loc.name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            children: [
              const Icon(Icons.people_outline, size: 12, color: AppColors.mutedText),
              const SizedBox(width: 4),
              Text(
                'Cap: ${loc.occupied}/${loc.capacity}',
                style: const TextStyle(fontSize: 10, color: AppColors.mutedText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
