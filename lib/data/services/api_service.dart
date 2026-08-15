import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

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
    return 'http://localhost:5000/api/v1';
  }

  static final GetStorage _box = GetStorage();

  static String? get token => _box.read<String>('auth_token');
  static Map<String, dynamic>? get currentUser => _box.read<Map<String, dynamic>>('current_user');

  static void saveSession(String token, Map<String, dynamic> user) {
    _box.write('auth_token', token);
    _box.write('current_user', user);
  }

  static void clearSession() {
    _box.remove('auth_token');
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

  static Future<Map<String, dynamic>> _execute(
    String method,
    String endpoint,
    Future<http.Response> Function(Uri uri, Map<String, String> headers) makeRequest,
  ) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    _logRequest(method, endpoint);
    try {
      final response = await makeRequest(uri, _headers).timeout(const Duration(seconds: 15));
      _logRequest(method, endpoint, response.statusCode);
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
    );
  }

  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> body) async {
    return _execute(
      'PUT',
      endpoint,
      (uri, headers) => http.put(uri, headers: headers, body: jsonEncode(body)),
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
