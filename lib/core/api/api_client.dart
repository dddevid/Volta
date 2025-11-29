import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import '../constants.dart';

/// Client API con gestione automatica di cookies e interceptors
class ApiClient {
  late final Dio _dio;
  final CookieJar _cookieJar = CookieJar();
  String? _jwtToken;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.connectionTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36',
          'Accept': '*/*',
          'Accept-Language': 'it-IT,it;q=0.9,en-US;q=0.8,en;q=0.7',
        },
        validateStatus: (status) => status! < 500,
      ),
    );

    // Add cookie manager
    _dio.interceptors.add(CookieManager(_cookieJar));

    // Add request interceptor for JWT token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_jwtToken != null && _jwtToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_jwtToken';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // Handle 401 unauthorized (token expired)
          if (error.response?.statusCode == 401) {
            // Token expired, need to re-authenticate
            // This will be handled by AuthService
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Set JWT token for authenticated requests
  void setJwtToken(String? token) {
    _jwtToken = token;
  }

  /// Get current JWT token
  String? get jwtToken => _jwtToken;

  /// Clear cookies and token
  void clearAuth() {
    _jwtToken = null;
    _cookieJar.deleteAll();
  }

  /// GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      rethrow;
    }
  }
}
