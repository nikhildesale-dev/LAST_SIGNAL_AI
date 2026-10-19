import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/animations/page_transitions.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/primary_button.dart';
import '../citizen/citizen_dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.registerCitizen(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      emergencyContactName: _contactNameController.text.isEmpty ? null : _contactNameController.text,
      emergencyContactPhone: _contactPhoneController.text.isEmpty ? null : _contactPhoneController.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful! Offline Emergency Pack initialized.'),
          backgroundColor: AppColors.successGreen,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        FadeSlidePageRoute(page: const CitizenDashboardScreen()),
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
        title: const Text('CITIZEN REGISTRATION'),
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
                const Text(
                  'JOIN EMERGENCY PREPAREDNESS MESH',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.icyBlue,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Create an offline-ready citizen account to receive predictive storm alerts, navigate safe corridors, and share local hazard reports.',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 24),

                // Full Name
                _buildLabel('FULL NAME (REQUIRED)'),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: AppColors.white),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.icyBlue),
                    hintText: 'e.g. Maya Lin',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Full name is required' : null,
                ),
                const SizedBox(height: 16),

                // Email
                _buildLabel('EMAIL ADDRESS (REQUIRED)'),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.white),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.icyBlue),
                    hintText: 'e.g. maya.lin@resident.org',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                _buildLabel('PASSWORD (MIN 6 CHARACTERS)'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppColors.white),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.icyBlue),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.mutedText,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    hintText: 'Create a password',
                  ),
                  validator: (v) => v == null || v.length < 6 ? 'Minimum 6 characters required' : null,
                ),
                const SizedBox(height: 16),

                // Confirm Password
                _buildLabel('CONFIRM PASSWORD'),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  style: const TextStyle(color: AppColors.white),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_reset, color: AppColors.icyBlue),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.mutedText,
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    hintText: 'Repeat password',
                  ),
                  validator: (v) {
                    if (v != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Optional Emergency Contact Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.darkOceanBlue.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderNavy),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.contact_phone_outlined, color: AppColors.icyBlue, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'EMERGENCY CONTACT (OPTIONAL)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: AppColors.icyBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _contactNameController,
                        style: const TextStyle(color: AppColors.white),
                        decoration: const InputDecoration(
                          hintText: 'Contact Name (e.g. David Lin - Spouse)',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _contactPhoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: AppColors.white),
                        decoration: const InputDecoration(
                          hintText: 'Phone Number (e.g. +1 555-019-2834)',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (auth.errorMessage != null) ...[
                  Text(
                    auth.errorMessage!,
                    style: const TextStyle(color: AppColors.emergencyRed, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                ],

                PrimaryButton(
                  label: 'Complete Registration & Enter',
                  icon: Icons.check_circle_outline,
                  isLoading: auth.isLoading,
                  onPressed: _handleRegister,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(letterSpacing: 0.8),
      ),
    );
  }
}
