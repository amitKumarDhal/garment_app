import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/sizes.dart';
import '../../controllers/admin/admin_controller.dart';
import '../../routes/route_names.dart';

// ✅ ALIGNED WITH YOUR TREE STRUCTURE
import 'worker_list_screen.dart';
import 'inventory_screen.dart';
import '../floor_management/agent_list_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // Using find() because it's injected in NavigationController
    final controller = Get.find<AdminController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : TColors.light,
      appBar: AppBar(
        title: const Text("Command Center"),
        backgroundColor: isDark ? TColors.dark : TColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => controller.refreshStats(),
            icon: const Icon(Icons.refresh),
          ),
          Obx(
            () => Stack(
              children: [
                IconButton(
                  onPressed: () => Get.toNamed(AppRouteNames.pendingApprovals),
                  icon: const Icon(Icons.notifications),
                ),
                if (controller.pendingApprovalsCount.value > 0)
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${controller.pendingApprovalsCount.value}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => controller.refreshStats(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(TSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Overview",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: TSizes.sm),

              // Main Navigation Hub (Stats + Hubs)
              _buildStatsGrid(context, controller),

              const SizedBox(height: TSizes.lg),

              const Text(
                "Quick Actions",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: TSizes.sm),

              // 1. Pending Approvals (Only Admin primary task remains here)
              _buildActionCard(
                context,
                title: "Pending Approvals",
                subtitle: "Review & verify new worker IDs",
                icon: Icons.verified_user,
                color: Colors.orange,
                onTap: () => Get.toNamed(AppRouteNames.pendingApprovals),
              ),

              // Note: Marketing Upload has been removed as it is now in the Sales Agent Tab
            ],
          ),
        ),
      ),
    );
  }

  // --- STATS GRID ---
  Widget _buildStatsGrid(BuildContext context, AdminController controller) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.3,
      children: [
        Obx(
          () => _buildStatCard(
            "Daily Sales",
            "₹${controller.totalDailyProduction.value}",
            Icons.currency_rupee,
            Colors.blue,
          ),
        ),
        GestureDetector(
          onTap: () => Get.to(() => const WorkerListScreen()),
          child: Obx(
            () => _buildStatCard(
              "Workforce",
              "${controller.activeWorkers.value}",
              Icons.groups,
              Colors.teal,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => Get.to(() => const AgentListScreen()),
          child: _buildStatCard(
            "Sales Force",
            "View Agents",
            Icons.support_agent,
            Colors.purple,
          ),
        ),
        GestureDetector(
          onTap: () => Get.to(() => const InventoryScreen()),
          child: _buildStatCard(
            "Inventory",
            "Check Stock",
            Icons.inventory_2,
            Colors.indigo,
          ),
        ),
        Obx(() {
          double eff = controller.averageEfficiency.value;
          Color effColor = eff >= 80
              ? Colors.green
              : (eff >= 50 ? Colors.orange : Colors.red);
          return _buildStatCard(
            "Factory Health",
            "${eff.toStringAsFixed(1)}%",
            Icons.speed,
            effColor,
          );
        }),
        Obx(
          () => _buildStatCard(
            "Damages",
            "${controller.totalDamages.value}",
            Icons.warning,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  // --- REUSABLE STAT CARD ---
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(color: color.withOpacity(0.8), fontSize: 11),
          ),
        ],
      ),
    );
  }

  // --- QUICK ACTION CARD ---
  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
