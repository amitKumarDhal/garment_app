import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CuttingController extends GetxController {
  final cuttingFormKey = GlobalKey<FormState>();
  final styleNo = TextEditingController();
  final lotNo = TextEditingController();
  final fabricType = TextEditingController();

  final sizeQuantities = <String, TextEditingController>{
    'S': TextEditingController(),
    'M': TextEditingController(),
    'L': TextEditingController(),
    'XL': TextEditingController(),
  }.obs;

  RxInt totalQuantity = 0.obs;

  void calculateTotal() {
    int sum = 0;
    for (var controller in sizeQuantities.values) {
      sum += int.tryParse(controller.text) ?? 0;
    }
    totalQuantity.value = sum;
  }

  void submitCuttingData() {
    if (cuttingFormKey.currentState!.validate()) {
      Get.snackbar(
        "Success",
        "Cutting for ${styleNo.text} recorded locally!",
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );
      _clearFields();
    }
  }

  void _clearFields() {
    [styleNo, lotNo, fabricType].forEach((c) => c.clear());
    for (var c in sizeQuantities.values) {
      c.clear();
    }
    totalQuantity.value = 0;
  }

  @override
  void onClose() {
    [styleNo, lotNo, fabricType].forEach((c) => c.dispose());
    for (var c in sizeQuantities.values) {
      c.dispose();
    }
    super.onClose();
  }
}
