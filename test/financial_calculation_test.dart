import 'package:flutter_test/flutter_test.dart';
import 'package:yoobbel/controllers/floor_management/marketing_upload_controller.dart';
import 'package:get/get.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() async {
    await TestHelper.setup();
  });

  tearDownAll(() {
    TestHelper.tearDown();
  });

  group('Live Financial Calculations Tests', () {
    late MarketingUploadController controller;

    setUp(() {
      Get.reset();
      controller = Get.put(MarketingUploadController());
    });

    test('Initial product row calculates correct base values', () {
      expect(controller.items.length, 1);
      expect(controller.subTotal.value, 2500.0);
      expect(controller.taxAmount.value, 125.0);
      expect(controller.grandTotal.value, 2625.0);
      expect(controller.balanceDue.value, 2625.0);
    });

    test('Live calculation updates immediately on quantity change', () {
      controller.items[0].quantity.text = '20';
      expect(controller.subTotal.value, 5000.0);
      expect(controller.taxAmount.value, 250.0);
      expect(controller.grandTotal.value, 5250.0);
      expect(controller.balanceDue.value, 5250.0);
    });

    test('Live calculation updates immediately on unit price change', () {
      controller.items[0].quantity.text = '10';
      controller.items[0].orderValue.text = '300';
      expect(controller.subTotal.value, 3000.0);
      expect(controller.taxAmount.value, 150.0);
      expect(controller.grandTotal.value, 3150.0);
    });

    test('Live calculation updates immediately on GST percentage change', () {
      controller.items[0].quantity.text = '10';
      controller.items[0].orderValue.text = '100';
      controller.items[0].gstInfo.text = '18';
      expect(controller.subTotal.value, 1000.0);
      expect(controller.taxAmount.value, 180.0);
      expect(controller.grandTotal.value, 1180.0);
    });

    test('Live calculation updates on advance payment change', () {
      controller.items[0].quantity.text = '10';
      controller.items[0].orderValue.text = '250';
      controller.items[0].gstInfo.text = '5';
      controller.advanceAmount.text = '1000';
      expect(controller.balanceDue.value, 1625.0);

      controller.advanceAmount.text = '2625';
      expect(controller.balanceDue.value, 0.0);
    });

    test('Live calculation updates on shipping charge change', () {
      controller.items[0].quantity.text = '10';
      controller.items[0].orderValue.text = '100';
      controller.items[0].gstInfo.text = '0';
      controller.shippingCharge.text = '150';
      expect(controller.grandTotal.value, 1150.0);
      expect(controller.balanceDue.value, 1150.0);
    });

    test('Adding multiple product items accumulates correctly', () {
      controller.items[0].quantity.text = '10';
      controller.items[0].orderValue.text = '100';
      controller.items[0].gstInfo.text = '5';

      controller.addNewItem();
      expect(controller.items.length, 2);
      expect(controller.subTotal.value, 1000.0 + 2500.0);
      expect(controller.taxAmount.value, 50.0 + 125.0);
      expect(controller.grandTotal.value, 1050.0 + 2625.0);

      controller.items[1].quantity.text = '5';
      controller.items[1].orderValue.text = '200';
      controller.items[1].gstInfo.text = '12';
      expect(controller.subTotal.value, 2000.0);
      expect(controller.taxAmount.value, 170.0);
      expect(controller.grandTotal.value, 2170.0);
    });

    test('Removing product item immediately deducts from totals', () {
      controller.items[0].quantity.text = '10';
      controller.items[0].orderValue.text = '100';
      controller.items[0].gstInfo.text = '0';

      controller.addNewItem();
      controller.items[1].quantity.text = '5';
      controller.items[1].orderValue.text = '200';
      controller.items[1].gstInfo.text = '0';

      expect(controller.subTotal.value, 2000.0);

      controller.removeItem(1);
      expect(controller.items.length, 1);
      expect(controller.subTotal.value, 1000.0);
      expect(controller.grandTotal.value, 1000.0);
    });

    test('Empty or clearing numeric fields safely behaves as zero without crashing', () {
      controller.items[0].quantity.text = '';
      controller.items[0].orderValue.text = '';
      controller.items[0].gstInfo.text = '';
      controller.shippingCharge.text = '';
      controller.advanceAmount.text = '';

      expect(controller.subTotal.value, 0.0);
      expect(controller.taxAmount.value, 0.0);
      expect(controller.grandTotal.value, 0.0);
      expect(controller.balanceDue.value, 0.0);
    });

    test('Decimal values calculate precisely', () {
      controller.items[0].quantity.text = '2.5';
      controller.items[0].orderValue.text = '199.50';
      controller.items[0].gstInfo.text = '18.0';
      controller.shippingCharge.text = '49.99';
      controller.advanceAmount.text = '100.00';

      expect(controller.subTotal.value, closeTo(498.75, 0.001));
      expect(controller.taxAmount.value, closeTo(89.775, 0.001));
      expect(controller.grandTotal.value, closeTo(638.515, 0.001));
      expect(controller.balanceDue.value, closeTo(538.515, 0.001));
    });
  });
}
