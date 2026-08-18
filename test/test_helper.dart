import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:yoobbel/data/services/api_service.dart';

class TestHelper {
  static Directory? _tempDir;

  static Future<void> setup() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    _tempDir = Directory.systemTemp.createTempSync('zobbra_unit_test_');

    const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async => _tempDir!.path,
    );

    // Initialize default GetStorage container in isolated temp dir
    await GetStorage.init();

    // Mock ApiService to intercept all controller network calls
    ApiService.mockHandler = (String method, String endpoint, dynamic body) async {
      if (endpoint == '/orders/last-serial' || endpoint.contains('last-serial')) {
        return {
          'success': true,
          'data': {
            'lastSerial': 260018,
            'nextSerial': 260019,
            'formattedLastSerial': 'ZBR260018',
            'formattedNextSerial': 'ZBR260019',
            'serial': 'ZBR260019',
            'lastOrderNo': 'ZBR260018',
            'nextOrderNo': 'ZBR260019',
          },
        };
      }
      if (endpoint == '/orders' || endpoint.startsWith('/orders?')) {
        if (method == 'POST') {
          return {
            'success': true,
            'data': {
              'id': 'new-order-id-12345',
              'manual_order_no': 'ZBR260019',
              'client_name': body?['clientName'] ?? 'Test Client',
            },
          };
        }
        return {
          'success': true,
          'orders': <Map<String, dynamic>>[],
          'data': <Map<String, dynamic>>[],
        };
      }
      if (endpoint.contains('/media/upload')) {
        return {
          'success': true,
          'url': 'https://res.cloudinary.com/demo/image/upload/sample.jpg',
        };
      }
      if (endpoint == '/quotations') {
        return {
          'success': true,
          'data': {
            'id': 'quote-12345',
            'quotationNo': body?['quotationNo'] ?? 'ZBR26001',
            'clientName': body?['clientName'] ?? 'Test Client',
          },
        };
      }
      if (endpoint == '/auth/refresh') {
        if (body?['refreshToken'] == 'valid-refresh-token' || body?['refreshToken'] != null) {
          return {
            'success': true,
            'accessToken': 'new-access-token-999',
            'refreshToken': 'new-refresh-token-999',
            'expiresAt': (DateTime.now().millisecondsSinceEpoch / 1000).round() + 3600,
            'user': {'id': 'user-1', 'email': 'agent@zobbra.com', 'role': 'SALES_ASSOCIATE'},
          };
        }
        throw ApiException('Invalid or expired refresh token', 401);
      }
      return {'success': true, 'data': {}};
    };
  }

  static void tearDown() {
    ApiService.mockHandler = null;
    try {
      if (_tempDir != null && _tempDir!.existsSync()) {
        _tempDir!.deleteSync(recursive: true);
      }
    } catch (_) {}
  }
}
