import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:yoobbel/data/models/order_model.dart';
import '../../data/services/api_service.dart';
import '../../data/models/activity_item_model.dart';

class AdminController extends GetxController {
  static AdminController get instance => Get.find();

  var totalDailyProduction = 0.0.obs;
  var averageEfficiency = 0.0.obs;
  var activeWorkers = 0.obs;
  var totalDamages = 0.obs;
  var adminName = "".obs;

  var periodRevenue = 0.0.obs;
  var periodOrders = 0.obs;
  var periodUnits = 0.obs;

  var todayOrders = 0.obs;
  var todayUnits = 0.obs;

  var timeframeLabel = "".obs;
  var startDate = DateTime(DateTime.now().year, DateTime.now().month, 1).obs;
  var endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59).obs;

  var reportDate = DateTime.now().obs;
  var reportSection = 'All'.obs;
  RxList<ActivityItem> reportList = <ActivityItem>[].obs;
  var isReportLoading = false.obs;

  RxList<Map<String, dynamic>> pendingRequests = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> allApprovedWorkers = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> unitSupervisors = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> salesManagers = <Map<String, dynamic>>[].obs;

  RxList<OrderModel> recentOrders = <OrderModel>[].obs;
  RxList<Map<String, dynamic>> recentCuttingEntries = <Map<String, dynamic>>[].obs;

  Future<void> refreshStats() async => await loadDashboardData();
  Future<void> selectSpecificMonth(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setTimeframe(DateFormat('MMMM yyyy').format(picked), 1);
  }

  void setTimeframe(String label, int months) {
    timeframeLabel.value = label;
    loadDashboardData();
  }

  void setFinancialYear() {
    timeframeLabel.value = 'This Financial Year';
    loadDashboardData();
  }

  final RxSet<String> processingUserIds = <String>{}.obs;

  Future<void> rejectRequest(String docId) async {
    if (docId.isEmpty) return;
    try {
      processingUserIds.add(docId);
      final res = await ApiService.delete('/users/$docId');
      if (res['success'] == true) {
        pendingRequests.removeWhere((u) => u['id'] == docId);
        pendingApprovalsCount.value = pendingRequests.length;
        Get.snackbar("Request Rejected", "The ID request has been rejected.", backgroundColor: Colors.orange, colorText: Colors.white);
        await loadDashboardData();
      } else {
        Get.snackbar("Rejection Failed", res['message']?.toString() ?? "Could not reject request", backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      final msg = e.toString().replaceFirst(RegExp(r'^(Exception|ApiException):\s*'), '');
      Get.snackbar("Error", "Could not reject request: $msg", backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      processingUserIds.remove(docId);
    }
  }

  Future<void> approveNextStage(String docId, dynamic user) async {
    final role = (user is Map ? user['role'] : 'SALES_ASSOCIATE')?.toString() ?? 'SALES_ASSOCIATE';
    await approveUserRequest(docId, role);
  }

  Future<void> fetchReportData() async {}
  void setReportDate(DateTime date) => reportDate.value = date;
  void setReportSection(String sec) => reportSection.value = sec;
  RxList<Map<String, dynamic>> recentPrintingEntries = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> recentStitchingEntries = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> recentPackingEntries = <Map<String, dynamic>>[].obs;
  RxList<ActivityItem> recentActivities = <ActivityItem>[].obs;

  var pendingApprovalsCount = 0.obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    timeframeLabel.value = DateFormat('MMM yyyy').format(DateTime.now());
    fetchAdminIdentity();
    loadDashboardData();
  }

  Future<void> fetchAdminIdentity() async {
    try {
      final user = ApiService.currentUser;
      if (user != null) {
        adminName.value = user['name'] ?? user['FullName'] ?? 'Admin';
      }
    } catch (e) {
      debugPrint("Error loading admin identity: $e");
    }
  }

  Future<void> loadDashboardData() async {
    try {
      isLoading.value = true;
      final analyticsRes = await ApiService.get('/analytics/dashboard');
      if (analyticsRes['success'] == true && analyticsRes['data'] != null) {
        final data = analyticsRes['data'] as Map<String, dynamic>;
        periodRevenue.value = double.tryParse(data['periodRevenue']?.toString() ?? '0') ?? 0.0;
        periodOrders.value = data['periodOrders'] ?? 0;
        periodUnits.value = data['periodUnits'] ?? 0;
        todayOrders.value = data['todayOrders'] ?? 0;
        todayUnits.value = data['todayUnits'] ?? 0;
        activeWorkers.value = data['activeWorkforce'] ?? 0;
      }

      final pendingRes = await ApiService.get('/users/pending');
      if (pendingRes['success'] == true) {
        final rawUsers = pendingRes['data'] ?? pendingRes['users'] ?? [];
        if (rawUsers is List) {
          final users = List<Map<String, dynamic>>.from(rawUsers);
          pendingRequests.assignAll(users);
          pendingApprovalsCount.value = users.length;
        }
      }

      final ordersRes = await ApiService.get('/orders');
      if (ordersRes['success'] == true) {
        final rawOrders = ordersRes['data'] ?? ordersRes['orders'] ?? [];
        if (rawOrders is List) {
          final ordersData = List<Map<String, dynamic>>.from(rawOrders);
          recentOrders.assignAll(ordersData.map((e) => OrderModel.fromJson(e)).toList());
        }
      }
    } catch (e) {
      debugPrint("Admin Dashboard Load Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> approveUserRequest(String userId, String role) async {
    if (userId.isEmpty) return;
    try {
      processingUserIds.add(userId);
      final res = await ApiService.post('/users/$userId/approve', {
        'adminApproved': true,
      });
      if (res['success'] == true) {
        pendingRequests.removeWhere((u) => u['id'] == userId);
        pendingApprovalsCount.value = pendingRequests.length;
        Get.snackbar("Approved", "User approved successfully as $role", backgroundColor: Colors.green, colorText: Colors.white);
        await loadDashboardData();
      } else {
        Get.snackbar("Approval Failed", res['message']?.toString() ?? "Could not approve user", backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      final msg = e.toString().replaceFirst(RegExp(r'^(Exception|ApiException):\s*'), '');
      Get.snackbar("Approval Error", msg, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      processingUserIds.remove(userId);
    }
  }

  Future<void> removeApprovedWorker(String uid) async {
    try {
      final res = await ApiService.delete('/users/$uid');
      if (res['success'] == true) {
        Get.snackbar("Removed", "User removed from system", backgroundColor: Colors.orange, colorText: Colors.white);
        loadDashboardData();
      }
    } catch (e) {
      Get.snackbar("Error", "Could not remove user: $e", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}