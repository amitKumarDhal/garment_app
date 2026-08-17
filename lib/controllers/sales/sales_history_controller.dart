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
      if (res['success'] == true) {
        final raw = res['data'] ?? res['orders'] ?? [];
        if (raw is List) {
          final list = List<Map<String, dynamic>>.from(raw);
          final orders = list.map((e) => OrderModel.fromJson(e)).toList();
          myOrders.assignAll(orders);
          filterByStatus(currentFilter.value);
        }
      }
    } catch (e) {
      debugPrint("Fetch My Orders Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void searchOrders(String query) {
    if (query.isEmpty) {
      filterByStatus(currentFilter.value);
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
    final lower = status.toLowerCase().trim();

    if (lower == 'all') {
      filteredOrders.assignAll(myOrders);
    } else if (lower == 'production') {
      const prodStages = [
        'production',
        'fab purchased',
        'fab ready',
        'cutting',
        'cutting done',
        'printing',
        'printed',
        'stitching',
        'stitched',
        'finishing',
        'packing',
        'packed',
        'out src',
      ];
      filteredOrders.assignAll(
        myOrders.where((o) => prodStages.contains(o.status.toLowerCase().trim())).toList(),
      );
    } else if (lower == 'dispatched') {
      const dispatchStages = ['dispatched', 'shipping', 'shipped'];
      filteredOrders.assignAll(
        myOrders.where((o) => dispatchStages.contains(o.status.toLowerCase().trim())).toList(),
      );
    } else {
      filteredOrders.assignAll(
        myOrders.where((o) => o.status.toLowerCase().trim() == lower).toList(),
      );
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