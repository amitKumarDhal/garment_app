import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../data/services/api_service.dart';

class MarketingController extends GetxController {
  var allAgents = <Map<String, dynamic>>[].obs;
  var filteredAgents = <Map<String, dynamic>>[].obs;
  var filteredClients = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDynamicAgentStats();
  }

  void initClients(List<dynamic> clients) {
    filteredClients.assignAll(clients.cast<Map<String, dynamic>>());
  }

  void searchClient(List<dynamic> allClients, String query) {
    final clients = allClients.cast<Map<String, dynamic>>();

    if (query.isEmpty) {
      filteredClients.assignAll(clients);
    } else {
      String lowerQuery = query.toLowerCase();
      filteredClients.assignAll(
        clients.where((c) {
          final name = (c['clientName'] ?? c['name'] ?? "").toString().toLowerCase();
          final org = (c['organization'] ?? c['org'] ?? "").toString().toLowerCase();
          return name.contains(lowerQuery) || org.contains(lowerQuery);
        }).toList(),
      );
    }
  }

  Future<void> fetchDynamicAgentStats() async {
    isLoading.value = true;
    try {
      final res = await ApiService.get('/analytics/leaderboard');
      if (res['success'] == true && res['leaderboard'] != null) {
        final list = List<Map<String, dynamic>>.from(res['leaderboard']);
        allAgents.assignAll(list);
        filteredAgents.assignAll(list);
      }
    } catch (e) {
      debugPrint("MarketingController fetch error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void searchAgent(String query) {
    if (query.isEmpty) {
      filteredAgents.assignAll(allAgents);
    } else {
      filteredAgents.assignAll(
        allAgents.where((a) => (a['name'] ?? a['agent_name'] ?? '').toString().toLowerCase().contains(query.toLowerCase())).toList(),
      );
    }
  }
}