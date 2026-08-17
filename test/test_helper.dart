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

    // Initialize GetStorage with unique container in temp dir
    await GetStorage.init('test_container_${DateTime.now().microsecondsSinceEpoch}');

    // Mock ApiService to intercept all controller network calls
    ApiService.mockHandler = (String method, String endpoint, dynamic body) async {
      if (endpoint == '/orders' || endpoint.startsWith('/orders?')) {
        return {
          'success': true,
          'orders': <Map<String, dynamic>>[],
          'data': <Map<String, dynamic>>[],
        };
      }
      if (endpoint.contains('last-serial') || endpoint.contains('serial')) {
        return {
          'success': true,
          'serial': 'ORD-1001',
          'data': {'serial': 'ORD-1001'},
        };
      }
      if (endpoint.contains('/media/upload')) {
        return {
          'success': true,
          'url': 'https://res.cloudinary.com/demo/image/upload/sample.jpg',
        };
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
