import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../data/models/order_model.dart';
import '../../controllers/sales/sales_agent_controller.dart';

class ClientController extends GetxController {
  final _db = FirebaseFirestore.instance;

  // ✅ Using your existing dependency logic
  final agentController = Get.find<SalesAgentController>();

  var isLoading = true.obs;
  var clients = <String, List<OrderModel>>{}.obs;
  var filteredClientNames = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Use 'ever' to refetch if the agent name changes/loads late
    ever(agentController.agentName, (_) => fetchClients());
    fetchClients();
  }

  void fetchClients() async {
    // Safety check if agent name isn't loaded yet
    if (agentController.agentName.value.isEmpty) return;

    try {
      isLoading.value = true;

      final snapshot = await _db
          .collection('orders')
          .where(
        'marketingPersonName',
        isEqualTo: agentController.agentName.value,
      )
          .get();

      Map<String, List<OrderModel>> grouped = {};

      // 1. Group Orders by Client
      for (var doc in snapshot.docs) {
        final order = OrderModel.fromSnapshot(doc);

        // Normalize name to prevent "John" vs "john" duplicates
        String clientName = order.clientName.trim();
        if (clientName.isEmpty) clientName = "Unknown";

        if (!grouped.containsKey(clientName)) {
          grouped[clientName] = [];
        }
        grouped[clientName]!.add(order);
      }

      // 2. ✅ SORTING LOGIC (Highest Value First)
      List<String> sortedKeys = grouped.keys.toList();

      sortedKeys.sort((a, b) {
        double totalA = getClientTotal(a);
        double totalB = getClientTotal(b);
        return totalB.compareTo(totalA); // Sort Descending
      });

      clients.value = grouped;
      filteredClientNames.value = sortedKeys; // Now your list is ranked!

    } catch (e) {
      print("Error fetching clients: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ Get Total Spent helper for the UI and Sorting
  double getClientTotal(String clientName) {
    if (!clients.containsKey(clientName)) return 0.0;
    return clients[clientName]!.fold(0.0, (sum, item) => sum + item.totalAmount);
  }

  // ✅ UPGRADED: Deep Search that keeps ranks intact!
  void searchClients(String query) {
    if (query.isEmpty) {
      // Restore the fully SORTED list
      List<String> sortedKeys = clients.keys.toList();
      sortedKeys.sort((a, b) => getClientTotal(b).compareTo(getClientTotal(a)));
      filteredClientNames.value = sortedKeys;
      return;
    }

    String lowerQuery = query.toLowerCase();

    // Filter the clients based on Name, Phone, OR what they bought
    List<String> matchedClients = clients.keys.where((clientName) {

      // 1. Matches Client Name
      if (clientName.toLowerCase().contains(lowerQuery)) return true;

      // 2. Look deep into their order history
      final clientOrders = clients[clientName] ?? [];

      for (var order in clientOrders) {
        // Matches Phone Number
        if ((order.clientPhone ?? "").toLowerCase().contains(lowerQuery)) return true;

        // Matches anything inside the Dynamic Products array!
        for (var product in order.products) {
          String pName = (product['productName'] ?? "").toString().toLowerCase();
          String pCode = (product['productCode'] ?? "").toString().toLowerCase();

          if (pName.contains(lowerQuery) || pCode.contains(lowerQuery)) {
            return true;
          }
        }
      }

      return false; // No match found for this client
    }).toList();

    // ✅ Keep the search results sorted by revenue too!
    matchedClients.sort((a, b) => getClientTotal(b).compareTo(getClientTotal(a)));

    filteredClientNames.value = matchedClients;
  }
}