import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/api_service.dart';

class InventoryController extends GetxController {
  var inventoryItems = <Map<String, dynamic>>[].obs;
  var currentUserRole = 'UNIT_SUPERVISOR'.obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchInventory();
  }

  Future<void> fetchInventory() async {
    try {
      isLoading.value = true;
      final user = ApiService.currentUser;
      if (user != null) {
        currentUserRole.value = (user['role'] ?? 'UNIT_SUPERVISOR').toString();
      }

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

  Future<void> fetchInventoryData({bool showSpinner = true}) async => await fetchInventory();
  List<String> get fabricTypes => ['PC Matty', 'Spun Matty', 'Nokia', 'Dotknit'];
  List<String> get colors => ['Black', 'White', 'Navy', 'Red', 'Royal Blue'];
  List<Map<String, dynamic>> get filteredStock => inventoryItems;
  List<Map<String, dynamic>> get filteredLogs => inventoryItems;
  void updateSearch(String query) {}

  Future<void> addTransaction({dynamic type, dynamic color, dynamic action, dynamic quantity}) async {}
  var currentView = 'Overview'.obs;
  void setView(String v) => currentView.value = v;
}