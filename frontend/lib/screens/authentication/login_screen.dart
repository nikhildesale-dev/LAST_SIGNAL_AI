import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/animations/page_transitions.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/primary_button.dart';
import '../citizen/citizen_dashboard_screen.dart';
import '../responder/responder_dashboard_screen.dart';
import '../administrator/admin_dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final UserRole initialRole;

  const LoginScreen({
    super.key,
    this.initialRole = UserRole.citizen,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late UserRole _selectedRole;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
    _fillDefaultDemoCredentials(_selectedRole);
  }

  void _fillDefaultDemoCredentials(UserRole role) {
    switch (role) {
      case UserRole.citizen:
        _emailController.text = AppConstants.demoCitizenEmail;
        _passwordController.text = AppConstants.demoCitizenPass;
        break;
      case UserRole.responder:
        _emailController.text = AppConstants.demoResponderEmail;
        _passwordController.text = AppConstants.demoResponderPass;
        break;
      case UserRole.admin:
        _emailController.text = AppConstants.demoAdminEmail;
        _passwordController.text = AppConstants.demoAdminPass;
        break;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      email: _emailController.text,
      password: _passwordController.text,
      expectedRole: _selectedRole,
    );

    if (!mounted) return;

    if (success) {
      Widget destination;
      switch (_selectedRole) {
        case UserRole.citizen:
          destination = const CitizenDashboardScreen();
          break;
        case UserRole.responder:
          destination = const ResponderDashboardScreen();
          break;
        case UserRole.admin:
          destination = const AdminDashboardScreen();
          break;
      }

      Navigator.pushAndRemoveUntil(
        context,
        FadeSlidePageRoute(page: destination),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.deepOceanNavy,
      appBar: AppBar(
        title: const Text('PORTAL ACCESS'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: AppLogo(size: 58, showText: true)),
                const SizedBox(height: 24),

                // Role Selector Segment
                Text(
                  'ACCESS LEVEL',
                  style: AppTypography.labelSmall.copyWith(letterSpacing: 1.2),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.darkOceanBlue,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderNavy),
                  ),
                  child: Row(
                    children: [
                      _buildRoleTab(UserRole.citizen, 'Citizen', Icons.person_outline),
                      _buildRoleTab(UserRole.responder, 'Responder', Icons.local_hospital_outlined),
                      _buildRoleTab(UserRole.admin, 'Admin', Icons.admin_panel_settings_outlined),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Email Input
                Text(
                  'REGISTERED EMAIL',
                  style: AppTypography.labelSmall.copyWith(letterSpacing: 1.0),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.white),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.icyBlue, size: 20),
                    hintText: 'Enter your email',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Password Input
                Text(
                  'PASSWORD',
                  style: AppTypography.labelSmall.copyWith(letterSpacing: 1.0),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppColors.white),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.icyBlue, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.mutedText,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    hintText: 'Enter password',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Error Message Display
                if (auth.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.emergencyRed.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.emergencyRed.withOpacity(0.6)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.emergencyRed, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            auth.errorMessage!,
                            style: const TextStyle(fontSize: 12, color: AppColors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Login Button
                PrimaryButton(
                  label: 'Sign In as ${_selectedRole.name.toUpperCase()}',
                  isLoading: auth.isLoading,
                  icon: Icons.login,
                  onPressed: _handleLogin,
                ),
                const SizedBox(height: 20),

                // Demo Credentials Helper Card
                AppCard(
                  padding: const EdgeInsets.all(14),
                  backgroundColor: AppColors.darkOceanBlue.withOpacity(0.7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.key_outlined, size: 16, color: AppColors.warningAmber),
                              SizedBox(width: 6),
                              Text(
                                'DEMO CREDENTIALS QUICK-FILL',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.warningAmber,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 24),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => _fillDefaultDemoCredentials(_selectedRole),
                            child: const Text('Fill Preset', style: TextStyle(fontSize: 11, color: AppColors.icyBlue)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getDemoHintText(_selectedRole),
                        style: AppTypography.code.copyWith(fontSize: 11, color: const Color(0xFFC4D5DF)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Create Account for Citizen
                if (_selectedRole == UserRole.citizen)
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          FadeSlidePageRoute(page: const RegisterScreen()),
                        );
                      },
                      child: const Text(
                        'New Citizen? Register for Emergency Alerts',
                        style: TextStyle(
                          color: AppColors.icyBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Local Hackathon Prototype Session • Real deployment uses FastAPI server auth',
                    style: TextStyle(fontSize: 10, color: AppColors.mutedText),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTab(UserRole role, String title, IconData icon) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRole = role;
            _fillDefaultDemoCredentials(role);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.teal : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? AppColors.white : AppColors.mutedText,
              ),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.white : AppColors.mutedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDemoHintText(UserRole role) {
    switch (role) {
      case UserRole.citizen:
        return 'Email: ${AppConstants.demoCitizenEmail}\nPassword: ${AppConstants.demoCitizenPass}';
      case UserRole.responder:
        return 'Email: ${AppConstants.demoResponderEmail}\nPassword: ${AppConstants.demoResponderPass}\n(Authorized First Responder)';
      case UserRole.admin:
        return 'Email: ${AppConstants.demoAdminEmail}\nPassword: ${AppConstants.demoAdminPass}\n(System Operations & Approvals)';
    }
  }
}
