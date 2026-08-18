import 'package:flutter_test/flutter_test.dart';
import 'package:yoobbel/data/services/api_service.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() async {
    await TestHelper.setup();
  });

  tearDownAll(() {
    TestHelper.tearDown();
  });

  group('Auth Token Session & Auto-Refresh Tests', () {
    test('saveSession stores access token, refresh token, and expiresAt correctly', () {
      ApiService.saveSession(
        'initial-access-token',
        {'id': 'u1', 'name': 'Sales Agent', 'role': 'SALES_ASSOCIATE'},
        refreshToken: 'initial-refresh-token',
        expiresAt: 1780000000,
      );

      expect(ApiService.token, 'initial-access-token');
      expect(ApiService.refreshToken, 'initial-refresh-token');
      expect(ApiService.expiresAt, 1780000000);
      expect(ApiService.currentUser?['name'], 'Sales Agent');
    });

    test('clearSession cleanly removes all session and auth keys', () {
      ApiService.clearSession();
      expect(ApiService.token, isNull);
      expect(ApiService.refreshToken, isNull);
      expect(ApiService.expiresAt, isNull);
      expect(ApiService.currentUser, isNull);
    });

    test('refreshSession successfully updates tokens upon valid refresh', () async {
      ApiService.saveSession(
        'expired-token',
        {'id': 'u1', 'name': 'Sales Agent'},
        refreshToken: 'valid-refresh-token',
      );

      final success = await ApiService.refreshSession();
      expect(success, isTrue);
      expect(ApiService.token, 'new-access-token-999');
      expect(ApiService.refreshToken, 'new-refresh-token-999');
    });

    test('ApiService transparently refreshes token and retries request on 401', () async {
      ApiService.saveSession(
        'expired-access-token',
        {'id': 'u1', 'name': 'Agent'},
        refreshToken: 'valid-refresh-token',
      );

      int attempts = 0;
      ApiService.mockHandler = (method, endpoint, body) async {
        if (endpoint == '/orders') {
          attempts++;
          if (attempts == 1) {
            // First attempt fails with 401
            throw ApiException('Invalid or expired access token', 401);
          }
          // Second attempt with refreshed token succeeds
          return {'success': true, 'orders': [{'id': 'o-101'}]};
        }
        if (endpoint == '/auth/refresh') {
          return {
            'success': true,
            'accessToken': 'refreshed-token-2026',
            'refreshToken': 'valid-refresh-token',
            'user': {'id': 'u1', 'name': 'Agent'},
          };
        }
        return {'success': true};
      };

      final response = await ApiService.get('/orders');
      expect(response['success'], isTrue);
      expect(attempts, 2); // Attempted first -> 401 -> refreshed -> retried -> succeeded
      expect(ApiService.token, 'refreshed-token-2026');
    });

    test('Failed refresh clears session and does not retry infinitely', () async {
      ApiService.saveSession(
        'expired-access-token',
        {'id': 'u1', 'name': 'Agent'},
        refreshToken: 'invalid-expired-refresh-token',
      );

      int attempts = 0;
      ApiService.mockHandler = (method, endpoint, body) async {
        if (endpoint == '/orders') {
          attempts++;
          throw ApiException('Invalid or expired access token', 401);
        }
        if (endpoint == '/auth/refresh') {
          throw ApiException('Invalid or expired refresh token', 401);
        }
        return {'success': true};
      };

      await expectLater(
        () async => await ApiService.get('/orders'),
        throwsA(isA<ApiException>()),
      );

      // Exactly 1 attempt on original request + 1 refresh attempt, zero recursion
      expect(attempts, 1);
      expect(ApiService.token, isNull);
    });

    test('Quotation save only creates quotation once upon 401 retry', () async {
      ApiService.saveSession(
        'expired-token',
        {'id': 'u1'},
        refreshToken: 'valid-refresh-token',
      );

      int creationCount = 0;
      ApiService.mockHandler = (method, endpoint, body) async {
        if (endpoint == '/quotations') {
          if (creationCount == 0) {
            creationCount++;
            throw ApiException('Invalid or expired access token', 401);
          }
          creationCount++;
          return {'success': true, 'data': {'id': 'q-999'}};
        }
        if (endpoint == '/auth/refresh') {
          return {
            'success': true,
            'accessToken': 'fresh-token',
            'refreshToken': 'valid-refresh-token',
          };
        }
        return {'success': true};
      };

      final res = await ApiService.post('/quotations', {'clientName': 'Acme'});
      expect(res['success'], isTrue);
      expect(creationCount, 2); // 1st was blocked by auth -> refreshed -> 2nd persisted
      expect(res['data']['id'], 'q-999');
    });
  });
}
