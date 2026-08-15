import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/order_model.dart';
import '../../data/services/api_service.dart';

class SalesManagerController extends GetxController {
  static SalesManagerController get instance => Get.find();

  final List<String> productionStages = [
    'Approved', 'Fab Purchased', 'Fab Ready', 'Cutting', 'Cutting Done',
    'Printing', 'Printed', 'Stitching', 'Stitched', 'Packing', 'Packed',
    'Out SRC', 'Shipping', 'Shipped', 'Delivered'
  ];

  var pendingOrders = <OrderModel>[].obs;
  var approvedOrders = <OrderModel>[].obs;
  var activeOrders = <OrderModel>[].obs;
  var completedOrders = <OrderModel>[].obs;
  var deletionRequests = <OrderModel>[].obs;
  var pendingPaymentRequests = <Map<String, dynamic>>[].obs;
  var leaderboardData = <Map<String, dynamic>>[].obs;

  var totalShippingCollected = 0.0.obs;
  var totalGstCollected = 0.0.obs;
  var visibleLeaderboardCount = 5.obs;
  var managerName = 'Manager'.obs;
  var selectedTimeframe = 'All Time'.obs;
  var selectedMonth = DateTime.now().obs;
  var isLoading = false.obs;

  var totalRevenue = 0.0.obs;
  var totalOrdersCount = 0.obs;
  var totalUnitsSold = 0.obs;
  var topAgents = <Map<String, dynamic>>[].obs;
  List<String> get timeframes => ['All Time', 'This Month', 'Last Month', 'Custom'];

  Future<void> fetchPendingOrders() async => await fetchAllData();
  Future<void> fetchMonthlyStats() async => await fetchAllData();
  void setTimeframe(String tf) => selectedTimeframe.value = tf;
  void changeMonth(DateTime month) => selectedMonth.value = month;

  Future<void> denyDeletionRequest(OrderModel order) async {}
  Future<void> approveDeletionRequest(OrderModel order) async {}

  int get urgentDeliverablesCount {
    List<String> safeStatuses = [
      'shipping', 'shipped', 'delivered', 'completed', 'rejected', 'deleted', 'cancelled'
    ];
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    return activeOrders.where((order) {
      String status = (order.status).toLowerCase().trim();
      if (safeStatuses.contains(status)) return false;
      DateTime deadline = DateTime(order.deliveryDate.year, order.deliveryDate.month, order.deliveryDate.day);
      return deadline.difference(today).inDays <= 3;
    }).length;
  }

  @override
  void onInit() {
    super.onInit();
    fetchManagerIdentity();
    fetchAllData();
  }

  Future<void> fetchManagerIdentity() async {
    final user = ApiService.currentUser;
    if (user != null) {
      managerName.value = user['name'] ?? user['FullName'] ?? 'Manager';
    }
  }

  Future<void> fetchAllData() async {
    try {
      isLoading.value = true;
      final ordersRes = await ApiService.get('/orders');
      if (ordersRes['success'] == true && ordersRes['orders'] != null) {
        final list = List<Map<String, dynamic>>.from(ordersRes['orders']);
        List<OrderModel> orders = list.map((doc) => OrderModel.fromJson(doc)).toList();

        pendingOrders.assignAll(orders.where((o) => o.status.toLowerCase() == 'pending').toList());
        approvedOrders.assignAll(orders.where((o) => o.status.toLowerCase() == 'approved').toList());
        activeOrders.assignAll(orders.where((o) => productionStages.contains(o.status)).toList());
        completedOrders.assignAll(orders.where((o) => o.status.toLowerCase() == 'completed').toList());
        deletionRequests.assignAll(orders.where((o) => o.isDeleteRequested).toList());
      }

      final paymentsRes = await ApiService.get('/payments');
      if (paymentsRes['success'] == true && paymentsRes['payments'] != null) {
        final payList = List<Map<String, dynamic>>.from(paymentsRes['payments']);
        pendingPaymentRequests.assignAll(payList.where((p) => (p['status'] ?? '').toString().toLowerCase() == 'pending').toList());
      }

      final lbRes = await ApiService.get('/analytics/leaderboard');
      if (lbRes['success'] == true && lbRes['leaderboard'] != null) {
        leaderboardData.assignAll(List<Map<String, dynamic>>.from(lbRes['leaderboard']));
      }
    } catch (e) {
      debugPrint("SalesManagerController fetch error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchOrderHistory() async => await fetchAllData();

  Future<void> approveOrder(String orderId) async {
    try {
      final res = await ApiService.post('/orders/$orderId/approve', {});
      if (res['success'] == true) {
        Get.snackbar("Order Approved", "Order has been moved to production queue", backgroundColor: Colors.green, colorText: Colors.white);
        fetchAllData();
      }
    } catch (e) {
      Get.snackbar("Approval Failed", "$e", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> approvePaymentRequest(String requestId) async {
    try {
      final res = await ApiService.post('/payments/$requestId/approve', {});
      if (res['success'] == true) {
        Get.snackbar("Payment Approved", "Advance payment approved", backgroundColor: Colors.green, colorText: Colors.white);
        fetchAllData();
      }
    } catch (e) {
      Get.snackbar("Approval Error", "$e", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> rejectOrder(String orderId) async {
    try {
      final res = await ApiService.post('/orders/$orderId/reject', {});
      if (res['success'] == true) {
        Get.snackbar("Order Rejected", "Order has been rejected", backgroundColor: Colors.orange, colorText: Colors.white);
        fetchAllData();
      }
    } catch (e) {
      Get.snackbar("Rejection Failed", "$e", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> approveOrderWithMargin(String orderId, double margin, double total) async {
    await approveOrder(orderId);
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      final res = await ApiService.put('/orders/$orderId/status', {'status': status});
      if (res['success'] == true) {
        Get.snackbar("Status Updated", "Order status changed to $status", backgroundColor: Colors.green, colorText: Colors.white);
        fetchAllData();
      }
    } catch (e) {
      Get.snackbar("Update Failed", "$e", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}