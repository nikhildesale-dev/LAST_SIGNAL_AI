import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/animations/page_transitions.dart';
import '../../models/app_user.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/primary_button.dart';
import '../authentication/login_screen.dart';
import '../authentication/register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        showGrid: true,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Brand Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const AppLogo(size: 44, showText: true),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.teal, width: 0.8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.shield_outlined, size: 14, color: AppColors.icyBlue),
                          SizedBox(width: 4),
                          Text(
                            'HACKATHON BUILD',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.icyBlue,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Welcome Headline
                AnimatedEntrance(
                  index: 1,
                  child: Text(
                    AppConstants.welcomeHeadline,
                    style: AppTypography.displayLarge.copyWith(
                      color: AppColors.white,
                      fontSize: 26,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Supporting Text
                AnimatedEntrance(
                  index: 2,
                  child: Text(
                    AppConstants.welcomeSubheadline,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.lightMutedText,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Three Featured Capabilities
                AnimatedEntrance(
                  index: 3,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildFeatureCard(
                          icon: Icons.radar,
                          title: 'Predict Risk',
                          subtitle: 'AI flood & storm modeling',
                          color: AppColors.icyBlue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildFeatureCard(
                          icon: Icons.alt_route,
                          title: 'Navigate Safe',
                          subtitle: 'Hazard-avoiding routes',
                          color: AppColors.warningAmber,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildFeatureCard(
                          icon: Icons.bluetooth_searching,
                          title: 'Offline P2P',
                          subtitle: 'Device mesh exchange',
                          color: AppColors.successGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // System Interaction Explanation Card
                AnimatedEntrance(
                  index: 4,
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: AppColors.darkOceanBlue.withOpacity(0.8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.hub_outlined, color: AppColors.icyBlue, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'HOW THE SYSTEM CONNECTS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.icyBlue,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Citizens detect hazards and submit local reports (saved offline if towers fail).\n'
                          '• Bluetooth P2P Relay hops data across neighbor phones without cell towers.\n'
                          '• Emergency Responders verify reports, adjust route safety, and direct relief.',
                          style: AppTypography.bodySmall.copyWith(
                            color: const Color(0xFFD0DFE7),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Primary Action: Get Started / Citizen Portal
                AnimatedEntrance(
                  index: 5,
                  child: PrimaryButton(
                    label: 'Get Started (Citizen Access)',
                    icon: Icons.arrow_forward,
                    onPressed: () {
                      Navigator.push(
                        context,
                        FadeSlidePageRoute(
                          page: const LoginScreen(initialRole: UserRole.citizen),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Secondary Actions: Responder & Admin Entry Points
                AnimatedEntrance(
                  index: 6,
                  child: Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: 'Responder Portal',
                          icon: Icons.local_hospital_outlined,
                          variant: ButtonVariant.secondary,
                          height: 46,
                          onPressed: () {
                            Navigator.push(
                              context,
                              FadeSlidePageRoute(
                                page: const LoginScreen(initialRole: UserRole.responder),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Admin Portal',
                          icon: Icons.admin_panel_settings_outlined,
                          variant: ButtonVariant.secondary,
                          height: 46,
                          onPressed: () {
                            Navigator.push(
                              context,
                              FadeSlidePageRoute(
                                page: const LoginScreen(initialRole: UserRole.admin),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Register New Citizen Link
                AnimatedEntrance(
                  index: 7,
                  child: Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          FadeSlidePageRoute(page: const RegisterScreen()),
                        );
                      },
                      child: RichText(
                        text: const TextSpan(
                          text: "Don't have an account? ",
                          style: AppTypography.bodySmall,
                          children: [
                            TextSpan(
                              text: 'Create Citizen Account',
                              style: TextStyle(
                                color: AppColors.icyBlue,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Visible Disclaimer
                AnimatedEntrance(
                  index: 8,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.deepOceanNavy.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderNavy, width: 0.8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: AppColors.warningAmber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppConstants.prototypeDisclaimer,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.mutedText,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.darkOceanBlue,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderNavy),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.lightMutedText,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
