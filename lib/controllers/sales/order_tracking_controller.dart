import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/order_model.dart';
import '../../data/services/api_service.dart';

class OrderTrackingController extends GetxController {
  var searchedOrder = Rxn<OrderModel>();
  var isLoading = false.obs;
  var hasSearched = false.obs;
  final searchController = TextEditingController();

  Future<void> searchOrder(String query) async {
    if (query.trim().isEmpty) {
      Get.snackbar("Error", "Please enter Order Number or Client Name");
      return;
    }

    try {
      isLoading.value = true;
      hasSearched.value = true;
      searchedOrder.value = null;

      final res = await ApiService.get('/orders');
      if (res['success'] == true && res['orders'] != null) {
        final list = List<Map<String, dynamic>>.from(res['orders']);
        final q = query.trim().toLowerCase();
        final match = list.firstWhereOrNull((o) {
          final no = (o['manual_order_no'] ?? o['manualOrderNo'] ?? o['id'] ?? '').toString().toLowerCase();
          final client = (o['client_name'] ?? o['clientName'] ?? '').toString().toLowerCase();
          return no.contains(q) || client.contains(q);
        });

        if (match != null) {
          searchedOrder.value = OrderModel.fromSnapshot(match);
        } else {
          Get.snackbar("Not Found", "No order matching '$query'");
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Could not fetch order: $e");
    } finally {
      isLoading.value = false;
    }
  }

  List<OrderModel> get searchResults => searchedOrder.value != null ? [searchedOrder.value!] : [];

  void clearSearch() {
    searchController.clear();
    searchedOrder.value = null;
    hasSearched.value = false;
  }
}