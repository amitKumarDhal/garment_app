import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../utils/constants/colors.dart';
import '../../controllers/floor_management/marketing_controller.dart';
import 'agent_detail_screen.dart';

class AgentListScreen extends StatelessWidget {
  const AgentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Finding the controller
    final controller = Get.put(MarketingController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),

      // ✅ 1. SLEEK TRANSPARENT APP BAR
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        title: Text(
          "Sales Force",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          // --- 2. PREMIUM SEARCH BAR ---
          Container(
            margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha:0.03)),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
              ],
            ),
            child: TextField(
              onChanged: controller.searchAgent,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: "Search Agent Name...",
                hintStyle: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                prefixIcon: const Icon(Icons.search_rounded, color: TColors.marketing, size: 22),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),

          // --- 3. AGENT LIST ---
          Expanded(
            child: Obx(() {
              // Show loader while Firestore aggregator is working
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: TColors.marketing),
                );
              }

              // Empty State
              if (controller.filteredAgents.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha:0.05) : Colors.black.withValues(alpha:0.03),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.support_agent_rounded, size: 48, color: Colors.grey.shade400),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No agents found.",
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
                itemCount: controller.filteredAgents.length,
                itemBuilder: (context, index) {
                  final agent = controller.filteredAgents[index];

                  return _buildAgentCard(agent, isDark);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // --- PREMIUM AGENT PROFILE CARD ---
  Widget _buildAgentCard(Map<String, dynamic> agent, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Get.to(() => AgentDetailScreen(agent: agent));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha:0.03)),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha:0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- DYNAMIC AVATAR WITH STATUS GLOW ---
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: TColors.marketing.withValues(alpha:0.1),
                shape: BoxShape.circle,
                border: Border.all(color: TColors.marketing.withValues(alpha:0.3), width: 1.5),
              ),
              child: Center(
                child: Text(
                  agent['avatar'] ?? "??",
                  style: const TextStyle(
                    color: TColors.marketing,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // --- DATA COLUMN ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    agent['name'] ?? "Unknown",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // --- HIGH-DENSITY STATS ROW ---
                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildMetricBox("REVENUE", agent['revenue'] ?? "₹0", isDark, isHighlight: true),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: _buildMetricBox("CLIENTS", "${agent['uniqueClientsCount'] ?? 0}", isDark),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: _buildMetricBox("ORDERS", "${agent['orders'] ?? 0}", isDark),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  // --- MODERN METRIC BOX ---
  Widget _buildMetricBox(String label, String value, bool isDark, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: isHighlight
            ? TColors.marketing.withValues(alpha:0.1)
            : (isDark ? Colors.white.withValues(alpha:0.05) : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlight
              ? TColors.marketing.withValues(alpha:0.2)
              : (isDark ? Colors.white10 : Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: isHighlight ? TColors.marketing.withValues(alpha:0.8) : Colors.grey.shade500,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: isHighlight ? TColors.marketing : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }
}