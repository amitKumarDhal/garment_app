import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/sizes.dart';
import '../../controllers/admin/admin_controller.dart';
import '../../controllers/navigation_controller.dart';
import '../../routes/route_names.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminController>();
    final navController = Get.find<NavigationController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : TColors.light,
      appBar: AppBar(
        title: const Text("Admin Command Center"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => navController.selectedIndex.value = 0,
        ),
        actions: [
          IconButton(
            onPressed: () => controller.refreshStats(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.md),
        child: Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (controller.pendingApprovalsCount.value > 0)
                _buildApprovalNotificationCard(controller, isDark),

              const SizedBox(height: TSizes.md),
              Text(
                "Factory Overview",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: TSizes.md),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.4,
                children: [
                  _buildStatCard(
                    "Production",
                    "${controller.totalDailyProduction.value}",
                    TColors.primary,
                    Icons.precision_manufacturing,
                  ),
                  _buildStatCard(
                    "Efficiency",
                    "${controller.averageEfficiency.value}%",
                    Colors.green,
                    Icons.trending_up,
                  ),
                  _buildStatCard(
                    "Workers",
                    "${controller.activeWorkers.value}",
                    Colors.blue,
                    Icons.people,
                  ),
                  _buildStatCard(
                    "Damages",
                    "${controller.totalDamages.value}",
                    Colors.red,
                    Icons.warning,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalNotificationCard(
    AdminController controller,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRouteNames.pendingApprovals),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.group_add, color: Colors.orange, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Pending Approvals",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "${controller.pendingApprovalsCount.value} requests waiting",
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.orange),
          ],
        ),
      ),
    );
  }
}
