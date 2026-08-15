import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/order_model.dart';
import '../../data/services/api_service.dart';

class ManagerController extends GetxController {
  var pendingOrders = <OrderModel>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPendingOrders();
  }

  Future<void> fetchPendingOrders() async {
    try {
      isLoading.value = true;
      final res = await ApiService.get('/orders');
      if (res['success'] == true && res['orders'] != null) {
        final list = List<Map<String, dynamic>>.from(res['orders']);
        final orders = list.map((e) => OrderModel.fromJson(e)).where((o) => o.status.toLowerCase() == 'pending').toList();
        pendingOrders.assignAll(orders);
      }
    } catch (e) {
      debugPrint("Fetch Manager Pending Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> approveOrder(String orderId) async {
    try {
      final res = await ApiService.post('/orders/$orderId/approve', {});
      if (res['success'] == true) {
        fetchPendingOrders();
        Get.snackbar("Approved", "Order approved successfully", backgroundColor: Colors.green, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", "Could not approve order: $e");
    }
  }
}
