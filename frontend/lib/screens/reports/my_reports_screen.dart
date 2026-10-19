import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/animations/page_transitions.dart';
import '../../models/hazard_report.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import '../reporting/hazard_report_screen.dart';
import 'report_detail_screen.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = [
    'All',
    'Pending Sync',
    'Submitted',
    'Under Review',
    'Verified',
    'Rejected',
    'Resolved',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reports = context.watch<ReportProvider>();
    final auth = context.watch<AuthProvider>();
    final userEmail = auth.currentUser?.email ?? AppConstants.demoCitizenEmail;

    final myReports = reports.getCitizenReports(userEmail);

    // Apply filter
    final filtered = myReports.where((r) {
      if (_selectedFilter != 'All' && r.status != _selectedFilter) {
        return false;
      }
      final query = _searchController.text.trim().toLowerCase();
      if (query.isNotEmpty) {
        final matchesId = r.id.toLowerCase().contains(query);
        final matchesType = r.hazardType.toLowerCase().contains(query);
        final matchesLoc = r.sampleLocation.toLowerCase().contains(query);
        final matchesDesc = r.description.toLowerCase().contains(query);
        return matchesId || matchesType || matchesLoc || matchesDesc;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.deepOceanNavy,
      appBar: AppBar(
        title: const Text('HAZARD REPORT HISTORY'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.icyBlue),
            onPressed: () {
              Navigator.push(
                context,
                FadeSlidePageRoute(page: const HazardReportScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.white),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: AppColors.mutedText),
                  hintText: 'Search by report ID, hazard type, or location...',
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.mutedText, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
            ),

            // Status Filter Chips
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;
                  return ChoiceChip(
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedFilter = filter);
                    },
                    label: Text(
                      filter,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.white : AppColors.lightMutedText,
                      ),
                    ),
                    selectedColor: AppColors.teal,
                    backgroundColor: AppColors.darkOceanBlue,
                    side: BorderSide(color: isSelected ? AppColors.icyBlue : AppColors.borderNavy),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Reports List
            Expanded(
              child: filtered.isEmpty
                  ? EmptyState(
                      icon: Icons.assignment_late_outlined,
                      title: 'No Reports Found',
                      message: _searchController.text.isNotEmpty || _selectedFilter != 'All'
                          ? 'No hazard reports match your current search or filter criteria.'
                          : 'You have not submitted any hazard reports yet.',
                      actionLabel: 'Submit a Report',
                      onAction: () {
                        Navigator.push(
                          context,
                          FadeSlidePageRoute(page: const HazardReportScreen()),
                        );
                      },
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final report = filtered[index];
                        return _buildReportCard(report);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(HazardReport report) {
    return AppCard(
      onTap: () {
        Navigator.push(
          context,
          FadeSlidePageRoute(page: ReportDetailScreen(report: report)),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    report.id,
                    style: AppTypography.code.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(label: report.severity, isSeverity: true),
                ],
              ),
              StatusBadge(label: report.status, isSeverity: false),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            report.hazardType,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.white),
          ),
          const SizedBox(height: 2),
          Text(
            report.description,
            style: AppTypography.bodySmall.copyWith(color: const Color(0xFFD0DFE7)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 13, color: AppColors.icyBlue),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  report.sampleLocation,
                  style: const TextStyle(fontSize: 11, color: AppColors.lightMutedText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                Formatters.timeAgo(report.timestamp),
                style: const TextStyle(fontSize: 10, color: AppColors.mutedText),
              ),
            ],
          ),
          if (report.responderNotes != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.deepOceanNavy,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.comment_outlined, size: 12, color: AppColors.icyBlue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Responder: ${report.responderNotes}',
                      style: const TextStyle(fontSize: 10, color: AppColors.lightMutedText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
