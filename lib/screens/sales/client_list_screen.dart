import 'package:flutter/material.dart';
import 'package:get/get.dart';
// ✅ Import the new Sales-specific detail screen
import 'package:yoobbel/screens/sales/sales_client_detail_screen.dart';
import '../../controllers/sales/client_controller.dart';

class ClientListScreen extends StatelessWidget {
  const ClientListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ClientController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Clients"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- Search Bar ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: controller.searchClients,
              decoration: InputDecoration(
                hintText: "Search client name...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // --- List of Clients ---
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.filteredClientNames.isEmpty) {
                return const Center(child: Text("No clients found."));
              }

              return ListView.builder(
                itemCount: controller.filteredClientNames.length,
                itemBuilder: (context, index) {
                  final name = controller.filteredClientNames[index];
                  final orders = controller.clients[name]!;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      child: Text(
                        name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("${orders.length} Total Orders"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      // ✅ Corrected navigation to the Sales-specific detail screen
                      Get.to(
                        () => SalesClientDetailScreen(
                          clientName: name,
                          orders: orders,
                        ),
                      );
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
