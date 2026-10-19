import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final LocalStorageService _storage;

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this._authService, this._storage);

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  UserRole get currentRole => _currentUser?.role ?? UserRole.citizen;
  bool get isCitizen => currentRole == UserRole.citizen;
  bool get isResponder => currentRole == UserRole.responder;
  bool get isAdmin => currentRole == UserRole.admin;

  List<AppUser> get allUsers => _authService.allUsers;
  List<AppUser> get pendingResponders =>
      _authService.allUsers.where((u) => u.role == UserRole.responder && !u.isApproved).toList();

  Future<void> init() async {
    await _authService.init();
    _currentUser = await _storage.getUserSession();
    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
    required UserRole expectedRole,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.login(
      email: email,
      password: password,
      expectedRole: expectedRole,
    );

    _isLoading = false;
    if (result.success && result.user != null) {
      _currentUser = result.user;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerCitizen({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.registerCitizen(
      name: name,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
    );

    _isLoading = false;
    if (result.success && result.user != null) {
      _currentUser = result.user;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    await _storage.clearUserSession();
    notifyListeners();
  }

  Future<void> approveResponder(String userId) async {
    await _authService.approveResponder(userId);
    notifyListeners();
  }

  Future<void> rejectResponder(String userId) async {
    await _authService.rejectResponder(userId);
    notifyListeners();
  }

  Future<void> toggleAccountStatus(String userId) async {
    await _authService.toggleAccountStatus(userId);
    notifyListeners();
  }
}
