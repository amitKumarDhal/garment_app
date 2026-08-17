import 'package:flutter_test/flutter_test.dart';
import 'package:yoobbel/controllers/sales/sales_history_controller.dart';
import 'package:yoobbel/controllers/sales/sales_manager_history_controller.dart';
import 'package:yoobbel/data/models/order_model.dart';
import 'package:yoobbel/utils/constants/app_constants.dart';
import 'package:get/get.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() async {
    await TestHelper.setup();
  });

  tearDownAll(() {
    TestHelper.tearDown();
  });

  group('Order Status Filters Tests', () {
    test('Order filter options contain EXACT required values only', () {
      expect(AppConstants.orderFilterOptions, [
        'All',
        'Pending',
        'Approved',
        'Production',
        'Dispatched',
        'Delivered',
      ]);

      expect(AppConstants.orderStatuses, [
        'Pending',
        'Approved',
        'Production',
        'Dispatched',
        'Delivered',
      ]);
    });

    test('SalesHistoryController correctly filters orders by exact status and maps production/dispatched', () {
      Get.reset();
      final controller = Get.put(SalesHistoryController());

      final dummyOrders = [
        OrderModel(clientName: 'Client 1', productName: 'T-Shirt', quantity: 10, priority: 'Medium', orderDate: DateTime.now(), deliveryDate: DateTime.now(), marketingPersonName: 'Agent', status: 'Pending', totalAmount: 1000),
        OrderModel(clientName: 'Client 2', productName: 'Polo', quantity: 20, priority: 'High', orderDate: DateTime.now(), deliveryDate: DateTime.now(), marketingPersonName: 'Agent', status: 'Approved', totalAmount: 2000),
        OrderModel(clientName: 'Client 3', productName: 'Hoodie', quantity: 15, priority: 'Medium', orderDate: DateTime.now(), deliveryDate: DateTime.now(), marketingPersonName: 'Agent', status: 'Production', totalAmount: 3000),
        OrderModel(clientName: 'Client 4', productName: 'Jersey', quantity: 5, priority: 'Low', orderDate: DateTime.now(), deliveryDate: DateTime.now(), marketingPersonName: 'Agent', status: 'Cutting Done', totalAmount: 1500),
        OrderModel(clientName: 'Client 5', productName: 'Cap', quantity: 50, priority: 'Medium', orderDate: DateTime.now(), deliveryDate: DateTime.now(), marketingPersonName: 'Agent', status: 'Dispatched', totalAmount: 5000),
        OrderModel(clientName: 'Client 6', productName: 'Sweater', quantity: 8, priority: 'Medium', orderDate: DateTime.now(), deliveryDate: DateTime.now(), marketingPersonName: 'Agent', status: 'Delivered', totalAmount: 4000),
      ];

      controller.myOrders.assignAll(dummyOrders);

      // Filter: All
      controller.filterByStatus('All');
      expect(controller.displayedOrders.length, 6);

      // Filter: Pending
      controller.filterByStatus('Pending');
      expect(controller.displayedOrders.length, 1);
      expect(controller.displayedOrders[0].clientName, 'Client 1');

      // Filter: Approved
      controller.filterByStatus('Approved');
      expect(controller.displayedOrders.length, 1);
      expect(controller.displayedOrders[0].clientName, 'Client 2');

      // Filter: Production (should match 'Production' and legacy 'Cutting Done')
      controller.filterByStatus('Production');
      expect(controller.displayedOrders.length, 2);

      // Filter: Dispatched
      controller.filterByStatus('Dispatched');
      expect(controller.displayedOrders.length, 1);
      expect(controller.displayedOrders[0].clientName, 'Client 5');

      // Filter: Delivered
      controller.filterByStatus('Delivered');
      expect(controller.displayedOrders.length, 1);
      expect(controller.displayedOrders[0].clientName, 'Client 6');
    });

    test('SalesManagerHistoryController correctly filters orders', () {
      Get.reset();
      final controller = Get.put(SalesManagerHistoryController());

      final dummyOrders = [
        OrderModel(clientName: 'Client A', productName: 'T-Shirt', quantity: 10, priority: 'Medium', orderDate: DateTime.now(), deliveryDate: DateTime.now(), marketingPersonName: 'Agent', status: 'Pending', totalAmount: 1000),
        OrderModel(clientName: 'Client B', productName: 'Polo', quantity: 20, priority: 'High', orderDate: DateTime.now(), deliveryDate: DateTime.now(), marketingPersonName: 'Agent', status: 'Delivered', totalAmount: 2000),
      ];

      controller.allOrders.assignAll(dummyOrders);

      controller.filterByStatus('All');
      expect(controller.displayedOrders.length, 2);

      controller.filterByStatus('Pending');
      expect(controller.displayedOrders.length, 1);

      controller.filterByStatus('Delivered');
      expect(controller.displayedOrders.length, 1);
    });
  });
}
