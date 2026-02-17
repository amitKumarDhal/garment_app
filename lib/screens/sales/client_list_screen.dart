import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // For currency formatting
import '../../controllers/sales/client_controller.dart';
import 'sales_client_detail_screen.dart'; // Ensure this import is correct

class ClientListScreen extends StatelessWidget {
  const ClientListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ClientController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Currency formatter for cleaner numbers (e.g., ₹ 12,500)
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Top Clients (By Revenue)"),
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
              onChanged: (val) => controller.searchClients(val),
              decoration: InputDecoration(
                hintText: "Search client...",
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

          // --- Ranked List ---
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.filteredClientNames.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 10),
                      Text("No clients found"),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: controller.filteredClientNames.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  // 1. Get Client Data
                  final clientName = controller.filteredClientNames[index];
                  final orders = controller.clients[clientName] ?? [];

                  // 2. Calculate Total Revenue
                  double totalRevenue = 0.0;
                  for (var order in orders) {
                    totalRevenue += order.totalAmount;
                  }

                  // 3. Determine Rank
                  final int rank = index + 1;

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      
                      // ✅ LEFT: Rank Badge (#1, #2, etc.)
                      leading: CircleAvatar(
                        backgroundColor: _getRankColor(rank),
                        foregroundColor: rank <= 3 ? Colors.white : Colors.black87,
                        child: Text(
                          "#$rank",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      
                      // ✅ MIDDLE: Name & Order Count
                      title: Text(
                        clientName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Text(
                        "${orders.length} Orders",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      
                      // ✅ RIGHT: Individual Total Revenue (Prominent)
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "Total Revenue",
                            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                          ),
                          Text(
                            currencyFormat.format(totalRevenue),
                            style: const TextStyle(
                              color: Colors.green, 
                              fontWeight: FontWeight.bold, 
                              fontSize: 15
                            ),
                          ),
                        ],
                      ),
                      
                      onTap: () {
                        Get.to(() => SalesClientDetailScreen(
                          clientName: clientName,
                          orders: orders,
                        ));
                      },
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // Rank Colors: Gold, Silver, Bronze, then default
  Color _getRankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700); // Gold
    if (rank == 2) return const Color(0xFFC0C0C0); // Silver
    if (rank == 3) return const Color(0xFFCD7F32); // Bronze
    return Colors.blue.withOpacity(0.1); // Default Blue tint
  }
}