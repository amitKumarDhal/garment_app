import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/order_model.dart';
import '../../data/services/api_service.dart';

class SalesManagerHistoryController extends GetxController {
  var allOrders = <OrderModel>[].obs;
  var filteredOrders = <OrderModel>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    try {
      isLoading.value = true;
      final res = await ApiService.get('/orders');
      if (res['success'] == true && res['orders'] != null) {
        final list = List<Map<String, dynamic>>.from(res['orders']);
        final orders = list.map((e) => OrderModel.fromSnapshot(e)).toList();
        allOrders.assignAll(orders);
        filteredOrders.assignAll(orders);
      }
    } catch (e) {
      debugPrint("Fetch History Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void searchOrders(String query) {
    if (query.isEmpty) {
      filteredOrders.assignAll(allOrders);
      return;
    }
    final q = query.toLowerCase();
    filteredOrders.assignAll(allOrders.where((o) {
      return (o.manualOrderNo ?? '').toLowerCase().contains(q) ||
          o.clientName.toLowerCase().contains(q) ||
          o.productName.toLowerCase().contains(q);
    }).toList());
  }

  List<OrderModel> get displayedOrders => filteredOrders;
  int get filteredOrdersCount => filteredOrders.length;
  double get filteredTotalRevenue => filteredOrders.fold(0.0, (sum, item) => sum + item.totalAmount);
  double get filteredAov => filteredOrdersCount > 0 ? filteredTotalRevenue / filteredOrdersCount : 0.0;
  List<OrderModel> get renderableOrders => filteredOrders;
  bool get canLoadMoreUI => false;
  var currentFilter = 'All'.obs;

  Future<void> refreshData() async => await fetchHistory();
  void loadMoreUI() {}
  void filterByStatus(String status) {
    currentFilter.value = status;
    if (status == 'All') {
      filteredOrders.assignAll(allOrders);
    } else {
      filteredOrders.assignAll(allOrders.where((o) => o.status.toLowerCase() == status.toLowerCase()).toList());
    }
  }
}