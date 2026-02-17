import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // ✅ Needed for Colors
import 'package:get/get.dart';
import '../../data/models/order_model.dart'; // ✅ Ensure this is imported

class SalesAgentController extends GetxController {
  static SalesAgentController get instance => Get.find();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // Observables
  final leaderboardData = <Map<String, dynamic>>[].obs;
  final isLoading = true.obs;
  final agentName = "".obs;
  final monthlyAchievement = 0.0.obs;

  // Target Configuration
  final double monthlyTarget = 100000.0;

  /// Master function to reload all data
  Future<void> loadDashboardData() async {
    if (_auth.currentUser == null) return; // Security Check

    isLoading.value = true;
    await fetchAgentIdentity();
    await Future.wait([fetchAgentStats(), fetchLeaderboard()]);
    isLoading.value = false;
  }

  // --- 1. Get Agent Identity ---
  Future<void> fetchAgentIdentity() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        String name = user.displayName ?? "Unknown";

        // Try to fetch specific profile name from 'users' collection
        final userDoc = await _db.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          name = userDoc.data()?['FullName'] ?? userDoc.data()?['Name'] ?? name;
        }
        agentName.value = name;
      }
    } catch (e) {
      print("Error fetching identity: $e");
    }
  }

  // --- 2. Calculate My Personal Stats (Approved Only) ---
  // --- 2. Calculate My Personal Stats (Includes All Revenue Generating Statuses) ---
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
          .where('orderDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('orderDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .orderBy('orderDate', descending: true)
          .get();

      double total = 0.0;

      // ✅ DEFINE VALID STATUSES (Money that counts)
      // We exclude 'Pending', 'Placed', and 'Rejected'
      List<String> validStatuses = [
        'approved',
        'cutting',
        'stitching',
        'printing',
        'packing',
        'shipping',
        'delivered', 
        'completed'
      ];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        String status = (data['status'] ?? 'pending').toString().toLowerCase();

        // ✅ CHECK IF STATUS IS IN THE VALID LIST
        if (validStatuses.contains(status)) {
          double amount = _parseAmount(data['totalAmount']);
          total += amount;
        }
      }

      monthlyAchievement.value = total;
      print("💰 Total Achievement (All Stages): $total");
    } catch (e) {
      print("❌ Stats Error: $e");
    }
  }
  // --- 3. Calculate Team Leaderboard ---
  // --- 3. Calculate Team Leaderboard (Includes All Active Revenue) ---
  Future<void> fetchLeaderboard() async {
    try {
      isLoading.value = true; 

      DateTime now = DateTime.now();
      DateTime start = DateTime(now.year, now.month, 1);
      DateTime end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // ✅ DEFINE VALID REVENUE STATUSES
      // (Must match the list used in Manager Controller)
      List<String> revenueStatuses = [
        'Approved',
        'Cutting',
        'Stitching',
        'Printing',
        'Packing',
        'Shipping',
        'Delivered',
        // Add lowercase versions if your database has mixed casing
        'approved', 'cutting', 'stitching', 'printing', 'packing', 'shipping', 'delivered'
      ];

      final snapshot = await _db
          .collection('orders')
          // ✅ FIX: Use 'whereIn' to catch all stages of the sale
          .where('status', whereIn: revenueStatuses)
          .where('orderDate', isGreaterThanOrEqualTo: start)
          .where('orderDate', isLessThanOrEqualTo: end)
          .get();

      Map<String, double> salesMap = {};
      Map<String, int> countMap = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        String agent = data['marketingPersonName'] ?? 'Unknown';

        double amount = _parseAmount(data['totalAmount']);

        salesMap[agent] = (salesMap[agent] ?? 0) + amount;
        countMap[agent] = (countMap[agent] ?? 0) + 1;
      }

      // Sort High to Low
      var sortedEntries = salesMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      double targetAmount = 100000.0;

      leaderboardData.value = sortedEntries.map((e) {
        String name = e.key;
        double amount = e.value;
        int count = countMap[name] ?? 0;

        double progress = amount / targetAmount;

        String greeting = "";
        if (progress >= 1.5) {
          greeting = "Unstoppable! 🚀";
        } else if (progress >= 1.0) greeting = "Target Smashed! 🏆";
        else if (progress >= 0.8) greeting = "Almost there! 🔥";
        else if (progress >= 0.5) greeting = "Halfway point 💪";
        else greeting = "Keep Pushing 📉";

        return {
          'name': name,
          'amount': amount,
          'count': count,
          'progress': progress, 
          'greeting': greeting,
        };
      }).toList();
    } catch (e) {
      print("Error fetching leaderboard: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // --- 4. ✅ UPDATE ORDER (Edit Logic) ---
  Future<void> updateOrder(OrderModel originalOrder, int newQty, double newPrice, String newDetails) async {
    try {
      isLoading.value = true;

      // 1. Calculate new totals
      double subTotal = newQty * newPrice;
      
      // Calculate GST Amount based on percentage
      double gstAmount = (subTotal * originalOrder.gstPercentage) / 100;
      
      // New Grand Total
      double newTotal = subTotal + gstAmount + originalOrder.shippingCharge;
      
      // New Balance Due (Total - Advance already paid)
      double newBalance = newTotal - originalOrder.advanceAmount;

      // 2. Prepare Data for Firestore
      Map<String, dynamic> updateData = {
        'quantity': newQty,
        'totalAmount': newTotal,
        'balanceDue': newBalance,
        'productDetails': newDetails,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update product price inside the products list (assuming single product editing for now)
      if (originalOrder.products.isNotEmpty) {
        List<dynamic> updatedProducts = List.from(originalOrder.products);
        if (updatedProducts[0] is Map) {
             Map<String, dynamic> firstProduct = Map<String, dynamic>.from(updatedProducts[0]);
             firstProduct['price'] = newPrice;
             updatedProducts[0] = firstProduct;
        }
        updateData['products'] = updatedProducts;
      }

      // 3. Update Firestore
      await _db
          .collection('orders')
          .doc(originalOrder.id)
          .update(updateData);
      
      // 4. Refresh stats to reflect new amounts
      await fetchAgentStats();

      Get.snackbar("Success", "Order updated successfully!",
          backgroundColor: Colors.green.withOpacity(0.1), colorText: Colors.green);
      
    } catch (e) {
      Get.snackbar("Error", "Failed to update order: $e",
          backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red);
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

  double get achievementPercentage {
    if (monthlyTarget <= 0) return 0.0;
    return (monthlyAchievement.value / monthlyTarget).clamp(0.0, 1.0);
  }
}