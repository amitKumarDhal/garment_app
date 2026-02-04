import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../data/models/order_model.dart';

class MarketingController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Observables ---
  var allAgents = <Map<String, dynamic>>[].obs;
  var filteredAgents = <Map<String, dynamic>>[].obs;

  // ✅ ADD THIS LINE: It was missing and causing the "undefined" error
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
          final name = (c['clientName'] ?? c['name'] ?? "")
              .toString()
              .toLowerCase();
          final org = (c['organization'] ?? c['org'] ?? "")
              .toString()
              .toLowerCase();
          return name.contains(lowerQuery) || org.contains(lowerQuery);
        }).toList(),
      );
    }
  }

  // --- 3. The Real-Time Aggregator ---
  void fetchDynamicAgentStats() {
    isLoading.value = true;

    _db.collection('orders').snapshots().listen((snapshot) {
      final allOrders = snapshot.docs
          .map((doc) => OrderModel.fromSnapshot(doc))
          .toList();

      Map<String, Map<String, dynamic>> agentMap = {};

      for (var order in allOrders) {
        String agentName = order.marketingPersonName;

        if (!agentMap.containsKey(agentName)) {
          agentMap[agentName] = {
            "name": agentName,
            "avatar": agentName.length >= 2
                ? agentName.substring(0, 2).toUpperCase()
                : "A",
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

        if (order.status.toLowerCase() == 'approved') {
          agent["revenue"] += order.totalAmount;
        }
      }

      // ✅ Syntax Fixed here (removed extra comma/parameter in .map)
      final List<Map<String, dynamic>> dynamicList = agentMap.values.map((
        agent,
      ) {
        double rev = agent["revenue"];

        return {
          "name": agent["name"],
          "avatar": agent["avatar"],
          "revenue": "₹${(rev / 100000).toStringAsFixed(1)}L",
          "orders": agent["orders"],
          "clients": agent["clients"],
          "uniqueClientsCount": agent["uniqueClientNames"].length,
        };
      }).toList();

      dynamicList.sort((a, b) => b["revenue"].compareTo(a["revenue"]));

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
        allAgents
            .where(
              (a) => a['name'].toString().toLowerCase().contains(
                query.toLowerCase(),
              ),
            )
            .toList(),
      );
    }
  }
}
