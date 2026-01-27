import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PrintingController extends GetxController {
  final printingFormKey = GlobalKey<FormState>();
  final isLoading = false.obs;

  final styleNo = TextEditingController();
  final receivedFromCutting = TextEditingController();

  // Size-wise damage controllers
  var damagedQuantities = <String, TextEditingController>{
    'S': TextEditingController(),
    'M': TextEditingController(),
    'L': TextEditingController(),
    'XL': TextEditingController(),
  }.obs;

  RxInt totalDamaged = 0.obs;
  RxInt netGoodPieces = 0.obs;

  void calculatePrintingTotals() {
    int damageSum = 0;
    damagedQuantities.forEach((size, controller) {
      damageSum += int.tryParse(controller.text) ?? 0;
    });
    totalDamaged.value = damageSum;

    int received = int.tryParse(receivedFromCutting.text) ?? 0;
    netGoodPieces.value = received - totalDamaged.value;
  }

  Future<void> submitPrintingData() async {
    if (!printingFormKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      // Prepare map for database
      Map<String, int> damageData = {};
      damagedQuantities.forEach((size, controller) {
        damageData[size] = int.tryParse(controller.text) ?? 0;
      });

      // Save to Firestore
      await FirebaseFirestore.instance.collection('printing_entries').add({
        "styleNo": styleNo.text.trim(),
        "receivedFromCutting": int.tryParse(receivedFromCutting.text) ?? 0,
        "damagedQuantities": damageData,
        "totalDamaged": totalDamaged.value,
        "netGoodPieces": netGoodPieces.value,
        "timestamp": FieldValue.serverTimestamp(),
        "status": "Printing Completed",
      });

      Get.snackbar(
        "Success",
        "Sent ${netGoodPieces.value} pieces to Stitching",
        backgroundColor: Colors.green.withValues(alpha: 0.1),
        colorText: Colors.green,
      );

      _clearFields();
      Get.back();
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void _clearFields() {
    for (var c in [styleNo, receivedFromCutting]) {
      c.clear();
    }
    damagedQuantities.forEach((_, c) => c.clear());
    totalDamaged.value = 0;
    netGoodPieces.value = 0;
  }

  @override
  void onClose() {
    // Memory disposal for 8GB RAM performance
    for (var c in [styleNo, receivedFromCutting]) {
      c.dispose();
    }
    damagedQuantities.forEach((_, c) => c.dispose());
    super.onClose();
  }
}
