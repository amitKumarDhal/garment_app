import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:yoobbel/screens/sales/manager/sales_manager_history_screen.dart';
import '../../../controllers/sales/sales_manager_controller.dart';
import '../../../utils/constants/colors.dart';

class SalesManagerHome extends StatelessWidget {
  const SalesManagerHome({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject the controller
    final controller = Get.put(SalesManagerController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : Colors.grey[50],
      appBar: AppBar(
        // ✅ 1. DYNAMIC APP BAR TITLE
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Dashboard",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            // Shows "February 2026" dynamically
            Obx(
              () => Text(
                DateFormat('MMMM yyyy').format(controller.selectedMonth.value),
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // ✅ 2. MONTH PICKER BUTTON
          IconButton(
            onPressed: () => _pickMonth(context, controller),
            icon: const Icon(Icons.calendar_month),
            tooltip: "Change Month",
          ),
          IconButton(
            onPressed: () => controller.fetchAllData(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => controller.fetchAllData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. KEY STATS ROW ---
              Row(
                children: [
                  // CARD A: TOTAL REVENUE (Dynamic Month Name)
                  Expanded(
                    child: Obx(
                      () => _buildStatCard(
                        context,
                        // "Revenue (Feb)"
                        "Revenue (${DateFormat('MMM').format(controller.selectedMonth.value)})",
                        "₹${(controller.totalRevenue.value / 100000).toStringAsFixed(2)}L",
                        Colors.green,
                        Icons.monetization_on,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // CARD B: PENDING COUNT (Real-time, not month dependent)
                  Expanded(
                    child: Obx(
                      () => _buildStatCard(
                        context,
                        "Pending Requests",
                        controller.pendingOrders.length.toString(),
                        Colors.orange,
                        Icons.pending_actions,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // --- 2. HISTORY LINK ---
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Get.to(
                    () => const SalesManagerHistoryScreen(),
                    arguments: "Approved",
                  ),
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text("View All Approved Orders"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: isDark ? Colors.white10 : Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // --- 3. LEADERBOARD SECTION ---
              // Dynamic Title: "Top Agents (February)"
              Obx(
                () => Text(
                  "Top Agents (${DateFormat('MMMM').format(controller.selectedMonth.value)})",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.topAgents.isEmpty) {
                  return _buildEmptyState(isDark, controller);
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.topAgents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final agent = controller.topAgents[index];
                    return _buildAgentRow(
                      index + 1,
                      agent['name'],
                      agent['formatted'],
                      isDark,
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ 3. MONTH PICKER FUNCTION
  Future<void> _pickMonth(
    BuildContext context,
    SalesManagerController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedMonth.value,
      firstDate: DateTime(2023), // Adjust based on your app launch
      lastDate: DateTime.now(),
      helpText: "SELECT MONTH",
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.purple,
            colorScheme: const ColorScheme.light(primary: Colors.purple),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Update the controller, which will reload stats
      controller.changeMonth(picked);
    }
  }

  // --- UI WIDGETS ---

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildAgentRow(int rank, String name, String amount, bool isDark) {
    // Determine Badge Color
    Color badgeColor;
    if (rank == 1)
      badgeColor = const Color(0xFFFFD700); // Gold
    else if (rank == 2)
      badgeColor = const Color(0xFFC0C0C0); // Silver
    else if (rank == 3)
      badgeColor = const Color(0xFFCD7F32); // Bronze
    else
      badgeColor = Colors.grey[200]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank Circle
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                "#$rank",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? Colors.white : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Name
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Amount
          Text(
            amount,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, SalesManagerController controller) {
    String month = DateFormat('MMMM').format(controller.selectedMonth.value);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.calendar_today, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text(
              "No approved sales data found in $month.",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
