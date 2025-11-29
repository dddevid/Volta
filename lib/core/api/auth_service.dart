import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:html/parser.dart' as html_parser;
import 'api_client.dart';
import '../constants.dart';
import '../../models/alunno.dart';

/// Servizio di autenticazione per Nuvola
class AuthService {
  final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Alunno? _currentStudent;
  DateTime? _tokenExpiry;

  AuthService(this._apiClient);

  /// Ottiene lo studente corrente
  Alunno? get currentStudent => _currentStudent;

  /// Ottiene l'API client autenticato
  ApiClient get apiClient => _apiClient;

  /// Verifica se l'utente è autenticato
  bool get isAuthenticated => _currentStudent != null && !_isTokenExpired();

  /// Verifica se il token è scaduto
  bool _isTokenExpired() {
    if (_tokenExpiry == null) return true;
    return DateTime.now().isAfter(_tokenExpiry!);
  }

  /// Login con username e password
  Future<bool> login(String username, String password,
      {bool rememberMe = false}) async {
    try {
      print('[AUTH] Step 1: Getting CSRF token...');
      // Step 1: GET /login to get CSRF token
      final loginPageResponse = await _apiClient.get(AppConstants.loginPage);

      if (loginPageResponse.statusCode != 200) {
        throw Exception('Impossibile caricare la pagina di login');
      }

      // Parse HTML to extract CSRF token
      final document = html_parser.parse(loginPageResponse.data);
      final csrfInput = document.querySelector('input[name="_csrf_token"]');

      if (csrfInput == null) {
        throw Exception('CSRF token non trovato');
      }

      final csrfToken = csrfInput.attributes['value'];

      if (csrfToken == null || csrfToken.isEmpty) {
        throw Exception('CSRF token non valido');
      }

      print('[AUTH] Step 2: Logging in with credentials...');
      // Step 2: POST /login_check with credentials
      final loginData = {
        '_csrf_token': csrfToken,
        '_username': username,
        '_password': password,
      };

      final loginResponse = await _apiClient.post(
        AppConstants.loginCheck,
        data: loginData,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: false,
          validateStatus: (status) => status! < 400,
        ),
      );

      // Check if login was successful (should redirect)
      if (loginResponse.statusCode != 302 && loginResponse.statusCode != 200) {
        throw Exception('Credenziali non valide');
      }

      print('[AUTH] Step 3: Accessing student area...');
      // Step 3: Access student area to establish session
      await _apiClient.get('/area-studente');

      print('[AUTH] Step 4: Getting JWT token...');
      // Step 4: Get JWT token from API
      final jwtResponse = await _apiClient.get(AppConstants.apiLoginFromWeb);

      if (jwtResponse.statusCode != 200 || jwtResponse.data == null) {
        print('[AUTH] JWT Response status: ${jwtResponse.statusCode}');
        print('[AUTH] JWT Response data: ${jwtResponse.data}');
        throw Exception('Impossibile ottenere il token di autenticazione');
      }

      // Parse JWT - could be a string directly or an object with 'token' field
      String? jwtToken;
      if (jwtResponse.data is String) {
        jwtToken = jwtResponse.data as String;
      } else if (jwtResponse.data is Map<String, dynamic>) {
        final jwtData = jwtResponse.data as Map<String, dynamic>;
        jwtToken = jwtData['token'] as String?;
      } else {
        throw Exception('Formato token JWT non riconosciuto');
      }

      if (jwtToken == null || jwtToken.isEmpty) {
        throw Exception('Token JWT non valido');
      }

      print('[AUTH] JWT token obtained successfully');
      // Set JWT token in API client
      _apiClient.setJwtToken(jwtToken);
      _tokenExpiry = DateTime.now().add(AppConstants.tokenExpiryDuration);

      print('[AUTH] Step 5: Getting student list...');
      // Step 5: Now get available roles/students with JWT token
      final studentsResponse = await _apiClient.get('/api-studente/v1/alunni');

      if (studentsResponse.statusCode != 200 || studentsResponse.data == null) {
        print(
            '[AUTH] Students Response status: ${studentsResponse.statusCode}');
        print('[AUTH] Students Response data: ${studentsResponse.data}');
        throw Exception('Impossibile ottenere la lista studenti');
      }

      // Parse response - Nuvola API returns object with 'valori' array
      List<dynamic> studentsData;
      if (studentsResponse.data is List) {
        studentsData = studentsResponse.data as List;
      } else if (studentsResponse.data is Map<String, dynamic>) {
        final responseMap = studentsResponse.data as Map<String, dynamic>;
        // Nuvola API uses 'valori' field for data array
        if (responseMap.containsKey('valori')) {
          studentsData = responseMap['valori'] as List;
        } else if (responseMap.containsKey('data')) {
          studentsData = responseMap['data'] as List;
        } else {
          // Single student returned as object
          studentsData = [responseMap];
        }
      } else {
        throw Exception('Formato risposta studenti non riconosciuto');
      }

      if (studentsData.isEmpty) {
        throw Exception('Nessuno studente associato a questo account');
      }

      print('[AUTH] Found ${studentsData.length} student(s)');
      // Get first student (or we could let user choose)
      final studentJson = studentsData.first as Map<String, dynamic>;
      print('[AUTH] Student JSON: $studentJson');
      _currentStudent = Alunno.fromJson(studentJson);

      print('[AUTH] Student selected: ${_currentStudent!.nomeCompleto}');

      // Save credentials if remember me is enabled
      if (rememberMe) {
        await _saveCredentials(username, password, jwtToken);
      } else {
        await _saveToken(jwtToken);
      }

      print('[AUTH] Login successful!');
      return true;
    } on DioException catch (e) {
      print('[AUTH] DioException: ${e.type}, ${e.message}');
      print('[AUTH] Response: ${e.response?.statusCode} - ${e.response?.data}');
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw Exception('Credenziali non valide');
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Timeout di connessione');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Errore di connessione');
      }
      throw Exception('Errore durante il login: ${e.message}');
    } catch (e) {
      print('[AUTH] Exception: $e');
      rethrow;
    }
  }

  /// Salva le credenziali in modo sicuro
  Future<void> _saveCredentials(
      String username, String password, String token) async {
    await _secureStorage.write(
        key: AppConstants.storageKeyUsername, value: username);
    await _secureStorage.write(
        key: AppConstants.storageKeyPassword, value: password);
    await _secureStorage.write(
        key: AppConstants.storageKeyJwtToken, value: token);
    await _secureStorage.write(
        key: AppConstants.storageKeyRememberMe, value: 'true');
  }

  /// Salva solo il token
  Future<void> _saveToken(String token) async {
    await _secureStorage.write(
        key: AppConstants.storageKeyJwtToken, value: token);
    await _secureStorage.write(
        key: AppConstants.storageKeyRememberMe, value: 'false');
  }

  /// Carica le credenziali salvate
  Future<Map<String, String?>> loadSavedCredentials() async {
    final username =
        await _secureStorage.read(key: AppConstants.storageKeyUsername);
    final password =
        await _secureStorage.read(key: AppConstants.storageKeyPassword);
    final rememberMe =
        await _secureStorage.read(key: AppConstants.storageKeyRememberMe);

    return {
      'username': username,
      'password': password,
      'rememberMe': rememberMe,
    };
  }

  /// Verifica lo stato di autenticazione all'avvio
  Future<bool> checkAuthStatus() async {
    try {
      final token =
          await _secureStorage.read(key: AppConstants.storageKeyJwtToken);

      if (token == null || token.isEmpty) {
        return false;
      }

      // Set token in API client
      _apiClient.setJwtToken(token);

      // Try to get student list to verify token is still valid
      final studentsResponse = await _apiClient.get('/api-studente/v1/alunni');

      if (studentsResponse.statusCode == 200 && studentsResponse.data != null) {
        final studentsData = studentsResponse.data as List;

        if (studentsData.isNotEmpty) {
          final studentJson = studentsData.first as Map<String, dynamic>;
          _currentStudent = Alunno.fromJson(studentJson);
          _tokenExpiry = DateTime.now().add(AppConstants.tokenExpiryDuration);
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    _currentStudent = null;
    _tokenExpiry = null;
    _apiClient.clearAuth();

    // Keep username if remember me was enabled, but clear password and token
    final rememberMe =
        await _secureStorage.read(key: AppConstants.storageKeyRememberMe);

    if (rememberMe != 'true') {
      await _secureStorage.delete(key: AppConstants.storageKeyUsername);
    }

    await _secureStorage.delete(key: AppConstants.storageKeyPassword);
    await _secureStorage.delete(key: AppConstants.storageKeyJwtToken);
  }

  /// Aggiorna il token se sta per scadere
  Future<void> refreshTokenIfNeeded() async {
    if (_isTokenExpired()) {
      // Try to re-login with saved credentials
      final credentials = await loadSavedCredentials();

      if (credentials['username'] != null && credentials['password'] != null) {
        await login(
          credentials['username']!,
          credentials['password']!,
          rememberMe: credentials['rememberMe'] == 'true',
        );
      }
    }
  }
}
