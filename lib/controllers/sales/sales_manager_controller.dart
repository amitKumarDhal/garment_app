import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/order_model.dart';

class SalesManagerController extends GetxController {
  static SalesManagerController get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Observables
  var pendingOrders = <OrderModel>[].obs;
  var topAgents = <Map<String, dynamic>>[].obs;
  var totalRevenue = 0.0.obs;
  var isLoading = true.obs;

  // Store the currently selected month (Defaults to Today)
  var selectedMonth = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllData();

    // 🔍 DEBUG: Auto-investigate this agent on launch
    // Look at your Debug Console for the output starting with "🕵️‍♂️"
    investigateAgent("Satyabrata Majhi");
  }

  // ✅ Master Fetch Function
  void fetchAllData() async {
    try {
      isLoading.value = true;
      await Future.wait([
        fetchPendingOrders(),
        fetchMonthlyStats(), // Now uses selectedMonth
      ]);
    } catch (e) {
      debugPrint("Error fetching dashboard data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Method called by the UI when user picks a date
  void changeMonth(DateTime newMonth) {
    selectedMonth.value = newMonth;
    fetchMonthlyStats(); // Reload stats for the new month
  }

  // --- 1. Fetch Pending Orders (Real-time, Always Global) ---
  Future<void> fetchPendingOrders() async {
    try {
      _db
          .collection('orders')
          .where('status', isEqualTo: 'Pending')
          .orderBy('orderDate', descending: true)
          .snapshots()
          .listen((snapshot) {
            pendingOrders.value = snapshot.docs
                .map((doc) => OrderModel.fromSnapshot(doc))
                .toList();
          });
    } catch (e) {
      print("Error fetching pending: $e");
    }
  }

  // --- 2. Calculate Monthly Stats & Leaderboard ---
  Future<void> fetchMonthlyStats() async {
    try {
      DateTime targetDate = selectedMonth.value;
      DateTime startOfMonth = DateTime(targetDate.year, targetDate.month, 1);
      DateTime endOfMonth = DateTime(
        targetDate.year,
        targetDate.month + 1,
        0,
        23,
        59,
        59,
      );

      print("\n🔍 --- DEBUGGING SALES STATS ---");
      print("📅 Selected Month: ${DateFormat('MMM yyyy').format(targetDate)}");
      print("⏳ Query Range: $startOfMonth  TO  $endOfMonth");

      final snapshot = await _db
          .collection('orders')
          .where('status', isEqualTo: 'Approved')
          .where('orderDate', isGreaterThanOrEqualTo: startOfMonth)
          .where('orderDate', isLessThanOrEqualTo: endOfMonth)
          .get();

      print("✅ Query Success! Found ${snapshot.docs.length} approved orders.");

      double total = 0.0;
      Map<String, double> agentSales = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // Debug each order found
        print(
          "   -> Order ID: ${doc.id} | Agent: ${data['marketingPersonName']} | Amount: ${data['totalAmount']}",
        );

        double amount = 0.0;
        var rawAmount = data['totalAmount'];

        if (rawAmount is num) {
          amount = rawAmount.toDouble();
        } else if (rawAmount is String) {
          amount = double.tryParse(rawAmount) ?? 0.0;
        }

        String agent = data['marketingPersonName'] ?? 'Unknown';

        total += amount;
        agentSales[agent] = (agentSales[agent] ?? 0) + amount;
      }

      print("💰 Calculated Total Revenue: $total");

      totalRevenue.value = total;

      var sortedAgents = agentSales.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      topAgents.value = sortedAgents
          .take(5)
          .map(
            (e) => {
              'name': e.key,
              'amount': e.value,
              'formatted': NumberFormat.compactCurrency(
                symbol: '₹',
                locale: 'en_IN',
              ).format(e.value),
            },
          )
          .toList();

      print("🏆 Leaderboard Updated: ${topAgents.length} agents found.");
      print("----------------------------------\n");
    } catch (e) {
      print("❌ STATS ERROR: $e");

      // CHECK FOR MISSING INDEX ERROR
      if (e.toString().contains("index")) {
        print(
          "🚨 CRITICAL: MISSING INDEX! Click the link in the console to create it.",
        );
        Get.snackbar(
          "System Alert",
          "Database Index Missing. Check Console Log.",
          duration: const Duration(seconds: 10),
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  // --- 🔍 DEBUG TOOL: INVESTIGATE AGENT ---
  // This will tell you exactly why orders are missing
  void investigateAgent(String agentName) async {
    print("\n🕵️‍♂️ --- INVESTIGATING AGENT: $agentName ---");

    // Get ALL orders for this person, ignoring filters
    try {
      final snapshot = await _db
          .collection('orders')
          .where('marketingPersonName', isEqualTo: agentName)
          .get();

      print(
        "📄 Found ${snapshot.docs.length} total documents for '$agentName'",
      );

      if (snapshot.docs.isEmpty) {
        print(
          "⚠️ WARNING: No orders found with exact name '$agentName'. Check spelling!",
        );
      }

      for (var doc in snapshot.docs) {
        final data = doc.data();
        String status = data['status'] ?? 'Unknown';
        DateTime? date = (data['orderDate'] as Timestamp?)?.toDate();
        var rawAmount = data['totalAmount'];
        double amount = 0.0;

        if (rawAmount is num) {
          amount = rawAmount.toDouble();
        } else if (rawAmount is String)
          // ignore: curly_braces_in_flow_control_structures
          amount = double.tryParse(rawAmount) ?? 0.0;

        print("   -> Order ${doc.id}:");
        print("      💰 Amount: ₹$amount");
        print(
          "      📊 Status: $status ${status == 'Approved' ? '✅' : '❌ (Must be Approved)'}",
        );

        // Check Date Match
        if (date != null) {
          String month = DateFormat('MMM yyyy').format(date);
          String selected = DateFormat('MMM yyyy').format(selectedMonth.value);

          // Check if month and year match
          bool matchMonth =
              selectedMonth.value.month == date.month &&
              selectedMonth.value.year == date.year;

          print(
            "      📅 Date: $month ${matchMonth ? '✅ Matches Dashboard' : '❌ Mismatch (Dashboard is $selected)'}",
          );
        } else {
          print("      📅 Date: NULL ❌");
        }
        print("--------------------------------");
      }
    } catch (e) {
      print("🕵️‍♂️ Investigation Error: $e");
    }
  }

  // --- 3. Approve / Reject Logic ---
  Future<void> approveOrder(String orderId) async {
    await _updateStatus(orderId, 'Approved', Colors.green);
  }

  Future<void> rejectOrder(String orderId) async {
    await _updateStatus(orderId, 'Rejected', Colors.red);
  }

  Future<void> _updateStatus(
    String orderId,
    String newStatus,
    Color color,
  ) async {
    try {
      await _db.collection('orders').doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Refresh stats if an order was just approved
      if (newStatus == 'Approved') fetchMonthlyStats();

      Get.snackbar(
        "Order $newStatus",
        "Successfully updated status.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: color.withValues(alpha: 0.1),
        colorText: color,
      );
    } catch (e) {
      Get.snackbar("Update Failed", e.toString());
    }
  }
}
