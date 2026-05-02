// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/admin/eligible_agents_controller.dart';
import '../../utils/constants/colors.dart';
import '../floor_management/agent_detail_screen.dart';

class EligibleAgentsScreen extends StatelessWidget {
  const EligibleAgentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              "Monthly Payouts",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            const Text(
              "Bonus Eligible Associates",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.green),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ✅ NEW: The Month Picker UI
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha:0.05)),
            ),
            child: Obx(() {
              String monthDisplay = DateFormat('MMMM yyyy').format(controller.selectedMonth.value);
              bool isCurrentMonth = controller.selectedMonth.value.year == DateTime.now().year &&
                  controller.selectedMonth.value.month == DateTime.now().month;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, color: TColors.primary),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      controller.changeMonth(-1);
                    },
                  ),
                  Text(
                    monthDisplay,
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : Colors.black87),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right_rounded, color: isCurrentMonth ? Colors.grey : TColors.primary),
                    onPressed: isCurrentMonth ? null : () {
                      HapticFeedback.selectionClick();
                      controller.changeMonth(1);
                    },
                  ),
                ],
              );
            }),
          ),

          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: TColors.primary));
              }

              final agentsList = controller.filteredAgents;

              if (agentsList.isEmpty) {
                String emptyMonth = DateFormat('MMMM yyyy').format(controller.selectedMonth.value);
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.workspace_premium_rounded, size: 56, color: Colors.green),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No eligible agents for $emptyMonth",
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w600),
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
          ),
        ],
      ),
    );
  }

  Widget _buildModernExtraEarningCard(Map<String, dynamic> agent, bool isDark) {
    Color textColor = isDark ? Colors.white : Colors.black87;
    Color subTextColor = isDark ? Colors.white60 : Colors.black54;
    Color cardBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    Color innerBoxColor = isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8F9FA);

    String name = agent['name'] ?? "Unknown";
    String avatar = agent['avatar'] ?? "??";
    String cid = agent['id'] ?? "N/A";
    String roleBadge = agent['roleStr'] ?? "JSA";

    // Since the controller already calculated these specific to the selected month, just display them!
    String totalRev = agent['totalRev'] ?? "₹0";
    String netAchievement = agent['netAchievement'] ?? "₹0";
    String eeEligibleMonths = agent['eeEligibleMonths'] ?? "0";
    String totalEE = agent['totalEE'] ?? "₹0";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.green.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 8)),
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
              // --- 1. HEADER (Avatar, Name, CID, Role) ---
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: TColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(avatar, style: const TextStyle(fontWeight: FontWeight.w900, color: TColors.primary, fontSize: 16)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: textColor, letterSpacing: -0.3), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text("CID: $cid", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: subTextColor)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text(roleBadge.toUpperCase(), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                  ],
                ),
              ),

              // --- 2. 3-COLUMN METRICS GRID ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(child: _buildModernMetricBox("MONTH GROSS", totalRev, innerBoxColor, textColor)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildModernMetricBox("MONTH NET", netAchievement, innerBoxColor, TColors.primary)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildModernMetricBox("TOTAL MTHS", eeEligibleMonths, innerBoxColor, Colors.orange.shade600)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- 3. FOOTER (Rich Green Reward Banner) ---
              Container(
                padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.green.shade600, Colors.green.shade800], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Earned This Month", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 0.5)),
                        SizedBox(height: 2),
                        Text("Performance Bonus", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white54)),
                      ],
                    ),
                    Text(totalEE, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernMetricBox(String title, String value, Color bgColor, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.5)),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: valueColor, letterSpacing: -0.3)),
          ),
        ],
      ),
    );
  }
}