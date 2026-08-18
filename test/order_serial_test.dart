import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:yoobbel/controllers/floor_management/marketing_upload_controller.dart';
import 'package:yoobbel/data/models/order_model.dart';
import 'package:yoobbel/data/services/api_service.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() async {
    await TestHelper.setup();
  });

  tearDownAll(() {
    TestHelper.tearDown();
  });

  group('New Order ID Auto-Sync & Serial Tests', () {
    late MarketingUploadController controller;

    setUp(() {
      Get.reset();
      controller = Get.put(MarketingUploadController());
    });

    tearDown(() {
      Get.delete<MarketingUploadController>();
    });

    test('Controller fetches latest serial on initialization and populates orderNo preview', () async {
      await controller.fetchLastOrderSerial();

      expect(controller.lastOrderSerial.value, 'ZBR260018');
      expect(controller.nextOrderSerial.value, 'ZBR260019');
      expect(controller.orderNo.text, 'ZBR260019');
    });

    test('Refreshing serial updates preview with newly returned database +1 value', () async {
      ApiService.mockHandler = (method, endpoint, body) async {
        if (endpoint.contains('last-serial')) {
          return {
            'success': true,
            'data': {
              'lastSerial': 260019,
              'nextSerial': 260020,
              'formattedLastSerial': 'ZBR260019',
              'formattedNextSerial': 'ZBR260020',
            },
          };
        }
        return {'success': true, 'data': {}};
      };

      await controller.fetchLastOrderSerial();

      expect(controller.lastOrderSerial.value, 'ZBR260019');
      expect(controller.nextOrderSerial.value, 'ZBR260020');
      expect(controller.orderNo.text, 'ZBR260020');
    });

    test('Failed serial fetch sets error state without crashing', () async {
      ApiService.mockHandler = (method, endpoint, body) async {
        if (endpoint.contains('last-serial')) {
          throw ApiException('Server error fetching serial', 500);
        }
        return {'success': true, 'data': {}};
      };

      await controller.fetchLastOrderSerial();

      expect(controller.serialFetchError.value, isNotEmpty);
      expect(controller.isFetchingSerial.value, isFalse);
    });

    test('Edit mode retains existing order manualOrderNo and skips auto-generation', () async {
      final existingOrder = OrderModel(
        id: 'order-uuid-1',
        manualOrderNo: 'ZBR260005',
        clientName: 'Test Client',
        productName: 'Polo T-Shirt',
        quantity: 10,
        priority: 'Medium',
        marketingPersonName: 'Agent Smith',
        orderDate: DateTime.now(),
        deliveryDate: DateTime.now().add(const Duration(days: 5)),
        products: [],
        status: 'Pending',
        totalAmount: 1000.0,
      );

      controller.loadOrderData(existingOrder);

      expect(controller.isEditing.value, isTrue);
      expect(controller.orderNo.text, 'ZBR260005');

      // Calling fetchLastOrderSerial in edit mode must NOT overwrite existing order's ID
      await controller.fetchLastOrderSerial();
      expect(controller.orderNo.text, 'ZBR260005');
    });
  });
}
