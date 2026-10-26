import '../core/constants/app_constants.dart';
import '../data/mock_users.dart';
import '../models/app_user.dart';
import 'api_service.dart';
import 'local_storage_service.dart';

class AuthResult {
  final bool success;
  final String message;
  final AppUser? user;

  const AuthResult({
    required this.success,
    required this.message,
    this.user,
  });
}

/// Authentication service managing backend communication with transparent
/// offline demo fallback for resilience during disaster simulations.
class AuthService {
  final LocalStorageService _storage;
  final ApiService? _apiService;
  List<AppUser> _users = [];

  AuthService(this._storage, [this._apiService]);

  Future<void> init() async {
    _users = List.from(MockUsers.initialUsers);

    // If backend is connected, populate latest user registry from API
    if (_apiService != null) {
      try {
        final remoteUsers = await _apiService.fetchAllUsers();
        if (remoteUsers != null && remoteUsers.isNotEmpty) {
          _users = remoteUsers;
          return;
        }
      } catch (_) {}
    }

    // Offline / fallback storage check
    final approvedList = await _storage.getApprovedResponders();
    if (approvedList != null) {
      _users = _users.map((u) {
        if (approvedList.contains(u.id)) {
          return u.copyWith(isApproved: true);
        }
        return u;
      }).toList();
    }
  }

  List<AppUser> get allUsers => List.unmodifiable(_users);

  Future<AuthResult> login({
    required String email,
    required String password,
    required UserRole expectedRole,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    // 1. First attempt live backend authentication if available
    if (_apiService != null) {
      try {
        final resp = await _apiService.login(
          email: cleanEmail,
          password: password,
          expectedRole: expectedRole.name,
        );
        if (resp != null) {
          final success = resp['success'] as bool? ?? false;
          final message = resp['message'] as String? ?? 'Authentication responded';
          if (success && resp['user'] != null) {
            final user = AppUser.fromJson(resp['user'] as Map<String, dynamic>);
            await _storage.saveUserSession(user);

            // Synchronize with local user cache
            final idx = _users.indexWhere((u) => u.id == user.id);
            if (idx >= 0) {
              _users[idx] = user;
            } else {
              _users.add(user);
            }
            return AuthResult(success: true, message: message, user: user);
          } else {
            return AuthResult(success: false, message: message);
          }
        }
      } catch (_) {
        // Fall through to offline demo credentials
      }
    }

    // 2. Offline Fallback: Check pre-configured demo credentials
    if (cleanEmail == AppConstants.demoCitizenEmail && password == AppConstants.demoCitizenPass) {
      final user = _users.firstWhere((u) => u.email == cleanEmail, orElse: () => MockUsers.initialUsers.first);
      if (!user.isEnabled) {
        return const AuthResult(
          success: false,
          message: 'This account has been disabled by the system administrator.',
        );
      }
      if (expectedRole != UserRole.citizen) {
        return const AuthResult(
          success: false,
          message: 'Role mismatch: This account has Citizen permissions only.',
        );
      }
      await _storage.saveUserSession(user);
      return AuthResult(success: true, message: 'Logged in as Citizen (Offline Mode)', user: user);
    }

    if (cleanEmail == AppConstants.demoResponderEmail && password == AppConstants.demoResponderPass) {
      final user = _users.firstWhere((u) => u.email == cleanEmail, orElse: () => MockUsers.initialUsers[1]);
      if (!user.isEnabled) {
        return const AuthResult(
          success: false,
          message: 'Responder credential has been revoked or disabled.',
        );
      }
      if (!user.isApproved) {
        return const AuthResult(
          success: false,
          message: 'Responder authorization pending administrative verification.',
        );
      }
      if (expectedRole != UserRole.responder) {
        return const AuthResult(
          success: false,
          message: 'Role mismatch: Please use the Responder access portal.',
        );
      }
      await _storage.saveUserSession(user);
      return AuthResult(success: true, message: 'Authorized Responder Access Granted (Offline Mode)', user: user);
    }

    if (cleanEmail == AppConstants.demoAdminEmail && password == AppConstants.demoAdminPass) {
      final user = _users.firstWhere((u) => u.email == cleanEmail, orElse: () => MockUsers.initialUsers[2]);
      if (expectedRole != UserRole.admin) {
        return const AuthResult(
          success: false,
          message: 'Administrative privileges restricted to Admin portal.',
        );
      }
      await _storage.saveUserSession(user);
      return AuthResult(success: true, message: 'Administrator Access Granted (Offline Mode)', user: user);
    }

    // Check newly registered or dynamically approved users in local memory
    final matchingUser = _users.where((u) => u.email.toLowerCase() == cleanEmail).firstOrNull;
    if (matchingUser != null) {
      if (!matchingUser.isEnabled) {
        return const AuthResult(
          success: false,
          message: 'Account access has been deactivated by administrator.',
        );
      }
      if (matchingUser.role != expectedRole) {
        return AuthResult(
          success: false,
          message: 'Role mismatch: Account is registered as ${matchingUser.role.name.toUpperCase()}.',
        );
      }
      if (matchingUser.role == UserRole.responder && !matchingUser.isApproved) {
        return const AuthResult(
          success: false,
          message: 'Your first responder application is pending administrative review.',
        );
      }
      if (password.length >= 6) {
        await _storage.saveUserSession(matchingUser);
        return AuthResult(success: true, message: 'Authenticated successfully (Local Cache)', user: matchingUser);
      } else {
        return const AuthResult(success: false, message: 'Invalid password. Minimum 6 characters required.');
      }
    }

    return const AuthResult(
      success: false,
      message: 'Invalid credentials. Check demo credentials on the login screen.',
    );
  }

  Future<AuthResult> registerCitizen({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) async {
    if (name.trim().isEmpty) {
      return const AuthResult(success: false, message: 'Full name is required.');
    }
    if (!email.contains('@') || !email.contains('.')) {
      return const AuthResult(success: false, message: 'Please enter a valid email address.');
    }
    if (password.length < 6) {
      return const AuthResult(success: false, message: 'Password must be at least 6 characters.');
    }
    if (password != confirmPassword) {
      return const AuthResult(success: false, message: 'Passwords do not match.');
    }

    // 1. Try registering via backend API
    if (_apiService != null) {
      try {
        final resp = await _apiService.register(
          name: name.trim(),
          email: email.trim().toLowerCase(),
          password: password,
          confirmPassword: confirmPassword,
          emergencyContactName: emergencyContactName?.trim(),
          emergencyContactPhone: emergencyContactPhone?.trim(),
        );
        if (resp != null) {
          final success = resp['success'] as bool? ?? false;
          final message = resp['message'] as String? ?? '';
          if (success && resp['user'] != null) {
            final newUser = AppUser.fromJson(resp['user'] as Map<String, dynamic>);
            _users.add(newUser);
            await _storage.saveUserSession(newUser);
            return AuthResult(success: true, message: message, user: newUser);
          } else {
            return AuthResult(success: false, message: message);
          }
        }
      } catch (_) {}
    }

    // 2. Offline fallback registration
    final exists = _users.any((u) => u.email.toLowerCase() == email.trim().toLowerCase());
    if (exists) {
      return const AuthResult(success: false, message: 'An account with this email already exists.');
    }

    final newUser = AppUser(
      id: 'USR-CIT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      name: name.trim(),
      email: email.trim().toLowerCase(),
      role: UserRole.citizen,
      isApproved: true,
      isEnabled: true,
      emergencyContactName: emergencyContactName?.trim(),
      emergencyContactPhone: emergencyContactPhone?.trim(),
      createdAt: DateTime.now(),
    );

    _users.add(newUser);
    await _storage.saveUserSession(newUser);
    return AuthResult(success: true, message: 'Registration complete. Welcome to LAST SIGNAL AI (Offline Cache).', user: newUser);
  }

  Future<void> approveResponder(String userId) async {
    if (_apiService != null) {
      try {
        await _apiService.approveResponder(userId);
      } catch (_) {}
    }

    _users = _users.map((u) {
      if (u.id == userId) {
        return u.copyWith(isApproved: true);
      }
      return u;
    }).toList();

    final approvedIds = _users.where((u) => u.isApproved).map((u) => u.id).toList();
    await _storage.saveApprovedResponders(approvedIds);
  }

  Future<void> rejectResponder(String userId) async {
    if (_apiService != null) {
      try {
        await _apiService.rejectResponder(userId);
      } catch (_) {}
    }

    _users = _users.map((u) {
      if (u.id == userId) {
        return u.copyWith(isApproved: false);
      }
      return u;
    }).toList();

    final approvedIds = _users.where((u) => u.isApproved).map((u) => u.id).toList();
    await _storage.saveApprovedResponders(approvedIds);
  }

  Future<void> toggleAccountStatus(String userId) async {
    if (_apiService != null) {
      try {
        await _apiService.toggleAccountStatus(userId);
      } catch (_) {}
    }

    _users = _users.map((u) {
      if (u.id == userId) {
        return u.copyWith(isEnabled: !u.isEnabled);
      }
      return u;
    }).toList();
  }
}
