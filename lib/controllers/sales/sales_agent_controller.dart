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
  final double monthlyTarget = 1000000.0;

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

  // --- 2. Calculate My Personal Stats (Current Month) ---
  Future<void> fetchAgentStats() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Define Current Month Range
      DateTime now = DateTime.now();
      DateTime startOfMonth = DateTime(now.year, now.month, 1);
      DateTime endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // Query by 'orderDate' for better reliability
      final snapshot = await _db
          .collection('orders')
          .where('marketingPersonId', isEqualTo: user.uid)
          .where(
            'orderDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .where(
            'orderDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth),
          )
          .get();

      double total = 0.0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        String status = data['status'] ?? 'Pending';

        // ✅ Check Status (Case Insensitive)
        if (status == 'Approved' || status == 'approved') {
          // ✅ Parse Amount Safely
          double amount = _parseAmount(data['totalAmount']);
          total += amount;
        }
      }

      monthlyAchievement.value = total;
    } catch (e) {
      print("Stats Error: $e");
    }
  }

  // --- 3. Calculate Team Leaderboard (Current Month) ---
  Future<void> fetchLeaderboard() async {
    try {
      isLoading.value = true;
      DateTime now = DateTime.now();
      DateTime startOfMonth = DateTime(now.year, now.month, 1);
      DateTime endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      print("🔍 Fetching Leaderboard: ${DateFormat('MMM yyyy').format(now)}");

      // Query ALL orders for this month using 'orderDate'
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
          .get();

      print("📄 Found ${snapshot.docs.length} orders this month.");

      Map<String, double> agentTotals = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        String name = data['marketingPersonName'] ?? 'Unknown Agent';
        String status = data['status'] ?? 'Pending';

        // ✅ 1. Check Status
        if (status == 'Approved' || status == 'approved') {
          // ✅ 2. Parse Amount Safely
          double amount = _parseAmount(data['totalAmount']);

          // ✅ 3. Aggregate Totals
          if (agentTotals.containsKey(name)) {
            agentTotals[name] = agentTotals[name]! + amount;
          } else {
            agentTotals[name] = amount;
          }
        }
      }

      // Sort: Highest First
      var sortedEntries = agentTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Calculate Highest Sale for Progress Bar (Prevent divide by zero)
      double highestSale = sortedEntries.isNotEmpty
          ? sortedEntries.first.value
          : 1.0;
      if (highestSale == 0) highestSale = 1.0;

      // Map to UI Structure
      leaderboardData.value = sortedEntries.asMap().entries.map((entry) {
        int rank = entry.key + 1;
        double amount = entry.value.value;

        return {
          "rank": rank.toString(),
          "name": entry.value.key,
          "amount": amount, // Store exact double for calculations
          "totalDisplay": NumberFormat.compactCurrency(
            symbol: '₹',
            locale: 'en_IN',
          ).format(amount),
          "progress": (amount / highestSale),
        };
      }).toList();
    } catch (e) {
      print("Leaderboard Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // --- ✅ CRITICAL HELPER: Safely parse numbers ---
  double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) {
      // Remove commas or currency symbols if present
      String clean = value.replaceAll(',', '').replaceAll('₹', '').trim();
      return double.tryParse(clean) ?? 0.0;
    }
    return 0.0;
  }

  // Helper for UI Progress Bar
  double get achievementPercentage {
    if (monthlyTarget <= 0) return 0.0;
    return (monthlyAchievement.value / monthlyTarget).clamp(0.0, 1.0);
  }
}
