import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PackingController extends GetxController {
  final packingFormKey = GlobalKey<FormState>();

  // 1. Shipment Details
  final styleNo = TextEditingController();
  final destination =
      TextEditingController(); // e.g., "Dubai Store", "New York Warehouse"
  final cartonNo = TextEditingController();

  // 2. Quantity Breakdown (Carton Packing List)
  // Tracking how many of each size are inside this specific box
  var boxContents = <String, TextEditingController>{
    'S': TextEditingController(),
    'M': TextEditingController(),
    'L': TextEditingController(),
    'XL': TextEditingController(),
  }.obs;

  // 3. Totals
  RxInt totalInBox = 0.obs;

  void calculateBoxTotal() {
    int sum = 0;
    boxContents.forEach((size, controller) {
      if (controller.text.isNotEmpty) {
        sum += int.tryParse(controller.text) ?? 0;
      }
    });
    totalInBox.value = sum;
  }

  void submitCarton() {
    if (packingFormKey.currentState!.validate()) {
      Get.snackbar(
        "Carton Sealed",
        "Carton #${cartonNo.text} recorded with ${totalInBox.value} pieces.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue.withOpacity(0.1),
        colorText: Colors.blue,
      );
      // Clear for next carton
      cartonNo.clear();
      boxContents.forEach((_, c) => c.clear());
      totalInBox.value = 0;
    }
  }

  @override
  void onClose() {
    styleNo.dispose();
    destination.dispose();
    cartonNo.dispose();
    boxContents.forEach((_, c) => c.dispose());
    super.onClose();
  }
}
