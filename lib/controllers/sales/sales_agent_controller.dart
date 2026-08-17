import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../data/models/order_model.dart';
import '../../data/services/api_service.dart';

class SalesAgentController extends GetxController {
  static SalesAgentController get instance => Get.find();

  var visibleLeaderboardCount = 5.obs;
  final leaderboardData = <Map<String, dynamic>>[].obs;
  final isLoading = true.obs;
  final agentName = "".obs;

  String dbBaseRole = "JSA";
  final userRole = "JSA".obs;

  var isSalesManager = false.obs;
  final agentCreatedAt = Rx<DateTime?>(null);

  final grossSales = 0.0.obs;
  final netAchievement = 0.0.obs;
  final totalOrders = 0.obs;
  final hasPendingER = false.obs;
  final extraEarningAmount = 0.0.obs;

  final baseTarget = 100000.0.obs;
  final currentDynamicTarget = 100000.0.obs;
  final prevMonthPendingAmount = 0.0.obs;
  final isPrevMonthCompleted = true.obs;
  final hasPrevMonthData = false.obs;

  var selectedMonth = DateTime.now().obs;
  var selectedTimeframe = 'Monthly'.obs;
  final List<String> timeframes = [
    'Monthly', 'Last 3 Months', 'Last 6 Months', 'Last 9 Months', 'Last 12 Months', 'This FY'
  ];

  void setTimeframe(String tf) {
    HapticFeedback.selectionClick();
    selectedTimeframe.value = tf;
    loadDashboardData();
  }

  void changeMonth(int offset) {
    HapticFeedback.selectionClick();
    DateTime current = selectedMonth.value;
    selectedMonth.value = DateTime(current.year, current.month + offset, 1);
    if (selectedTimeframe.value != 'Monthly') {
      selectedTimeframe.value = 'Monthly';
    }
    loadDashboardData();
  }

  Future<void> fetchAgentIdentity() async {
    try {
      final user = ApiService.currentUser;
      if (user != null) {
        agentName.value = user['name'] ?? user['FullName'] ?? 'Agent';
        String role = (user['role'] ?? '').toString().toLowerCase();
        dbBaseRole = _parseRoleAcronym(role);
        userRole.value = dbBaseRole;

        if (role.contains('manager') || role == 'sales_manager') {
          baseTarget.value = 150000.0;
          isSalesManager.value = true;
        } else {
          baseTarget.value = _getTargetForRole(dbBaseRole);
          isSalesManager.value = false;
        }
      }
    } catch (e) {
      debugPrint("Error fetching identity: $e");
    }
  }

  double _getTargetForRole(String role) {
    if (role == 'SSA') return 150000.0;
    if (role == 'SC') return 200000.0;
    if (role == 'SM') return 150000.0;
    return 100000.0;
  }

  String _parseRoleAcronym(String role) {
    if (role.contains('senior') || role == 'ssa') return 'SSA';
    if (role.contains('coordinator') || role == 'sc') return 'SC';
    if (role.contains('manager') || role == 'sm') return 'SM';
    return 'JSA';
  }

  Future<void> loadDashboardData() async {
    visibleLeaderboardCount.value = 5;
    isLoading.value = true;

    await fetchAgentIdentity();
    await Future.wait([fetchAgentStats(), fetchLeaderboard()]);
    isLoading.value = false;
  }

  Future<void> fetchAgentStats() async {
    try {
      final res = await ApiService.get('/analytics/dashboard');
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'] as Map<String, dynamic>;
        grossSales.value = double.tryParse(data['grossSales']?.toString() ?? '0') ?? 0.0;
        netAchievement.value = double.tryParse(data['periodRevenue']?.toString() ?? '0') ?? 0.0;
        totalOrders.value = data['periodOrders'] ?? 0;
      }
    } catch (e) {
      debugPrint("Stats Error: $e");
    }
  }

  Future<void> fetchLeaderboard() async {
    try {
      final res = await ApiService.get('/analytics/leaderboard');
      if (res['success'] == true && res['leaderboard'] != null) {
        final list = List<Map<String, dynamic>>.from(res['leaderboard']);
        leaderboardData.assignAll(list);
      }
    } catch (e) {
      debugPrint("Leaderboard Error: $e");
    }
  }

  Future<void> updateOrder(OrderModel originalOrder, int newQty, double newPrice, String newDetails) async {
    try {
      isLoading.value = true;
      double subTotal = newQty * newPrice;
      double gstAmount = (subTotal * originalOrder.gstPercentage) / 100;
      double newTotal = subTotal + gstAmount + originalOrder.shippingCharge;
      double newBalance = newTotal - originalOrder.advanceAmount;

      final res = await ApiService.put('/orders/${originalOrder.id}', {
        'quantity': newQty,
        'total_amount': newTotal,
        'balance_due': newBalance,
        'product_details': newDetails,
        'status': 'Pending',
      });

      if (res['success'] == true) {
        await fetchAgentStats();
        Get.snackbar("Success", "Order updated cleanly!", backgroundColor: Colors.green, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to update order: $e", backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteOrder(String orderId, String currentStatus) async {
    try {
      isLoading.value = true;
      final res = await ApiService.delete('/orders/$orderId');
      if (res['success'] == true) {
        await loadDashboardData();
        Get.snackbar("Request Sent", "Deletion processed", backgroundColor: Colors.orange, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", "Could not delete order: $e", backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
}