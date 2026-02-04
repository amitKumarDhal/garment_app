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

  // ✅ NEW: Consumption Controller (Meters per piece)
  final consumption = TextEditingController();

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

  /// --- Submit Logic with Inventory Check & Deduction ---
  Future<void> submitCuttingData() async {
    if (!cuttingFormKey.currentState!.validate()) return;

    // Ensure calculation is fresh
    calculateTotal();

    if (totalQuantity.value == 0) {
      Get.snackbar(
        "Error",
        "Total quantity cannot be zero",
        backgroundColor: Colors.red.withValues(alpha: 0.1),
      );
      return;
    }

    // Validate Consumption
    double cons = double.tryParse(consumption.text) ?? 0.0;
    if (cons <= 0) {
      Get.snackbar(
        "Error",
        "Please enter valid consumption (e.g., 1.5)",
        backgroundColor: Colors.red.withValues(alpha: 0.1),
      );
      return;
    }

    try {
      isLoading.value = true;
      final firestore = FirebaseFirestore.instance;
      final fabricName = fabricType.text.trim();

      // Calculate total fabric needed
      final double totalFabricNeeded = totalQuantity.value * cons;

      // --- 1. 🔍 CHECK INVENTORY STOCK ---
      final inventorySnapshot = await firestore
          .collection('inventory')
          .where(
            'name',
            isEqualTo: fabricName,
          ) // Must match exact name in Inventory
          .limit(1)
          .get();

      if (inventorySnapshot.docs.isEmpty) {
        throw "Fabric '$fabricName' not found in Inventory. Please add stock first.";
      }

      final stockDoc = inventorySnapshot.docs.first;
      double currentStock = (stockDoc['quantity'] as num).toDouble();

      // --- 2. 🛑 VALIDATE SUFFICIENT STOCK ---
      if (currentStock < totalFabricNeeded) {
        throw "Insufficient Stock! Needed: ${totalFabricNeeded}m, Available: ${currentStock}m";
      }

      // --- 3. 📉 DEDUCT STOCK ---
      await stockDoc.reference.update({
        'quantity': currentStock - totalFabricNeeded,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // --- 4. 💾 SAVE CUTTING ENTRY ---
      Map<String, int> sizeData = {};
      sizeQuantities.forEach((size, controller) {
        sizeData[size] = int.tryParse(controller.text) ?? 0;
      });

      await firestore.collection('cutting_entries').add({
        "styleNo": styleNo.text.trim(),
        "lotNo": lotNo.text.trim(),
        "fabricType": fabricName,
        "consumption": cons, // Record how much used per pc
        "totalFabricUsed": totalFabricNeeded, // Record total deducted
        "sizes": sizeData,
        "totalQuantity": totalQuantity.value,
        "entryDate": DateTime.now(),
        "status": "Cut Completed",
        "timestamp": FieldValue.serverTimestamp(),
      });

      // --- 5. 📡 BROADCAST TO LIVE FEED ---
      await firestore.collection('activities').add({
        "title": "Cutting: ${styleNo.text.trim()}",
        "subtitle":
            "Used ${totalFabricNeeded.toStringAsFixed(1)}m of $fabricName",
        "time": FieldValue.serverTimestamp(),
        "iconCode": Icons.content_cut.codePoint,
        "colorValue": Colors.blue.value,
      });

      Get.snackbar(
        "Success",
        "Stock Deducted: ${totalFabricNeeded}m. Batch Recorded!",
        backgroundColor: Colors.green.withValues(alpha: 0.1),
        colorText: Colors.green,
        snackPosition: SnackPosition.BOTTOM,
      );

      _clearFields();
      Get.back(); // Return to Supervisor Menu
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        duration: const Duration(seconds: 4), // Longer duration to read error
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _clearFields() {
    for (var c in [styleNo, lotNo, fabricType, consumption]) {
      c.clear();
    }
    for (var c in sizeQuantities.values) {
      c.clear();
    }
    totalQuantity.value = 0;
  }

  @override
  void onClose() {
    // Crucial memory cleanup for 8GB RAM
    for (var c in [styleNo, lotNo, fabricType, consumption]) {
      c.dispose();
    }
    for (var c in sizeQuantities.values) {
      c.dispose();
    }
    super.onClose();
  }
}
