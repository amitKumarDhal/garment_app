import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../data/models/order_model.dart';

class SalesAgentController extends GetxController {
  static SalesAgentController get instance => Get.find();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // Observables
  final leaderboardData = <Map<String, dynamic>>[].obs;
  final isLoading = true.obs;
  final agentName = "".obs;

  // ✅ NEW: User Role Observable (JSA, SSA, SC, SM)
  final userRole = "JSA".obs;

  // Observables for Gross vs Net
  final grossSales = 0.0.obs;
  final netAchievement = 0.0.obs;
  final totalOrders = 0.obs;

  // Observable to track if the personal margin is pending
  final hasPendingER = false.obs;

  // Dynamic Target Observables
  final baseTarget = 100000.0.obs;
  final currentDynamicTarget = 100000.0.obs;
  final prevMonthPendingAmount = 0.0.obs;
  final isPrevMonthCompleted = true.obs;

  // Tracks if the previous month actually had any data
  final hasPrevMonthData = false.obs;

  // Checks if user is a manager (hides bonus UI if true)
  var isSalesManager = false.obs;

  // OBSERVABLE FOR SELECTED MONTH
  var selectedMonth = DateTime.now().obs;

  // METHOD TO CHANGE MONTH AND RELOAD
  void changeMonth(int offset) {
    HapticFeedback.selectionClick();
    DateTime current = selectedMonth.value;
    selectedMonth.value = DateTime(current.year, current.month + offset, 1);

    isLoading.value = true;
    Future.wait([fetchAgentStats(), fetchLeaderboard()]).then((_) {
      isLoading.value = false;
    });
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

          // ✅ Assign exact Role Acronym
          userRole.value = _parseRoleAcronym(role);

          if (role.contains('manager') || role == 'sales manager') {
            baseTarget.value = 150000.0;
            isSalesManager.value = true;
          } else {
            // ✅ Dynamic Base Target based on Role
            baseTarget.value = _getTargetForRole(userRole.value);
            isSalesManager.value = false;

            // ✅ Silent Auto-Promotion Check (Only run if they are a Junior)
            if (userRole.value == 'JSA') {
              await _checkPromotionEligibility(user.uid);
            }
          }
        }
        agentName.value = name;
      }
    } catch (e) {
      debugPrint("Error fetching identity: $e");
    }
  }

  // ✅ Helper: Role to Target Mapping
  double _getTargetForRole(String role) {
    if (role == 'SSA') return 150000.0; // 1.5 Lakh
    if (role == 'SC') return 200000.0;  // 2 Lakh
    if (role == 'SM') return 150000.0;
    return 100000.0; // Default JSA 1L
  }

  // ✅ Helper: Parse Role String to Acronym
  String _parseRoleAcronym(String role) {
    if (role.contains('senior') || role == 'ssa') return 'SSA';
    if (role.contains('coordinator') || role == 'sc') return 'SC';
    if (role.contains('manager') || role == 'sm') return 'SM';
    return 'JSA'; // Default
  }

  // ✅ THE SILENT PROMOTION ENGINE
  Future<void> _checkPromotionEligibility(String uid) async {
    DateTime now = DateTime.now();
    DateTime firstOfThisMonth = DateTime(now.year, now.month, 1);
    DateTime firstOfLastMonth = DateTime(now.year, now.month - 1, 1);

    final lastMonthSnap = await _db.collection('orders')
        .where('marketingPersonId', isEqualTo: uid)
        .where('orderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(firstOfLastMonth))
        .where('orderDate', isLessThan: Timestamp.fromDate(firstOfThisMonth))
        .get();

    int orderCount = 0;
    double totalRevenue = 0.0;
    bool has50kOrder = false;

    for (var doc in lastMonthSnap.docs) {
      final data = doc.data();
      if (data['isDeleted'] == true) continue;

      String status = (data['status'] ?? '').toString().toLowerCase();
      if (status == 'rejected' || status == 'cancelled') continue;

      orderCount++;
      double effRev = _parseAmount(data['effectiveRevenue']);
      double totAmt = _parseAmount(data['totalAmount']);
      double val = (effRev > 0) ? effRev : totAmt;

      totalRevenue += val;
      if (val >= 50000) has50kOrder = true;
    }

    // 🏆 CRITERIA CHECK: 10 Orders + 1.5L Revenue + One 50k Order
    if (orderCount >= 10 && totalRevenue >= 150000 && has50kOrder) {
      await _db.collection('users').doc(uid).update({'Role': 'Senior Sales Associate'});
      userRole.value = 'SSA';
      baseTarget.value = 150000.0; // Upgrade their target immediately

      Get.snackbar("Level Up! 🚀", "Congratulations! You've been promoted to Senior Sales Associate (SSA)!",
          backgroundColor: Colors.purple.withValues(alpha:0.1), colorText: Colors.purple, duration: const Duration(seconds: 6));
    }
  }


  Future<void> loadDashboardData() async {
    if (_auth.currentUser == null) return;
    isLoading.value = true;
    await fetchAgentIdentity();
    await Future.wait([fetchAgentStats(), fetchLeaderboard()]);
    isLoading.value = false;
  }

  // --- Calculate My Personal Stats & Previous Month Rollover ---
  Future<void> fetchAgentStats() async {
    if (agentName.value.isEmpty) await fetchAgentIdentity();
    if (agentName.value.isEmpty) return;

    try {
      DateTime targetMonth = selectedMonth.value;
      DateTime startOfMonth = DateTime(targetMonth.year, targetMonth.month, 1);
      DateTime endOfMonth = DateTime(targetMonth.year, targetMonth.month + 1, 0, 23, 59, 59);

      DateTime prevMonth = DateTime(targetMonth.year, targetMonth.month - 1, 1);
      DateTime startOfPrevMonth = DateTime(prevMonth.year, prevMonth.month, 1);
      DateTime endOfPrevMonth = DateTime(prevMonth.year, prevMonth.month + 1, 0, 23, 59, 59);

      final currentMonthFuture = _db.collection('orders')
          .where('marketingPersonName', isEqualTo: agentName.value)
          .where('orderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('orderDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .orderBy('orderDate', descending: true)
          .get();

      final prevMonthFuture = _db.collection('orders')
          .where('marketingPersonName', isEqualTo: agentName.value)
          .where('orderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfPrevMonth))
          .where('orderDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfPrevMonth))
          .get();

      final results = await Future.wait([currentMonthFuture, prevMonthFuture]);
      final currentSnap = results[0];
      final prevSnap = results[1];

      // ✅ UPDATED: Added new granular statuses so orders don't disappear from agent's dashboard
      List<String> validStatuses = [
        'approved', 'fab purchased', 'fab ready', 'cutting', 'cutting done',
        'printing', 'printed', 'stitching', 'stitched', 'packing', 'packed',
        'shipping', 'shipped', 'delivered', 'completed'
      ];
      // --- CALCULATE PREVIOUS MONTH ---
      double prevTotalNet = 0.0;
      hasPrevMonthData.value = prevSnap.docs.isNotEmpty;

      for (var doc in prevSnap.docs) {
        final data = doc.data();
        String status = (data['status'] ?? 'pending').toString().toLowerCase();
        if (validStatuses.contains(status) && data['isDeleteRequested'] != true && data['isDeleted'] != true) {
          double totalAmt = _parseAmount(data['totalAmount']);
          double effRev = _parseAmount(data['effectiveRevenue']);
          prevTotalNet += (effRev > 0) ? effRev : totalAmt;
        }
      }

      // CALCULATE SHORTFALL
      double shortfall = baseTarget.value - prevTotalNet;

      if (!hasPrevMonthData.value || shortfall <= 0) {
        isPrevMonthCompleted.value = true;
        prevMonthPendingAmount.value = 0.0;
        currentDynamicTarget.value = baseTarget.value;
      } else {
        isPrevMonthCompleted.value = false;
        prevMonthPendingAmount.value = shortfall;
        currentDynamicTarget.value = baseTarget.value + shortfall;
      }

      // --- CALCULATE CURRENT MONTH ---
      double totalGross = 0.0;
      double totalNet = 0.0;
      int orderCount = 0;
      bool currentMonthMissingMargin = false;

      for (var doc in currentSnap.docs) {
        final data = doc.data();
        String status = (data['status'] ?? 'pending').toString().toLowerCase();
        if (validStatuses.contains(status) && data['isDeleteRequested'] != true && data['isDeleted'] != true) {
          orderCount++;
          double totalAmt = _parseAmount(data['totalAmount']);
          double effRev = _parseAmount(data['effectiveRevenue']);

          if (effRev <= 0) {
            currentMonthMissingMargin = true;
          }

          totalGross += totalAmt;
          totalNet += (effRev > 0) ? effRev : totalAmt;
        }
      }

      grossSales.value = totalGross;
      netAchievement.value = totalNet;
      totalOrders.value = orderCount;
      hasPendingER.value = currentMonthMissingMargin;

    } catch (e) {
      debugPrint("❌ Stats Error: $e");
    }
  }

  // --- Calculate Team Leaderboard ---
  Future<void> fetchLeaderboard() async {
    try {
      isLoading.value = true;

      DateTime targetMonth = selectedMonth.value;
      DateTime start = DateTime(targetMonth.year, targetMonth.month, 1);
      DateTime end = DateTime(targetMonth.year, targetMonth.month + 1, 0, 23, 59, 59);

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

      // ✅ UPDATED & CLEANED: Added new granular statuses. Only lowercase needed since we convert the data string to lowercase below.
      List<String> revenueStatuses = [
        'approved', 'fab purchased', 'fab ready', 'cutting', 'cutting done',
        'printing', 'printed', 'stitching', 'stitched', 'packing', 'packed',
        'shipping', 'shipped', 'delivered', 'completed'
      ];
      final snapshot = await _db
          .collection('orders')
          .where('orderDate', isGreaterThanOrEqualTo: start)
          .where('orderDate', isLessThanOrEqualTo: end)
          .get();

      Map<String, double> salesMap = {};
      Map<String, int> countMap = {};
      Map<String, bool> pendingERMap = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        String status = (data['status'] ?? 'Pending').toString().toLowerCase();

        if (revenueStatuses.contains(status) && data['isDeleteRequested'] != true && data['isDeleted'] != true) {
          String agent = data['marketingPersonName'] ?? 'Unknown';

          double totalAmt = _parseAmount(data['totalAmount']);
          double effRev = _parseAmount(data['effectiveRevenue']);

          if (effRev <= 0) {
            pendingERMap[agent] = true;
          }

          // ✅ Perfect fallback logic remains intact
          double amountToCount = (effRev > 0) ? effRev : totalAmt;

          salesMap[agent] = (salesMap[agent] ?? 0) + amountToCount;
          countMap[agent] = (countMap[agent] ?? 0) + 1;
        }
      }

      var sortedEntries = salesMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

      leaderboardData.value = sortedEntries.map((e) {
        String name = e.key;
        double amount = e.value;
        int count = countMap[name] ?? 0;

        String role = userRoleMap[name] ?? 'JSA';
        bool isSM = role == 'SM';
        double targetAmount = _getTargetForRole(role);

        double progress = amount / targetAmount;

        String greeting = "";
        if (progress >= 1.5) greeting = "Unstoppable! 🚀";
        else if (progress >= 1.0) greeting = "Target Smashed! 🏆";
        else if (progress >= 0.8) greeting = "Almost there! 🔥";
        else if (progress >= 0.5) greeting = "Halfway point 💪";
        else greeting = "Keep Pushing 📉";

        return {
          'name': name,
          'amount': amount,
          'count': count,
          'progress': progress,
          'greeting': greeting,
          'isSM': isSM,
          'roleStr': role,
          'hasPendingER': pendingERMap[name] ?? false,
        };
      }).toList();
    } catch (e) {
      debugPrint("Error fetching leaderboard: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // --- UPDATE ORDER (Edit Logic) ---
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

  // --- REQUEST DELETE ORDER LOGIC ---
  Future<void> deleteOrder(String orderId, String currentStatus) async {
    // ✅ UPDATED: Added new 14-stage logic for locking deletions
    // It is usually safe to delete if it's just 'Approved' or 'Fab Purchased'.
    // Once 'Fab Ready' or 'Cutting' starts, the agent should be locked out.
    final lockedStatuses = [
      'fab ready',
      'cutting',
      'cutting done',
      'printing',
      'printed',
      'stitching',
      'stitched',
      'packing',
      'packed',
      'shipping',
      'shipped',
      'delivered',
      'completed'
    ];

    if (lockedStatuses.contains(currentStatus.toLowerCase().trim())) {
      Get.snackbar(
          "Action Denied",
          "Production has already started ($currentStatus). Deletion is no longer possible.",
          backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
          colorText: Colors.red,
          snackPosition: SnackPosition.BOTTOM
      );
      return;
    }

    try {
      isLoading.value = true;

      // 1. Flag the order in Firestore
      await _db.collection('orders').doc(orderId).update({
        'isDeleteRequested': true,
        'deleteRequestedAt': FieldValue.serverTimestamp(),
      });

      // 2. Notify all Sales Managers
      try {
        final managerSnapshot = await _db.collection('users')
            .where('Role', isEqualTo: 'Sales Manager')
            .get();

        for (var managerDoc in managerSnapshot.docs) {
          await _db.collection('notifications').add({
            'targetUserId': managerDoc.id,
            'title': 'Deletion Request 🗑️',
            'message': '${agentName.value} requested to delete order ID: $orderId',
            'type': 'OrderApproval', // ✅ Ensuring the NotificationController routes this to the right screen
            'orderId': orderId,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });
        }
      } catch (e) {
        debugPrint("Notification failed: $e");
      }

      // 3. Refresh Local Data
      await fetchAgentStats();

      Get.snackbar(
          "Request Sent",
          "Deletion request sent to manager for approval.",
          backgroundColor: Colors.orange.withValues(alpha: 0.1),
          colorText: Colors.orange,
          snackPosition: SnackPosition.BOTTOM
      );
    } catch (e) {
      Get.snackbar(
          "Error",
          "Could not send deletion request: $e",
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          colorText: Colors.red
      );
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

  double get achievementPercentage {
    if (currentDynamicTarget.value <= 0) return 0.0;
    return (grossSales.value / currentDynamicTarget.value).clamp(0.0, 1.0);
  }
}