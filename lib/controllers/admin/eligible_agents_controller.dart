import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/api_service.dart';

class EligibleAgentsController extends GetxController {
  var eligibleAgents = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchEligibleAgents();
  }

  Future<void> fetchEligibleAgents() async {
    try {
      isLoading.value = true;
      final res = await ApiService.get('/analytics/leaderboard');
      if (res['success'] == true && res['leaderboard'] != null) {
        final list = List<Map<String, dynamic>>.from(res['leaderboard']);
        eligibleAgents.assignAll(list);
      }
    } catch (e) {
      debugPrint("Fetch Eligible Agents Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  var selectedMonth = DateTime.now().obs;
  List<Map<String, dynamic>> get filteredAgents => eligibleAgents;

  void changeMonth(int monthDelta) {
    selectedMonth.value = DateTime(selectedMonth.value.year, selectedMonth.value.month + monthDelta, 1);
    fetchEligibleAgents();
  }
}