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

    // Sync the filtered list with this agent's specific clients
    controller.initClients(agent['clients'] ?? []);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Agent Portfolio"),
        backgroundColor: TColors.marketing,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- STATS HEADER (Based on your sketch) ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: TColors.marketing.withOpacity(0.1),
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
                          _buildMetricBox(
                            "CLIENTS",
                            "${agent['clients']?.length ?? 0}",
                            isDark,
                          ),
                          const SizedBox(width: 8),
                          _buildMetricBox(
                            "STATUS",
                            "Active",
                            isDark,
                            color: Colors.green,
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
                hintText: "Search Client Name...",
                prefixIcon: const Icon(Icons.search, color: TColors.marketing),
                fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                filled: true,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: TColors.marketing,
                    width: 2,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Result Count Indicator
          Obx(
            () => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Showing ${controller.filteredClients.length} Clients",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // Client List
          Expanded(
            child: Obx(() {
              if (controller.filteredClients.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_search,
                        size: 60,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "No clients found",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: controller.filteredClients.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
                itemBuilder: (context, index) {
                  final client = controller.filteredClients[index];
                  return ListTile(
                    tileColor: Theme.of(context).scaffoldBackgroundColor,
                    leading: Icon(
                      _getStatusIcon(client['status'] ?? ""),
                      color: _getStatusColor(client['status'] ?? ""),
                    ),
                    title: Text(
                      client['name'] ?? "Unknown Client",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      client['org'] ?? "No Organization",
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),

                    // --- UPDATED: Navigation Arrow followed by Call Icon ---
                    trailing: Row(
                      mainAxisSize: MainAxisSize
                          .min, // Vital to prevent Row from taking full width
                      children: [
                        // Navigation Arrow
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: TColors.marketing,
                        ),
                        const SizedBox(
                          width: 16,
                        ), // Space between Arrow and Call Icon
                        // SEPARATE CALL WIDGET
                        GestureDetector(
                          onTap: () => _makePhoneCall(client['phone'] ?? ""),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
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
                        Get.to(() => ClientDetailScreen(client: client)),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // --- Helper: Metric Box UI ---
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

  // Helper to extract initials for the Avatar
  String _getInitials(String name) {
    List<String> names = name.trim().split(" ");
    if (names.length > 1) {
      return (names[0][0] + names[1][0]).toUpperCase();
    }
    return names[0][0].toUpperCase();
  }

  // URL Launcher for Phone Calls
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      Get.snackbar(
        "Error",
        "Could not open dialer for $phoneNumber",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case "Delivered":
        return Icons.check_circle;
      case "Processing":
        return Icons.sync;
      case "Cancelled":
        return Icons.cancel;
      case "Dispatched":
        return Icons.local_shipping;
      default:
        return Icons.info;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Delivered":
        return Colors.green;
      case "Processing":
        return Colors.orange;
      case "Cancelled":
        return Colors.red;
      case "Dispatched":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
