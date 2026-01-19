import 'package:get/get.dart';

class MarketingController extends GetxController {
  // Observables for state management
  var allAgents = <Map<String, dynamic>>[].obs;
  var filteredAgents = <Map<String, dynamic>>[].obs;
  var filteredClients = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadDummyData();
  }

  void _loadDummyData() {
    allAgents.value = [
      {
        "name": "Amit Sharma",
        "avatar": "AS",
        "revenue": "₹18.2L", // Formatted for UI
        "orders": 2,
        "clients": [
          {
            "name": "Global Tech Corp",
            "org": "GT Solutions",
            "status": "Processing",
            "qty": 500,
            "value": "₹5,40,000",
            "numericValue": 540000, // Used for calculation
            "phone": "9876543210",
            "address": "Bhubaneswar, Odisha",
            "gst": "18%",
            "targetDate": "25 Jan 2026",
          },
          {
            "name": "Pioneer Industries",
            "org": "Pioneer Group",
            "status": "Delivered",
            "qty": 1200,
            "value": "₹12,80,000",
            "numericValue": 1280000,
            "phone": "9988776655",
            "address": "Cuttack, Odisha",
            "gst": "12%",
            "targetDate": "10 Feb 2026",
          },
        ],
      },
      {
        "name": "Sneha Reddy",
        "avatar": "SR",
        "revenue": "₹0",
        "orders": 0,
        "clients": [],
      },
    ];
    filteredAgents.assignAll(allAgents);
  }

  // --- Helper to update totals dynamically ---
  // Call this whenever a new order is added to an agent
  void calculateAgentStats(int agentIndex) {
    double totalRevenue = 0;
    List clients = allAgents[agentIndex]['clients'];

    for (var client in clients) {
      totalRevenue += (client['numericValue'] ?? 0);
    }

    // Convert to Lakhs format (e.g., 1820000 -> 18.2L)
    allAgents[agentIndex]['revenue'] =
        "₹${(totalRevenue / 100000).toStringAsFixed(1)}L";
    allAgents[agentIndex]['orders'] = clients.length;

    allAgents.refresh(); // Notifies the Obx listeners in the UI
    filteredAgents.assignAll(allAgents); // Syncs the search list
  }

  // --- Search Logic for Agents ---
  void searchAgent(String query) {
    if (query.isEmpty) {
      filteredAgents.assignAll(allAgents);
    } else {
      filteredAgents.assignAll(
        allAgents.where(
          (a) =>
              a['name'].toString().toLowerCase().contains(query.toLowerCase()),
        ),
      );
    }
  }

  // --- Client Management ---
  void initClients(List<dynamic> clients) {
    filteredClients.assignAll(clients.cast<Map<String, dynamic>>());
  }

  void searchClient(List<dynamic> allClients, String query) {
    final clients = allClients.cast<Map<String, dynamic>>();
    if (query.isEmpty) {
      filteredClients.assignAll(clients);
    } else {
      filteredClients.assignAll(
        clients.where(
          (c) =>
              c['name'].toString().toLowerCase().contains(
                query.toLowerCase(),
              ) ||
              c['org'].toString().toLowerCase().contains(query.toLowerCase()),
        ),
      );
    }
  }
}
