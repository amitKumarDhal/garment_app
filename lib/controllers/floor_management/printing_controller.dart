import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PrintingController extends GetxController {
  final printingFormKey = GlobalKey<FormState>();

  // 1. References from Cutting (To be fetched from DB later)
  final styleNo = TextEditingController();
  final receivedFromCutting = TextEditingController(); // e.g., 100 pieces

  // 2. Printing Specific Inputs
  final printingMachineNo = TextEditingController();
  final inkType = TextEditingController();

  // 3. Size-Wise "Damaged" Logic
  // We track damages per size to identify where the printing press is failing
  var damagedQuantities = <String, TextEditingController>{
    'S': TextEditingController(),
    'M': TextEditingController(),
    'L': TextEditingController(),
    'XL': TextEditingController(),
  }.obs;

  // 4. Calculations
  RxInt totalDamaged = 0.obs;
  RxInt netGoodPieces = 0.obs;

  void calculatePrintingTotals() {
    int damageSum = 0;
    damagedQuantities.forEach((size, controller) {
      if (controller.text.isNotEmpty) {
        damageSum += int.tryParse(controller.text) ?? 0;
      }
    });
    totalDamaged.value = damageSum;

    // Net Pieces = Received - Damaged
    int received = int.tryParse(receivedFromCutting.text) ?? 0;
    netGoodPieces.value = received - totalDamaged.value;
  }

  void submitPrintingData() {
    if (printingFormKey.currentState!.validate()) {
      Get.snackbar(
        "Printing Updated",
        "Total Good Pieces: ${netGoodPieces.value}. Sending to Stitching...",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.purple.withOpacity(0.1),
        colorText: Colors.purple,
      );
      // Future: Firebase Update call here
    }
  }

  @override
  void onClose() {
    styleNo.dispose();
    receivedFromCutting.dispose();
    printingMachineNo.dispose();
    inkType.dispose();
    damagedQuantities.forEach((_, c) => c.dispose());
    super.onClose();
  }
}
