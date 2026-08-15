import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/services/api_service.dart';

class StatsService {
  static Future<void> updateMonthlyStats({
    required String agentName,
    required DateTime orderDate,
    required double amountChange,
    required int countChange,
  }) async {
    try {
      String monthKey = DateFormat('yyyy-MM').format(orderDate);
      await ApiService.post('/analytics/agent-stats', {
        'agentName': agentName,
        'monthKey': monthKey,
        'amountChange': amountChange,
        'countChange': countChange,
      });
      debugPrint("✅ Stats updated for $agentName ($monthKey) | Amt: $amountChange | Count: $countChange");
    } catch (e) {
      debugPrint("❌ Failed to update stats: $e");
    }
  }
}