import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StitchingController extends GetxController {
  final stitchingFormKey = GlobalKey<FormState>();

  // 1. Assignment Details
  final workerName = TextEditingController();
  final styleNo = TextEditingController();
  final operationType = TextEditingController(); // e.g., Side Seam, Neck, etc.

  // 2. Production Tracking
  final assignedQty = TextEditingController();
  final completedQty = TextEditingController();
  final rejectedQty = TextEditingController();

  // 3. Worker List (Dummy data until we use Firebase)
  var availableWorkers = <String>[
    "Worker 001 - Rahul",
    "Worker 002 - Priya",
    "Worker 003 - Amit",
    "Worker 004 - Suman",
  ].obs;

  // 4. Summary Calculations
  RxInt balanceQty = 0.obs;
  RxDouble efficiency = 0.0.obs;

  void calculateStitchingStats() {
    int assigned = int.tryParse(assignedQty.text) ?? 0;
    int completed = int.tryParse(completedQty.text) ?? 0;
    int rejected = int.tryParse(rejectedQty.text) ?? 0;

    // Remaining = Total - (Completed + Rejected)
    balanceQty.value = assigned - (completed + rejected);

    // Efficiency = (Completed / Assigned) * 100
    if (assigned > 0) {
      efficiency.value = (completed / assigned) * 100;
    }
  }

  void submitStitchingEntry() {
    if (stitchingFormKey.currentState!.validate()) {
      Get.snackbar(
        "Production Saved",
        "Record for ${workerName.text} added to Daily Log.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );
      // Logic to push to a 'Daily Production List' will go here
    }
  }

  @override
  void onClose() {
    workerName.dispose();
    styleNo.dispose();
    operationType.dispose();
    assignedQty.dispose();
    completedQty.dispose();
    rejectedQty.dispose();
    super.onClose();
  }
}
