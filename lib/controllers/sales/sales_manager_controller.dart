import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../data/models/order_model.dart';

class SalesManagerController extends GetxController {
  static SalesManagerController get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<String> productionStages = [
    'Approved', 'Fab Purchased', 'Fab Ready', 'Cutting', 'Cutting Done',
    'Printing', 'Printed', 'Stitching', 'Stitched', 'Packing', 'Packed',
    'Out SRC',
    'Shipping', 'Shipped', 'Delivered'
  ];

  // --- Observables ---
  var pendingOrders = <OrderModel>[].obs;
  var approvedOrders = <OrderModel>[].obs;
  var deletionRequests = <OrderModel>[].obs;
  var totalShippingCollected = 0.0.obs;
  var totalGstCollected = 0.0.obs;

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
  var selectedTimeframe = 'Monthly'.obs;
  final List<String> timeframes = [
    'Monthly', 'Last 3 Months', 'Last 6 Months', 'Last 9 Months', 'Last 12 Months', 'This FY'
  ];

  @override
  void onInit() {
    super.onInit();
    fetchAllData();
  }

  void fetchAllData() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (_auth.currentUser == null) return;

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

  void setTimeframe(String tf) {
    HapticFeedback.selectionClick();
    selectedTimeframe.value = tf;
    fetchAllData();
  }

  void changeMonth(DateTime newMonth) {
    selectedMonth.value = newMonth;
    if (selectedTimeframe.value != 'Monthly') {
      selectedTimeframe.value = 'Monthly';
    }
    fetchAllData();
  }

  Map<String, dynamic> _getDateRange() {
    DateTime now = DateTime.now();
    DateTime start;
    DateTime end;
    int monthsInPeriod = 1;

    switch (selectedTimeframe.value) {
      case 'Last 3 Months':
        start = DateTime(now.year, now.month - 2, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        monthsInPeriod = 3;
        break;
      case 'Last 6 Months':
        start = DateTime(now.year, now.month - 5, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        monthsInPeriod = 6;
        break;
      case 'Last 9 Months':
        start = DateTime(now.year, now.month - 8, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        monthsInPeriod = 9;
        break;
      case 'Last 12 Months':
        start = DateTime(now.year, now.month - 11, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        monthsInPeriod = 12;
        break;
      case 'This FY':
        int startYear = now.month >= 4 ? now.year : now.year - 1;
        start = DateTime(startYear, 4, 1);
        end = DateTime(startYear + 1, 3, 31, 23, 59, 59);
        monthsInPeriod = 12;
        break;
      case 'Monthly':
      default:
        start = DateTime(selectedMonth.value.year, selectedMonth.value.month, 1);
        end = DateTime(selectedMonth.value.year, selectedMonth.value.month + 1, 0, 23, 59, 59);
        monthsInPeriod = 1;
        break;
    }
    return {'start': start, 'end': end, 'multiplier': monthsInPeriod};
  }

  void fetchPendingOrders() {
    if (_auth.currentUser == null) return;
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
    if (_auth.currentUser == null) return;
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

  void fetchOrderHistory() {
    if (_auth.currentUser == null) return;

    _db.collection('orders')
        .where('status', whereIn: [
      'Approved', 'Fab Purchased', 'Fab Ready', 'Cutting', 'Cutting Done',
      'Printing', 'Printed', 'Stitching', 'Stitched', 'Packing', 'Packed',
      'Out SRC', 'Shipping'
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
    if (_auth.currentUser == null) return;
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
    final user = _auth.currentUser;
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

  Future<void> fetchMonthlyStats() async {
    if (_auth.currentUser == null) return;
    try {
      final rangeData = _getDateRange();
      DateTime start = rangeData['start'];
      DateTime end = rangeData['end'];
      int multiplier = rangeData['multiplier'];

      String targetMonthKey = DateFormat('yyyy-MM').format(selectedMonth.value);

      // 1. Fetch Users & Identify Roles
      final usersSnap = await _db.collection('users').get();
      Map<String, String> roleMap = {};

      for (var doc in usersSnap.docs) {
        final d = doc.data();
        String n = d['FullName'] ?? d['Name'] ?? '';
        String r = (d['Role'] ?? d['role'] ?? 'JSA').toString().toUpperCase();

        if (n.isNotEmpty) {
          if (r.contains('MANAGER') || r == 'SM') r = 'SM';
          else if (r.contains('SENIOR') || r == 'SSA') r = 'SSA';
          else if (r.contains('COORDINATOR') || r == 'SC') r = 'SC';
          else r = 'JSA';

          roleMap[n] = r;
        }
      }

      final snapshot = await _db.collection('orders')
          .where('orderDate', isLessThanOrEqualTo: end)
          .get();

      // ✅ FIX APPLIED: 'pending' and 'placed' have been REMOVED!
      // Now, only orders that the Manager has Approved will count toward revenue and targets.
      List<String> validStatuses = [
        'approved', 'fab purchased', 'fab ready', 'cutting', 'cutting done',
        'printing', 'printed', 'stitching', 'stitched', 'packing', 'packed',
        'out src', 'shipping', 'shipped', 'delivered', 'completed'
      ];

      int validOrderCount = 0;
      double total = 0.0;
      double shippingTotal = 0.0;
      double gstTotal = 0.0;
      int unitsCount = 0;

      Map<String, Map<String, double>> agentHistory = {};
      Map<String, int> currentPeriodCount = {};
      Map<String, double> currentPeriodSales = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        String status = (data['status'] ?? 'Pending').toString().toLowerCase();

        bool isDeleted = data['isDeleted'] == true || data['isDeleted'] == "true";
        bool isDeleteRequested = data['isDeleteRequested'] == true || data['isDeleteRequested'] == "true";

        if (validStatuses.contains(status) && !isDeleteRequested && !isDeleted) {
          DateTime orderDate = (data['orderDate'] as Timestamp).toDate();
          String monthKey = DateFormat('yyyy-MM').format(orderDate);
          String agent = data['marketingPersonName'] ?? 'Unknown';

          double totalAmt = _parseAmount(data['totalAmount']);
          double effRev = _parseAmount(data['effectiveRevenue']);
          double finalAmount = (effRev > 0) ? effRev : totalAmt;

          agentHistory.putIfAbsent(agent, () => {});
          agentHistory[agent]![monthKey] = (agentHistory[agent]![monthKey] ?? 0.0) + finalAmount;

          if (orderDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
              orderDate.isBefore(end.add(const Duration(seconds: 1)))) {

            validOrderCount++;
            total += finalAmount;

            currentPeriodSales[agent] = (currentPeriodSales[agent] ?? 0) + finalAmount;
            currentPeriodCount[agent] = (currentPeriodCount[agent] ?? 0) + 1;

            shippingTotal += _parseAmount(data['shippingCharge']);

            double orderGst = 0.0;
            if (data['products'] != null && data['products'] is List) {
              for (var item in data['products']) {
                double pPrice = _parseAmount(item['price']);
                int pQty = (item['qty'] is num) ? (item['qty'] as num).toInt() : int.tryParse(item['qty'].toString()) ?? 0;
                double pGstPct = _parseAmount(item['gstPercentage']);
                orderGst += (pPrice * pQty) * (pGstPct / 100);
              }
            } else {
              double pGstPct = _parseAmount(data['gstPercentage']);
              double base = totalAmt / (1 + (pGstPct / 100));
              orderGst += totalAmt - base;
            }
            gstTotal += orderGst;

            int orderQty = 0;
            if (data['products'] != null && data['products'] is List) {
              for (var item in data['products']) {
                orderQty += (item['qty'] is num) ? (item['qty'] as num).toInt() : int.tryParse(item['qty'].toString()) ?? 0;
              }
            } else if (data['quantity'] != null) {
              orderQty = (data['quantity'] is num) ? (data['quantity'] as num).toInt() : int.tryParse(data['quantity'].toString()) ?? 0;
            }
            unitsCount += orderQty;
          }
        }
      }

      totalOrdersCount.value = validOrderCount;
      totalRevenue.value = total;
      totalUnitsSold.value = unitsCount;
      totalShippingCollected.value = shippingTotal;
      totalGstCollected.value = gstTotal;

      // 3. Process Leaderboard with EXACT logic from Agent Dashboard
      List<Map<String, dynamic>> leaderboardList = [];

      for (String agent in currentPeriodSales.keys) {
        String dbRole = roleMap[agent] ?? 'JSA';
        bool isSM = dbRole == 'SM';

        String calculatedRank = dbRole;
        double currentTarget = (dbRole == 'SC') ? 200000.0 : ((dbRole == 'SSA' || dbRole == 'SM') ? 150000.0 : 100000.0);
        double accumulatedDue = 0.0;

        if (agentHistory.containsKey(agent) && selectedTimeframe.value == 'Monthly') {
          List<String> sortedKeys = agentHistory[agent]!.keys.toList()..sort();

          // ✅ EXACT MATCH: Uses the first logged month instead of join date
          String firstMonth = sortedKeys.isNotEmpty ? sortedKeys.first : targetMonthKey;

          for (String mKey in sortedKeys) {
            if (mKey == targetMonthKey) break;

            // ✅ EXACT MATCH: The Feb 2026 No-Grace-Period Rule
            if (mKey == firstMonth && firstMonth != '2026-02') continue;

            double monthNet = agentHistory[agent]![mKey] ?? 0.0;

            // ✅ EXACT MATCH: Deduct debt BEFORE checking promotion
            double effectiveForPromotion = monthNet - accumulatedDue;

            accumulatedDue += (currentTarget - monthNet);
            if (accumulatedDue < 0) accumulatedDue = 0;

            if (accumulatedDue <= 0 && !isSM) {
              if (calculatedRank == 'JSA' && effectiveForPromotion >= 150000) {
                calculatedRank = 'SSA';
                currentTarget = 150000.0;
              } else if (calculatedRank == 'SSA' && effectiveForPromotion >= 200000) {
                calculatedRank = 'SC';
                currentTarget = 200000.0;
              }
            }
          }
        } else if (selectedTimeframe.value != 'Monthly') {
          currentTarget = (dbRole == 'SC') ? 200000.0 : ((dbRole == 'SSA' || dbRole == 'SM') ? 150000.0 : 100000.0);
        }

        double amount = currentPeriodSales[agent] ?? 0.0;
        double targetAmount = currentTarget * multiplier;
        double progress = targetAmount > 0 ? (amount / targetAmount) : 0.0;

        String greeting = "";
        if (progress >= 1.0) greeting = "Target Smashed! 🏆";
        else if (progress >= 0.8) greeting = "Almost there! 🔥";
        else greeting = "Keep Pushing 📉";

        leaderboardList.add({
          'name': agent,
          'amount': amount,
          'formatted': NumberFormat.compactCurrency(symbol: '₹', locale: 'en_IN', decimalDigits: 1).format(amount),
          'progress': progress,
          'greeting': greeting,
          'count': currentPeriodCount[agent] ?? 0,
          'isSM': isSM,
          'roleStr': calculatedRank, // Passes exact dynamic rank
        });
      }

      leaderboardList.sort((a, b) => b['amount'].compareTo(a['amount']));
      topAgents.value = leaderboardList.take(10).toList();

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
        if (newStatus == 'Out SRC') emoji = "🏢";
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