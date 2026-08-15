import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/api_service.dart';

class StockSummaryController extends GetxController {
  var inventoryItems = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchInventory();
  }

  Future<void> fetchInventory() async {
    try {
      isLoading.value = true;
      final res = await ApiService.get('/inventory');
      if (res['success'] == true && res['inventory'] != null) {
        inventoryItems.assignAll(List<Map<String, dynamic>>.from(res['inventory']));
      }
    } catch (e) {
      debugPrint("Fetch Inventory Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  var selectedCategory = 'All'.obs;
  void updateCategory(String cat) => selectedCategory.value = cat;
  List<Map<String, dynamic>> get groupedStock => inventoryItems;
  List<String> get categories => ['All', 'Standard Fabric', 'Rib Fabric'];
  void updateSearch(String query) {}
}