import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/sizes.dart';
import '../../routes/route_names.dart';
import '../../controllers/floor_management/supervisor_controller.dart';

// ✅ LIVE FEED IMPORTS
import '../../controllers/admin/admin_controller.dart';
import '../../data/models/activity_item_model.dart';
import '../admin/production_reports_screen.dart';

// ✅ INVENTORY SCREEN IMPORT
import '../admin/inventory_screen.dart';

class SupervisorMenuScreen extends StatelessWidget {
  const SupervisorMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controllers are initialized
    final controller = Get.put(SupervisorController());

    // Safely find AdminController (It's put by GeneralBindings now)
    final adminController = Get.find<AdminController>();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Yoobbel Production"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Welcome Section ---
            Obx(
              () => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? TColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: TColors.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.person, color: TColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Welcome back,",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          controller.supervisorName.value,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: TSizes.xl),

            // --- Production Floor Section ---
            const Text(
              "Production Floor",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            // ✅ NEW: FABRIC INVENTORY (Works for Unit Supervisor & Cutting Check)
            _buildMenuCard(
              "Fabric Inventory",
              "Inward stock & Check availability",
              Icons.store_mall_directory,
              Colors.brown,
              () => Get.to(() => const InventoryScreen()),
            ),

            _buildMenuCard(
              "Cutting Section",
              "Manage fabric layers",
              Icons.content_cut,
              TColors.cutting,
              () => controller.goToSection(AppRouteNames.cuttingEntry),
            ),
            _buildMenuCard(
              "Printing Section",
              "Designs & ink batches",
              Icons.print,
              TColors.printing,
              () => controller.goToSection(AppRouteNames.printingEntry),
            ),
            _buildMenuCard(
              "Stitching Section",
              "Assembly line & QC",
              Icons.handyman,
              TColors.stitching,
              () => controller.goToSection(AppRouteNames.stitchingEntry),
            ),
            _buildMenuCard(
              "Packing Section",
              "Seal cartons & record shipment",
              Icons.inventory_2,
              TColors.packing,
              () => controller.goToSection(AppRouteNames.packingEntry),
            ),

            const SizedBox(height: TSizes.xl),

            // --- Live Feed Section ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Live Floor Updates",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      Get.to(() => const ProductionReportsScreen()),
                  child: const Text("View All", style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Obx(() {
              if (adminController.isLoading.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (adminController.recentActivities.isEmpty) {
                return const Center(child: Text("No recent activity found."));
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: adminController.recentActivities.length,
                itemBuilder: (context, index) => _buildActivityTile(
                  context,
                  adminController.recentActivities[index],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // --- Helpers ---

  Widget _buildActivityTile(BuildContext context, ActivityItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String formattedDate =
        "${item.time.day}/${item.time.month} ${item.time.hour}:${item.time.minute.toString().padLeft(2, '0')}";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  item.subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            formattedDate,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    String title,
    String sub,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    Widget? trailing,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black12, width: 0.5),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          sub,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing:
            trailing ??
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ),
    );
  }
}
