import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/api_service.dart';

class StockInOutController extends GetxController {
  final fabricType = TextEditingController();
  final color = TextEditingController();
  final quantity = TextEditingController();
  final actionType = 'IN'.obs;
  final isLoading = false.obs;

  Future<void> recordTransaction() async {
    if (fabricType.text.trim().isEmpty || color.text.trim().isEmpty || quantity.text.trim().isEmpty) {
      Get.snackbar("Error", "Please fill required fields");
      return;
    }

    try {
      isLoading.value = true;
      final user = ApiService.currentUser;
      final addedBy = user != null ? (user['name'] ?? user['FullName'] ?? 'Supervisor') : 'Supervisor';

      final res = await ApiService.post('/inventory/transactions', {
        'fabric_type': fabricType.text.trim(),
        'color': color.text.trim(),
        'action': actionType.value,
        'quantity': double.tryParse(quantity.text.trim()) ?? 0.0,
        'unit': 'KG',
        'added_by': addedBy,
      });

      if (res['success'] == true) {
        Get.snackbar("Success", "Inventory transaction recorded", backgroundColor: Colors.green.withValues(alpha: 0.1));
        Get.back();
      }
    } catch (e) {
      Get.snackbar("Error", "Failed: $e");
    } finally {
      isLoading.value = false;
    }
  }

  var selectedDate = DateTime.now().obs;
  var selectedTransactionType = 'Stock In'.obs;
  var recentHistory = <Map<String, dynamic>>[].obs;
  var visibleLogCount = 10.obs;
  var selectedColor = ''.obs;
  var currentBalance = 0.0.obs;
  var isFetchingBalance = false.obs;
  bool isPcs = false;

  final vendorController = TextEditingController();
  final challanNoController = TextEditingController();
  final remarksController = TextEditingController();
  final ribQtyController = TextEditingController();
  TextEditingController get qtyController => quantity;

  final selectedFabricCategory = 'Standard Fabric'.obs;
  final selectedFabricType = ''.obs;
  final selectedRibStyle = 'Solid color'.obs;
  final selectedRibColor = ''.obs;

  List<String> get fabricTypes => ['PC Matty', 'Spun Matty', 'Nokia', 'Dotknit'];
  List<String> get colors => ['Black', 'White', 'Navy', 'Red', 'Royal Blue'];
  List<Map<String, dynamic>> get allColors => [
    {'name': 'Black', 'color': Colors.black},
    {'name': 'White', 'color': Colors.white},
    {'name': 'Navy', 'color': Colors.indigo},
    {'name': 'Red', 'color': Colors.red},
    {'name': 'Royal Blue', 'color': Colors.blue},
  ];
  List<String> get collarStyles => ['Solid color', 'Tipping', 'Jacquard'];

  void updateType(String type) => selectedTransactionType.value = type;
  void setSelectedFabricType(String type) => selectedFabricType.value = type;
  void setSelectedColor(String c) {
    color.text = c;
    selectedColor.value = c;
  }

  var hasRib = false.obs;
  var selectedProduct = ''.obs;
  var selectedCollarStyle = 'Solid color'.obs;

  List<String> get transactionTypes => ['Stock In', 'Stock Out'];
  List<String> get products => ['Round Neck T-Shirt', 'Polo T-Shirt', 'Hoodie', 'Sweatshirt'];

  void resetFields() {
    fabricType.clear();
    color.clear();
    quantity.clear();
    vendorController.clear();
    challanNoController.clear();
    remarksController.clear();
  }

  Future<void> submitStock() async => await recordTransaction();

  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) selectedDate.value = picked;
  }
}