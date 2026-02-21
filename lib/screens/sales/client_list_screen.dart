import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/sales/client_controller.dart';
import '../../utils/constants/colors.dart';
import 'sales_client_detail_screen.dart';

class ClientListScreen extends StatelessWidget {
  const ClientListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ClientController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
        elevation: 0,
        centerTitle: false,
        titleSpacing: 24,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: () => Get.back(),
        ),
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        title: Text(
          "Top Clients",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          // --- 1. CLEAN SEARCH HEADER ---
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
            ),
            child: TextField(
              onChanged: (val) => controller.searchClients(val),
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: "Search client portfolio...",
                hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black38, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white70 : TColors.primary, size: 20),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: isDark ? BorderSide.none : BorderSide(color: Colors.black.withValues(alpha:0.05))
                ),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: TColors.primary, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          // --- 2. RANKED LEADERBOARD ---
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.filteredClientNames.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black.withValues(alpha:0.05), shape: BoxShape.circle),
                        child: Icon(Icons.group_off_rounded, size: 48, color: isDark ? Colors.white54 : Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Text("No clients found.", style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40, top: 4),
                physics: const BouncingScrollPhysics(),
                itemCount: controller.filteredClientNames.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final clientName = controller.filteredClientNames[index];
                  final orders = controller.clients[clientName] ?? [];
                  final int rank = index + 1;

                  // Calculate Total Revenue
                  double totalRevenue = 0.0;
                  for (var order in orders) {
                    totalRevenue += order.totalAmount;
                  }

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Get.to(() => SalesClientDetailScreen(clientName: clientName, orders: orders));
                    },
                    child: _buildClientCard(rank, clientName, orders.length, totalRevenue, currencyFormat, isDark),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildClientCard(int rank, String clientName, int orderCount, double totalRevenue, NumberFormat currencyFormat, bool isDark) {
    bool isTop3 = rank <= 3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha:0.05) : Colors.black.withValues(alpha:0.03)),
        boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withValues(alpha:0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // --- RANK BADGE ---
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: _getRankGradient(rank, isDark),
              borderRadius: BorderRadius.circular(14),
              boxShadow: isTop3 ? [BoxShadow(color: _getRankShadowColor(rank).withValues(alpha:0.4), blurRadius: 8, offset: const Offset(0, 4))] : [],
              border: !isTop3 ? Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300) : null,
            ),
            child: Center(
              child: Text(
                "#$rank",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: isTop3 ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // --- CLIENT INFO ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : Colors.black87, letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.shopping_bag_rounded, size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      "$orderCount Orders",
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // --- FINANCIAL DATA ---
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("REVENUE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade500, letterSpacing: 1)),
              const SizedBox(height: 2),
              Text(
                currencyFormat.format(totalRevenue),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Rank Styling Logic ---

  LinearGradient _getRankGradient(int rank, bool isDark) {
    if (rank == 1) return const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFDB931)], begin: Alignment.topLeft, end: Alignment.bottomRight); // Gold
    if (rank == 2) return const LinearGradient(colors: [Color(0xFFE0E0E0), Color(0xFF9E9E9E)], begin: Alignment.topLeft, end: Alignment.bottomRight); // Silver
    if (rank == 3) return const LinearGradient(colors: [Color(0xFFCD7F32), Color(0xFFA0522D)], begin: Alignment.topLeft, end: Alignment.bottomRight); // Bronze

    // Default Flat Color for rank 4+
    return LinearGradient(colors: [isDark ? Colors.white.withValues(alpha:0.05) : Colors.grey.shade100, isDark ? Colors.white.withValues(alpha:0.05) : Colors.grey.shade100]);
  }

  Color _getRankShadowColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFF9E9E9E);
    if (rank == 3) return const Color(0xFFCD7F32);
    return Colors.transparent;
  }
}