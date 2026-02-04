import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SalesAgentController extends GetxController {
  static SalesAgentController get instance => Get.find();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // Observables
  final leaderboardData = <Map<String, dynamic>>[].obs;
  final isLoading = true.obs;
  final agentName = "".obs;
  final monthlyAchievement = 0.0.obs;

  // Target Configuration (Could be fetched from DB later)
  final double monthlyTarget = 1000000.0; // ₹10,00,000

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  /// Master function to load everything
  Future<void> loadDashboardData() async {
    isLoading.value = true;
    await fetchAgentIdentity(); // 1. Get Name First
    await Future.wait([
      fetchAgentStats(), // 2. Get Personal Stats
      fetchLeaderboard(), // 3. Get Leaderboard
    ]);
    isLoading.value = false;
  }

  /// 1. Get the Agent's Name from 'id_requests'
  Future<void> fetchAgentIdentity() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        String name = user.displayName ?? "Unknown";

        // Check Firestore for the official registered name
        final userDoc = await _db.collection('id_requests').doc(user.uid).get();
        if (userDoc.exists) {
          name = userDoc.data()?['name'] ?? name;
        }
        agentName.value = name;
      }
    } catch (e) {
      debugPrint("Error fetching identity: $e");
    }
  }

  /// 2. Calculate "My Achievement" for the current month
  Future<void> fetchAgentStats() async {
    if (agentName.value.isEmpty) return;

    try {
      final DateTime now = DateTime.now();

      // Query all orders for this agent
      // (Optimization: In the future, you can add .where('orderDate') here with an index)
      final snapshot = await _db
          .collection('orders')
          .where('marketingPersonName', isEqualTo: agentName.value)
          .get();

      double totalApproved = 0.0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final String status = data['status'] ?? '';
        final Timestamp? orderTimestamp = data['orderDate'] as Timestamp?;
        final double amount = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;

        if (orderTimestamp != null) {
          DateTime date = orderTimestamp.toDate();

          // ✅ Filter: Must be 'Approved' AND in the current Month/Year
          if (status == 'Approved' &&
              date.month == now.month &&
              date.year == now.year) {
            totalApproved += amount;
          }
        }
      }

      monthlyAchievement.value = totalApproved;
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to load stats: $e",
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    }
  }

  /// 3. Calculate Leaderboard (Top Agents this Month)
  Future<void> fetchLeaderboard() async {
    try {
      final DateTime now = DateTime.now();

      // Fetch ALL approved orders
      final snapshot = await _db
          .collection('orders')
          .where('status', isEqualTo: 'Approved')
          .get();

      // Map to aggregate totals: { "Agent Name": 50000.0 }
      Map<String, double> agentTotals = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final Timestamp? timestamp = data['orderDate'] as Timestamp?;
        final String name = data['marketingPersonName'] ?? 'Unknown';
        final double amount = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;

        if (timestamp != null) {
          DateTime date = timestamp.toDate();
          // ✅ Only count orders from THIS month
          if (date.month == now.month && date.year == now.year) {
            agentTotals[name] = (agentTotals[name] ?? 0.0) + amount;
          }
        }
      }

      // Convert Map to List of Maps for the UI
      List<Map<String, dynamic>> sortedList = agentTotals.entries.map((e) {
        return {
          "name": e.key,
          "totalVal": e.value,
          // Format: 1.5L
          "totalDisplay": "₹${(e.value / 100000).toStringAsFixed(1)}L",
          // Calculate progress bar (0.0 to 1.0)
          "progress": (e.value / monthlyTarget).clamp(0.0, 1.0),
        };
      }).toList();

      // Sort: Highest Value First
      sortedList.sort((a, b) => b['totalVal'].compareTo(a['totalVal']));

      // Assign Rank (1, 2, 3...)
      for (int i = 0; i < sortedList.length; i++) {
        sortedList[i]['rank'] = (i + 1).toString();
      }

      leaderboardData.assignAll(sortedList);
    } catch (e) {
      debugPrint("Leaderboard Error: $e");
    }
  }

  /// ✅ Helper: Get Progress % for UI (0.0 to 1.0)
  double get achievementPercentage {
    if (monthlyTarget <= 0) return 0.0;
    return (monthlyAchievement.value / monthlyTarget).clamp(0.0, 1.0);
  }
}
