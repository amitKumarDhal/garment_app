import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/order_model.dart';

class SalesManagerController extends GetxController {
  static SalesManagerController get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Observables ---
  var pendingOrders = <OrderModel>[].obs;
  var approvedOrders = <OrderModel>[].obs;
  var managerName = 'Manager'.obs;

  // ✅ ADDED THESE FOR HISTORY SCREEN
  var activeOrders = <OrderModel>[].obs; // Cutting, Stitching, etc.
  var completedOrders = <OrderModel>[].obs; // Delivered, Rejected

  var topAgents = <Map<String, dynamic>>[].obs;
  var totalRevenue = 0.0.obs;
  var isLoading = true.obs;
  var totalOrdersCount = 0.obs;

  // Defaults to the current month
  var selectedMonth = DateTime.now().obs;

  /// ✅ Master Fetch Function (Dashboard)
  void fetchAllData() async {
    if (FirebaseAuth.instance.currentUser == null) return;

    try {
      isLoading.value = true;
      fetchPendingOrders();
      fetchApprovedOrders();
      await fetchMonthlyStats();
      await fetchManagerProfile(); // ✅ Fetch name first
      fetchOrderHistory(); // ✅ Also fetch history data
    } catch (e) {
      debugPrint("Error fetching dashboard data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void changeMonth(DateTime newMonth) {
    selectedMonth.value = newMonth;
    fetchMonthlyStats();
  }

  /// --- 1. Fetch Pending Orders (Real-time) ---
  void fetchPendingOrders() {
    if (FirebaseAuth.instance.currentUser == null) return;
    try {
      _db
          .collection('orders')
          // ✅ Fix: Look for BOTH 'Placed' and 'Pending'
          .where('status', whereIn: ['Placed', 'Pending'])
          .orderBy('orderDate', descending: true)
          .snapshots()
          .listen((snapshot) {
            pendingOrders.value = snapshot.docs
                .map((doc) => OrderModel.fromSnapshot(doc))
                .toList();
          });
    } catch (e) {
      print("Error fetching pending: $e");
    }
  }

  /// --- 2. Fetch Approved Orders (Real-time) ---
  void fetchApprovedOrders() {
    if (FirebaseAuth.instance.currentUser == null) return;
    try {
      _db
          .collection('orders')
          .where('status', isEqualTo: 'Approved')
          .orderBy('orderDate', descending: true)
          .snapshots()
          .listen((snapshot) {
            approvedOrders.value = snapshot.docs
                .map((doc) => OrderModel.fromSnapshot(doc))
                .toList();
          });
    } catch (e) {
      print("Error fetching approved orders: $e");
    }
  }

  /// ✅ 3. FETCH ORDERS FOR HISTORY SCREEN (Active vs Completed)
  void fetchOrderHistory() {
    if (FirebaseAuth.instance.currentUser == null) return;

    // A. Fetch ACTIVE Orders (In Production)
    // Note: 'Approved' is included here so it shows up immediately after approval
    _db
        .collection('orders')
        .where(
          'status',
          whereIn: [
            'Approved',
            'Cutting',
            'Stitching',
            'Printing',
            'Packing',
            'Shipping',
          ],
        )
        .orderBy('orderDate', descending: true)
        .snapshots()
        .listen((snapshot) {
          activeOrders.value = snapshot.docs
              .map((doc) => OrderModel.fromSnapshot(doc))
              .toList();
        });

    // B. Fetch COMPLETED Orders (History)
    _db
        .collection('orders')
        .where('status', whereIn: ['Delivered', 'Rejected'])
        .orderBy('orderDate', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
          completedOrders.value = snapshot.docs
              .map((doc) => OrderModel.fromSnapshot(doc))
              .toList();
        });
  }


// 2. Add this function to fetch the FullName from Firestore
Future<void> fetchManagerProfile() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        String fullName = doc.data()?['FullName'] ?? '';
        if (fullName.isNotEmpty) {
          // Takes "Sales" from "Sales Manager Dummy"
          managerName.value = fullName.trim().split(' ').first;
        }
      }
    } catch (e) {
      print("Error fetching profile: $e");
    }
  }
}



  /// --- 4. Monthly Stats & Leaderboard ---
  /// --- ✅ UPDATED: Monthly Stats & Leaderboard ---
  /// --- ✅ UPDATED: Monthly Stats & Leaderboard ---
  Future<void> fetchMonthlyStats() async {
    if (FirebaseAuth.instance.currentUser == null) return;

    try {
      DateTime targetDate = selectedMonth.value;
      DateTime startOfMonth = DateTime(targetDate.year, targetDate.month, 1);
      DateTime endOfMonth = DateTime(
        targetDate.year,
        targetDate.month + 1,
        0,
        23,
        59,
        59,
      );

      // 1. QUERY ALL ORDERS FOR THE MONTH
      final snapshot = await _db
          .collection('orders')
          .where('orderDate', isGreaterThanOrEqualTo: startOfMonth)
          .where('orderDate', isLessThanOrEqualTo: endOfMonth)
          .get();

      // Statuses that DO NOT count towards total volume or revenue
      List<String> excludedStatuses = ['rejected', 'cancelled'];

      int validOrderCount = 0;
      double total = 0.0;
      Map<String, double> agentSales = {};
      Map<String, int> countMap = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        String status = (data['status'] ?? 'Pending').toString().toLowerCase();

        // ✅ FIX: Exclude Rejected/Cancelled from ALL stats
        if (!excludedStatuses.contains(status)) {

          // 1. Increment valid order count
          validOrderCount++;

          // 2. Calculate Revenue (Only for revenue generating statuses)
          List<String> revenueStatuses = [
            'approved', 'cutting', 'stitching', 'printing', 'packing', 'shipping', 'delivered'
          ];

          if (revenueStatuses.contains(status)) {
            double amount = 0.0;
            var rawAmount = data['totalAmount'];
            if (rawAmount is num) {
              amount = rawAmount.toDouble();
            } else if (rawAmount is String) {
              amount = double.tryParse(rawAmount) ?? 0.0;
            }

            String agent = data['marketingPersonName'] ?? 'Unknown';

            total += amount;
            agentSales[agent] = (agentSales[agent] ?? 0) + amount;
            countMap[agent] = (countMap[agent] ?? 0) + 1;
          }
        }
      }

      // ✅ SET TOTAL VOLUME (Only valid orders)
      totalOrdersCount.value = validOrderCount;
      totalRevenue.value = total;

      // --- SORT AGENTS ---
      var sortedAgents = agentSales.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      double targetAmount = 100000.0;

      topAgents.value = sortedAgents.take(10).map((e) {
        String agentName = e.key;
        double currentSales = e.value;
        double progress = currentSales / targetAmount;

        String greeting = "";
        if (progress >= 1.5) {
          greeting = "Unstoppable! 🚀";
        } else if (progress >= 1.0) greeting = "Target Smashed! 🏆";
        else if (progress >= 0.8) greeting = "Almost there! 🔥";
        else if (progress >= 0.5) greeting = "Halfway point 💪";
        else greeting = "Keep Pushing 📉";

        return {
          'name': agentName,
          'amount': currentSales,
          'formatted': NumberFormat.compactCurrency(
              symbol: '₹',
              locale: 'en_IN',
              decimalDigits: 1
          ).format(currentSales),
          'progress': progress,
          'greeting': greeting,
          'count': countMap[agentName] ?? 0,
        };
      }).toList();
    } catch (e) {
      print("❌ STATS ERROR: $e");
    }
  }

  /// --- 5. Actions ---
  Future<void> approveOrder(String orderId) async {
    await _updateStatus(orderId, 'Approved', Colors.green);
  }

  Future<void> rejectOrder(String orderId) async {
    await _updateStatus(orderId, 'Rejected', Colors.red);
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _db.collection('orders').doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        "Status Updated",
        "Order moved to: $newStatus",
        backgroundColor: Colors.blue.withOpacity(0.1),
        colorText: Colors.blue,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar("Error", "Failed to update status: $e");
    }
  }

  Future<void> _updateStatus(
    String orderId,
    String newStatus,
    Color color,
  ) async {
    try {
      await _db.collection('orders').doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (newStatus == 'Approved') fetchMonthlyStats();

      Get.snackbar(
        "Order $newStatus",
        "Successfully updated status.",
        backgroundColor: color.withOpacity(0.1),
        colorText: color,
      );
    } catch (e) {
      Get.snackbar("Update Failed", e.toString());
    }
  }
}