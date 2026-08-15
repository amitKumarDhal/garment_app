import 'package:get/get.dart';
import '../../data/models/order_model.dart';
import '../../data/services/api_service.dart';

class ClientController extends GetxController {
  var isLoading = true.obs;
  var clients = <String, List<OrderModel>>{}.obs;
  var filteredClientNames = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchClients();
  }

  void fetchClients() async {
    try {
      isLoading.value = true;
      final response = await ApiService.get('/clients');
      Map<String, List<OrderModel>> grouped = {};

      if (response['success'] == true && response['clients'] != null) {
        final clientList = List<Map<String, dynamic>>.from(response['clients']);
        for (var c in clientList) {
          String clientName = c['name']?.toString().trim() ?? "Unknown";
          grouped[clientName] = [];
        }
      }

      final ordersRes = await ApiService.get('/orders');
      if (ordersRes['success'] == true && ordersRes['orders'] != null) {
        final orderList = List<Map<String, dynamic>>.from(ordersRes['orders']);
        for (var o in orderList) {
          final order = OrderModel.fromSnapshot(o);
          String clientName = order.clientName.trim();
          if (clientName.isEmpty) clientName = "Unknown";
          if (!grouped.containsKey(clientName)) {
            grouped[clientName] = [];
          }
          grouped[clientName]!.add(order);
        }
      }

      List<String> sortedKeys = grouped.keys.toList();
      sortedKeys.sort((a, b) => getClientTotal(b).compareTo(getClientTotal(a)));

      clients.value = grouped;
      filteredClientNames.value = sortedKeys;
    } catch (e) {
      print("Error fetching clients: $e");
    } finally {
      isLoading.value = false;
    }
  }

  double getClientTotal(String clientName) {
    if (!clients.containsKey(clientName)) return 0.0;
    return clients[clientName]!.fold(0.0, (sum, item) => sum + item.totalAmount);
  }

  void searchClients(String query) {
    if (query.isEmpty) {
      List<String> sortedKeys = clients.keys.toList();
      sortedKeys.sort((a, b) => getClientTotal(b).compareTo(getClientTotal(a)));
      filteredClientNames.value = sortedKeys;
      return;
    }

    String lowerQuery = query.toLowerCase();
    List<String> matchedClients = clients.keys.where((clientName) {
      if (clientName.toLowerCase().contains(lowerQuery)) return true;
      final clientOrders = clients[clientName] ?? [];
      for (var order in clientOrders) {
        if ((order.clientPhone ?? "").toLowerCase().contains(lowerQuery)) return true;
      }
      return false;
    }).toList();

    matchedClients.sort((a, b) => getClientTotal(b).compareTo(getClientTotal(a)));
    filteredClientNames.value = matchedClients;
  }
}