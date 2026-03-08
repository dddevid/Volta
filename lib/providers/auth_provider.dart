import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/api/auth_service.dart';
import '../models/alunno.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;

  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  AuthProvider(ApiClient apiClient) : _authService = AuthService(apiClient);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  Alunno? get currentStudent => _authService.currentStudent;
  AuthService get authService => _authService;

  Future<bool> login(String username, String password,
      {bool rememberMe = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success =
          await _authService.login(username, password, rememberMe: rememberMe);

      if (success) {
        _isAuthenticated = true;
      }

      _isLoading = false;
      notifyListeners();

      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      _isAuthenticated = false;
      notifyListeners();

      return false;
    }
  }

  Future<bool> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isAuth = await _authService.checkAuthStatus();
      _isAuthenticated = isAuth;
      _isLoading = false;
      notifyListeners();

      return isAuth;
    } catch (e) {
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();

      return false;
    }
  }

  Future<Map<String, String?>> loadSavedCredentials() async {
    return await _authService.loadSavedCredentials();
  }

  Future<void> logout() async {
    await _authService.logout();
    _isAuthenticated = false;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
