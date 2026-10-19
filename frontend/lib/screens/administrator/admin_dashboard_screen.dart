import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/animations/page_transitions.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/primary_button.dart';
import '../welcome/welcome_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final reports = context.watch<ReportProvider>();
    final users = auth.allUsers;
    final pendingResponders = auth.pendingResponders;

    return Scaffold(
      backgroundColor: AppColors.deepOceanNavy,
      appBar: AppBar(
        title: const Text('ADMINISTRATIVE CONSOLE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.mutedText),
            onPressed: () async {
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
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // System Health & Metric Cards
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.security, color: AppColors.icyBlue, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'SYSTEM TELEMETRY & AUTHORIZATION STATUS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.icyBlue,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('TOTAL USERS', users.length.toString()),
                        _buildStat('PENDING APPS', pendingResponders.length.toString(), color: AppColors.warningAmber),
                        _buildStat('ACTIVE HAZARDS', reports.allReports.length.toString()),
                        _buildStat('P2P RELAYS', '3 NODES', color: AppColors.successGreen),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // FLOW E: PENDING FIRST RESPONDER APPROVALS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'RESPONDER AUTHORIZATION REQUESTS (FLOW E)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: AppColors.warningAmber,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warningAmber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${pendingResponders.length} PENDING',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.warningAmber),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (pendingResponders.isEmpty)
                const AppCard(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'All responder accounts are verified. No pending applications.',
                        style: AppTypography.bodySmall,
                      ),
                    ),
                  ),
                )
              else
                ...pendingResponders.map((applicant) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      borderColor: AppColors.warningAmber,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                applicant.name,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.warningAmber.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'AWAITING APPROVAL',
                                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.warningAmber),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Email: ${applicant.email}',
                            style: AppTypography.code.copyWith(fontSize: 11),
                          ),
                          Text(
                            'Unit: ${applicant.organization ?? "First Responder Field Corps"}',
                            style: AppTypography.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: PrimaryButton(
                                  label: 'Approve Responder',
                                  icon: Icons.check,
                                  height: 36,
                                  onPressed: () async {
                                    await auth.approveResponder(applicant.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Approved ${applicant.name}. Account is now authorized to log in as Responder!',
                                          ),
                                          backgroundColor: AppColors.successGreen,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: PrimaryButton(
                                  label: 'Reject',
                                  icon: Icons.close,
                                  variant: ButtonVariant.ghost,
                                  height: 36,
                                  onPressed: () async {
                                    await auth.rejectResponder(applicant.id);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 20),

              // DEMO USER ACCOUNTS & PRIVILEGE MANAGEMENT
              const Text(
                'ALL REGISTERED DEMO ACCOUNTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: AppColors.lightMutedText,
                ),
              ),
              const SizedBox(height: 8),
              ...users.map((u) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.deepOceanNavy,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            u.role == UserRole.admin
                                ? Icons.admin_panel_settings
                                : (u.role == UserRole.responder ? Icons.shield : Icons.person),
                            size: 18,
                            color: AppColors.icyBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    u.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.deepOceanNavy,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      u.role.name.toUpperCase(),
                                      style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.icyBlue),
                                    ),
                                  ),
                                ],
                              ),
                              Text(u.email, style: AppTypography.code.copyWith(fontSize: 10)),
                            ],
                          ),
                        ),
                        // Enable/Disable Switch (Administrator control)
                        Column(
                          children: [
                            Text(
                              u.isEnabled ? 'ENABLED' : 'DISABLED',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: u.isEnabled ? AppColors.successGreen : AppColors.emergencyRed,
                              ),
                            ),
                            Switch(
                              value: u.isEnabled,
                              activeColor: AppColors.teal,
                              onChanged: (val) async {
                                await auth.toggleAccountStatus(u.id);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 18),

              // Architectural Notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.darkOceanBlue,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderNavy),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ARCHITECTURE NOTE',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.icyBlue),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'This administrator view mutates shared application state within the local prototype. In production deployment, approvals and permissions are securely enforced on the FastAPI backend.',
                      style: TextStyle(fontSize: 10, color: AppColors.mutedText, height: 1.4),
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

  Widget _buildStat(String label, String value, {Color color = AppColors.icyBlue}) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.lightMutedText)),
      ],
    );
  }
}
