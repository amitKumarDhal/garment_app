// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/admin/eligible_agents_controller.dart';
import '../../utils/constants/colors.dart';
import '../floor_management/agent_detail_screen.dart';

class EligibleAgentsScreen extends StatelessWidget {
  const EligibleAgentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Use the new dedicated controller!
    final controller = Get.put(EligibleAgentsController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        title: Column(
          children: [
            Text(
              "Top Performers",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            const Text(
              "Bonus Eligible Associates",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: TColors.primary));
        }

        // ✅ The controller is already filtering out the 0-bonus agents,
        // so we can just grab the list directly!
        final agentsList = controller.filteredAgents;

        if (agentsList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, size: 56, color: Colors.green),
                ),
                const SizedBox(height: 16),
                Text(
                  "No eligible agents yet.",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  "Bonus unlocks when net achievement\ncrosses the monthly target.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 40),
          itemCount: agentsList.length,
          itemBuilder: (context, index) {
            final agent = agentsList[index];
            return _buildModernExtraEarningCard(agent, isDark);
          },
        );
      }),
    );
  }

  // ===========================================================================
  // ✅ MODERN UI/UX EXTRA EARNING CARD
  // ===========================================================================
  Widget _buildModernExtraEarningCard(Map<String, dynamic> agent, bool isDark) {
    Color textColor = isDark ? Colors.white : Colors.black87;
    Color subTextColor = isDark ? Colors.white60 : Colors.black54;
    Color cardBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    Color innerBoxColor = isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8F9FA);

    // --- Data Extraction ---
    String name = agent['name'] ?? "Unknown";
    String avatar = agent['avatar'] ?? "??";
    String cid = agent['id'] ?? "N/A";

    String totalRev = agent['totalRev'] ?? "₹0";
    String extraRevenue = agent['extraRevenue'] ?? "₹0";
    String eeEligibleMonths = agent['eeEligibleMonths'] ?? "0";
    String totalEE = agent['totalEE'] ?? "₹0";
    String roleBreakdown = agent['roleBreakdown'] ?? "Pending data...";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.green.withValues(alpha: 0.1),
          highlightColor: Colors.green.withValues(alpha: 0.05),
          onTap: () {
            HapticFeedback.lightImpact();
            Get.to(() => AgentDetailScreen(agent: agent));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // --- 1. HEADER (Avatar, Name, CID) ---
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                          color: TColors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle
                      ),
                      alignment: Alignment.center,
                      child: Text(avatar, style: const TextStyle(fontWeight: FontWeight.w900, color: TColors.primary, fontSize: 16)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: textColor, letterSpacing: -0.3),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "CID: $cid",
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: subTextColor),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.workspace_premium_rounded, color: Colors.green, size: 20),
                    ),
                  ],
                ),
              ),

              // --- 2. METRICS GRID (Soft Inner Containers) ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildModernMetricBox("TOTAL REVENUE", totalRev, innerBoxColor, textColor)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildModernMetricBox("EXTRA REVENUE", extraRevenue, innerBoxColor, Colors.green.shade600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildModernMetricBox("ELIGIBLE MTHS", eeEligibleMonths, innerBoxColor, textColor)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildModernMetricBox("ROLE TIMELINE", roleBreakdown, innerBoxColor, TColors.primary, isSmallText: true)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // --- 3. FOOTER (Rich Green Reward Banner) ---
              Container(
                padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade600, Colors.green.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20)
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total Extra Earnings",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 0.5),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Performance Bonus",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white54),
                        ),
                      ],
                    ),
                    Text(
                      totalEE,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                    ),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER FOR SOFT METRIC BOXES ---
  Widget _buildModernMetricBox(String title, String value, Color bgColor, Color valueColor, {bool isSmallText = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.grey,
                letterSpacing: 0.5
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallText ? 13 : 16,
              fontWeight: FontWeight.w900,
              color: valueColor,
              letterSpacing: -0.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}