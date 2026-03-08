import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:html/parser.dart' as html_parser;
import 'api_client.dart';
import '../constants.dart';
import '../../models/alunno.dart';

class AuthService {
  final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Alunno? _currentStudent;
  DateTime? _tokenExpiry;

  AuthService(this._apiClient);

  Alunno? get currentStudent => _currentStudent;

  ApiClient get apiClient => _apiClient;

  bool get isAuthenticated => _currentStudent != null && !_isTokenExpired();

  bool _isTokenExpired() {
    if (_tokenExpiry == null) return true;
    return DateTime.now().isAfter(_tokenExpiry!);
  }

  Future<bool> login(String username, String password,
      {bool rememberMe = false}) async {
    try {
      debugPrint('[AUTH] Step 1: getting CSRF token');
      final loginPageResponse = await _apiClient.get(AppConstants.loginPage);

      if (loginPageResponse.statusCode != 200) {
        throw Exception('Impossibile caricare la pagina di login');
      }

      final document = html_parser.parse(loginPageResponse.data);
      final csrfInput = document.querySelector('input[name="_csrf_token"]');

      if (csrfInput == null) {
        throw Exception('CSRF token non trovato');
      }

      final csrfToken = csrfInput.attributes['value'];

      if (csrfToken == null || csrfToken.isEmpty) {
        throw Exception('CSRF token non valido');
      }

      debugPrint('[AUTH] Step 2: logging in');

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

      if (loginResponse.statusCode != 302 && loginResponse.statusCode != 200) {
        throw Exception('Credenziali non valide');
      }

      debugPrint('[AUTH] Step 3: accessing student area');
      await _apiClient.get('/area-studente');

      debugPrint('[AUTH] Step 4: getting JWT token');
      final jwtResponse = await _apiClient.get(AppConstants.apiLoginFromWeb);

      if (jwtResponse.statusCode != 200 || jwtResponse.data == null) {
        throw Exception('Impossibile ottenere il token di autenticazione');
      }

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

      debugPrint('[AUTH] JWT token obtained successfully');

      _apiClient.setJwtToken(jwtToken);
      _tokenExpiry = DateTime.now().add(AppConstants.tokenExpiryDuration);

      debugPrint('[AUTH] Step 5: getting student list');

      final studentsResponse = await _apiClient.get('/api-studente/v1/alunni');

      if (studentsResponse.statusCode != 200 || studentsResponse.data == null) {
        throw Exception('Impossibile ottenere la lista studenti');
      }

      List<dynamic> studentsData;
      if (studentsResponse.data is List) {
        studentsData = studentsResponse.data as List;
      } else if (studentsResponse.data is Map<String, dynamic>) {
        final responseMap = studentsResponse.data as Map<String, dynamic>;
        if (responseMap.containsKey('valori')) {
          studentsData = responseMap['valori'] as List;
        } else if (responseMap.containsKey('data')) {
          studentsData = responseMap['data'] as List;
        } else {
          studentsData = [responseMap];
        }
      } else {
        throw Exception('Formato risposta studenti non riconosciuto');
      }

      if (studentsData.isEmpty) {
        throw Exception('Nessuno studente associato a questo account');
      }

      debugPrint('[AUTH] Found ${studentsData.length} student(s)');

      final studentJson = studentsData.first as Map<String, dynamic>;
      _currentStudent = Alunno.fromJson(studentJson);

      if (rememberMe) {
        await _saveCredentials(username, password, jwtToken);
      } else {
        await _saveToken(jwtToken);
      }

      debugPrint('[AUTH] Login successful');
      return true;
    } on DioException catch (e) {
      debugPrint('[AUTH] DioException: ${e.type}');
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
      debugPrint('[AUTH] Unexpected exception: ${e.runtimeType}');
      rethrow;
    }
  }

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

  Future<void> _saveToken(String token) async {
    await _secureStorage.write(
        key: AppConstants.storageKeyJwtToken, value: token);
    await _secureStorage.write(
        key: AppConstants.storageKeyRememberMe, value: 'false');
  }

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

  Future<bool> checkAuthStatus() async {
    try {
      final token =
          await _secureStorage.read(key: AppConstants.storageKeyJwtToken);

      if (token == null || token.isEmpty) {
        return false;
      }

      _apiClient.setJwtToken(token);

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

  Future<void> logout() async {
    _currentStudent = null;
    _tokenExpiry = null;
    _apiClient.clearAuth();

    final rememberMe =
        await _secureStorage.read(key: AppConstants.storageKeyRememberMe);

    if (rememberMe != 'true') {
      await _secureStorage.delete(key: AppConstants.storageKeyUsername);
    }

    await _secureStorage.delete(key: AppConstants.storageKeyPassword);
    await _secureStorage.delete(key: AppConstants.storageKeyJwtToken);
  }

  Future<void> refreshTokenIfNeeded() async {
    if (_isTokenExpired()) {

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
