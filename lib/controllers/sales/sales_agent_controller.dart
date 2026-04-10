import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../data/models/order_model.dart';

class SalesAgentController extends GetxController {
  static SalesAgentController get instance => Get.find();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // --- UI State Observables ---
  final leaderboardData = <Map<String, dynamic>>[].obs;
  final isLoading = true.obs;
  final agentName = "".obs;

  // Tracks the official DB role vs the Displayed Dynamic Role
  String dbBaseRole = "JSA";
  final userRole = "JSA".obs;

  var isSalesManager = false.obs;
  final agentCreatedAt = Rx<DateTime?>(null);

  // --- Financial Observables ---
  final grossSales = 0.0.obs;
  final netAchievement = 0.0.obs;
  final totalOrders = 0.obs;
  final hasPendingER = false.obs;

  // Observable for the UI to display the calculated bonus
  final extraEarningAmount = 0.0.obs;

  // --- Target Logic Observables ---
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
      final user = _auth.currentUser;
      if (user != null) {
        String name = user.displayName ?? "Unknown";

        final userDoc = await _db.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          name = userDoc.data()?['FullName'] ?? userDoc.data()?['Name'] ?? name;
          String role = (userDoc.data()?['Role'] ?? userDoc.data()?['role'] ?? '').toString().toLowerCase();

          dbBaseRole = _parseRoleAcronym(role);
          userRole.value = dbBaseRole; // Fallback

          if (role.contains('manager') || role == 'sales manager') {
            baseTarget.value = 150000.0;
            isSalesManager.value = true;
          } else {
            baseTarget.value = _getTargetForRole(dbBaseRole);
            isSalesManager.value = false;
          }

          var createdRaw = userDoc.data()?['createdAt'];
          if (createdRaw != null && createdRaw is Timestamp) {
            agentCreatedAt.value = createdRaw.toDate();
          } else {
            agentCreatedAt.value = user.metadata.creationTime ?? DateTime.now();
          }
        }
        agentName.value = name;
      }
    } catch (e) {
      debugPrint("Error fetching identity: $e");
    }
  }

  double _getTargetForRole(String role) {
    if (role == 'SSA') return 150000.0;
    if (role == 'SC') return 200000.0;
    if (role == 'SM') return 150000.0;
    return 100000.0; // Default JSA
  }

  String _parseRoleAcronym(String role) {
    if (role.contains('senior') || role == 'ssa') return 'SSA';
    if (role.contains('coordinator') || role == 'sc') return 'SC';
    if (role.contains('manager') || role == 'sm') return 'SM';
    return 'JSA';
  }

  Future<void> loadDashboardData() async {
    if (_auth.currentUser == null) return;
    isLoading.value = true;
    await fetchAgentIdentity();
    await Future.wait([fetchAgentStats(), fetchLeaderboard()]);
    isLoading.value = false;
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
        end = DateTime(selectedMonth.value.year, selectedMonth.value.month + 1, 0, 23, 59, 59, 999);
        monthsInPeriod = 1;
        break;
    }
    return {'start': start, 'end': end, 'multiplier': monthsInPeriod};
  }

  // =====================================================================
  // ✅ PERSONAL STATS WITH DYNAMIC PROMOTION LOGIC
  // =====================================================================
  Future<void> fetchAgentStats() async {
    if (agentName.value.isEmpty) await fetchAgentIdentity();
    if (agentName.value.isEmpty) return;

    try {
      final rangeData = _getDateRange();
      DateTime start = rangeData['start'];
      DateTime end = rangeData['end'];
      int multiplier = rangeData['multiplier'];

      DateTime joinedDate = agentCreatedAt.value ?? DateTime.now();
      DateTime officialStartMonth;

      if (joinedDate.year == 2026 && joinedDate.month == 2) {
        officialStartMonth = DateTime(joinedDate.year, joinedDate.month, 1);
      } else {
        officialStartMonth = DateTime(joinedDate.year, joinedDate.month + 1, 1);
      }

      final allOrdersSnap = await _db.collection('orders')
          .where('marketingPersonName', isEqualTo: agentName.value)
          .orderBy('orderDate', descending: false)
          .get();

      // ✅ FIX: 'pending' and 'placed' REMOVED! Only approved orders count for the agent now.
      List<String> validStatuses = [
        'approved', 'fab purchased', 'fab ready', 'cutting', 'cutting done',
        'printing', 'printed', 'stitching', 'stitched', 'packing', 'packed',
        'out src', 'shipping', 'shipped', 'delivered', 'completed'
      ];

      Map<String, double> monthlySalesMap = {};
      double periodGross = 0.0;
      double periodNet = 0.0;
      int periodOrderCount = 0;
      bool periodMissingMargin = false;

      String targetMonthKey = DateFormat('yyyy-MM').format(selectedMonth.value);

      for (var doc in allOrdersSnap.docs) {
        final data = doc.data();
        String status = (data['status'] ?? 'pending').toString().toLowerCase();

        bool isDeleted = data['isDeleted'] == true || data['isDeleted'] == "true";
        bool isDeleteRequested = data['isDeleteRequested'] == true || data['isDeleteRequested'] == "true";

        if (validStatuses.contains(status) && !isDeleted && !isDeleteRequested) {
          DateTime orderDate = (data['orderDate'] as Timestamp).toDate();
          String monthKey = DateFormat('yyyy-MM').format(orderDate);

          double totalAmt = _parseAmount(data['totalAmount']);
          double effRev = _parseAmount(data['effectiveRevenue']);
          double finalAmount = (effRev > 0) ? effRev : totalAmt;

          monthlySalesMap[monthKey] = (monthlySalesMap[monthKey] ?? 0.0) + finalAmount;

          if (orderDate.isAfter(start.subtract(const Duration(seconds: 1))) && orderDate.isBefore(end.add(const Duration(seconds: 1)))) {
            periodOrderCount++;
            periodGross += totalAmt;
            periodNet += finalAmount;
            if (effRev <= 0) periodMissingMargin = true;
          }
        }
      }

      String calculatedRank = dbBaseRole;
      double currentTarget = _getTargetForRole(calculatedRank);
      double accumulatedDue = 0.0;

      List<String> sortedKeys = monthlySalesMap.keys.toList()..sort();
      hasPrevMonthData.value = sortedKeys.isNotEmpty;

      if (selectedTimeframe.value == 'Monthly') {
        for (String mKey in sortedKeys) {
          if (mKey == targetMonthKey) break;

          DateTime loopMonth = DateFormat('yyyy-MM').parse(mKey);
          if (loopMonth.isBefore(officialStartMonth)) continue;

          double monthNet = monthlySalesMap[mKey] ?? 0.0;

          // ✅ FIX: Calculate effective achievement by deducting past dues FIRST
          double effectiveForPromotion = monthNet - accumulatedDue;

          accumulatedDue += (currentTarget - monthNet);
          if (accumulatedDue < 0) accumulatedDue = 0;

          // ✅ PROMOTION LOGIC: Now uses the adjusted amount (183k - 59k = 124k)
          if (accumulatedDue <= 0 && !isSalesManager.value) {
            if (calculatedRank == 'JSA' && effectiveForPromotion >= 150000) {
              calculatedRank = 'SSA';
              currentTarget = 150000.0;
            } else if (calculatedRank == 'SSA' && effectiveForPromotion >= 200000) {
              calculatedRank = 'SC';
              currentTarget = 200000.0;
            }
          }
        }
      }

      userRole.value = calculatedRank;
      baseTarget.value = currentTarget;

      grossSales.value = periodGross;
      netAchievement.value = periodNet;
      totalOrders.value = periodOrderCount;
      hasPendingER.value = periodMissingMargin;

      if (selectedTimeframe.value == 'Monthly') {
        prevMonthPendingAmount.value = accumulatedDue;
        currentDynamicTarget.value = currentTarget + accumulatedDue;
        isPrevMonthCompleted.value = accumulatedDue <= 0;
      } else {
        prevMonthPendingAmount.value = 0.0;
        currentDynamicTarget.value = currentTarget * multiplier;
      }

      calculateTieredBonus();

    } catch (e) {
      debugPrint("❌ Stats Error: $e");
    }
  }
  // =====================================================================
  // ✅ TIERED SLAB BONUS LOGIC
  // =====================================================================
  void calculateTieredBonus() {
    if (selectedTimeframe.value != 'Monthly') {
      extraEarningAmount.value = 0.0;
      return;
    }

    double x = netAchievement.value - currentDynamicTarget.value;

    if (x <= 0) {
      extraEarningAmount.value = 0.0;
      return;
    }

    double bonus = 0.0;
    double remainingSurplus = x;

    // SLAB 1: First ₹50,000 gets 2%
    if (remainingSurplus > 0) {
      double slab1Amount = remainingSurplus > 50000 ? 50000 : remainingSurplus;
      bonus += (slab1Amount * 0.02);
      remainingSurplus -= slab1Amount;
    }

    // SLAB 2: Next ₹50,000 (between 50k to 100k) gets 1.5%
    if (remainingSurplus > 0) {
      double slab2Amount = remainingSurplus > 50000 ? 50000 : remainingSurplus;
      bonus += (slab2Amount * 0.015);
      remainingSurplus -= slab2Amount;
    }

    // SLAB 3: Anything above ₹1,00,000 gets 1%
    if (remainingSurplus > 0) {
      bonus += (remainingSurplus * 0.01);
    }

    extraEarningAmount.value = bonus;
  }

  // =====================================================================
  // ✅ TEAM LEADERBOARD WITH DYNAMIC RANKS
  // =====================================================================
  Future<void> fetchLeaderboard() async {
    try {
      isLoading.value = true;

      final rangeData = _getDateRange();
      DateTime start = rangeData['start'];
      DateTime end = rangeData['end'];
      int multiplier = rangeData['multiplier'];
      String targetMonthKey = DateFormat('yyyy-MM').format(selectedMonth.value);

      final usersSnap = await _db.collection('users').get();
      Map<String, String> userRoleMap = {};

      for (var doc in usersSnap.docs) {
        final d = doc.data();
        String n = d['FullName'] ?? d['Name'] ?? '';
        String r = (d['Role'] ?? d['role'] ?? '').toString().toLowerCase();
        if (n.isNotEmpty) {
          userRoleMap[n] = _parseRoleAcronym(r);
        }
      }

      List<String> revenueStatuses = [
        'pending', 'placed', 'approved', 'fab purchased', 'fab ready', 'cutting', 'cutting done',
        'printing', 'printed', 'stitching', 'stitched', 'packing', 'packed',
        'out src', 'shipping', 'shipped', 'delivered', 'completed'
      ];

      final snapshot = await _db
          .collection('orders')
          .where('orderDate', isLessThanOrEqualTo: end)
          .get();

      Map<String, Map<String, double>> agentHistory = {};
      Map<String, double> currentPeriodSales = {};
      Map<String, int> currentPeriodCount = {};
      Map<String, bool> pendingERMap = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        String status = (data['status'] ?? 'Pending').toString().toLowerCase();

        bool isDeleted = data['isDeleted'] == true || data['isDeleted'] == "true";
        bool isDeleteRequested = data['isDeleteRequested'] == true || data['isDeleteRequested'] == "true";

        if (revenueStatuses.contains(status) && !isDeleted && !isDeleteRequested) {
          String agent = data['marketingPersonName'] ?? 'Unknown';
          DateTime orderDate = (data['orderDate'] as Timestamp).toDate();
          String monthKey = DateFormat('yyyy-MM').format(orderDate);

          double totalAmt = _parseAmount(data['totalAmount']);
          double effRev = _parseAmount(data['effectiveRevenue']);
          if (effRev <= 0) pendingERMap[agent] = true;
          double finalAmount = (effRev > 0) ? effRev : totalAmt;

          agentHistory.putIfAbsent(agent, () => {});
          agentHistory[agent]![monthKey] = (agentHistory[agent]![monthKey] ?? 0.0) + finalAmount;

          if (orderDate.isAfter(start.subtract(const Duration(seconds: 1))) && orderDate.isBefore(end.add(const Duration(seconds: 1)))) {
            currentPeriodSales[agent] = (currentPeriodSales[agent] ?? 0) + finalAmount;
            currentPeriodCount[agent] = (currentPeriodCount[agent] ?? 0) + 1;
          }
        }
      }

      List<Map<String, dynamic>> tempList = [];

      for (String agent in currentPeriodSales.keys) {
        String dbRole = userRoleMap[agent] ?? 'JSA';
        bool isSM = dbRole == 'SM';

        String calculatedRank = dbRole;
        double currentTarget = _getTargetForRole(calculatedRank);
        double accumulatedDue = 0.0;

        if (agentHistory.containsKey(agent) && selectedTimeframe.value == 'Monthly') {
          List<String> sortedKeys = agentHistory[agent]!.keys.toList()..sort();

          String firstMonth = sortedKeys.isNotEmpty ? sortedKeys.first : targetMonthKey;

          for (String mKey in sortedKeys) {
            if (mKey == targetMonthKey) break;

            if (mKey == firstMonth && firstMonth != '2026-02') continue;

            double monthNet = agentHistory[agent]![mKey] ?? 0.0;

            // ✅ FIX: Calculate effective achievement by deducting past dues FIRST
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
          currentTarget = _getTargetForRole(dbRole);
        }

        double amount = currentPeriodSales[agent] ?? 0.0;
        double targetAmount = currentTarget * multiplier;
        double progress = targetAmount > 0 ? (amount / targetAmount) : 0.0;

        String greeting = "";
        if (progress >= 1.5) greeting = "Unstoppable! 🚀";
        else if (progress >= 1.0) greeting = "Target Smashed! 🏆";
        else if (progress >= 0.8) greeting = "Almost there! 🔥";
        else if (progress >= 0.5) greeting = "Halfway point 💪";
        else greeting = "Keep Pushing 📉";

        tempList.add({
          'name': agent,
          'amount': amount,
          'count': currentPeriodCount[agent] ?? 0,
          'progress': progress,
          'greeting': greeting,
          'isSM': isSM,
          'roleStr': calculatedRank,
          'hasPendingER': pendingERMap[agent] ?? false,
        });
      }

      tempList.sort((a, b) => b['amount'].compareTo(a['amount']));
      leaderboardData.value = tempList;

    } catch (e) {
      debugPrint("Error fetching leaderboard: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateOrder(OrderModel originalOrder, int newQty, double newPrice, String newDetails) async {
    try {
      isLoading.value = true;

      double subTotal = newQty * newPrice;
      double gstAmount = (subTotal * originalOrder.gstPercentage) / 100;
      double newTotal = subTotal + gstAmount + originalOrder.shippingCharge;
      double newBalance = newTotal - originalOrder.advanceAmount;

      Map<String, dynamic> updateData = {
        'quantity': newQty,
        'totalAmount': newTotal,
        'balanceDue': newBalance,
        'productDetails': newDetails,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (originalOrder.products.isNotEmpty) {
        List<dynamic> updatedProducts = List.from(originalOrder.products);
        if (updatedProducts[0] is Map) {
          Map<String, dynamic> firstProduct = Map<String, dynamic>.from(updatedProducts[0]);
          firstProduct['price'] = newPrice;
          updatedProducts[0] = firstProduct;
        }
        updateData['products'] = updatedProducts;
      }

      await _db.collection('orders').doc(originalOrder.id).update(updateData);
      await fetchAgentStats();

      Get.snackbar("Success", "Order updated successfully!",
          backgroundColor: Colors.green.withValues(alpha:0.1), colorText: Colors.green);

    } catch (e) {
      Get.snackbar("Error", "Failed to update order: $e",
          backgroundColor: Colors.red.withValues(alpha:0.1), colorText: Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteOrder(String orderId, String currentStatus) async {
    final lockedStatuses = [
      'fab ready', 'cutting', 'cutting done', 'printing', 'printed',
      'stitching', 'stitched', 'packing', 'packed', 'shipping',
      'shipped', 'delivered', 'completed'
    ];

    if (lockedStatuses.contains(currentStatus.toLowerCase().trim())) {
      Get.snackbar("Action Denied", "Production has already started. Deletion not possible.", backgroundColor: Colors.redAccent.withValues(alpha: 0.1), colorText: Colors.red);
      return;
    }

    try {
      isLoading.value = true;
      await _db.collection('orders').doc(orderId).update({
        'isDeleteRequested': true,
        'deleteRequestedAt': FieldValue.serverTimestamp(),
      });

      try {
        final managerSnapshot = await _db.collection('users').where('Role', isEqualTo: 'Sales Manager').get();
        for (var managerDoc in managerSnapshot.docs) {
          await _db.collection('notifications').add({
            'targetUserId': managerDoc.id,
            'title': 'Deletion Request 🗑️',
            'message': '${agentName.value} requested to delete order ID: $orderId',
            'type': 'OrderApproval',
            'orderId': orderId,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });
        }
      } catch (e) {}

      await loadDashboardData();
      Get.snackbar("Request Sent", "Deletion request sent to manager.", backgroundColor: Colors.orange.withValues(alpha: 0.1), colorText: Colors.orange);
    } catch (e) {
      Get.snackbar("Error", "Could not send request: $e", backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) {
      String clean = value.replaceAll(',', '').replaceAll('₹', '').trim();
      return double.tryParse(clean) ?? 0.0;
    }
    return 0.0;
  }
}