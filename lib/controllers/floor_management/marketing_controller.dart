import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // ✅ Added for premium Indian Rupee formatting
import '../../data/models/order_model.dart';

class MarketingController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Observables ---
  var allAgents = <Map<String, dynamic>>[].obs;
  var filteredAgents = <Map<String, dynamic>>[].obs;
  var filteredClients = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDynamicAgentStats();
  }

  // --- 1. Initialize the clients list for the detail page ---
  void initClients(List<dynamic> clients) {
    filteredClients.assignAll(clients.cast<Map<String, dynamic>>());
  }

  // --- 2. Search logic specifically for the detail page list ---
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

  // --- 3. The Real-Time Aggregator ---
  void fetchDynamicAgentStats() {
    isLoading.value = true;
    final formatCurrency = NumberFormat('#,##,##0', 'en_IN');

    // ✅ Match the valid statuses from the SalesAgentController so numbers align perfectly
    final List<String> validRevenueStatuses = [
      'approved', 'cutting', 'stitching', 'printing',
      'packing', 'shipping', 'delivered', 'completed'
    ];

    _db.collection('orders').snapshots().listen((snapshot) {
      final allOrders = snapshot.docs.map((doc) => OrderModel.fromSnapshot(doc)).toList();

      Map<String, Map<String, dynamic>> agentMap = {};

      for (var order in allOrders) {
        String agentName = order.marketingPersonName;

        if (!agentMap.containsKey(agentName)) {
          agentMap[agentName] = {
            "name": agentName,
            "avatar": agentName.length >= 2 ? agentName.substring(0, 2).toUpperCase() : "A",
            "revenue": 0.0,
            "orders": 0,
            "clients": <Map<String, dynamic>>[],
            "uniqueClientNames": <String>{},
          };
        }

        var agent = agentMap[agentName]!;
        agent["clients"].add(order.toJson());
        agent["uniqueClientNames"].add(order.clientName.toLowerCase().trim());
        agent["orders"] += 1;

        // ✅ Count revenue across ALL active production stages
        if (validRevenueStatuses.contains(order.status.toLowerCase())) {
          agent["revenue"] += order.totalAmount;
        }
      }

      final List<Map<String, dynamic>> dynamicList = agentMap.values.map((agent) {
        double rawRev = agent["revenue"];

        return {
          "name": agent["name"],
          "avatar": agent["avatar"],
          "rawRevenue": rawRev, // ✅ Keep raw number strictly for accurate mathematical sorting
          "revenue": "₹${formatCurrency.format(rawRev)}", // ✅ Format to ₹1,50,000 for the UI
          "orders": agent["orders"],
          "clients": agent["clients"],
          "uniqueClientsCount": agent["uniqueClientNames"].length,
        };
      }).toList();

      // ✅ Fix: Sort by the raw Double, not the formatted String!
      dynamicList.sort((a, b) => (b["rawRevenue"] as double).compareTo(a["rawRevenue"] as double));

      allAgents.assignAll(dynamicList);
      filteredAgents.assignAll(dynamicList);
      isLoading.value = false;
    });
  }

  // --- 4. Search Logic for Agent List ---
  void searchAgent(String query) {
    if (query.isEmpty) {
      filteredAgents.assignAll(allAgents);
    } else {
      filteredAgents.assignAll(
        allAgents.where((a) => a['name'].toString().toLowerCase().contains(query.toLowerCase())).toList(),
      );
    }
  }
}