// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../utils/constants/colors.dart';
import '../../controllers/floor_management/marketing_controller.dart';
import '../admin/associate_analytics_screen.dart';
import 'agent_detail_screen.dart';

class AgentListScreen extends StatelessWidget {
  const AgentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MarketingController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
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
          // --- SEARCH BAR ---
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
                prefixIcon: const Icon(Icons.search_rounded, color: TColors.primary, size: 22),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),

          // --- AGENT LIST ---
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: TColors.primary),
                );
              }

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
                  return _buildModernAgentCard(agent, isDark);
                },
              );
            }),
          ),
        ],
      ),
    );
  }
// ===========================================================================
  // ✅ MODERN PREMIUM CARD DESIGN (WITH ANALYTICS BUTTON)
  // ===========================================================================
  Widget _buildModernAgentCard(Map<String, dynamic> agent, bool isDark) {
    Color textColor = isDark ? Colors.white : Colors.black87;
    Color subTextColor = isDark ? Colors.white70 : Colors.black54;

    // --- DATA EXTRACTION ---
    String name = agent['name'] ?? "Unknown";
    String avatar = agent['avatar'] ?? "??";
    String id = agent['id'] ?? "N/A";

    String grossRev = agent['grossRevenue']?.toString() ?? "₹0";
    String netAch = agent['netAchievement']?.toString() ?? "₹0";

    String monthsActive = (agent['monthsActive'] ?? "0").toString();
    String totalTarget = (agent['totalTarget'] ?? "0").toString();
    String clients = "${agent['uniqueClientsCount'] ?? 0}";
    String orders = "${agent['orders'] ?? 0}";
    String avgRev = agent['avgRevenue']?.toString() ?? "₹0";
    String extraEarning = agent['extraEarning']?.toString() ?? "₹0";

    List<dynamic> roleHistory = agent['roleHistory'] ?? [{'text': "Data pending..."}];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03)),
        boxShadow: [
          if (!isDark)
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 6)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          splashColor: TColors.primary.withValues(alpha: 0.1),
          highlightColor: TColors.primary.withValues(alpha: 0.05),
          onTap: () {
            HapticFeedback.lightImpact();
            Get.to(() => AgentDetailScreen(agent: agent));
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // --- 1. HEADER: AVATAR & INFO ---
                Row(
                  children: [
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(color: TColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(avatar, style: const TextStyle(fontWeight: FontWeight.w900, color: TColors.primary, fontSize: 18)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: textColor, letterSpacing: -0.3), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text("ID: $id", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: TColors.primary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey.shade100, shape: BoxShape.circle),
                      child: Icon(Icons.arrow_forward_ios_rounded, color: isDark ? Colors.white54 : Colors.black54, size: 14),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // --- 2. FINANCIAL SUMMARY ---
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("GROSS SALES", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 0.5)),
                            Text(grossRev, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor)),
                            const SizedBox(height: 8),
                            Text("NET ACHIEVEMENT", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: TColors.primary, letterSpacing: 0.5)),
                            Text(netAch, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.green, letterSpacing: -0.5)),
                            const SizedBox(height: 4),
                            Text("Target: $totalTarget ($monthsActive mths)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: subTextColor)),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 70, color: isDark ? Colors.white10 : Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 12)),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: roleHistory.map((historyItem) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text(historyItem['text'] ?? "Unknown", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: subTextColor)),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // --- 3. BOTTOM METRICS CHIPS ---
                Row(
                  children: [
                    Expanded(child: _buildMetricChip("Clients", clients, isDark)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMetricChip("Orders", orders, isDark)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMetricChip("AOV", avgRev, isDark)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMetricChip("Bonus", extraEarning, isDark, isHighlight: true)),
                  ],
                ),

                const SizedBox(height: 16),

                // ✅ 4. NEW ANALYTICS BUTTON
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      // Navigate to your new screen, passing the agent data!
                      Get.to(() => AssociateAnalyticsScreen(agent: agent));
                    },
                    icon: const Icon(Icons.insights_rounded, size: 18),
                    label: const Text("Deep Product Analytics", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : Colors.black87,
                      side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- HELPER FOR MODERN METRIC CHIPS ---
  Widget _buildMetricChip(String title, String value, bool isDark, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: isHighlight
            ? Colors.green.withValues(alpha: 0.1) // Green tint for Bonus
            : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlight
              ? Colors.green.withValues(alpha: 0.3)
              : (isDark ? Colors.white10 : Colors.grey.shade200),
        ),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isHighlight ? Colors.green.shade700 : Colors.grey.shade500,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: isHighlight ? Colors.green : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }
}