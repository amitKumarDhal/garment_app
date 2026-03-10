import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/order_model.dart';

class SalesManagerController extends GetxController {
  static SalesManagerController get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ✅ Centralized master list of production stages
  final List<String> productionStages = [
    'Approved', 'Cutting', 'Printing', 'Printed',
    'Stitching', 'Stitched', 'Packing', 'Packed', 'Shipping', 'Shipped', 'Delivered'
  ];

  // --- Observables ---
  var pendingOrders = <OrderModel>[].obs;
  var approvedOrders = <OrderModel>[].obs;

  var deletionRequests = <OrderModel>[].obs;

  int get urgentDeliverablesCount {
    List<String> safeStatuses = [
      'packed', 'packing', 'shipped', 'shipping',
      'delivered', 'completed', 'rejected', 'deleted', 'cancelled'
    ];

    DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    return activeOrders.where((order) {
      String status = (order.status).toLowerCase();
      if (safeStatuses.contains(status)) return false;

      DateTime deadline = DateTime(order.deliveryDate.year, order.deliveryDate.month, order.deliveryDate.day);
      int daysLeft = deadline.difference(today).inDays;

      return daysLeft <= 3;
    }).length;
  }

  var managerName = 'Manager'.obs;
  var activeOrders = <OrderModel>[].obs;
  var completedOrders = <OrderModel>[].obs;

  var topAgents = <Map<String, dynamic>>[].obs;
  var totalRevenue = 0.0.obs;
  var isLoading = true.obs;
  var totalOrdersCount = 0.obs;
  var totalUnitsSold = 0.obs;

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

      fetchPendingOrders();
      fetchApprovedOrders();
      fetchOrderHistory();
      fetchDeletionRequests();

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
  void fetchPendingOrders() {
    if (FirebaseAuth.instance.currentUser == null) return;
    try {
      _db.collection('orders')
          .where('status', whereIn: ['Placed', 'Pending'])
          .orderBy('orderDate', descending: true)
          .snapshots()
          .listen((snapshot) {

        final validDocs = snapshot.docs.where((doc) {
          final data = doc.data();
          return data['isDeleted'] != true;
        });

        pendingOrders.value = validDocs.map((doc) => OrderModel.fromSnapshot(doc)).toList();

      }, onError: (e) {
        debugPrint("Stream error fetching pending: $e");
      });
    } catch (e) {
      debugPrint("Error fetching pending: $e");
    }
  }

  /// --- 2. Fetch Approved Orders ---
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
        .where('status', whereIn: [
      'Approved', 'Cutting', 'Printing', 'Printed',
      'Stitching', 'Stitched', 'Packed', 'Packing', 'Shipping'
    ])
        .orderBy('orderDate', descending: true)
        .snapshots()
        .listen((snapshot) {
      activeOrders.value = snapshot.docs.map((doc) => OrderModel.fromSnapshot(doc)).toList();
    }, onError: (e) {
      debugPrint("Error in Active Orders Stream: $e");
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

  /// --- 4. FETCH DELETION REQUESTS ---
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

  // ✅ BULLETPROOF PARSING HELPER
  double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      // Strips out commas and ₹ symbols so tryParse doesn't fail
      String clean = value.replaceAll(',', '').replaceAll('₹', '').trim();
      return double.tryParse(clean) ?? 0.0;
    }
    return 0.0;
  }

  Future<void> fetchMonthlyStats() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    try {
      DateTime targetDate = selectedMonth.value;
      DateTime startOfMonth = DateTime(targetDate.year, targetDate.month, 1);
      DateTime endOfMonth = DateTime(targetDate.year, targetDate.month + 1, 0, 23, 59, 59);

      final usersSnap = await _db.collection('users').get();
      Map<String, bool> managerMap = {};
      for (var doc in usersSnap.docs) {
        final d = doc.data();
        String n = d['FullName'] ?? d['Name'] ?? '';
        String r = (d['Role'] ?? d['role'] ?? '').toString().toLowerCase();
        if (n.isNotEmpty && (r.contains('manager') || r == 'sales manager')) {
          managerMap[n] = true;
        }
      }

      final snapshot = await _db.collection('orders')
          .where('orderDate', isGreaterThanOrEqualTo: startOfMonth)
          .where('orderDate', isLessThanOrEqualTo: endOfMonth)
          .get();

      // ✅ BUG FIXED: Added 'pending' and 'placed' so they don't inflate the stats
      List<String> excludedStatuses = ['rejected', 'cancelled', 'pending', 'placed'];

      int validOrderCount = 0;
      double total = 0.0;
      int unitsCount = 0;
      Map<String, double> agentSales = {};
      Map<String, int> countMap = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        String status = (data['status'] ?? 'Pending').toString().toLowerCase();

        bool isDeleteRequested = data['isDeleteRequested'] == true;

        if (!excludedStatuses.contains(status) && !isDeleteRequested) {
          validOrderCount++;

          int orderQty = 0;
          if (data['products'] != null && data['products'] is List) {
            for (var item in data['products']) {
              orderQty += (item['qty'] is num) ? (item['qty'] as num).toInt() : int.tryParse(item['qty'].toString()) ?? 0;
            }
          } else if (data['quantity'] != null) {
            orderQty = (data['quantity'] is num) ? (data['quantity'] as num).toInt() : int.tryParse(data['quantity'].toString()) ?? 0;
          }
          unitsCount += orderQty;

          List<String> revenueStatuses = [
            'approved', 'cutting', 'printing', 'printed',
            'stitching', 'stitched', 'packed', 'packing',
            'shipped', 'shipping', 'delivered'
          ];

          if (revenueStatuses.contains(status)) {
            // Using robust parser for both values
            double effRev = _parseAmount(data['effectiveRevenue']);
            double totalAmt = _parseAmount(data['totalAmount']);

            // If manager gave margin, use it. Otherwise, instantly use full amount!
            double amount = (effRev > 0) ? effRev : totalAmt;

            String agent = data['marketingPersonName'] ?? 'Unknown';
            total += amount;
            agentSales[agent] = (agentSales[agent] ?? 0) + amount;
            countMap[agent] = (countMap[agent] ?? 0) + 1;
          }
        }
      }

      totalOrdersCount.value = validOrderCount;
      totalRevenue.value = total;
      totalUnitsSold.value = unitsCount;

      var sortedAgents = agentSales.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

      topAgents.value = sortedAgents.take(10).map((e) {
        String agentName = e.key;
        double currentSales = e.value;

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
          'isSM': isSM,
        };
      }).toList();
    } catch (e) {
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
        if (newStatus == 'Printing' || newStatus == 'Printed') emoji = "🖨️";
        if (newStatus == 'Packed' || newStatus == 'Packing') emoji = "📦";
        if (newStatus == 'Shipping' || newStatus == 'Shipped') emoji = "🚚";
        if (newStatus == 'Delivered') emoji = "🎉";

        await _db.collection('notifications').add({
          'targetUserId': associateId,
          'title': 'Order Update $emoji',
          'message': 'Order $orderNo has been moved to $newStatus.',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }

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

  Future<void> approveDeletionRequest(OrderModel order) async {
    try {
      await _db.collection('orders').doc(order.id).update({
        'status': 'Deleted',
        'isDeleted': true,
        'isDeleteRequested': false,
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

      fetchMonthlyStats();

      Get.snackbar("Success", "Order moved to trash.",
          backgroundColor: Colors.redAccent.withValues(alpha: 0.1), colorText: Colors.red);
    } catch (e) {
      Get.snackbar("Error", "Could not soft delete: $e");
    }
  }

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

  Future<void> approveOrderWithMargin(String orderId, double marginAmount, double totalAmount) async {
    try {
      await _db.collection('orders').doc(orderId).update({
        'status': 'Approved',
        'effectiveRevenue': marginAmount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      fetchMonthlyStats();
      Get.back();

      Get.snackbar("Success", "Order approved successfully!",
          backgroundColor: Colors.green.withValues(alpha: 0.1), colorText: Colors.green);
    } catch (e) {
      Get.snackbar("Error", "Failed to approve order: $e",
          backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red);
    }
  }
}