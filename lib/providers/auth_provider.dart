import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isLoggedIn = false;

  AuthProvider(this._authService) {
    _initialize();
  }

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _isLoggedIn;
  bool get isStudent => _user?.isStudent ?? false;
  bool get isTeacher => _user?.isTeacher ?? false;
  bool get isAdmin => _user?.isAdmin ?? false;

  // Initialize auth state
  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isLoggedIn = await _authService.isLoggedIn();
      if (_isLoggedIn) {
        _user = await _authService.getCurrentUser();
      }
    } catch (e) {
      _error = e.toString();
      _isLoggedIn = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.login(email, password);
      
      if (response.success && response.data != null) {
        _user = response.data!.user;
        _isLoggedIn = true;
        _error = null;
        return true;
      } else {
        _error = response.message;
        _isLoggedIn = false;
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoggedIn = false;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
    } catch (e) {
      print('Logout error: $e');
    } finally {
      _user = null;
      _isLoggedIn = false;
      _error = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh token
  Future<bool> refreshToken() async {
    try {
      final success = await _authService.refreshToken();
      if (!success) {
        await logout();
      }
      return success;
    } catch (e) {
      await logout();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Update user profile
  void updateUser(User updatedUser) {
    _user = updatedUser;
    notifyListeners();
  }
}
