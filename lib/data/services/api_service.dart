import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../../routes/route_names.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      final trimmed = _envBaseUrl.trim();
      final normalized = trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
      return normalized.endsWith('/api/v1') ? normalized : '$normalized/api/v1';
    }
    return 'https://api.zobbra.com/api/v1';
  }

  static final GetStorage _box = GetStorage();

  static String? get token => _box.read<String>('auth_token');
  static String? get refreshToken => _box.read<String>('refresh_token');
  static int? get expiresAt => _box.read<int>('expires_at');
  static Map<String, dynamic>? get currentUser => _box.read<Map<String, dynamic>>('current_user');

  static void saveSession(
    String token,
    Map<String, dynamic> user, {
    String? refreshToken,
    int? expiresAt,
  }) {
    _box.write('auth_token', token);
    _box.write('current_user', user);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      _box.write('refresh_token', refreshToken);
    }
    if (expiresAt != null) {
      _box.write('expires_at', expiresAt);
    }
  }

  static void clearSession() {
    _box.remove('auth_token');
    _box.remove('refresh_token');
    _box.remove('expires_at');
    _box.remove('current_user');
  }

  static Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static void _logRequest(String method, String endpoint, [int? statusCode]) {
    if (kDebugMode) {
      if (statusCode != null) {
        debugPrint('[ZOBRA API] STATUS: $statusCode for $method $endpoint');
      } else {
        debugPrint('[ZOBRA API] BASE URL: $baseUrl');
        debugPrint('[ZOBRA API] REQUEST: $method $endpoint');
      }
    }
  }

  static Future<Map<String, dynamic>> Function(String method, String endpoint, dynamic body)? mockHandler;

  // Single in-flight refresh Future to synchronize concurrent 401s
  static Future<bool>? _refreshFuture;

  /// Centralized session refresh method
  static Future<bool> refreshSession() async {
    if (_refreshFuture != null) {
      return await _refreshFuture!;
    }

    _refreshFuture = _performRefresh();
    try {
      final result = await _refreshFuture!;
      return result;
    } finally {
      _refreshFuture = null;
    }
  }

  static Future<bool> _performRefresh() async {
    final rToken = refreshToken;
    if (rToken == null || rToken.isEmpty) {
      debugPrint('[ZOBRA AUTH] No refresh token stored in session');
      return false;
    }

    try {
      debugPrint('[ZOBRA AUTH] Attempting session refresh...');

      // Allow mock handler to intercept in unit test environment
      if (mockHandler != null) {
        final mockRes = await mockHandler!('POST', '/auth/refresh', {'refreshToken': rToken});
        if (mockRes['success'] == true) {
          final data = mockRes['data'] is Map<String, dynamic> ? mockRes['data'] as Map<String, dynamic> : mockRes;
          final newToken = data['accessToken'] ?? data['token'] ?? 'mock_refreshed_token';
          final newRToken = data['refreshToken'] ?? rToken;
          final newExpires = data['expiresAt'] is int ? data['expiresAt'] as int : null;
          final user = (data['user'] ?? currentUser ?? {}) as Map<String, dynamic>;
          saveSession(newToken.toString(), user, refreshToken: newRToken.toString(), expiresAt: newExpires);
          return true;
        }
        return false;
      }

      final uri = Uri.parse('$baseUrl/auth/refresh');
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'refreshToken': rToken}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final data = decoded['data'] is Map<String, dynamic> ? decoded['data'] as Map<String, dynamic> : decoded;
        final newAccessToken = (data['accessToken'] ?? data['token']) as String?;
        final newRefreshToken = (data['refreshToken'] ?? rToken) as String?;
        final newExpiresAt = data['expiresAt'] is int ? data['expiresAt'] as int : null;
        final user = (data['user'] ?? currentUser ?? {}) as Map<String, dynamic>;

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          saveSession(newAccessToken, user, refreshToken: newRefreshToken, expiresAt: newExpiresAt);
          debugPrint('[ZOBRA AUTH] Session refreshed successfully!');
          return true;
        }
      }

      debugPrint('[ZOBRA AUTH] Session refresh rejected by server (${response.statusCode})');
      return false;
    } catch (e) {
      debugPrint('[ZOBRA AUTH] Session refresh exception: $e');
      return false;
    }
  }

  static void handleSessionExpired() {
    clearSession();
    try {
      if (Get.currentRoute != AppRouteNames.login && Get.key.currentState != null) {
        Get.offAllNamed(AppRouteNames.login);
        Get.snackbar(
          "Session Expired",
          "Session expired, please login again",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> _execute(
    String method,
    String endpoint,
    Future<http.Response> Function(Uri uri, Map<String, String> headers) makeRequest, [
    dynamic body,
    bool isRetry = false,
  ]) async {
    if (mockHandler != null) {
      try {
        return await mockHandler!(method, endpoint, body);
      } on ApiException catch (e) {
        if (e.statusCode == 401 && !isRetry && endpoint != '/auth/login' && endpoint != '/auth/refresh') {
          final refreshed = await refreshSession();
          if (refreshed) {
            return await _execute(method, endpoint, makeRequest, body, true);
          } else {
            handleSessionExpired();
            rethrow;
          }
        }
        rethrow;
      }
    }

    final uri = Uri.parse('$baseUrl$endpoint');
    _logRequest(method, endpoint);
    try {
      final response = await makeRequest(uri, _headers).timeout(const Duration(seconds: 15));
      _logRequest(method, endpoint, response.statusCode);

      // Handle 401 Token Expiration with Automatic Refresh & Single Retry
      if (response.statusCode == 401 && !isRetry && endpoint != '/auth/login' && endpoint != '/auth/refresh') {
        debugPrint('[ZOBRA API] Received 401 on $method $endpoint. Attempting token refresh...');
        final refreshed = await refreshSession();
        if (refreshed) {
          debugPrint('[ZOBRA API] Retrying request $method $endpoint with refreshed token...');
          return await _execute(method, endpoint, makeRequest, body, true);
        } else {
          debugPrint('[ZOBRA API] Token refresh failed. Triggering session expiry...');
          handleSessionExpired();
          throw ApiException('Session expired, please login again', 401);
        }
      }

      return _handleResponse(response);
    } on SocketException catch (_) {
      throw ApiException('Unable to connect to Zobra server. Please check your network connection or try again.');
    } on http.ClientException catch (_) {
      throw ApiException('Unable to connect to Zobra server. Please check your network connection or try again.');
    } on TimeoutException catch (_) {
      throw ApiException('Connection timed out. Please check your network connection or try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unable to connect to Zobra server. Please check your network connection or try again.');
    }
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    return _execute('GET', endpoint, (uri, headers) => http.get(uri, headers: headers));
  }

  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    return _execute(
      'POST',
      endpoint,
      (uri, headers) => http.post(uri, headers: headers, body: jsonEncode(body)),
      body,
    );
  }

  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> body) async {
    return _execute(
      'PUT',
      endpoint,
      (uri, headers) => http.put(uri, headers: headers, body: jsonEncode(body)),
      body,
    );
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    return _execute('DELETE', endpoint, (uri, headers) => http.delete(uri, headers: headers));
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      } else {
        final message = decoded['message'] ?? 'API Request Failed (${response.statusCode})';
        throw ApiException(message.toString(), response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Server communication error (${response.statusCode})', response.statusCode);
    }
  }
}
