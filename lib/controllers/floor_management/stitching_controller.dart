import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StitchingController extends GetxController {
  static StitchingController get instance => Get.find();
  final stitchingFormKey = GlobalKey<FormState>();
  final isLoading = false.obs;

  // --- Input Controllers ---
  final workerName = TextEditingController();
  final styleNo = TextEditingController();
  final operationType = TextEditingController();

  final assignedQty = TextEditingController();
  final completedQty = TextEditingController();
  final rejectedQty = TextEditingController();

  // --- FIX: Re-adding the missing list for the Dropdown ---
  var availableWorkers = <String>[
    "Worker 001 - Rahul",
    "Worker 002 - Priya",
    "Worker 003 - Amit",
    "Worker 004 - Suman",
  ].obs;

  // --- Summary Calculations ---
  RxInt balanceQty = 0.obs;
  RxDouble efficiency = 0.0.obs;

  void calculateStitchingStats() {
    int assigned = int.tryParse(assignedQty.text) ?? 0;
    int completed = int.tryParse(completedQty.text) ?? 0;
    int rejected = int.tryParse(rejectedQty.text) ?? 0;

    balanceQty.value = assigned - (completed + rejected);

    if (assigned > 0) {
      efficiency.value = (completed / assigned) * 100;
    }
  }

  /// --- Submit Logic with Firestore Integration ---
  Future<void> submitStitchingEntry() async {
    if (!stitchingFormKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      // Save to 'stitching_entries' collection
      await FirebaseFirestore.instance.collection('stitching_entries').add({
        "workerName": workerName.text.trim(),
        "styleNo": styleNo.text.trim(),
        "operationType": operationType.text.trim(),
        "assignedQty": int.tryParse(assignedQty.text) ?? 0,
        "completedQty": int.tryParse(completedQty.text) ?? 0,
        "rejectedQty": int.tryParse(rejectedQty.text) ?? 0,
        "efficiency": efficiency.value,
        "timestamp": FieldValue.serverTimestamp(),
        "status": "Stitching Record Added",
      });

      Get.snackbar(
        "Production Saved",
        "Record for ${workerName.text} synced to Cloud.",
        backgroundColor: Colors.green.withValues(alpha: 0.1),
        colorText: Colors.green,
      );

      _clearFields();
      Get.back();
    } catch (e) {
      Get.snackbar("Error", "Cloud Update Failed: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _clearFields() {
    for (var c in [
      workerName,
      styleNo,
      operationType,
      assignedQty,
      completedQty,
      rejectedQty,
    ]) {
      c.clear();
    }
    balanceQty.value = 0;
    efficiency.value = 0.0;
  }

  @override
  void onClose() {
    // Memory disposal for 8GB RAM performance
    for (var c in [
      workerName,
      styleNo,
      operationType,
      assignedQty,
      completedQty,
      rejectedQty,
    ]) {
      c.dispose();
    }
    super.onClose();
  }
}
