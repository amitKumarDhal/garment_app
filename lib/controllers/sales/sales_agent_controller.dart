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

  // Observables
  final leaderboardData = <Map<String, dynamic>>[].obs;
  final isLoading = true.obs;
  final agentName = "".obs;

  // User Role Observable
  final userRole = "JSA".obs;

  // Observables for Gross vs Net
  final grossSales = 0.0.obs;
  final netAchievement = 0.0.obs;
  final totalOrders = 0.obs;

  // Observable to track if personal margin is pending
  final hasPendingER = false.obs;

  // Dynamic Target Observables (UPDATED FOR CUMULATIVE LOGIC)
  final baseTarget = 100000.0.obs;
  final currentDynamicTarget = 100000.0.obs;
  final prevMonthPendingAmount = 0.0.obs; // Represents "Accumulated Lifetime Due"
  final isPrevMonthCompleted = true.obs; // True if accumulated due is 0
  final hasPrevMonthData = false.obs;

  var isSalesManager = false.obs;
  var selectedMonth = DateTime.now().obs;

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

          userRole.value = _parseRoleAcronym(role);

          if (role.contains('manager') || role == 'sales manager') {
            baseTarget.value = 150000.0;
            isSalesManager.value = true;
          } else {
            baseTarget.value = _getTargetForRole(userRole.value);
            isSalesManager.value = false;
            // Removed old promotion logic here, it is now handled beautifully in the Stats function!
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

  // =====================================================================
  // ✅ THE NEW AUTOMATED CAREER PATH ENGINE (Promotions & Demotions)
  // =====================================================================
  Future<void> _evaluateAgentCareerPath(Map<String, double> monthlySalesMap, double accumulatedDue, double currentMonthNet) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || isSalesManager.value) return;

    // 1. JSA -> SSA PROMOTION LOGIC
    if (userRole.value == 'JSA') {
      // RULE: No pending debt AND current month hit 1.5L
      if (accumulatedDue <= 0 && currentMonthNet >= 150000) {
        await _db.collection('users').doc(uid).update({'Role': 'SSA'});
        userRole.value = 'SSA';
        baseTarget.value = 150000.0; // Target instantly updates

        Get.snackbar(
          "Promotion Unlocked! 🚀",
          "You cleared all dues and hit 1.5L! You are now a Senior Sales Associate.",
          backgroundColor: Colors.purple.withValues(alpha: 0.15),
          colorText: Colors.purple,
          duration: const Duration(seconds: 6),
        );
        return; // Stop evaluating to prevent conflicts
      }
    }

    // 2. SSA DEMOTION & SALARY HIKE LOGIC
    if (userRole.value == 'SSA') {
      DateTime now = DateTime.now();
      List<double> last3Months = [];

      // Get revenue for the exact last 3 completed months
      for (int i = 1; i <= 3; i++) {
        DateTime prevDate = DateTime(now.year, now.month - i, 1);
        String monthKey = DateFormat('yyyy-MM').format(prevDate);
        last3Months.add(monthlySalesMap[monthKey] ?? 0.0);
      }

      // We need at least 3 months of data to judge them
      if (last3Months.length == 3) {

        // DEMOTION RULE: Missed 1.5L target 3 months in a row
        bool failedAll3 = last3Months.every((rev) => rev < 150000);
        if (failedAll3) {
          await _db.collection('users').doc(uid).update({'Role': 'JSA'});
          userRole.value = 'JSA';
          baseTarget.value = 100000.0;

          Get.snackbar(
            "Rank Adjusted 📉",
            "Target missed for 3 consecutive months. Rank adjusted to JSA.",
            backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
            colorText: Colors.redAccent,
            duration: const Duration(seconds: 6),
          );
          return;
        }

        // SALARY PROMOTION RULE: Hit 1.5L target 3 months in a row
        bool hitAll3 = last3Months.every((rev) => rev >= 150000);
        if (hitAll3) {
          // Check DB first so we don't spam them with popups every time they load the app
          final doc = await _db.collection('users').doc(uid).get();
          if (doc.data()?['salaryHikeEligible'] != true) {
            await _db.collection('users').doc(uid).update({'salaryHikeEligible': true});

            Get.snackbar(
              "Salary Hike Eligible! 💰",
              "You hit the SSA target for 3 consecutive months! You are eligible for a salary promotion.",
              backgroundColor: Colors.green.withValues(alpha: 0.15),
              colorText: Colors.green,
              duration: const Duration(seconds: 8),
            );
          }
        }
      }
    }
  }

  // =====================================================================
  // ✅ STATS WITH CUMULATIVE DEBT
  // =====================================================================
  Future<void> fetchAgentStats() async {
    if (agentName.value.isEmpty) await fetchAgentIdentity();
    if (agentName.value.isEmpty) return;

    try {
      DateTime targetMonth = selectedMonth.value;

      final allOrdersSnap = await _db.collection('orders')
          .where('marketingPersonName', isEqualTo: agentName.value)
          .orderBy('orderDate', descending: false)
          .get();

      List<String> validStatuses = [
        'approved', 'fab purchased', 'fab ready', 'cutting', 'cutting done',
        'printing', 'printed', 'stitching', 'stitched', 'packing', 'packed',
        'shipping', 'shipped', 'delivered', 'completed'
      ];

      Map<String, double> monthlySalesMap = {};
      double currentMonthGross = 0.0;
      double currentMonthNet = 0.0;
      int currentMonthOrderCount = 0;
      bool currentMonthMissingMargin = false;

      String targetMonthKey = DateFormat('yyyy-MM').format(targetMonth);

      for (var doc in allOrdersSnap.docs) {
        final data = doc.data();
        String status = (data['status'] ?? 'pending').toString().toLowerCase();

        if (validStatuses.contains(status) && data['isDeleteRequested'] != true && data['isDeleted'] != true) {
          DateTime orderDate = (data['orderDate'] as Timestamp).toDate();
          String monthKey = DateFormat('yyyy-MM').format(orderDate);

          double totalAmt = _parseAmount(data['totalAmount']);
          double effRev = _parseAmount(data['effectiveRevenue']);
          double finalAmount = (effRev > 0) ? effRev : totalAmt;

          monthlySalesMap[monthKey] = (monthlySalesMap[monthKey] ?? 0.0) + finalAmount;

          if (monthKey == targetMonthKey) {
            currentMonthOrderCount++;
            currentMonthGross += totalAmt;
            currentMonthNet += finalAmount;
            if (effRev <= 0) currentMonthMissingMargin = true;
          }
        }
      }

      double accumulatedDue = 0.0;
      List<String> sortedKeys = monthlySalesMap.keys.toList()..sort();
      hasPrevMonthData.value = sortedKeys.isNotEmpty;

      for (String mKey in sortedKeys) {
        if (mKey == targetMonthKey) break;

        double monthRevenue = monthlySalesMap[mKey] ?? 0.0;

        // Cumulative Debt Formula
        accumulatedDue = accumulatedDue + (baseTarget.value - monthRevenue);

        if (accumulatedDue < 0) {
          accumulatedDue = 0;
        }
      }

      // ✅ Evaluate the agent's career path BEFORE setting the UI variables
      await _evaluateAgentCareerPath(monthlySalesMap, accumulatedDue, currentMonthNet);

      // Set the Observables for the UI
      grossSales.value = currentMonthGross;
      netAchievement.value = currentMonthNet;
      totalOrders.value = currentMonthOrderCount;
      hasPendingER.value = currentMonthMissingMargin;

      if (accumulatedDue <= 0) {
        isPrevMonthCompleted.value = true;
        prevMonthPendingAmount.value = 0.0;
        currentDynamicTarget.value = baseTarget.value;
      } else {
        isPrevMonthCompleted.value = false;
        prevMonthPendingAmount.value = accumulatedDue;
        currentDynamicTarget.value = baseTarget.value + accumulatedDue;
      }

    } catch (e) {
      debugPrint("❌ Stats Error: $e");
    }
  }

  // =====================================================================
  // ✅ TIERED COMMISSION CALCULATOR
  // =====================================================================
  double calculateTieredBonus() {
    if (netAchievement.value < currentDynamicTarget.value) {
      return 0.0;
    }

    double surplusAmount = netAchievement.value - currentDynamicTarget.value;
    if (surplusAmount <= 0) return 0.0;

    double bonus = 0.0;
    double remainingSurplus = surplusAmount;

    if (remainingSurplus > 0) {
      double slab1Amount = remainingSurplus > 50000 ? 50000 : remainingSurplus;
      bonus += (slab1Amount * 0.02);
      remainingSurplus -= slab1Amount;
    }

    if (remainingSurplus > 0) {
      double slab2Amount = remainingSurplus > 50000 ? 50000 : remainingSurplus;
      bonus += (slab2Amount * 0.015);
      remainingSurplus -= slab2Amount;
    }

    if (remainingSurplus > 0) {
      bonus += (remainingSurplus * 0.01);
    }

    return bonus;
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

  // --- UPDATE ORDER ---
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

  // --- REQUEST DELETE ---
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

      await fetchAgentStats();
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

  double get achievementPercentage {
    if (baseTarget.value <= 0) return 0.0;
    return (grossSales.value / baseTarget.value).clamp(0.0, 1.0);
  }
}