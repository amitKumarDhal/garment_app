import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

  // Observables for Gross vs Net
  final grossSales = 0.0.obs;
  final netAchievement = 0.0.obs;
  final totalOrders = 0.obs;

  // Observable Target that adapts based on the user role
  final monthlyTarget = 100000.0.obs;

  Future<void> fetchAgentIdentity() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        String name = user.displayName ?? "Unknown";

        final userDoc = await _db.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          name = userDoc.data()?['FullName'] ?? userDoc.data()?['Name'] ?? name;

          // CHECK ROLE to set the personal target dynamically
          String role = (userDoc.data()?['Role'] ?? userDoc.data()?['role'] ?? '').toString().toLowerCase();
          if (role.contains('manager') || role == 'sales manager') {
            monthlyTarget.value = 150000.0;
          } else {
            monthlyTarget.value = 100000.0;
          }
        }
        agentName.value = name;
      }
    } catch (e) {
      debugPrint("Error fetching identity: $e");
    }
  }

  /// Master function to reload all data
  Future<void> loadDashboardData() async {
    if (_auth.currentUser == null) return; // Security Check

    isLoading.value = true;
    await fetchAgentIdentity();
    await Future.wait([fetchAgentStats(), fetchLeaderboard()]);
    isLoading.value = false;
  }

  // --- 2. Calculate My Personal Stats (Gross vs Net) ---
  Future<void> fetchAgentStats() async {
    if (agentName.value.isEmpty) await fetchAgentIdentity();
    if (agentName.value.isEmpty) return;

    try {
      DateTime now = DateTime.now();
      DateTime startOfMonth = DateTime(now.year, now.month, 1);
      DateTime endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final snapshot = await _db
          .collection('orders')
          .where('marketingPersonName', isEqualTo: agentName.value)
          .where('orderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('orderDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .orderBy('orderDate', descending: true)
          .get();

      double totalGross = 0.0;
      double totalNet = 0.0;
      int orderCount = 0;

      List<String> validStatuses = [
        'approved', 'cutting', 'stitching', 'printing', 'packing', 'shipping', 'delivered', 'completed'
      ];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        String status = (data['status'] ?? 'pending').toString().toLowerCase();

        // ✅ NEW: Check for both Delete Requests AND Soft Deletes
        bool isDeleteRequested = data['isDeleteRequested'] == true;
        bool isDeleted = data['isDeleted'] == true;

        if (validStatuses.contains(status) && !isDeleteRequested && !isDeleted) {
          orderCount++;
          double totalAmt = _parseAmount(data['totalAmount']);
          double effRev = _parseAmount(data['effectiveRevenue']);

          totalGross += totalAmt;
          totalNet += (effRev > 0) ? effRev : totalAmt;
        }
      }

      grossSales.value = totalGross;
      netAchievement.value = totalNet;
      totalOrders.value = orderCount;

    } catch (e) {
      debugPrint("❌ Stats Error: $e");
    }
  }

  // --- 3. Calculate Team Leaderboard (Using Effective Revenue) ---
  Future<void> fetchLeaderboard() async {
    try {
      isLoading.value = true;

      DateTime now = DateTime.now();
      DateTime start = DateTime(now.year, now.month, 1);
      DateTime end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // FETCH USER ROLES to build the leaderboard targets & tags accurately
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

      List<String> revenueStatuses = [
        'Approved', 'Cutting', 'Stitching', 'Printing', 'Packing', 'Shipping', 'Delivered',
        'approved', 'cutting', 'stitching', 'printing', 'packing', 'shipping', 'delivered'
      ];

      final snapshot = await _db
          .collection('orders')
          .where('status', whereIn: revenueStatuses)
          .where('orderDate', isGreaterThanOrEqualTo: start)
          .where('orderDate', isLessThanOrEqualTo: end)
          .get();

      Map<String, double> salesMap = {};
      Map<String, int> countMap = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        String status = (data['status'] ?? 'Pending').toString().toLowerCase();

        // ✅ NEW: Check for Soft Deletes
        bool isDeleteRequested = data['isDeleteRequested'] == true;
        bool isDeleted = data['isDeleted'] == true;

        if (revenueStatuses.contains(status) && !isDeleteRequested && !isDeleted) {
          String agent = data['marketingPersonName'] ?? 'Unknown';

          double totalAmt = _parseAmount(data['totalAmount']);
          double effRev = _parseAmount(data['effectiveRevenue']);
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

        bool isSM = managerMap[name] == true;
        double targetAmount = isSM ? 150000.0 : 100000.0;

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
        };
      }).toList();
    } catch (e) {
      debugPrint("Error fetching leaderboard: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // --- 4. UPDATE ORDER (Edit Logic) ---
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

  // --- 5. ✅ REQUEST DELETE ORDER LOGIC ---
  Future<void> deleteOrder(String orderId, String currentStatus) async {
    final lockedStatuses = ['shipping', 'shipped', 'delivered'];

    if (lockedStatuses.contains(currentStatus.toLowerCase())) {
      Get.snackbar(
        "Action Denied",
        "Orders in '$currentStatus' phase cannot be deleted.",
        backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
        colorText: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading.value = true;

      // ✅ CHANGE: Request deletion instead of hard deleting
      await _db.collection('orders').doc(orderId).update({
        'isDeleteRequested': true,
        'deleteRequestedAt': FieldValue.serverTimestamp(),
      });

      // ✅ NOTIFY MANAGERS
      try {
        final managerSnapshot = await _db.collection('users').where('Role', isEqualTo: 'Sales Manager').get();
        for (var managerDoc in managerSnapshot.docs) {
          await _db.collection('notifications').add({
            'targetUserId': managerDoc.id,
            'title': 'Deletion Request 🗑️',
            'message': '${agentName.value} requested to delete an order.',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });
        }
      } catch (e) {
        debugPrint("Could not notify manager: $e");
      }

      await fetchAgentStats();

      Get.snackbar(
        "Request Sent",
        "Deletion request sent to manager for approval.",
        backgroundColor: Colors.orange.withValues(alpha: 0.1),
        colorText: Colors.orange,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Could not send deletion request: $e",
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // --- Helper: Safely parse numbers ---
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

// ✅ UPDATED: Now shows progress according to Gross Sales
  double get achievementPercentage {
    if (monthlyTarget.value <= 0) return 0.0;
    // Change netAchievement.value to grossSales.value
    return (grossSales.value / monthlyTarget.value).clamp(0.0, 1.0);
  }}