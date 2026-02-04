import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../data/models/order_model.dart';
import '../../controllers/sales/sales_agent_controller.dart';

class ClientController extends GetxController {
  final _db = FirebaseFirestore.instance;
  final agentController = Get.find<SalesAgentController>();

  var isLoading = true.obs;
  var clients = <String, List<OrderModel>>{}
      .obs; // Key: Client Name, Value: List of their orders
  var filteredClientNames = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchClients();
  }

  void fetchClients() async {
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

      for (var doc in snapshot.docs) {
        final order = OrderModel.fromSnapshot(doc);
        if (!grouped.containsKey(order.clientName)) {
          grouped[order.clientName] = [];
        }
        grouped[order.clientName]!.add(order);
      }

      clients.value = grouped;
      filteredClientNames.value = grouped.keys.toList();
    } finally {
      isLoading.value = false;
    }
  }

  void searchClients(String query) {
    if (query.isEmpty) {
      filteredClientNames.value = clients.keys.toList();
    } else {
      filteredClientNames.value = clients.keys
          .where((name) => name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }
}
