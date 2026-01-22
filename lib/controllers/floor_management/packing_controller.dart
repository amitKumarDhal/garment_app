import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PackingController extends GetxController {
  static PackingController get instance => Get.find();

  final packingFormKey = GlobalKey<FormState>();

  // 📦 Carton Identification
  final cartonNo = TextEditingController();

  // Optional: Add Style No if you need to track which style is in the carton
  final styleNo = TextEditingController();

  // 📏 Category selection for the entire carton
  var selectedCartonSize = 'M'.obs;
  final List<String> sizeOptions = ['S', 'M', 'L', 'XL', 'XXL'];

  // 📝 Live Inventory List (Synced from Firestore)
  var inventoryList = <Map<String, dynamic>>[].obs;

  // 📊 Specific quantities inside the carton
  final Map<String, TextEditingController> boxContents = {
    'S': TextEditingController(),
    'M': TextEditingController(),
    'L': TextEditingController(),
    'XL': TextEditingController(),
    'XXL': TextEditingController(),
  };

  final RxInt totalInBox = 0.obs;
  final RxBool isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    _bindInventoryStream(); // Start listening to Firestore immediately
  }

  // --- 1. REAL-TIME FIRESTORE LISTENER ---
  void _bindInventoryStream() {
    FirebaseFirestore.instance
        .collection('packing_entries')
        .orderBy('timestamp', descending: true)
        .snapshots() // This creates the live connection
        .listen(
          (snapshot) {
            inventoryList.value = snapshot.docs
                .map((doc) => doc.data())
                .toList();
          },
          onError: (e) {
            print("Error fetching inventory: $e");
          },
        );
  }

  // --- 2. COMPUTED STATS (Now use real firestore data) ---
  int get countSmall => inventoryList.where((c) => c['category'] == 'S').length;
  int get countMedium =>
      inventoryList.where((c) => c['category'] == 'M').length;
  int get countLarge => inventoryList.where((c) => c['category'] == 'L').length;
  int get countXL => inventoryList.where((c) => c['category'] == 'XL').length;
  int get countXXL => inventoryList.where((c) => c['category'] == 'XXL').length;

  int get totalPiecesInFactory => inventoryList.fold(
    0,
    (sum, item) => sum + (item['totalPieces'] as int? ?? 0),
  );

  // --- 3. CALCULATION LOGIC ---
  void calculateBoxTotal() {
    int sum = 0;
    for (final controller in boxContents.values) {
      if (controller.text.isNotEmpty) {
        sum += int.tryParse(controller.text) ?? 0;
      }
    }
    totalInBox.value = sum;
  }

  // --- 4. SUBMIT TO CLOUD ---
  Future<void> submitCarton() async {
    if (!packingFormKey.currentState!.validate()) return;

    // Ensure calculation is up to date before submit
    calculateBoxTotal();

    if (totalInBox.value == 0) {
      Get.snackbar(
        "Error",
        "Carton cannot be empty",
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return;
    }

    isSubmitting.value = true;

    try {
      // Create the data object
      final newEntry = {
        "cartonNo": cartonNo.text.trim(),
        "styleNo": styleNo.text.trim(), // Optional but recommended
        "category": selectedCartonSize.value,
        "totalPieces": totalInBox.value,
        // Save the detailed breakdown too
        "breakdown": {
          "S": int.tryParse(boxContents['S']!.text) ?? 0,
          "M": int.tryParse(boxContents['M']!.text) ?? 0,
          "L": int.tryParse(boxContents['L']!.text) ?? 0,
          "XL": int.tryParse(boxContents['XL']!.text) ?? 0,
          "XXL": int.tryParse(boxContents['XXL']!.text) ?? 0,
        },
        "timestamp": FieldValue.serverTimestamp(), // Use Server Time
        "status": "Packed",
      };

      // Write to Firestore
      await FirebaseFirestore.instance
          .collection('packing_entries')
          .add(newEntry);

      Get.snackbar(
        "Inventory Updated",
        "Carton ${cartonNo.text} synced to Cloud.",
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );

      _resetForm();
    } catch (e) {
      Get.snackbar(
        "Error",
        "Cloud sync failed: $e",
        backgroundColor: Colors.red.withOpacity(0.1),
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  void _resetForm() {
    cartonNo.clear();
    styleNo.clear();
    for (final controller in boxContents.values) {
      controller.clear();
    }
    totalInBox.value = 0;
    // Don't reset selectedCartonSize, user might be packing multiple of same size
  }

  @override
  void onClose() {
    cartonNo.dispose();
    styleNo.dispose();
    for (var c in boxContents.values) {
      c.dispose();
    }
    super.onClose();
  }
}
