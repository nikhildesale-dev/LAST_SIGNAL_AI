import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../models/emergency_contact.dart';
import '../../models/emergency_location.dart';
import '../../providers/emergency_pack_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/primary_button.dart';

class EmergencyPackScreen extends StatefulWidget {
  const EmergencyPackScreen({super.key});

  @override
  State<EmergencyPackScreen> createState() => _EmergencyPackScreenState();
}

class _EmergencyPackScreenState extends State<EmergencyPackScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _instructionsController = TextEditingController();
  bool _isEditingInstructions = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final pack = context.read<EmergencyPackProvider>();
    _instructionsController.text = pack.emergencyInstructions;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _showAddEditContactDialog([EmergencyContact? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final relCtrl = TextEditingController(text: existing?.relationship ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    bool isPrimary = existing?.isPrimary ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.darkOceanBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.borderNavy),
          ),
          title: Text(
            existing == null ? 'ADD EMERGENCY CONTACT' : 'EDIT CONTACT',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.icyBlue),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: AppColors.white),
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: relCtrl,
                  style: const TextStyle(color: AppColors.white),
                  decoration: const InputDecoration(labelText: 'Relationship (e.g. Spouse, Parent)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppColors.white),
                  decoration: const InputDecoration(labelText: 'Phone Number / Radio Frequency'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  style: const TextStyle(color: AppColors.white),
                  decoration: const InputDecoration(labelText: 'Notes (e.g. Blood type, Evac address)'),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Primary Emergency Contact', style: TextStyle(fontSize: 12, color: AppColors.white)),
                  value: isPrimary,
                  activeColor: AppColors.teal,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setDialogState(() => isPrimary = val ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.mutedText)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                minimumSize: const Size(100, 40),
              ),
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) return;
                final pack = context.read<EmergencyPackProvider>();
                if (existing == null) {
                  pack.addContact(
                    name: nameCtrl.text.trim(),
                    relationship: relCtrl.text.trim().isEmpty ? 'Contact' : relCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    isPrimary: isPrimary,
                    notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                  );
                } else {
                  pack.updateContact(
                    existing.copyWith(
                      name: nameCtrl.text.trim(),
                      relationship: relCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      isPrimary: isPrimary,
                      notes: notesCtrl.text.trim(),
                    ),
                  );
                }
                Navigator.pop(ctx);
              },
              child: const Text('Save Contact'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pack = context.watch<EmergencyPackProvider>();

    return Scaffold(
      backgroundColor: AppColors.deepOceanNavy,
      appBar: AppBar(
        title: const Text('OFFLINE EMERGENCY PACK'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.icyBlue,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.mutedText,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'CONTACTS'),
            Tab(text: 'CHECKLIST'),
            Tab(text: 'DIRECTIVES'),
            Tab(text: 'OFFLINE HUBS'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Persistence Status Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.darkOceanBlue,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.save_outlined, size: 14, color: AppColors.successGreen),
                      SizedBox(width: 6),
                      Text(
                        'Stored Locally in Device Non-Volatile Memory',
                        style: TextStyle(fontSize: 10, color: AppColors.lightMutedText),
                      ),
                    ],
                  ),
                  Text(
                    'Updated: ${Formatters.timeAgo(pack.lastUpdated)}',
                    style: const TextStyle(fontSize: 10, color: AppColors.mutedText),
                  ),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildContactsTab(pack),
                  _buildChecklistTab(pack),
                  _buildDirectivesTab(pack),
                  _buildOfflineHubsTab(pack),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsTab(EmergencyPackProvider pack) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'FAMILY & EMERGENCY DISPATCH',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.icyBlue,
                letterSpacing: 1.0,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppColors.icyBlue, size: 24),
              onPressed: () => _showAddEditContactDialog(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (pack.contacts.isEmpty)
          const AppCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No emergency contacts saved. Tap + to add offline contacts.', style: AppTypography.bodySmall),
              ),
            ),
          )
        else
          ...pack.contacts.map((contact) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (contact.isPrimary ? AppColors.emergencyRed : AppColors.teal).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        contact.isPrimary ? Icons.star : Icons.phone_outlined,
                        color: contact.isPrimary ? AppColors.emergencyRed : AppColors.icyBlue,
                        size: 20,
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
                                contact.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                  fontSize: 14,
                                ),
                              ),
                              if (contact.isPrimary) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.emergencyRed,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'PRIMARY',
                                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            '${contact.relationship} • ${contact.phone}',
                            style: AppTypography.bodySmall,
                          ),
                          if (contact.notes != null)
                            Text(
                              contact.notes!,
                              style: const TextStyle(fontSize: 10, color: AppColors.lightMutedText),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.mutedText, size: 18),
                      onPressed: () => _showAddEditContactDialog(contact),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.emergencyRed, size: 18),
                      onPressed: () async {
                        final confirm = await ConfirmationDialog.show(
                          context: context,
                          title: 'Remove Contact',
                          message: 'Remove ${contact.name} from your offline emergency pack?',
                          confirmLabel: 'Remove',
                          isDestructive: true,
                        );
                        if (confirm == true) {
                          pack.removeContact(contact.id);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildChecklistTab(EmergencyPackProvider pack) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '72-HOUR DISASTER PREPARATION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.icyBlue,
                letterSpacing: 1.0,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${pack.completedChecklistCount}/${pack.totalChecklistCount} PACKED',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.successGreen,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...pack.checklistItems.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              onTap: () => pack.toggleChecklistItem(item.id),
              child: Row(
                children: [
                  Checkbox(
                    value: item.isCompleted,
                    activeColor: AppColors.successGreen,
                    onChanged: (_) => pack.toggleChecklistItem(item.id),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: item.isCompleted ? AppColors.white : AppColors.lightMutedText,
                            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        Text(
                          item.description,
                          style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDirectivesTab(EmergencyPackProvider pack) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'FAMILY EMERGENCY DIRECTIVES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.icyBlue,
                  letterSpacing: 1.0,
                ),
              ),
              TextButton.icon(
                icon: Icon(
                  _isEditingInstructions ? Icons.check : Icons.edit,
                  size: 16,
                  color: AppColors.icyBlue,
                ),
                label: Text(
                  _isEditingInstructions ? 'Save' : 'Edit',
                  style: const TextStyle(color: AppColors.icyBlue),
                ),
                onPressed: () {
                  if (_isEditingInstructions) {
                    pack.updateInstructions(_instructionsController.text);
                  }
                  setState(() => _isEditingInstructions = !_isEditingInstructions);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AppCard(
              padding: const EdgeInsets.all(14),
              child: _isEditingInstructions
                  ? TextField(
                      controller: _instructionsController,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(color: AppColors.white, height: 1.5),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter emergency evacuation instructions, meet points...',
                      ),
                    )
                  : SingleChildScrollView(
                      child: Text(
                        pack.emergencyInstructions,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.white,
                          height: 1.6,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineHubsTab(EmergencyPackProvider pack) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: pack.savedLocations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final loc = pack.savedLocations[index];
        final isHospital = loc.type == LocationType.hospital;

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (isHospital ? AppColors.emergencyRed : AppColors.teal).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isHospital ? 'HOSPITAL' : 'SHELTER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isHospital ? AppColors.emergencyRed : AppColors.icyBlue,
                      ),
                    ),
                  ),
                  Text(
                    '${loc.distanceKm} km away',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.icyBlue),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                loc.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.white),
              ),
              const SizedBox(height: 2),
              Text(loc.sampleAddress, style: AppTypography.bodySmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone, size: 12, color: AppColors.mutedText),
                  const SizedBox(width: 4),
                  Text(loc.contactPhone, style: AppTypography.code.copyWith(fontSize: 11)),
                  const Spacer(),
                  Text(
                    'Capacity: ${loc.occupied}/${loc.capacity}',
                    style: const TextStyle(fontSize: 11, color: AppColors.lightMutedText),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: loc.availableServices.map((srv) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.deepOceanNavy,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      srv,
                      style: const TextStyle(fontSize: 9, color: AppColors.lightMutedText),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
