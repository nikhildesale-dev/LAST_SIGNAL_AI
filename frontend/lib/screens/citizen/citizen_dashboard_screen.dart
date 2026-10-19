import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/animations/page_transitions.dart';
import '../../core/animations/pulsing_widget.dart';
import '../../models/emergency_location.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/emergency_pack_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/theme_provider.dart';
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
  RiskEstimate? _riskEstimate;
  bool _isLoadingRisk = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRiskData();
    });
  }

  Future<void> _loadRiskData() async {
    if (!mounted) return;
    setState(() => _isLoadingRisk = true);
    final conn = context.read<ConnectivityProvider>();
    final riskService = RiskService(conn.apiService);
    final estimate = await riskService.getAreaRiskEstimate();
    if (mounted) {
      setState(() {
        _riskEstimate = estimate;
        _isLoadingRisk = false;
      });
    }
  }

  void _showRiskFactorsModal(BuildContext context, RiskEstimate estimate) {
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
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.analytics_outlined, color: AppColors.icyBlue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'AI RISK FACTORS BREAKDOWN',
                          style: AppTypography.titleMedium.copyWith(color: AppColors.icyBlue),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.mutedText),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: estimate.isLiveAi ? AppColors.teal : AppColors.surfaceCardDark,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: estimate.isLiveAi ? AppColors.icyBlue : AppColors.borderNavy),
                  ),
                  child: Text(
                    estimate.isLiveAi ? 'LIVE BACKEND PREDICTION' : 'LOCAL OFFLINE HEURISTIC (DEMO)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: estimate.isLiveAi ? AppColors.white : AppColors.lightMutedText,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'CONTRIBUTING ENVIRONMENTAL FACTORS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppColors.lightMutedText,
                  ),
                ),
                const SizedBox(height: 10),
                ...estimate.contributingFactors.map((factor) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.deepOceanNavy,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderNavy),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              factor.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: factor.status.contains('Critical')
                                    ? AppColors.emergencyRed.withOpacity(0.2)
                                    : AppColors.warningAmber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                factor.status,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: factor.status.contains('Critical')
                                      ? AppColors.emergencyRed
                                      : AppColors.warningAmber,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: factor.weight,
                            backgroundColor: AppColors.darkOceanBlue,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              factor.status.contains('Critical') ? AppColors.emergencyRed : AppColors.icyBlue,
                            ),
                            minHeight: 5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(factor.details, style: AppTypography.bodySmall),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 14),
                const Text(
                  'ACTIONABLE SAFETY DIRECTIVES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppColors.lightMutedText,
                  ),
                ),
                const SizedBox(height: 8),
                ...estimate.recommendedActions.map((action) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, color: AppColors.teal, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(action, style: const TextStyle(fontSize: 12, color: AppColors.white)),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Dismiss',
                  height: 42,
                  onPressed: () => Navigator.pop(ctx),
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
    final conn = context.watch<ConnectivityProvider>();
    final reports = context.watch<ReportProvider>();
    final pack = context.watch<EmergencyPackProvider>();
    final notifs = context.watch<NotificationProvider>();
    final theme = context.watch<ThemeProvider>();

    final userReports = reports.getCitizenReports(user?.email ?? AppConstants.demoCitizenEmail);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const AppLogo(size: 34, showText: true),
        actions: [
          // Theme Toggle Button (Dark / Light)
          IconButton(
            tooltip: theme.isDarkMode ? 'Switch to Light Theme' : 'Switch to Dark Theme',
            icon: Icon(
              theme.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: AppColors.icyBlue,
            ),
            onPressed: () => theme.toggleTheme(),
          ),

          // Connectivity Indicator in header
          const ConnectivityIndicator(compact: true),
          const SizedBox(width: 4),

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
                // 1. TACTICAL EMERGENCY ADVISORY & STATUS BANNER
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B2525), Color(0xFF5A1414)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.emergencyRed),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.emergencyRed.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      PulsingWidget(
                        pulseColor: AppColors.emergencyRed,
                        duration: const Duration(milliseconds: 900),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: const BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TACTICAL ADVISORY: CYCLONE & SURGE WATCH',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.6,
                              ),
                            ),
                            Text(
                              'Elevated inundation warning across Sector 3 maritime roads. Prepare evacuation essentials.',
                              style: TextStyle(fontSize: 10, color: Color(0xFFF3D2D2)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            FadeSlidePageRoute(page: const EmergencyModeScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'SOS MODE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF8B2525),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Greeting & Location
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${user?.name ?? "Citizen"}',
                          style: AppTypography.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        const Row(
                          children: [
                            Icon(Icons.location_on, size: 13, color: AppColors.icyBlue),
                            SizedBox(width: 4),
                            Text(
                              'Sector 3 • Coastal Maritime Zone (Demo)',
                              style: TextStyle(fontSize: 11, color: AppColors.lightMutedText),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.darkOceanBlue,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderNavy),
                      ),
                      child: Text(
                        'DEMO ENVIRONMENT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.icyBlue.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 2. FEATURED RISK CARD (AI ESTIMATE & EXPLANATION)
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _riskEstimate?.isLiveAi == true
                                  ? AppColors.teal.withOpacity(0.3)
                                  : AppColors.deepOceanNavy,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _riskEstimate?.isLiveAi == true
                                    ? AppColors.icyBlue
                                    : AppColors.borderNavy,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 6,
                                  color: _riskEstimate?.isLiveAi == true
                                      ? AppColors.successGreen
                                      : AppColors.icyBlue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _riskEstimate?.isLiveAi == true
                                      ? 'LIVE BACKEND AI'
                                      : 'OFFLINE HEURISTIC (DEMO)',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: _riskEstimate?.isLiveAi == true
                                        ? AppColors.white
                                        : AppColors.lightMutedText,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      if (_isLoadingRisk)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Column(
                              children: [
                                SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.icyBlue),
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Synthesizing multi-factor predictive telemetry...',
                                  style: TextStyle(fontSize: 11, color: AppColors.lightMutedText),
                                ),
                              ],
                            ),
                          ),
                        )
                      else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            RiskGauge(
                              targetScore: _riskEstimate?.score ?? 68,
                              category: _riskEstimate?.category ?? 'High',
                              size: 134,
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
                                  Row(
                                    children: [
                                      const Icon(Icons.hub_outlined, size: 12, color: AppColors.icyBlue),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Model: ${_riskEstimate?.modelVersion ?? "v2.4-flood"}',
                                          style: AppTypography.code.copyWith(fontSize: 10),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Source: ${_riskEstimate?.dataSource ?? "Simulated Doppler Index"}',
                                    style: const TextStyle(fontSize: 9, color: AppColors.mutedText),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () {
                            if (_riskEstimate != null) {
                              _showRiskFactorsModal(context, _riskEstimate!);
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.deepOceanNavy,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.borderNavy),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.tune, color: AppColors.icyBlue, size: 14),
                                    SizedBox(width: 6),
                                    Text(
                                      'View 4 Risk Factors & Directives',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.icyBlue),
                                    ),
                                  ],
                                ),
                                Icon(Icons.chevron_right, size: 16, color: AppColors.icyBlue),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 3. CONNECTIVITY & LOCAL OFFLINE QUEUE CARD
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    children: [
                      Row(
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
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                  ),
                                ),
                                Text(
                                  reports.pendingSyncCount > 0
                                      ? '${reports.pendingSyncCount} report(s) in local offline queue'
                                      : 'Local storage synchronized',
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (reports.pendingSyncCount > 0)
                            PrimaryButton(
                              label: 'Sync Now',
                              width: 82,
                              height: 32,
                              onPressed: () async {
                                await conn.simulateReconnection(onReconnected: () async {
                                  final count = await reports.syncPendingReports();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('$count pending reports synchronized to shared queue!'),
                                        backgroundColor: AppColors.teal,
                                      ),
                                    );
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Network Quick Simulator Chips
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Simulate Link:',
                            style: TextStyle(fontSize: 10, color: AppColors.mutedText),
                          ),
                          Wrap(
                            spacing: 6,
                            children: [
                              _buildConnChip('Online', conn.isOnline, () => conn.simulateOnline()),
                              _buildConnChip('Weak', conn.isWeak, () => conn.simulateWeak()),
                              _buildConnChip('Offline', conn.isOffline, () => conn.simulateOffline()),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 4. CRITICAL ACTIONS GRID
                const Text(
                  'CRITICAL RESPONSE ACTIONS',
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
                        label: 'Emergency Map',
                        badgeText: null,
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
                        badgeText: reports.pendingSyncCount > 0 ? '${reports.pendingSyncCount}' : null,
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
                        icon: Icons.backpack_outlined,
                        label: 'Offline Pack',
                        badgeText: '${pack.completedChecklistCount}/${pack.totalChecklistCount}',
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
                        label: 'P2P Mesh',
                        badgeText: 'BLE',
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

                // 5. RECOMMENDED SAFE EVACUATION CORRIDOR
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'RECOMMENDED EVACUATION CORRIDOR',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: AppColors.lightMutedText,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'SAFEST ROUTE',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.successGreen),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppCard(
                  onTap: () {
                    final defaultDest = pack.savedLocations.isNotEmpty ? pack.savedLocations.first : null;
                    Navigator.push(
                      context,
                      FadeSlidePageRoute(page: InteractiveMapScreen(initialDestination: defaultDest)),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.teal.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.alt_route, color: AppColors.icyBlue, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pack.savedLocations.isNotEmpty
                                      ? pack.savedLocations.first.name
                                      : 'Sector 3 Central Safe Staging Area',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                                ),
                                const Text(
                                  'Distance: 2.8 km • ETA: 14 mins convoy / 42 mins walking',
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.icyBlue),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.deepOceanNavy,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.shield_outlined, size: 14, color: AppColors.successGreen),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Hazard avoidance active: route diverts via High Ridge Flyover avoiding 4th Ave inundation.',
                                style: TextStyle(fontSize: 10, color: AppColors.lightMutedText),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 6. NEARBY HOSPITALS AND SHELTERS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'NEARBY HOSPITALS & SHELTERS',
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
                      child: const Text('View All on Map', style: TextStyle(fontSize: 12, color: AppColors.icyBlue)),
                    ),
                  ],
                ),
                SizedBox(
                  height: 146,
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

                // 7. EMERGENCY CONTACTS DIRECT ACCESS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'EMERGENCY DIRECT DIAL (OFFLINE READY)',
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
                          FadeSlidePageRoute(page: const EmergencyPackScreen()),
                        );
                      },
                      child: const Text('Manage', style: TextStyle(fontSize: 12, color: AppColors.icyBlue)),
                    ),
                  ],
                ),
                AppCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      _buildEmergencyContactRow(
                        name: 'National Emergency Dispatch',
                        number: '112',
                        role: 'Police / Fire / Maritime Rescue',
                        icon: Icons.local_police_outlined,
                        color: AppColors.emergencyRed,
                      ),
                      const Divider(height: 16),
                      _buildEmergencyContactRow(
                        name: 'Disaster Relief Helpline',
                        number: '1077',
                        role: 'Civil Defense & Evacuation Hub',
                        icon: Icons.shield_outlined,
                        color: AppColors.warningAmber,
                      ),
                      const Divider(height: 16),
                      _buildEmergencyContactRow(
                        name: 'Emergency Medical Service',
                        number: '108',
                        role: 'Critical Ambulance & Triage',
                        icon: Icons.local_hospital_outlined,
                        color: AppColors.icyBlue,
                      ),
                      if (pack.contacts.isNotEmpty) ...[
                        const Divider(height: 16),
                        _buildEmergencyContactRow(
                          name: pack.contacts.first.name,
                          number: pack.contacts.first.phone,
                          role: 'Personal ICE: ${pack.contacts.first.relationship}',
                          icon: Icons.person_pin_outlined,
                          color: AppColors.teal,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 8. EMERGENCY PREPAREDNESS PACK STATUS
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
                              Icon(Icons.inventory_2_outlined, color: AppColors.icyBlue, size: 18),
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
                                'Open Checklist',
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

                // 9. RECENT HAZARD ACTIVITY & MY REPORTS
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
                  const AppCard(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline, size: 32, color: AppColors.successGreen),
                          SizedBox(height: 6),
                          Text('No Active Reports Filed', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(height: 2),
                          Text('Report local road blockages or flooding to assist first responders.', style: AppTypography.bodySmall, textAlign: TextAlign.center),
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

  Widget _buildConnChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.teal : AppColors.deepOceanNavy,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? AppColors.icyBlue : AppColors.borderNavy),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.mutedText,
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required String? badgeText,
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
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (badgeText != null)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.emergencyRed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
              ],
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
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          FadeSlidePageRoute(page: InteractiveMapScreen(initialDestination: loc)),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                const Row(
                  children: [
                    Text('Route', style: TextStyle(fontSize: 10, color: AppColors.icyBlue, fontWeight: FontWeight.bold)),
                    Icon(Icons.chevron_right, size: 12, color: AppColors.icyBlue),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactRow({
    required String name,
    required String number,
    required String role,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(role, style: const TextStyle(fontSize: 10, color: AppColors.mutedText)),
            ],
          ),
        ),
        InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: number));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$name number ($number) copied to clipboard!'),
                backgroundColor: AppColors.teal,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.deepOceanNavy,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.borderNavy),
            ),
            child: Row(
              children: [
                const Icon(Icons.phone, size: 12, color: AppColors.icyBlue),
                const SizedBox(width: 4),
                Text(
                  number,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.icyBlue),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
