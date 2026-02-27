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

  // ✅ NEW: Observable for Deletion Requests
  var deletionRequests = <OrderModel>[].obs;

  var managerName = 'Manager'.obs;
  var activeOrders = <OrderModel>[].obs;
  var completedOrders = <OrderModel>[].obs;

  var topAgents = <Map<String, dynamic>>[].obs;
  var totalRevenue = 0.0.obs;
  var isLoading = true.obs;
  var totalOrdersCount = 0.obs;

  var selectedMonth = DateTime.now().obs;

  void fetchAllData() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (FirebaseAuth.instance.currentUser == null) return;

    try {
      isLoading.value = true;
      await Future.wait([
        fetchManagerProfile(),
        fetchMonthlyStats(),
      ]);

      // Start listeners
      fetchPendingOrders();
      fetchApprovedOrders();
      fetchOrderHistory();
      fetchDeletionRequests(); // ✅ Start listening for deletion requests

    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void changeMonth(DateTime newMonth) {
    selectedMonth.value = newMonth;
    fetchMonthlyStats();
  }

  /// --- 1. Fetch Pending Orders ---
  /// --- 1. Fetch Pending Orders ---
  void fetchPendingOrders() {
    if (FirebaseAuth.instance.currentUser == null) return;
    try {
      _db.collection('orders')
      // 1. Just query by the status
          .where('status', whereIn: ['Placed', 'Pending'])
          .orderBy('orderDate', descending: true)
          .snapshots()
          .listen((snapshot) {

        // 2. ✅ Filter out soft-deleted orders LOCALLY!
        // This prevents Firebase Index errors and handles missing 'isDeleted' fields perfectly.
        final validDocs = snapshot.docs.where((doc) {
          final data = doc.data();
          return data['isDeleted'] != true; // Keeps it if 'isDeleted' is false OR if it doesn't exist
        });

        // 3. Update the observable
        pendingOrders.value = validDocs.map((doc) => OrderModel.fromSnapshot(doc)).toList();

      }, onError: (e) {
        debugPrint("Stream error fetching pending: $e");
      });
    } catch (e) {
      debugPrint("Error fetching pending: $e");
    }
  }  /// --- 2. Fetch Approved Orders ---
  void fetchApprovedOrders() {
    if (FirebaseAuth.instance.currentUser == null) return;
    try {
      _db.collection('orders')
          .where('status', isEqualTo: 'Approved')
          .orderBy('orderDate', descending: true)
          .snapshots()
          .listen((snapshot) {
        approvedOrders.value = snapshot.docs.map((doc) => OrderModel.fromSnapshot(doc)).toList();
      });
    } catch (e) {
      print("Error fetching approved orders: $e");
    }
  }

  /// --- 3. FETCH ORDERS FOR HISTORY SCREEN ---
  void fetchOrderHistory() {
    if (FirebaseAuth.instance.currentUser == null) return;

    _db.collection('orders')
        .where('status', whereIn: ['Approved', 'Cutting', 'Stitching', 'Printing', 'Packing', 'Shipping'])
        .orderBy('orderDate', descending: true)
        .snapshots()
        .listen((snapshot) {
      activeOrders.value = snapshot.docs.map((doc) => OrderModel.fromSnapshot(doc)).toList();
    });

    _db.collection('orders')
        .where('status', whereIn: ['Delivered', 'Rejected'])
        .orderBy('orderDate', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      completedOrders.value = snapshot.docs.map((doc) => OrderModel.fromSnapshot(doc)).toList();
    });
  }

  /// ✅ NEW: FETCH DELETION REQUESTS (Real-time)
  void fetchDeletionRequests() {
    if (FirebaseAuth.instance.currentUser == null) return;
    try {
      _db.collection('orders')
          .where('isDeleteRequested', isEqualTo: true)
          .snapshots()
          .listen((snapshot) {
        deletionRequests.value = snapshot.docs.map((doc) => OrderModel.fromSnapshot(doc)).toList();
      });
    } catch (e) {
      print("Error fetching deletion requests: $e");
    }
  }

  Future<void> fetchManagerProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await _db.collection('users').doc(user.uid).get();
        if (doc.exists) {
          String fullName = doc.data()?['FullName'] ?? '';
          if (fullName.isNotEmpty) {
            managerName.value = fullName.trim().split(' ').first;
          }
        }
      } catch (e) {}
    }
  }

  Future<void> fetchMonthlyStats() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    try {
      DateTime targetDate = selectedMonth.value;
      DateTime startOfMonth = DateTime(targetDate.year, targetDate.month, 1);
      DateTime endOfMonth = DateTime(targetDate.year, targetDate.month + 1, 0, 23, 59, 59);

      // 👇 ADD THIS NEW BLOCK HERE 👇
      // 1. Fetch Users Collection to Identify Managers for the "SM" tag
      final usersSnap = await _db.collection('users').get();
      Map<String, bool> managerMap = {};
      for (var doc in usersSnap.docs) {
        final d = doc.data();
        String n = d['FullName'] ?? d['Name'] ?? '';
        String r = (d['Role'] ?? d['role'] ?? '').toString().toLowerCase();
        // If role is manager, mark them in the map
        if (n.isNotEmpty && (r.contains('manager') || r == 'sales manager')) {
          managerMap[n] = true;
        }
      }
      // 👆 END OF NEW BLOCK 👆

      final snapshot = await _db.collection('orders')
          .where('orderDate', isGreaterThanOrEqualTo: startOfMonth)
          .where('orderDate', isLessThanOrEqualTo: endOfMonth)
          .get();

      List<String> excludedStatuses = ['rejected', 'cancelled'];
      int validOrderCount = 0;
      double total = 0.0;
      Map<String, double> agentSales = {};
      Map<String, int> countMap = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        String status = (data['status'] ?? 'Pending').toString().toLowerCase();

        // ✅ 1. Check if the order has a pending deletion request
        bool isDeleteRequested = data['isDeleteRequested'] == true;

        // ✅ 2. Skip the order if it is rejected, cancelled, OR pending deletion
        if (!excludedStatuses.contains(status) && !isDeleteRequested) {

          validOrderCount++; // Count this as a valid order!

          List<String> revenueStatuses = ['approved', 'cutting', 'stitching', 'printing', 'packing', 'shipping', 'delivered'];

          if (revenueStatuses.contains(status)) {
            // ✅ 3. Use Effective Revenue if available, otherwise fallback to Total Amount
            double amount = 0.0;
            var rawEffRevenue = data['effectiveRevenue'];

            if (rawEffRevenue != null && (rawEffRevenue as num) > 0) {
              amount = (rawEffRevenue).toDouble();
            } else {
              var rawTotal = data['totalAmount'];
              amount = (rawTotal is num) ? rawTotal.toDouble() : (double.tryParse(rawTotal?.toString() ?? '0') ?? 0.0);
            }

            String agent = data['marketingPersonName'] ?? 'Unknown';
            total += amount;
            agentSales[agent] = (agentSales[agent] ?? 0) + amount;
            countMap[agent] = (countMap[agent] ?? 0) + 1;
          }
        }
      }

      // Update the UI observables with the clean numbers
      totalOrdersCount.value = validOrderCount;
      totalRevenue.value = total;

      var sortedAgents = agentSales.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      double _ = 100000.0;

// 👇 REPLACE YOUR EXISTING topAgents MAPPING WITH THIS 👇
      topAgents.value = sortedAgents.take(10).map((e) {
        String agentName = e.key;
        double currentSales = e.value;

        // ✅ DYNAMIC TARGET: 150k for SM, 100k for normal agents
        bool isSM = managerMap[agentName] == true;
        double targetAmount = isSM ? 150000.0 : 100000.0;

        double progress = currentSales / targetAmount;
        String greeting = "";

        if (progress >= 1.5) greeting = "Unstoppable! 🚀";
        else if (progress >= 1.0) greeting = "Target Smashed! 🏆";
        else if (progress >= 0.8) greeting = "Almost there! 🔥";
        else if (progress >= 0.5) greeting = "Halfway point 💪";
        else greeting = "Keep Pushing 📉";

        return {
          'name': agentName,
          'amount': currentSales,
          'formatted': NumberFormat.compactCurrency(symbol: '₹', locale: 'en_IN', decimalDigits: 1).format(currentSales),
          'progress': progress,
          'greeting': greeting,
          'count': countMap[agentName] ?? 0,
          'isSM': isSM, // ✅ Pass the SM flag to the UI
        };
      }).toList();    } catch (e) {
      print("❌ STATS ERROR: $e");
    }
  }
  /// --- ACTIONS ---
  Future<void> approveOrder(String orderId) async {
    await _updateStatus(orderId, 'Approved', Colors.green);
  }

  Future<void> rejectOrder(String orderId) async {
    await _updateStatus(orderId, 'Rejected', Colors.red);
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _updateStatus(orderId, newStatus, Colors.blue);
  }

  Future<void> _updateStatus(String orderId, String newStatus, Color color) async {
    try {
      final orderDoc = await _db.collection('orders').doc(orderId).get();
      final associateId = orderDoc.data()?['marketingPersonId'] ?? '';
      final orderNo = orderDoc.data()?['manualOrderNo'] ?? orderId;

      await _db.collection('orders').doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (associateId.isNotEmpty) {
        String emoji = "🔄";
        if (newStatus == 'Approved') emoji = "✅";
        if (newStatus == 'Rejected') emoji = "❌";
        if (newStatus == 'Cutting' || newStatus == 'Stitching') emoji = "✂️";
        if (newStatus == 'Printing' || newStatus == 'Packing') emoji = "📦";
        if (newStatus == 'Shipping') emoji = "🚚";
        if (newStatus == 'Delivered') emoji = "🎉";

        await _db.collection('notifications').add({
          'targetUserId': associateId,
          'title': 'Order Update $emoji',
          'message': 'Order $orderNo has been moved to $newStatus.',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }

      // ✅ FIX: Now it updates the math for BOTH Approvals and Rejections!
      if (newStatus == 'Approved' || newStatus == 'Rejected') {
        fetchMonthlyStats();
      }

      Get.snackbar(
        "Order $newStatus",
        "Successfully updated status & notified associate.",
        backgroundColor: color.withValues(alpha: 0.1),
        colorText: color,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar("Update Failed", e.toString());
    }
  }
  // ✅ NEW: APPROVE DELETION
// ✅ UPDATED: Soft Delete instead of hard delete
  Future<void> approveDeletionRequest(OrderModel order) async {
    try {
      await _db.collection('orders').doc(order.id).update({
        'status': 'Deleted',       // Change status
        'isDeleted': true,         // Add a hidden flag
        'isDeleteRequested': false, // Close the request
        'deletedAt': FieldValue.serverTimestamp(),
      });

      if (order.marketingPersonId != null && order.marketingPersonId!.isNotEmpty) {
        await _db.collection('notifications').add({
          'targetUserId': order.marketingPersonId,
          'title': 'Deletion Approved 🗑️',
          'message': 'Order ${order.manualOrderNo} was approved for removal.',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }

      fetchMonthlyStats(); // Refresh stats to remove this order's revenue

      Get.snackbar("Success", "Order moved to trash.",
          backgroundColor: Colors.redAccent.withValues(alpha: 0.1), colorText: Colors.red);
    } catch (e) {
      Get.snackbar("Error", "Could not soft delete: $e");
    }
  }
  // ✅ NEW: DENY DELETION
  Future<void> denyDeletionRequest(OrderModel order) async {
    try {
      await _db.collection('orders').doc(order.id).update({
        'isDeleteRequested': false,
        'deleteRequestedAt': FieldValue.delete(),
      });

      if (order.marketingPersonId != null && order.marketingPersonId!.isNotEmpty) {
        await _db.collection('notifications').add({
          'targetUserId': order.marketingPersonId,
          'title': 'Deletion Denied ❌',
          'message': 'Your request to delete Order ${order.manualOrderNo} was denied. It remains active.',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }

      Get.snackbar(
          "Denied",
          "Deletion request denied. The order is active.",
          backgroundColor: Colors.orange.withValues(alpha: 0.1),
          colorText: Colors.orange
      );
    } catch (e) {
      Get.snackbar("Error", "Could not deny request: $e");
    }
  }
}