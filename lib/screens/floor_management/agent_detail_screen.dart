import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/constants/colors.dart';
import '../../controllers/floor_management/marketing_controller.dart';
import 'client_detail_screen.dart';

class AgentDetailScreen extends StatelessWidget {
  final Map<String, dynamic> agent;
  const AgentDetailScreen({super.key, required this.agent});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MarketingController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ DYNAMIC: Sync the filtered list with the agent's actual list of orders/clients
    // Note: 'clients' in our dynamic map is actually the list of Order objects
    controller.initClients(agent['clients'] ?? []);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Agent Portfolio"),
        centerTitle: true,
        backgroundColor: TColors.marketing,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- STATS HEADER ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: TColors.marketing.withValues(alpha: 0.1),
                  child: Text(
                    _getInitials(agent['name'] ?? "??"),
                    style: const TextStyle(
                      color: TColors.marketing,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agent['name'] ?? "Unknown Agent",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildMetricBox(
                            "REVENUE",
                            agent['revenue'] ?? "₹0",
                            isDark,
                          ),
                          const SizedBox(width: 8),
                          // ✅ DYNAMIC: Show Unique Clients count from our Aggregator
                          _buildMetricBox(
                            "CLIENTS",
                            "${agent['uniqueClientsCount'] ?? 0}",
                            isDark,
                          ),
                          const SizedBox(width: 8),
                          _buildMetricBox(
                            "ORDERS",
                            "${agent['orders'] ?? 0}",
                            isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (value) =>
                  controller.searchClient(agent['clients'] ?? [], value),
              decoration: InputDecoration(
                hintText: "Search Client or Organization...",
                prefixIcon: const Icon(Icons.search, color: TColors.marketing),
                fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Result Indicator
          Obx(
            () => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Showing ${controller.filteredClients.length} Recent Transactions",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // --- DYNAMIC CLIENT/ORDER LIST ---
          Expanded(
            child: Obx(() {
              if (controller.filteredClients.isEmpty) {
                return const Center(
                  child: Text("No data available for this agent."),
                );
              }

              return ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: controller.filteredClients.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final order = controller.filteredClients[index];

                  return ListTile(
                    leading: Icon(
                      _getStatusIcon(order['status'] ?? ""),
                      color: _getStatusColor(order['status'] ?? ""),
                    ),
                    title: Text(
                      order['clientName'] ?? "Unknown Client",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order['organization'] ?? "No Organization"),
                        Text(
                          "Total: ₹${order['totalAmount']?.toStringAsFixed(0) ?? '0'}",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: TColors.marketing,
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () =>
                              _makePhoneCall(order['clientPhone'] ?? ""),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.phone,
                              color: Colors.green,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () =>
                        Get.to(() => ClientDetailScreen(client: order)),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // ✅ ADD THIS METHOD AT THE BOTTOM OF YOUR AgentDetailScreen CLASS
  String _getInitials(String name) {
    if (name.isEmpty) return "??";
    List<String> names = name.trim().split(" ");
    if (names.length > 1) {
      // Takes the first letter of the first and last name
      return (names[0][0] + names[names.length - 1][0]).toUpperCase();
    }
    // If only one name, take the first two letters
    return name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name[0].toUpperCase();
  }

  // ✅ ADD THIS METHOD AT THE BOTTOM OF YOUR AgentDetailScreen CLASS

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        Get.snackbar(
          "Error",
          "Could not open dialer for $phoneNumber",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          colorText: Colors.red,
        );
      }
    } catch (e) {
      Get.snackbar("Error", "An unexpected error occurred: $e");
    }
  }

  // ✅ ADD THIS METHOD AT THE BOTTOM OF YOUR AgentDetailScreen CLASS
  Widget _buildMetricBox(
    String label,
    String value,
    bool isDark, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color ?? TColors.marketing,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ ADD THESE METHODS AT THE BOTTOM OF YOUR AgentDetailScreen CLASS

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case "delivered":
      case "approved":
        return Icons.check_circle;
      case "processing":
      case "pending":
        return Icons.sync;
      case "cancelled":
      case "rejected":
        return Icons.cancel;
      case "dispatched":
        return Icons.local_shipping;
      default:
        return Icons.info;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "delivered":
      case "approved":
        return Colors.green;
      case "processing":
      case "pending":
        return Colors.orange;
      case "cancelled":
      case "rejected":
        return Colors.red;
      case "dispatched":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Helper UI methods (Keep your existing _buildMetricBox, _getInitials, _makePhoneCall, etc.)
  // ...
}
