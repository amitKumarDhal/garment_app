// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
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
    final formatCurrency = NumberFormat('#,##,##0', 'en_IN');

    // Sync the filtered list with the agent's actual list of orders
    controller.initClients(agent['clients'] ?? []);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),

      // ✅ 1. SLEEK TRANSPARENT APP BAR (Admin Menu Removed)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        title: Text(
          "Agent Portfolio",
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
          // --- 2. MODERN PROFILE HEADER CARD ---
          _buildModernHeaderCard(agent, isDark),

          // --- 3. PREMIUM SEARCH BAR ---
          Container(
            margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha:0.03)),
            ),
            child: TextField(
              onChanged: (value) => controller.searchClient(agent['clients'] ?? [], value),
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Search Client or Organization...",
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: TColors.primary, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),

          // Meta Text
          Obx(() => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "TRANSACTION HISTORY (${controller.filteredClients.length})",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          )),

          // --- 4. FLOATING TRANSACTION LEDGER ---
          Expanded(
            child: Obx(() {
              if (controller.filteredClients.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text("No transactions found.", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40, top: 8),
                itemCount: controller.filteredClients.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final order = controller.filteredClients[index];
                  final status = order['status'] ?? "Pending";
                  final statusColor = _getStatusColor(status);

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Get.to(() => ClientDetailScreen(client: order));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha:0.03)),
                        boxShadow: [
                          if (!isDark) BoxShadow(color: Colors.black.withValues(alpha:0.02), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Left Status Indicator Strip
                          Container(
                            width: 4,
                            height: 40,
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Order Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order['clientName'] ?? "Unknown Client",
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? Colors.white : Colors.black87),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.business_rounded, size: 12, color: Colors.grey.shade500),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        order['organization'] ?? "No Organization",
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Financials & Actions
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "₹${formatCurrency.format((order['effectiveRevenue'] != null && order['effectiveRevenue'] > 0) ? order['effectiveRevenue'] : (order['totalAmount'] ?? 0))}",
                                style: const TextStyle(fontSize: 15, color: Colors.green, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: statusColor.withValues(alpha:0.1), borderRadius: BorderRadius.circular(6)),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: statusColor, letterSpacing: 0.5),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      _makePhoneCall(order['clientPhone'] ?? "");
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(color: Colors.blue.withValues(alpha:0.1), shape: BoxShape.circle),
                                      child: const Icon(Icons.phone_rounded, color: Colors.blue, size: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
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

  // ===========================================================================
  // ✅ MODERN HEADER CARD UI (3-COLUMN METRIC ROW)
  // ===========================================================================
  Widget _buildModernHeaderCard(Map<String, dynamic> agent, bool isDark) {
    Color textColor = isDark ? Colors.white : Colors.black87;
    Color subTextColor = isDark ? Colors.white60 : Colors.black54;
    Color cardBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    Color innerBoxColor = isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8F9FA);

    // --- Data Extraction ---
    String name = agent['name'] ?? "Unknown";
    String avatar = agent['avatar'] ?? "??";
    String cid = agent['id'] ?? "N/A";
    String role = agent['roleBreakdown'] ?? agent['role'] ?? "Associate";

    // Data Mapping
    String totalAchievement = agent['grossRevenue']?.toString() ?? agent['totalRev']?.toString() ?? "₹0";
    String netAchievement = agent['netAchievement']?.toString() ?? "₹0";
    String eeEligibleMonths = agent['eeEligibleMonths']?.toString() ?? "0";

    // Bottom Banner Bonus
    String totalEE = agent['extraEarning']?.toString() ?? agent['totalEE']?.toString() ?? "₹0";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // --- 1. HEADER (Avatar, Name, CID, Role Badge) ---
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
                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(role.toUpperCase(), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
                ),
              ],
            ),
          ),

          // --- 2. 3-COLUMN METRICS GRID ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(child: _buildModernMetricBox("TOTAL ACHV", totalAchievement, innerBoxColor, textColor)),
                const SizedBox(width: 8),
                Expanded(child: _buildModernMetricBox("NET ACHV", netAchievement, innerBoxColor, TColors.primary)),
                const SizedBox(width: 8),
                Expanded(child: _buildModernMetricBox("ELIGIBLE MTHS", eeEligibleMonths, innerBoxColor, Colors.orange.shade600)),
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
    );
  }

  // --- HELPER FOR SOFT METRIC BOXES ---
  Widget _buildModernMetricBox(String title, String value, Color bgColor, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey,
                  letterSpacing: 0.5
              ),
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: valueColor,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== HELPERS =====================
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        Get.snackbar("Error", "Could not open dialer for $phoneNumber", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", "An unexpected error occurred: $e", snackPosition: SnackPosition.BOTTOM);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "delivered":
      case "approved":
        return Colors.green;
      case "processing":
      case "pending":
      case "placed":
        return Colors.orange;
      case "cancelled":
      case "rejected":
        return Colors.redAccent;
      case "dispatched":
      case "shipping":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}