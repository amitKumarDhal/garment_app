import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/order_model.dart';
import '../../data/services/api_service.dart';

class SalesHistoryController extends GetxController {
  var myOrders = <OrderModel>[].obs;
  var filteredOrders = <OrderModel>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchMyOrders();
  }

  Future<void> fetchMyOrders() async {
    try {
      isLoading.value = true;
      final res = await ApiService.get('/orders');
      if (res['success'] == true && res['orders'] != null) {
        final list = List<Map<String, dynamic>>.from(res['orders']);
        final orders = list.map((e) => OrderModel.fromJson(e)).toList();
        myOrders.assignAll(orders);
        filteredOrders.assignAll(orders);
      }
    } catch (e) {
      debugPrint("Fetch My Orders Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void searchOrders(String query) {
    if (query.isEmpty) {
      filteredOrders.assignAll(myOrders);
      return;
    }
    final q = query.toLowerCase();
    filteredOrders.assignAll(myOrders.where((o) {
      return (o.manualOrderNo ?? '').toLowerCase().contains(q) ||
          o.clientName.toLowerCase().contains(q) ||
          o.productName.toLowerCase().contains(q);
    }).toList());
  }

  List<OrderModel> get displayedOrders => filteredOrders;
  int get filteredOrdersCount => filteredOrders.length;
  double get filteredTotalRevenue => filteredOrders.fold(0.0, (sum, item) => sum + item.totalAmount);
  double get filteredAov => filteredOrdersCount > 0 ? filteredTotalRevenue / filteredOrdersCount : 0.0;
  var isLoadingMore = false.obs;
  var hasMoreData = false.obs;
  var currentFilter = 'All'.obs;

  Future<void> fetchHistory() async => await fetchMyOrders();
  Future<void> refreshData() async => await fetchMyOrders();
  Future<void> fetchNextPage() async {}

  void filterByStatus(String status) {
    currentFilter.value = status;
    if (status == 'All') {
      filteredOrders.assignAll(myOrders);
    } else {
      filteredOrders.assignAll(myOrders.where((o) => o.status.toLowerCase() == status.toLowerCase()).toList());
    }
  }

  Future<void> recordPayment(dynamic orderOrId, double amount, [String mode = 'UPI', String ref = '']) async {
    final String orderId = orderOrId is OrderModel ? (orderOrId.id ?? '') : orderOrId.toString();
    try {
      final res = await ApiService.post('/payments', {
        'orderId': orderId,
        'amount': amount,
        'paymentMode': mode,
        'referenceNumber': ref,
      });
      if (res['success'] == true) {
        Get.snackbar("Payment Recorded", "Payment request submitted for manager approval", backgroundColor: Colors.green, colorText: Colors.white);
        fetchMyOrders();
      }
    } catch (e) {
      Get.snackbar("Payment Error", "$e", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  bool hasPendingPayment(dynamic order) => false;
  Future<void> requestDeleteOrder(dynamic orderOrId) async {}
  Future<void> cancelDeleteRequest(dynamic orderOrId) async {}
}