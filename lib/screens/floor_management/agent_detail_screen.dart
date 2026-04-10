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

      // ✅ 1. SLEEK TRANSPARENT APP BAR
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
          // --- 2. EXECUTIVE PROFILE HEADER ---
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: TColors.primary.withValues(alpha:0.3), width: 1.5),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: TColors.primary.withValues(alpha:0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
              ],
            ),
            child: Row(
              children: [
                // --- DYNAMIC GRADIENT AVATAR WITH GLOW ---
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [TColors.primary, TColors.primary.withValues(alpha: 0.6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: TColors.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(agent['name'] ?? "??"),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Agent Info & Stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agent['name'] ?? "Unknown Agent",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),

                      // Data Row
                      Row(
                        children: [
                          Expanded(
                            flex: 4,
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
              ],
            ),
          ),

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

  // ===================== HELPERS =====================

  String _getInitials(String name) {
    if (name.isEmpty) return "??";
    List<String> names = name.trim().split(" ");
    if (names.length > 1) {
      return (names[0][0] + names[names.length - 1][0]).toUpperCase();
    }
    return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name[0].toUpperCase();
  }

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

  Widget _buildMetricBox(String label, String value, bool isDark, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: isHighlight ? TColors.primary.withValues(alpha:0.1) : (isDark ? Colors.white.withValues(alpha:0.05) : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isHighlight ? TColors.primary.withValues(alpha:0.2) : (isDark ? Colors.white10 : Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: isHighlight ? TColors.primary.withValues(alpha:0.8) : Colors.grey.shade500, letterSpacing: 0.5),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: isHighlight ? TColors.primary : (isDark ? Colors.white : Colors.black87)),
            ),
          ),
        ],
      ),
    );
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