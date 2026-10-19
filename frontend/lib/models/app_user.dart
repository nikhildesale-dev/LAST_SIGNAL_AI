enum UserRole {
  citizen,
  responder,
  admin,
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final bool isApproved; // Crucial for responder authorization
  final bool isEnabled;  // Administrator disable/enable control
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? organization;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isApproved = true,
    this.isEnabled = true,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.organization,
    required this.createdAt,
  });

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    bool? isApproved,
    bool? isEnabled,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? organization,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isApproved: isApproved ?? this.isApproved,
      isEnabled: isEnabled ?? this.isEnabled,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      organization: organization ?? this.organization,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'isApproved': isApproved,
      'isEnabled': isEnabled,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'organization': organization,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.citizen,
      ),
      isApproved: json['isApproved'] as bool? ?? true,
      isEnabled: json['isEnabled'] as bool? ?? true,
      emergencyContactName: json['emergencyContactName'] as String?,
      emergencyContactPhone: json['emergencyContactPhone'] as String?,
      organization: json['organization'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
