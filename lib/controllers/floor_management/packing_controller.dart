import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/constants/colors.dart';

class PackingController extends GetxController {
  final packingFormKey = GlobalKey<FormState>();

  // 📦 Carton Identification
  final cartonNo = TextEditingController();

  // 📏 Category selection for the entire carton
  var selectedCartonSize = 'M'.obs;
  final List<String> sizeOptions = ['S', 'M', 'L', 'XL', 'XXL'];

  // 📝 Live Inventory List to reflect in the Stock Summary Screen
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

  // --- UPDATED: All Computed Stats for Factory Summary Screen ---
  int get countSmall => inventoryList.where((c) => c['category'] == 'S').length;
  int get countMedium =>
      inventoryList.where((c) => c['category'] == 'M').length;
  int get countLarge => inventoryList.where((c) => c['category'] == 'L').length;

  // Added these to fix your "undefined getter" errors:
  int get countXL => inventoryList.where((c) => c['category'] == 'XL').length;
  int get countXXL => inventoryList.where((c) => c['category'] == 'XXL').length;

  int get totalPiecesInFactory =>
      inventoryList.fold(0, (sum, item) => sum + (item['totalPieces'] as int));

  void calculateBoxTotal() {
    int sum = 0;
    for (final controller in boxContents.values) {
      if (controller.text.isNotEmpty) {
        sum += int.tryParse(controller.text) ?? 0;
      }
    }
    totalInBox.value = sum;
  }

  Future<void> submitCarton() async {
    if (!packingFormKey.currentState!.validate()) return;
    if (totalInBox.value == 0) {
      Get.snackbar(
        "Error",
        "Carton cannot be empty",
        backgroundColor: Colors.red.withOpacity(0.1),
      );
      return;
    }

    isSubmitting.value = true;

    try {
      final newEntry = {
        "cartonNo": cartonNo.text,
        "category": selectedCartonSize.value,
        "totalPieces": totalInBox.value,
        "timestamp": DateTime.now().toString(),
      };

      inventoryList.add(newEntry);

      print("Stock Updated: $newEntry");
      await Future.delayed(const Duration(milliseconds: 500));

      Get.snackbar(
        "Inventory Updated",
        "Added 1 ${selectedCartonSize.value} Size Carton to Stock",
        backgroundColor: TColors.packing.withOpacity(0.1),
        colorText: TColors.packing,
      );

      _resetForm();
    } finally {
      isSubmitting.value = false;
    }
  }

  void _resetForm() {
    cartonNo.clear();
    for (final controller in boxContents.values) {
      controller.clear();
    }
    totalInBox.value = 0;
  }

  @override
  void onClose() {
    cartonNo.dispose();
    for (var c in boxContents.values) {
      c.dispose();
    }
    super.onClose();
  }
}
