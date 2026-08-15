import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/api_service.dart';

class CuttingController extends GetxController {
  final styleNo = TextEditingController();
  final lotNo = TextEditingController();
  final fabricType = TextEditingController();
  final consumption = TextEditingController();

  final sizeControllers = <String, TextEditingController>{}.obs;
  final totalQuantity = 0.obs;

  final isLoading = false.obs;

  void updateSizeQuantity(String size, String value) {
    if (!sizeControllers.containsKey(size)) {
      sizeControllers[size] = TextEditingController();
    }
    sizeControllers[size]!.text = value;

    int total = 0;
    sizeControllers.forEach((_, controller) {
      final val = int.tryParse(controller.text.trim()) ?? 0;
      total += val;
    });
    totalQuantity.value = total;
  }

  Future<void> submitCuttingEntry(String? orderId) async {
    if (styleNo.text.trim().isEmpty || fabricType.text.trim().isEmpty) {
      Get.snackbar("Error", "Please fill required fields", backgroundColor: Colors.red.withValues(alpha: 0.1));
      return;
    }

    try {
      isLoading.value = true;
      final cons = double.tryParse(consumption.text.trim()) ?? 0.0;
      final sizesMap = <String, int>{};
      sizeControllers.forEach((size, controller) {
        sizesMap[size] = int.tryParse(controller.text.trim()) ?? 0;
      });

      final res = await ApiService.post('/production/cutting', {
        'order_id': orderId,
        'style_no': styleNo.text.trim(),
        'lot_no': lotNo.text.trim(),
        'fabric_type': fabricType.text.trim(),
        'consumption': cons,
        'total_fabric_used': totalQuantity.value * cons,
        'sizes': sizesMap,
        'total_quantity': totalQuantity.value,
      });

      if (res['success'] == true) {
        Get.snackbar("Success", "Cutting entry recorded successfully", backgroundColor: Colors.green.withValues(alpha: 0.1));
        Get.back();
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to submit entry: $e", backgroundColor: Colors.red.withValues(alpha: 0.1));
    } finally {
      isLoading.value = false;
    }
  }

  final cuttingFormKey = GlobalKey<FormState>();
  final sizeQuantities = <String, TextEditingController>{
    'S': TextEditingController(),
    'M': TextEditingController(),
    'L': TextEditingController(),
    'XL': TextEditingController(),
    'XXL': TextEditingController(),
  };

  void calculateTotal() {
    int total = 0;
    sizeQuantities.forEach((_, ctrl) {
      total += int.tryParse(ctrl.text.trim()) ?? 0;
    });
    totalQuantity.value = total;
  }

  Future<void> submitCuttingData() async => await submitCuttingEntry(null);
}
