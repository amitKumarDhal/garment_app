import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class SalesAgentController extends GetxController {
  static SalesAgentController get instance => Get.find();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // Observables
  final leaderboardData = <Map<String, dynamic>>[].obs;
  final isLoading = true.obs;
  final agentName = "".obs;
  final monthlyAchievement = 0.0.obs;

  // Target Configuration (e.g., ₹10,00,000)
  final double monthlyTarget = 100000.0;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  /// Master function to reload all data
  Future<void> loadDashboardData() async {
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
          .where(
            'orderDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .where(
            'orderDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth),
          )
          // ✅ FIX: Match your existing Firestore Index (Descending)
          .orderBy('orderDate', descending: true)
          .get();

      double total = 0.0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        // Convert status to lowercase to handle 'Approved', 'approved', 'APPROVED'
        String status = (data['status'] ?? 'pending').toString().toLowerCase();

        // ✅ FIXED: Only count strictly 'approved'
        if (status == 'approved') {
          double amount = _parseAmount(data['totalAmount']);
          total += amount;
        }
      }

      monthlyAchievement.value = total;
      print("💰 Total Approved Achievement: $total");
    } catch (e) {
      print("❌ Stats Error: $e");
    }
  }

  // --- 3. Calculate Team Leaderboard (With Greetings & Overachievement) ---
  Future<void> fetchLeaderboard() async {
    try {
      isLoading.value = true;
      DateTime now = DateTime.now();
      DateTime startOfMonth = DateTime(now.year, now.month, 1);
      DateTime endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // Query ALL orders for this month
      final snapshot = await _db
          .collection('orders')
          .where(
            'orderDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .where(
            'orderDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth),
          )
          .orderBy('orderDate', descending: true)
          .get();

      Map<String, double> agentTotals = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        String name = data['marketingPersonName'] ?? 'Unknown Agent';
        String status = (data['status'] ?? 'Pending').toString().toLowerCase();

        if (status == 'approved') {
          double amount = _parseAmount(data['totalAmount']);
          if (agentTotals.containsKey(name)) {
            agentTotals[name] = agentTotals[name]! + amount;
          } else {
            agentTotals[name] = amount;
          }
        }
      }

      var sortedEntries = agentTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      leaderboardData.value = sortedEntries.asMap().entries.map((entry) {
        int rank = entry.key + 1;
        double amount = entry.value.value;

        // ✅ 1. Remove .clamp() to allow > 100% progress
        double progress = (monthlyTarget > 0) ? (amount / monthlyTarget) : 0.0;

        // ✅ 2. Add a Fun Greeting based on Rank
        String greeting = "";
        if (rank == 1)
          greeting = "👑 Leading the Pack!";
        else if (rank == 2)
          greeting = "🔥 On Fire!";
        else if (rank == 3)
          greeting = "🚀 Sky High!";
        else if (progress >= 1.0)
          greeting = "🌟 Super Star!"; // Overachiever
        else
          greeting = "💪 Keep Pushing!";

        return {
          "rank": rank.toString(),
          "name": entry.value.key,
          "amount": amount,
          "totalDisplay": NumberFormat.compactCurrency(
            symbol: '₹',
            locale: 'en_IN',
          ).format(amount),
          "progress": progress, // Raw value (can be 1.2, 1.5 etc.)
          "greeting": greeting, // New field you can show in UI!
        };
      }).toList();
    } catch (e) {
      print("Leaderboard Error: $e");
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
