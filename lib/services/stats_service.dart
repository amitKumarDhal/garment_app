import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StatsService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Call this WHENEVER an order is Placed, Updated, or Deleted.
  /// Use negative numbers for [amountChange] and [countChange] if an order is deleted.
  static Future<void> updateMonthlyStats({
    required String agentName,
    required DateTime orderDate,
    required double amountChange,
    required int countChange,
  }) async {
    try {
      // 1. Create the exact Month Key (e.g., "2026-04")
      String monthKey = DateFormat('yyyy-MM').format(orderDate);

      // 2. Create a unique Document ID (e.g., "Amit_2026-04")
      // Remove spaces from the agent's name to ensure clean IDs
      String safeAgentName = agentName.trim().replaceAll(' ', '_');
      String docId = "${safeAgentName}_$monthKey";

      // 3. Point to the new lightweight collection
      DocumentReference statsRef = _db.collection('monthly_agent_stats').doc(docId);

      // 4. Safely increment the math on Firebase's servers
      await statsRef.set({
        'agentName': agentName, // Keep original name for display
        'monthKey': monthKey,
        'totalNetRevenue': FieldValue.increment(amountChange),
        'totalOrders': FieldValue.increment(countChange),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint("✅ Stats updated for $agentName ($monthKey) | Amt: $amountChange | Count: $countChange");

    } catch (e) {
      debugPrint("❌ Failed to update stats: $e");
    }
  }
}