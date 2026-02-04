import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PackingController extends GetxController {
  static PackingController get instance => Get.find();

  final packingFormKey = GlobalKey<FormState>();

  // --- Input Controllers ---
  final cartonNo = TextEditingController();
  final styleNo = TextEditingController();

  // --- State Variables ---
  var selectedCartonSize = 'M'.obs;
  final List<String> sizeOptions = ['S', 'M', 'L', 'XL', 'XXL'];

  // --- Inventory Data (Live from Firestore) ---
  var inventoryList = <Map<String, dynamic>>[].obs;

  // --- SEARCH & FILTER STATE ---
  final RxString searchQuery = ''.obs;
  final RxString activeFilter = 'All'.obs;

  List<Map<String, dynamic>> get filteredInventory {
    return inventoryList.where((item) {
      final query = searchQuery.value.toLowerCase();
      final cNo = item['cartonNo']?.toString().toLowerCase() ?? '';
      final sNo = item['styleNo']?.toString().toLowerCase() ?? '';
      bool matchesSearch = cNo.contains(query) || sNo.contains(query);
      bool matchesFilter =
          activeFilter.value == 'All' || item['category'] == activeFilter.value;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  // --- Input Grid Controllers ---
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
    _bindInventoryStream();
  }

  void _bindInventoryStream() {
    FirebaseFirestore.instance
        .collection('packing_entries')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .listen(
          (snapshot) {
            inventoryList.value = snapshot.docs
                .map((doc) => doc.data())
                .toList();
          },
          onError: (e) {
            if (kDebugMode) print("Firestore Error: $e");
          },
        );
  }

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

  void calculateBoxTotal() {
    int sum = 0;
    for (final controller in boxContents.values) {
      if (controller.text.isNotEmpty) sum += int.tryParse(controller.text) ?? 0;
    }
    totalInBox.value = sum;
  }

  void clearForm() {
    cartonNo.clear();
    styleNo.clear();
    for (final controller in boxContents.values) controller.clear();
    totalInBox.value = 0;
  }

  // --- ✅ UPDATED SUBMIT LOGIC ---
  Future<void> submitCarton() async {
    if (!packingFormKey.currentState!.validate()) return;
    calculateBoxTotal();

    if (totalInBox.value == 0) {
      Get.snackbar(
        "Error",
        "Carton cannot be empty",
        backgroundColor: Colors.red.withOpacity(0.1),
      );
      return;
    }

    isSubmitting.value = true;
    final firestore = FirebaseFirestore.instance;

    try {
      final newEntry = {
        "cartonNo": cartonNo.text.trim(),
        "styleNo": styleNo.text.trim(),
        "category": selectedCartonSize.value,
        "totalPieces": totalInBox.value,
        "breakdown": {
          "S": int.tryParse(boxContents['S']!.text) ?? 0,
          "M": int.tryParse(boxContents['M']!.text) ?? 0,
          "L": int.tryParse(boxContents['L']!.text) ?? 0,
          "XL": int.tryParse(boxContents['XL']!.text) ?? 0,
          "XXL": int.tryParse(boxContents['XXL']!.text) ?? 0,
        },
        "timestamp": FieldValue.serverTimestamp(),
        "status": "Packed",
      };

      // 1. Save detailed entry
      await firestore.collection('packing_entries').add(newEntry);

      // ✅ 2. BROADCAST TO LIVE FEED
      await firestore.collection('activities').add({
        "title": "Packed: ${styleNo.text.trim()}",
        "subtitle": "Carton ${cartonNo.text} (${totalInBox.value} Pcs)",
        "time": FieldValue.serverTimestamp(),
        "iconCode": Icons.inventory_2.codePoint,
        "colorValue": Colors.brown.value,
      });

      Get.toNamed('/factory-stock-summary');

      Get.snackbar(
        "Success",
        "Carton ${cartonNo.text} Added to Factory Stock",
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      clearForm();
    } catch (e) {
      Get.snackbar(
        "Error",
        "Save failed: $e",
        backgroundColor: Colors.red.withOpacity(0.1),
      );
    } finally {
      isSubmitting.value = false;
    }
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
