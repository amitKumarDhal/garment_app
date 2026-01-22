import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FinishingController extends GetxController {
  static FinishingController get instance => Get.find();

  final formKey = GlobalKey<FormState>();
  final isLoading = false.obs;

  // --- Input Controllers ---
  final checkerName = TextEditingController(); // Who checked/packed it
  final styleNo = TextEditingController();

  // Quantities
  final receivedQty = TextEditingController(); // Qty received from stitching
  final ironedQty = TextEditingController();
  final packedQty = TextEditingController();
  final defectiveQty = TextEditingController(); // Rejections at final stage

  // --- Logic ---
  Future<void> submitFinishingEntry() async {
    if (!formKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      // Calculate Net Good Pieces ready for shipment
      int packed = int.tryParse(packedQty.text) ?? 0;
      int defective = int.tryParse(defectiveQty.text) ?? 0;

      await FirebaseFirestore.instance.collection('finishing_entries').add({
        "checkerName": checkerName.text.trim(),
        "styleNo": styleNo.text.trim(),
        "receivedQty": int.tryParse(receivedQty.text) ?? 0,
        "ironedQty": int.tryParse(ironedQty.text) ?? 0,
        "packedQty": packed,
        "defectiveQty": defective,
        "timestamp": FieldValue.serverTimestamp(),
        "status": "Ready for Shipment",
      });

      Get.snackbar(
        "Shipment Ready",
        "Style ${styleNo.text} - $packed Pcs Packed",
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );

      _clearFields();
      Get.back(); // Return to menu
    } catch (e) {
      Get.snackbar("Error", "Could not save entry: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _clearFields() {
    checkerName.clear();
    styleNo.clear();
    receivedQty.clear();
    ironedQty.clear();
    packedQty.clear();
    defectiveQty.clear();
  }

  @override
  void onClose() {
    checkerName.dispose();
    styleNo.dispose();
    receivedQty.dispose();
    ironedQty.dispose();
    packedQty.dispose();
    defectiveQty.dispose();
    super.onClose();
  }
}
