import '../models/app_user.dart';

class MockUsers {
  MockUsers._();

  static final List<AppUser> initialUsers = [
    // Pre-authorized Citizen
    AppUser(
      id: 'USR-CIT-01',
      name: 'Maya Lin',
      email: 'citizen@lastsignal.demo',
      role: UserRole.citizen,
      isApproved: true,
      isEnabled: true,
      emergencyContactName: 'David Lin (Spouse)',
      emergencyContactPhone: '+1 (555) 019-2834',
      organization: 'Resident - Sector 4',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),

    // Pre-authorized First Responder
    AppUser(
      id: 'USR-RSP-01',
      name: 'Capt. Marcus Vance',
      email: 'responder@lastsignal.demo',
      role: UserRole.responder,
      isApproved: true,
      isEnabled: true,
      organization: 'Coastal Emergency Response Team (CERT-9)',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ),

    // System Administrator
    AppUser(
      id: 'USR-ADM-01',
      name: 'Dr. Sarah Chen',
      email: 'admin@lastsignal.demo',
      role: UserRole.admin,
      isApproved: true,
      isEnabled: true,
      organization: 'Emergency Intelligence Operations',
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
    ),

    // Pending Responder Request (Used for Flow E: Administrator Approval Demo)
    AppUser(
      id: 'USR-RSP-REQ-02',
      name: 'Lt. Jordan Kelly',
      email: 'jordan.kelly@coastal-rescue.org',
      role: UserRole.responder,
      isApproved: false, // Requires Administrator Approval!
      isEnabled: true,
      organization: 'Marine & Flood Rescue Unit 3',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),

    // Second Citizen Example
    AppUser(
      id: 'USR-CIT-02',
      name: 'Elena Rostova',
      email: 'elena.rostova@metro.org',
      role: UserRole.citizen,
      isApproved: true,
      isEnabled: true,
      emergencyContactName: 'Dr. Rostova (Sister)',
      emergencyContactPhone: '+1 (555) 837-1294',
      organization: 'Civic Volunteer Network',
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
    ),
  ];
}
