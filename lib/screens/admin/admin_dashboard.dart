import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/constants/colors.dart';
import '../../controllers/admin/admin_controller.dart';
import '../../routes/route_names.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Modern background colors
    final backgroundColor = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF5F5F5);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? TColors.dark : Colors.white,
        elevation: 0,
        titleSpacing: 20,
        automaticallyImplyLeading: false, // Clean header
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "COMMAND CENTER",
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey : Colors.grey[600],
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              "Yoobbel Admin",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => controller.refreshStats(),
              icon: const Icon(Icons.refresh, size: 20),
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),

      // --- FIX: WRAP BODY IN REFRESH INDICATOR ---
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.refreshStats(); // Trigger the refresh
        },
        color: TColors.primary,
        backgroundColor: isDark ? TColors.dark : Colors.white,
        child: SingleChildScrollView(
          // Important: Ensures scrolling works even if content is short
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Alert Banner
                if (controller.pendingApprovalsCount.value > 0)
                  _buildAlertBanner(controller),

                const SizedBox(height: 10),

                // 2. Statistics Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    _buildModernStatCard(
                      "Production",
                      "₹${controller.totalDailyProduction.value}",
                      TColors.primary,
                      Icons.currency_rupee,
                      isDark,
                    ),
                    _buildModernStatCard(
                      "Efficiency",
                      "${controller.averageEfficiency.value.toStringAsFixed(1)}%",
                      Colors.green,
                      Icons.trending_up,
                      isDark,
                    ),
                    _buildModernStatCard(
                      "Workers",
                      "${controller.activeWorkers.value}",
                      Colors.blue,
                      Icons.groups,
                      isDark,
                    ),
                    _buildModernStatCard(
                      "Damages",
                      "${controller.totalDamages.value}",
                      Colors.red,
                      Icons.warning_amber_rounded,
                      isDark,
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // 3. Quick Actions
                const Text(
                  "QUICK ACCESS",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        context,
                        "Sales Agents",
                        "Team & Orders",
                        Icons.person_pin_circle_outlined,
                        TColors.marketing,
                        () => Get.toNamed(AppRouteNames.agentList),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildActionCard(
                        context,
                        "Inventory",
                        "Stock Summary",
                        Icons.inventory_2_outlined,
                        TColors.packing,
                        () => Get.toNamed(AppRouteNames.factoryStock),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // 4. Live Activity Feeds
                _buildModernSectionHeader("Live Floor Activity"),
                const SizedBox(height: 15),

                // --- Stitching Feed ---
                _buildDepartmentHeader("Stitching Line", TColors.stitching),
                if (controller.recentStitchingEntries.isEmpty)
                  _buildEmptyState("No stitching data yet")
                else
                  ...controller.recentStitchingEntries.map(
                    (entry) => _buildLogTile(
                      title: "${entry['workerName']}",
                      subtitle:
                          "Style: ${entry['styleNo']} • Op: ${entry['operationType']}",
                      value: "${entry['completedQty']}",
                      unit: "Pcs",
                      color: TColors.stitching,
                      icon: Icons.precision_manufacturing_outlined,
                      isDark: isDark,
                      cardColor: cardColor,
                    ),
                  ),

                const SizedBox(height: 20),

                // --- Printing Feed ---
                _buildDepartmentHeader("Printing Unit", TColors.printing),
                if (controller.recentPrintingEntries.isEmpty)
                  _buildEmptyState("No printing data yet")
                else
                  ...controller.recentPrintingEntries.map(
                    (entry) => _buildLogTile(
                      title: "Style: ${entry['styleNo']}",
                      subtitle: "${entry['totalDamaged']} Damaged",
                      value: "${entry['netGoodPieces']}",
                      unit: "Good",
                      color: TColors.printing,
                      icon: Icons.print,
                      isDark: isDark,
                      cardColor: cardColor,
                    ),
                  ),

                const SizedBox(height: 20),

                // --- Cutting Feed ---
                _buildDepartmentHeader("Cutting Table", TColors.cutting),
                if (controller.recentCuttingEntries.isEmpty)
                  _buildEmptyState("No cutting data yet")
                else
                  ...controller.recentCuttingEntries.map(
                    (entry) => _buildLogTile(
                      title: "Style: ${entry['styleNo']}",
                      subtitle: "Lot: ${entry['lotNo']}",
                      value: "${entry['totalQuantity']}",
                      unit: "Layers",
                      color: TColors.cutting,
                      icon: Icons.content_cut,
                      isDark: isDark,
                      cardColor: cardColor,
                    ),
                  ),

                const SizedBox(height: 20),

                // --- Marketing Feed ---
                _buildDepartmentHeader("Recent Orders", TColors.marketing),
                if (controller.recentOrders.isEmpty)
                  _buildEmptyState("No new orders")
                else
                  ...controller.recentOrders.map(
                    (order) => _buildLogTile(
                      title: order.clientName,
                      subtitle: "${order.productName} (x${order.quantity})",
                      value: "₹${order.totalAmount}",
                      unit: "",
                      color: TColors.marketing,
                      icon: Icons.shopping_bag,
                      isDark: isDark,
                      cardColor: cardColor,
                    ),
                  ),

                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ... (Paste all your Helper Widgets here: _buildModernStatCard, _buildActionCard, etc.) ...
  // Keeping the helpers the same as your code to save space.

  Widget _buildModernStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -5,
            top: -5,
            child: Icon(icon, size: 70, color: color.withValues(alpha: 0.08)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertBanner(AdminController controller) {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRouteNames.pendingApprovals),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Action Required",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "${controller.pendingApprovalsCount.value} New users waiting",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: TColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildLogTile({
    required String title,
    required String subtitle,
    required String value,
    required String unit,
    required Color color,
    required IconData icon,
    required bool isDark,
    required Color cardColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              if (unit.isNotEmpty)
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
