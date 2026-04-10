import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

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
  Future<void> fetchDynamicAgentStats() async {
    isLoading.value = true;
    final formatCurrency = NumberFormat('#,##,##0', 'en_IN');

    try {
      // ✅ Step 1: Fetch all users to ensure even new agents with 0 sales appear
      final usersSnap = await _db.collection('users').get();
      List<String> salesRoles = ['Sales Agent', 'Sales Manager', 'JSA', 'SSA', 'SC', 'SM'];
      Map<String, Map<String, dynamic>> baseAgentMap = {};

      for (var doc in usersSnap.docs) {
        final data = doc.data();
        String role = (data['Role'] ?? data['role'] ?? '').toString();

        if (salesRoles.any((r) => role.toUpperCase().contains(r.toUpperCase()))) {
          String name = data['FullName'] ?? data['name'] ?? 'Unknown';
          if (name != 'Unknown') {
            baseAgentMap[name] = {
              "name": name,
              "avatar": name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase(),
              "role": role,
              "revenue": 0.0,
              "orders": 0,
              "clients": <Map<String, dynamic>>[],
              "uniqueClientNames": <String>{},
            };
          }
        }
      }

      // ✅ Define valid statuses for revenue calculation (excludes deleted/cancelled)
      final List<String> validRevenueStatuses = [
        'placed', 'pending', 'approved', 'fab purchased', 'fab ready',
        'cutting', 'cutting done', 'printing', 'printed', 'stitching', 'stitched',
        'packing', 'packed', 'out src', 'shipping', 'shipped', 'delivered', 'completed'
      ];

      // ✅ Step 2: Listen to real-time order updates
      _db.collection('orders').snapshots().listen((snapshot) {

        // Clone the base map so we reset to 0 before applying the fresh snapshot data
        Map<String, Map<String, dynamic>> liveAgentMap = {};
        baseAgentMap.forEach((key, value) {
          liveAgentMap[key] = Map.from(value);
          liveAgentMap[key]!['clients'] = <Map<String, dynamic>>[];
          liveAgentMap[key]!['uniqueClientNames'] = <String>{};
        });

        for (var doc in snapshot.docs) {
          final data = doc.data();
          if (data['isDeleted'] == true) continue;

          String agentName = data['marketingPersonName'] ?? '';

          // If the agent made the sale but isn't in our users table (e.g., deleted user), add them dynamically
          if (!liveAgentMap.containsKey(agentName) && agentName.isNotEmpty && agentName != 'Unknown') {
            liveAgentMap[agentName] = {
              "name": agentName,
              "avatar": agentName.length >= 2 ? agentName.substring(0, 2).toUpperCase() : agentName.toUpperCase(),
              "role": "Former Agent",
              "revenue": 0.0,
              "orders": 0,
              "clients": <Map<String, dynamic>>[],
              "uniqueClientNames": <String>{},
            };
          }

          if (liveAgentMap.containsKey(agentName)) {
            var agent = liveAgentMap[agentName]!;

            // Add order data to their clients list
            agent["clients"].add({...data, 'id': doc.id});
            agent["uniqueClientNames"].add((data['clientName'] ?? 'Unknown').toString().toLowerCase().trim());
            agent["orders"] += 1;

            String status = (data['status'] ?? '').toString().toLowerCase();

            if (validRevenueStatuses.contains(status)) {
              double effRev = double.tryParse(data['effectiveRevenue']?.toString() ?? '0') ?? 0.0;
              double totalAmt = double.tryParse(data['totalAmount']?.toString() ?? '0') ?? 0.0;

              // Apply Effective Revenue if it exists, otherwise Total Amount
              agent["revenue"] += (effRev > 0) ? effRev : totalAmt;
            }
          }
        }

        // ✅ Step 3: Format the final list for the UI
        final List<Map<String, dynamic>> dynamicList = liveAgentMap.values.map((agent) {
          double rawRev = agent["revenue"];

          return {
            "name": agent["name"],
            "avatar": agent["avatar"],
            "role": agent["role"],
            "rawRevenue": rawRev, // Kept strictly for accurate sorting
            "revenue": "₹${formatCurrency.format(rawRev)}", // Formatted to ₹1,50,000 for UI
            "orders": agent["orders"],
            "clients": agent["clients"],
            "uniqueClientsCount": (agent["uniqueClientNames"] as Set).length,
          };
        }).toList();

        // Sort mathematically by raw revenue (Highest earner at the top)
        dynamicList.sort((a, b) => (b["rawRevenue"] as double).compareTo(a["rawRevenue"] as double));

        allAgents.assignAll(dynamicList);

        // If the user is currently searching, don't overwrite their filtered list blindly
        if (filteredAgents.isNotEmpty && allAgents.length != filteredAgents.length) {
          searchAgent('');
        } else {
          filteredAgents.assignAll(dynamicList);
        }

        isLoading.value = false;
      });

    } catch (e) {
      isLoading.value = false;
    }
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