import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/sizes.dart';
import '../../routes/route_names.dart';
import '../../controllers/floor_management/supervisor_controller.dart';

class SupervisorMenuScreen extends StatelessWidget {
  const SupervisorMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is initialized
    final controller = Get.put(SupervisorController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Yoobbel Production"),
        centerTitle: true,
        automaticallyImplyLeading: false, // Hides back button
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
                      backgroundColor: TColors.primary.withOpacity(0.1),
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

            // --- Marketing Section ---
            const Text(
              "Department Sections",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            _buildMenuCard(
              "New Order Entry",
              "Upload and record client orders",
              Icons.add_shopping_cart,
              TColors.marketing,
              () => _safeNavigate(AppRouteNames.marketingUpload),
            ),

            const Divider(height: 32),

            // --- Production Floor ---
            const Text(
              "Production Floor",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 12),

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

            // --- UPDATED PACKING CARD ---
            // Renamed to "Packing Section" and removed the inventory button
            _buildMenuCard(
              "Packing Section",
              "Seal cartons & record shipment",
              Icons.inventory_2,
              TColors.packing,
              () => controller.goToSection(AppRouteNames.packingEntry),
              // No trailing button here anymore. It defaults to the arrow >
            ),
          ],
        ),
      ),
    );
  }

  // --- Helpers ---

  void _safeNavigate(String route) {
    try {
      Get.toNamed(route);
    } catch (e) {
      Get.snackbar("Error", "Page not found: $route");
    }
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
            color: color.withOpacity(0.1),
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
