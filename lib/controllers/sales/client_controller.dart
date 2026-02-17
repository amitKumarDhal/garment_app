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
        // Ensure your OrderModel handles safe parsing!
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
        // Calculate Total for Client A
        double totalA = grouped[a]!.fold(0.0, (sum, item) => sum + item.totalAmount);
        // Calculate Total for Client B
        double totalB = grouped[b]!.fold(0.0, (sum, item) => sum + item.totalAmount);
        
        // Sort Descending (B compares to A)
        return totalB.compareTo(totalA);
      });

      clients.value = grouped;
      filteredClientNames.value = sortedKeys; // Now your list is ranked!
      
    } catch (e) {
      print("Error fetching clients: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ Get Total Spent helper for the UI
  double getClientTotal(String clientName) {
    if (!clients.containsKey(clientName)) return 0.0;
    return clients[clientName]!.fold(0.0, (sum, item) => sum + item.totalAmount);
  }

  void searchClients(String query) {
    if (query.isEmpty) {
      // Restore the SORTED list
      // We re-sort to ensure rank is maintained even after clearing search
      List<String> sortedKeys = clients.keys.toList();
      sortedKeys.sort((a, b) {
         double totalA = getClientTotal(a);
         double totalB = getClientTotal(b);
         return totalB.compareTo(totalA);
      });
      filteredClientNames.value = sortedKeys;
    } else {
      filteredClientNames.value = clients.keys
          .where((name) => name.toLowerCase().contains(query.toLowerCase()))
          .toList();
      // Note: Search results might lose 'ranking' order strictly, 
      // but usually, you want to find the name first.
    }
  }
}