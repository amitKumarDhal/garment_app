import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CuttingController extends GetxController {
  static CuttingController get instance => Get.find();

  final cuttingFormKey = GlobalKey<FormState>();

  // --- Form Field Controllers ---
  final styleNo = TextEditingController();
  final lotNo = TextEditingController();
  final fabricType = TextEditingController();

  // Observable map for size-wise quantities
  final sizeQuantities = <String, TextEditingController>{
    'S': TextEditingController(),
    'M': TextEditingController(),
    'L': TextEditingController(),
    'XL': TextEditingController(),
  }.obs;

  RxInt totalQuantity = 0.obs;
  final isLoading = false.obs;

  /// Calculates total quantity across all size fields
  void calculateTotal() {
    int sum = 0;
    for (var controller in sizeQuantities.values) {
      sum += int.tryParse(controller.text) ?? 0;
    }
    totalQuantity.value = sum;
  }

  /// --- Submit Logic with Firestore Integration ---
  Future<void> submitCuttingData() async {
    if (!cuttingFormKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      // Prepare size-wise map for database storage
      Map<String, int> sizeData = {};
      sizeQuantities.forEach((size, controller) {
        sizeData[size] = int.tryParse(controller.text) ?? 0;
      });

      // Save entry to Cloud Firestore
      await FirebaseFirestore.instance.collection('cutting_entries').add({
        "styleNo": styleNo.text.trim(),
        "lotNo": lotNo.text.trim(),
        "fabricType": fabricType.text.trim(),
        "sizes": sizeData,
        "totalQuantity": totalQuantity.value,
        "entryDate": DateTime.now(),
        "status": "Cut Completed",
        "timestamp": FieldValue.serverTimestamp(), // Backend sorting
      });

      Get.snackbar(
        "Success",
        "Cutting for ${styleNo.text} recorded in Cloud!",
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
        snackPosition: SnackPosition.BOTTOM,
      );

      _clearFields();
      Get.back(); // Return to Supervisor Menu
    } catch (e) {
      Get.snackbar(
        "Error",
        "Cloud sync failed: $e",
        backgroundColor: Colors.red.withOpacity(0.1),
      );
    } finally {
      isLoading.value = false;
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
    // Crucial memory cleanup for 8GB RAM
    [styleNo, lotNo, fabricType].forEach((c) => c.dispose());
    for (var c in sizeQuantities.values) {
      c.dispose();
    }
    super.onClose();
  }
}
