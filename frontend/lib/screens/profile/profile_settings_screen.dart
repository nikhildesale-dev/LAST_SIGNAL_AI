import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/animations/page_transitions.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/primary_button.dart';
import '../citizen/citizen_dashboard_screen.dart';
import '../responder/responder_dashboard_screen.dart';
import '../administrator/admin_dashboard_screen.dart';
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
  late TextEditingController _backendUrlController;
  bool _isTestingBackend = false;
  String? _backendTestStatus;

  @override
  void initState() {
    super.initState();
    final conn = context.read<ConnectivityProvider>();
    _backendUrlController = TextEditingController(text: conn.backendUrl);
  }

  @override
  void dispose() {
    _backendUrlController.dispose();
    super.dispose();
  }

  Future<void> _testBackendConnection() async {
    setState(() {
      _isTestingBackend = true;
      _backendTestStatus = null;
    });

    final conn = context.read<ConnectivityProvider>();
    await conn.updateBackendUrl(_backendUrlController.text.trim());
    final result = await conn.checkBackend();

    if (mounted) {
      setState(() {
        _isTestingBackend = false;
        _backendTestStatus = result.isHealthy
            ? 'Success: Connected in ${result.pingMs}ms'
            : 'Notice: ${result.message}';
      });
    }
  }

  void _switchRole(UserRole targetRole) async {
    final auth = context.read<AuthProvider>();
    String targetEmail;
    String targetPass;

    switch (targetRole) {
      case UserRole.citizen:
        targetEmail = AppConstants.demoCitizenEmail;
        targetPass = AppConstants.demoCitizenPass;
        break;
      case UserRole.responder:
        targetEmail = AppConstants.demoResponderEmail;
        targetPass = AppConstants.demoResponderPass;
        break;
      case UserRole.admin:
        targetEmail = AppConstants.demoAdminEmail;
        targetPass = AppConstants.demoAdminPass;
        break;
    }

    final success = await auth.login(
      email: targetEmail,
      password: targetPass,
      expectedRole: targetRole,
    );
    if (success && mounted) {
      Widget nextScreen;
      switch (targetRole) {
        case UserRole.citizen:
          nextScreen = const CitizenDashboardScreen();
          break;
        case UserRole.responder:
          nextScreen = const ResponderDashboardScreen();
          break;
        case UserRole.admin:
          nextScreen = const AdminDashboardScreen();
          break;
      }
      Navigator.pushAndRemoveUntil(
        context,
        FadeSlidePageRoute(page: nextScreen),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final conn = context.watch<ConnectivityProvider>();
    final theme = context.watch<ThemeProvider>();
    final user = auth.currentUser;

    return Scaffold(
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
                                user?.name ?? 'Citizen User',
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
                              'ICE Contact: ${user!.emergencyContactName}',
                              style: const TextStyle(fontSize: 11, color: AppColors.lightMutedText),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // THEME & APPEARANCE
              _buildSectionTitle('APPEARANCE & THEME'),
              AppCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          theme.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                          color: AppColors.icyBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              theme.isDarkMode ? 'Deep Ocean Dark Theme' : 'Coastal Daylight Light Theme',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const Text(
                              'Optimized for low-light emergencies or bright daylight',
                              style: TextStyle(fontSize: 10, color: AppColors.lightMutedText),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: theme.isDarkMode,
                      activeColor: AppColors.teal,
                      onChanged: (_) => theme.toggleTheme(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // BACKEND & AI MODEL INTEGRATION
              _buildSectionTitle('BACKEND & AI MODEL INTEGRATION'),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'REST API Base URL',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: conn.isOnline ? AppColors.successGreen.withOpacity(0.2) : AppColors.warningAmber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            conn.isOnline ? 'ONLINE' : 'DEMO MODE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: conn.isOnline ? AppColors.successGreen : AppColors.warningAmber,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _backendUrlController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'e.g. http://localhost:8000 or http://10.0.2.2:8000',
                        prefixIcon: Icon(Icons.link, color: AppColors.icyBlue, size: 18),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            label: _isTestingBackend ? 'Testing Link...' : 'Save & Test Backend',
                            height: 38,
                            isLoading: _isTestingBackend,
                            onPressed: _testBackendConnection,
                          ),
                        ),
                      ],
                    ),
                    if (_backendTestStatus != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.deepOceanNavy,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _backendTestStatus!.contains('Success') ? Icons.check_circle : Icons.info_outline,
                              size: 14,
                              color: _backendTestStatus!.contains('Success') ? AppColors.successGreen : AppColors.warningAmber,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _backendTestStatus!,
                                style: const TextStyle(fontSize: 11, color: AppColors.lightMutedText),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ROLE SWITCHER (FOR HACKATHON EVALUATION)
              _buildSectionTitle('SWITCH USER ROLE (DEMO & EVALUATION)'),
              AppCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _buildRoleOption(
                      role: UserRole.citizen,
                      title: 'Citizen Dashboard',
                      subtitle: 'Hazard reporting, AI risk gauge, offline pack, emergency map',
                      isSelected: auth.currentRole == UserRole.citizen,
                      onTap: () => _switchRole(UserRole.citizen),
                    ),
                    const Divider(height: 12),
                    _buildRoleOption(
                      role: UserRole.responder,
                      title: 'First Responder Console',
                      subtitle: 'Incident triage queue, field verification notes, status updates',
                      isSelected: auth.currentRole == UserRole.responder,
                      onTap: () => _switchRole(UserRole.responder),
                    ),
                    const Divider(height: 12),
                    _buildRoleOption(
                      role: UserRole.admin,
                      title: 'System Administrator',
                      subtitle: 'Telemetry audit, responder access authorizations, system metrics',
                      isSelected: auth.currentRole == UserRole.admin,
                      onTap: () => _switchRole(UserRole.admin),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // EMERGENCY & OFFLINE PREFERENCES
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
                      subtitle: const Text('Allows phone to hop emergency packets when cellular is down', style: TextStyle(fontSize: 11, color: AppColors.mutedText)),
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

              // Device Permissions Audit
              _buildSectionTitle('HARDWARE & OFFLINE CAPABILITIES'),
              AppCard(
                child: Column(
                  children: [
                    _buildPermRow('GPS Geolocation', 'Simulated Sector 3 Fixed Anchor', AppColors.icyBlue),
                    const Divider(height: 16),
                    _buildPermRow('Bluetooth LE Advertising', 'Simulated Store-and-Forward Mesh', AppColors.teal),
                    const Divider(height: 16),
                    _buildPermRow('Local Secure Persistence', 'Active (Device SharedPreferences)', AppColors.successGreen),
                    const Divider(height: 16),
                    _buildPermRow('AI Inference Engine', 'Hybrid (Live REST API + Offline Heuristics)', AppColors.warningAmber),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Logout Button
              PrimaryButton(
                label: 'Sign Out & Return to Welcome',
                variant: ButtonVariant.emergency,
                icon: Icons.logout,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => ConfirmationDialog(
                      title: 'CONFIRM SIGN OUT',
                      message: 'Are you sure you want to end your current session?',
                      confirmLabel: 'Sign Out',
                      isDestructive: true,
                      onConfirm: () async {
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
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleOption({
    required UserRole role,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.icyBlue : AppColors.mutedText,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.lightMutedText,
                    ),
                  ),
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.mutedText)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
          color: AppColors.icyBlue,
        ),
      ),
    );
  }

  Widget _buildPermRow(String title, String status, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
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
