import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/animations/page_transitions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/primary_button.dart';
import '../welcome/welcome_screen.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  bool _alertPush = true;
  bool _p2pMeshRelay = true;
  bool _batterySaver = false;
  bool _offlineAutoSave = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final conn = context.watch<ConnectivityProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.deepOceanNavy,
      appBar: AppBar(
        title: const Text('PROFILE & SYSTEM SETTINGS'),
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
              // User Profile Banner Card
              AppCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.teal,
                      child: Text(
                        user?.name.isNotEmpty == true ? user!.name.substring(0, 1).toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                user?.name ?? 'Maya Lin',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.teal,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  user?.role.name.toUpperCase() ?? 'CITIZEN',
                                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.icyBlue),
                                ),
                              ),
                            ],
                          ),
                          Text(user?.email ?? AppConstants.demoCitizenEmail, style: AppTypography.code.copyWith(fontSize: 11)),
                          if (user?.emergencyContactName != null)
                            Text(
                              'Emergency: ${user!.emergencyContactName}',
                              style: const TextStyle(fontSize: 11, color: AppColors.lightMutedText),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Network Status Simulation
              _buildSectionTitle('COMMUNICATION CONTROLS'),
              AppCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Network Simulation State', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        Text(
                          conn.status.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: conn.isOnline ? AppColors.successGreen : AppColors.warningAmber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(conn.statusLabel, style: AppTypography.bodySmall),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Emergency & Offline Preferences
              _buildSectionTitle('EMERGENCY & OFFLINE PREFERENCES'),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Predictive Storm & Flood Alerts', style: TextStyle(fontSize: 13, color: Colors.white)),
                      subtitle: const Text('AI risk index updates for local sector', style: TextStyle(fontSize: 11, color: AppColors.mutedText)),
                      value: _alertPush,
                      activeColor: AppColors.teal,
                      onChanged: (v) => setState(() => _alertPush = v),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Autonomous P2P Relay Node', style: TextStyle(fontSize: 13, color: Colors.white)),
                      subtitle: const Text('Allows phone to hop emergency packets when towers are dark', style: TextStyle(fontSize: 11, color: AppColors.mutedText)),
                      value: _p2pMeshRelay,
                      activeColor: AppColors.teal,
                      onChanged: (v) => setState(() => _p2pMeshRelay = v),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Auto-Cache Emergency Pack', style: TextStyle(fontSize: 13, color: Colors.white)),
                      subtitle: const Text('Persist hospital contacts and maps locally on restart', style: TextStyle(fontSize: 11, color: AppColors.mutedText)),
                      value: _offlineAutoSave,
                      activeColor: AppColors.teal,
                      onChanged: (v) => setState(() => _offlineAutoSave = v),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Disaster Battery Conservation Mode', style: TextStyle(fontSize: 13, color: Colors.white)),
                      subtitle: const Text('Lowers animation framerates to save battery power', style: TextStyle(fontSize: 11, color: AppColors.mutedText)),
                      value: _batterySaver,
                      activeColor: AppColors.teal,
                      onChanged: (v) => setState(() => _batterySaver = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Device Permissions Status Card
              _buildSectionTitle('HARDWARE PERMISSION AUDIT (PROTOTYPE)'),
              AppCard(
                child: Column(
                  children: [
                    _buildPermRow('GPS Geolocation', 'Simulated (Sector 3 Anchor)', AppColors.icyBlue),
                    const Divider(height: 16),
                    _buildPermRow('Bluetooth LE Advertising', 'Simulated Mesh Relay', AppColors.teal),
                    const Divider(height: 16),
                    _buildPermRow('Local Secure Persistence', 'Active (Device SharedPreferences)', AppColors.successGreen),
                    const Divider(height: 16),
                    _buildPermRow('FastAPI Cloud Backend', 'Simulated In-Memory Contract', AppColors.warningAmber),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Logout Action
              PrimaryButton(
                label: 'Sign Out of Session',
                icon: Icons.logout,
                variant: ButtonVariant.ghost,
                onPressed: () async {
                  final confirm = await ConfirmationDialog.show(
                    context: context,
                    title: 'Sign Out',
                    message: 'Are you sure you want to end your current prototype session?',
                    confirmLabel: 'Sign Out',
                    isDestructive: true,
                  );
                  if (confirm == true) {
                    await auth.logout();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        FadeSlidePageRoute(page: const WelcomeScreen()),
                        (route) => false,
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
          color: AppColors.lightMutedText,
        ),
      ),
    );
  }

  Widget _buildPermRow(String name, String status, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(name, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            status,
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }
}
