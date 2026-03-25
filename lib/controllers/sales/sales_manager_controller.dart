import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/order_model.dart';

class SalesManagerController extends GetxController {
  static SalesManagerController get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ✅ UPDATED: Centralized list now includes "Out SRC" before Shipping
  final List<String> productionStages = [
    'Approved', 'Fab Purchased', 'Fab Ready', 'Cutting', 'Cutting Done',
    'Printing', 'Printed', 'Stitching', 'Stitched', 'Packing', 'Packed',
    'Out SRC', // 🏢 New Stage
    'Shipping', 'Shipped', 'Delivered'
  ];

  // --- Observables ---
  var pendingOrders = <OrderModel>[].obs;
  var approvedOrders = <OrderModel>[].obs;
  var deletionRequests = <OrderModel>[].obs;

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

  /// --- ✅ UPDATED: Added "Out SRC" to the Active Orders Stream ---
  void fetchOrderHistory() {
    if (FirebaseAuth.instance.currentUser == null) return;

    _db.collection('orders')
        .where('status', whereIn: [
      'Approved', 'Fab Purchased', 'Fab Ready', 'Cutting', 'Cutting Done',
      'Printing', 'Printed', 'Stitching', 'Stitched', 'Packing', 'Packed',
      'Out SRC', 'Shipping' // Included Out SRC here
    ])
        .orderBy('orderDate', descending: true)
        .snapshots()
        .listen((snapshot) {
      activeOrders.value = snapshot.docs.map((doc) => OrderModel.fromSnapshot(doc)).toList();
    }, onError: (e) {
      debugPrint("Error in Active Orders Stream: $e");
    });

    _db.collection('orders')
        .where('status', whereIn: ['Shipped', 'Delivered', 'Rejected'])
        .orderBy('orderDate', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      completedOrders.value = snapshot.docs.map((doc) => OrderModel.fromSnapshot(doc)).toList();
    });
  }

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

  double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      String clean = value.replaceAll(',', '').replaceAll('₹', '').trim();
      return double.tryParse(clean) ?? 0.0;
    }
    return 0.0;
  }

  /// --- ✅ UPDATED: Added "out src" to Revenue Logic ---
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
            'approved', 'fab purchased', 'fab ready', 'cutting', 'cutting done',
            'printing', 'printed', 'stitching', 'stitched', 'packing', 'packed',
            'out src', // ✅ Added
            'shipping', 'shipped', 'delivered', 'completed'
          ];

          if (revenueStatuses.contains(status)) {
            double effRev = _parseAmount(data['effectiveRevenue']);
            double totalAmt = _parseAmount(data['totalAmount']);
            double amount = (effRev > 0) ? effRev : totalAmt;

            String agent = data['marketingPersonName'] ?? 'Unknown';
            total += amount;
            agentSales[agent] = (agentSales[agent] ?? 0) + amount;
            countMap[agent] = (agentSales[agent] ?? 0).toInt(); // Temporary fix for count
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

        String rankLabel = "JSA";
        double targetAmount = 100000.0;

        if (isSM) {
          rankLabel = "SM";
          targetAmount = 150000.0;
        } else {
          if (currentSales >= 200000) {
            rankLabel = "SC";
            targetAmount = 200000.0;
          } else if (currentSales >= 150000) {
            rankLabel = "SSA";
            targetAmount = 150000.0;
          } else if (currentSales >= 100000) {
            rankLabel = "JSA";
            targetAmount = 100000.0;
          }
        }

        double progress = currentSales / targetAmount;
        String greeting = "";
        if (progress >= 1.0) greeting = "Target Smashed! 🏆";
        else if (progress >= 0.8) greeting = "Almost there! 🔥";
        else greeting = "Keep Pushing 📉";

        return {
          'name': agentName,
          'amount': currentSales,
          'formatted': NumberFormat.compactCurrency(symbol: '₹', locale: 'en_IN', decimalDigits: 1).format(currentSales),
          'progress': progress,
          'greeting': greeting,
          'count': countMap[agentName] ?? 0,
          'isSM': isSM,
          'rank': rankLabel,
        };
      }).toList();
    } catch (e) {
      print("❌ STATS ERROR: $e");
    }
  }

  Future<void> approveOrder(String orderId) async {
    await _updateStatus(orderId, 'Approved', Colors.green);
  }

  Future<void> rejectOrder(String orderId) async {
    await _updateStatus(orderId, 'Rejected', Colors.red);
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _updateStatus(orderId, newStatus, Colors.blue);
  }

  /// --- ✅ UPDATED: Added Notification Emoji for Out SRC ---
  Future<void> _updateStatus(String orderId, String newStatus, Color color, {double? effectiveRevenue}) async {
    try {
      final orderDoc = await _db.collection('orders').doc(orderId).get();

      if (orderDoc.exists && orderDoc.data()?['status'] == newStatus) {
        return;
      }

      final associateId = orderDoc.data()?['marketingPersonId'] ?? '';
      final orderNo = orderDoc.data()?['manualOrderNo'] ?? orderId;

      final historyEvent = {
        'stage': newStatus,
        'updatedBy': managerName.value,
        'timestamp': Timestamp.now(),
      };

      Map<String, dynamic> updatePayload = {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastUpdatedBy': managerName.value,
        'stageHistory': FieldValue.arrayUnion([historyEvent]),
      };

      if (effectiveRevenue != null) {
        updatePayload['effectiveRevenue'] = effectiveRevenue;
      }

      await _db.collection('orders').doc(orderId).update(updatePayload);

      if (associateId.isNotEmpty) {
        String emoji = "🔄";
        if (newStatus == 'Approved') emoji = "✅";
        if (newStatus == 'Rejected') emoji = "❌";
        if (newStatus == 'Cutting' || newStatus == 'Stitching' || newStatus == 'Cutting Done') emoji = "✂️";
        if (newStatus == 'Printing' || newStatus == 'Printed') emoji = "🖨️";
        if (newStatus == 'Packed' || newStatus == 'Packing') emoji = "📦";
        if (newStatus == 'Out SRC') emoji = "🏢"; // ✅ Added Emoji for Outsourcing
        if (newStatus == 'Shipping' || newStatus == 'Shipped') emoji = "🚚";
        if (newStatus == 'Delivered') emoji = "🎉";
        if (newStatus == 'Fab Purchased' || newStatus == 'Fab Ready') emoji = "🧵";

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
    await _updateStatus(orderId, 'Approved', Colors.green, effectiveRevenue: marginAmount);
  }
}