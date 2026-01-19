import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/constants/colors.dart';
import '../../controllers/floor_management/marketing_controller.dart';
import 'agent_detail_screen.dart';

class AgentListScreen extends StatelessWidget {
  const AgentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Finding the controller (initialized in AppRoutes or here)
    final controller = Get.put(MarketingController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Sales Agents"),
        backgroundColor: TColors.marketing,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: controller.searchAgent,
              decoration: InputDecoration(
                hintText: "Search Agent Name...",
                prefixIcon: const Icon(Icons.search, color: TColors.marketing),
                fillColor: isDark ? TColors.darkCard : Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Agent List
          Expanded(
            child: Obx(
              () => ListView.builder(
                itemCount: controller.filteredAgents.length,
                itemBuilder: (context, index) {
                  final agent = controller.filteredAgents[index];
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                    color: isDark ? TColors.darkCard : Colors.white,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      onTap: () =>
                          Get.to(() => AgentDetailScreen(agent: agent)),

                      // --- INITIALS AVATAR (AS) ---
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: TColors.marketing.withOpacity(0.1),
                        child: Text(
                          agent['avatar'] ?? "??",
                          style: const TextStyle(
                            color: TColors.marketing,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            agent['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // --- STATS ROW FROM YOUR SKETCH ---
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
                                "${agent['clients'].length}",
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
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widget to create the rectangular boxes under the name
  Widget _buildMetricBox(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 7,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: TColors.marketing,
            ),
          ),
        ],
      ),
    );
  }
}
