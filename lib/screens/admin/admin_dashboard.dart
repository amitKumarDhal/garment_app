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
              // 1. Pending Approvals Card
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

              // 2. Statistics Grid (Now fully dynamic)
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
                    "₹${controller.totalDailyProduction.value}",
                    TColors.primary,
                    Icons.currency_rupee,
                  ),
                  _buildStatCard(
                    "Efficiency",
                    "${controller.averageEfficiency.value.toStringAsFixed(1)}%",
                    controller.averageEfficiency.value > 80
                        ? Colors.green
                        : Colors.orange,
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

              const SizedBox(height: TSizes.xl),

              // 3. NEW: Stitching Section Entries
              _buildSectionHeader(
                context,
                "Floor Status: Stitching",
                Icons.precision_manufacturing_outlined,
              ),
              const SizedBox(height: TSizes.md),

              if (controller.recentStitchingEntries.isEmpty)
                const Center(child: Text("No stitching records today."))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.recentStitchingEntries.length,
                  itemBuilder: (context, index) {
                    final entry = controller.recentStitchingEntries[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: TColors.stitching,
                          child: Icon(
                            Icons.person_outline,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          "${entry['workerName']}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Style: ${entry['styleNo']} • Op: ${entry['operationType']}",
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${entry['completedQty']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: TColors.stitching,
                              ),
                            ),
                            const Text("Done", style: TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: TSizes.xl),

              // 4. Printing Section Entries
              _buildSectionHeader(
                context,
                "Floor Status: Printing",
                Icons.colorize,
              ),
              const SizedBox(height: TSizes.md),

              if (controller.recentPrintingEntries.isEmpty)
                const Center(child: Text("No printing entries recorded today."))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.recentPrintingEntries.length,
                  itemBuilder: (context, index) {
                    final entry = controller.recentPrintingEntries[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.purple,
                          child: Icon(
                            Icons.print_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          "Style: ${entry['styleNo']}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Good Pieces: ${entry['netGoodPieces']}",
                        ),
                        trailing: Text(
                          "${entry['totalDamaged']} Bad",
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: TSizes.xl),

              // 5. Cutting Section Entries
              _buildSectionHeader(
                context,
                "Floor Status: Cutting",
                Icons.content_cut,
              ),
              const SizedBox(height: TSizes.md),

              if (controller.recentCuttingEntries.isEmpty)
                const Center(child: Text("No cutting entries recorded today."))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.recentCuttingEntries.length,
                  itemBuilder: (context, index) {
                    final entry = controller.recentCuttingEntries[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.redAccent,
                          child: Icon(Icons.cut, color: Colors.white, size: 18),
                        ),
                        title: Text(
                          "Style: ${entry['styleNo']}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Lot: ${entry['lotNo']} • Fabric: ${entry['fabricType']}",
                        ),
                        trailing: Text(
                          "${entry['totalQuantity']} Pcs",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: TSizes.xl),

              // 6. Marketing Orders Section
              _buildSectionHeader(
                context,
                "Recent Marketing Orders",
                Icons.shopping_bag_outlined,
              ),
              const SizedBox(height: TSizes.md),

              if (controller.recentOrders.isEmpty)
                const Center(child: Text("No orders recorded yet."))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.recentOrders.length,
                  itemBuilder: (context, index) {
                    final order = controller.recentOrders[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.storefront_outlined),
                        ),
                        title: Text(
                          order.clientName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "${order.productName} • Qty: ${order.quantity}",
                        ),
                        trailing: Text(
                          "₹${order.totalAmount}",
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Helpers ---
  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: TColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
        margin: const EdgeInsets.only(bottom: TSizes.md),
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
