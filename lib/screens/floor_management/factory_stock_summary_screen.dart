import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/sizes.dart';
import '../../controllers/floor_management/packing_controller.dart';

class FactoryStockSummaryScreen extends StatelessWidget {
  const FactoryStockSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We use Get.find because the controller is already alive from the previous screen
    final controller = Get.find<PackingController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Factory Inventory Stock"),
        centerTitle: true,
        backgroundColor: TColors.packing,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. TOTAL PIECES OVERVIEW ---
            _buildMainInventoryCard(controller),

            const SizedBox(height: TSizes.lg),

            // --- 2. CARTONS BY SIZE CATEGORY ---
            const Text(
              "Stock by Carton Size",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: TSizes.md),

            Obx(
              () => GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: TSizes.md,
                crossAxisSpacing: TSizes.md,
                childAspectRatio: 1.5, // Slightly wider for better fit
                children: [
                  _buildSizeBox(
                    "Small (S)",
                    controller.countSmall,
                    Colors.blue,
                    isDark,
                  ),
                  _buildSizeBox(
                    "Medium (M)",
                    controller.countMedium,
                    Colors.green,
                    isDark,
                  ),
                  _buildSizeBox(
                    "Large (L)",
                    controller.countLarge,
                    Colors.orange,
                    isDark,
                  ),
                  _buildSizeBox(
                    "X-Large (XL)",
                    controller.countXL,
                    Colors.red,
                    isDark,
                  ),
                  _buildSizeBox(
                    "XX-Large (XXL)",
                    controller.countXXL,
                    Colors.purple,
                    isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: TSizes.lg),

            // --- 3. RECENT PRODUCTION LOG ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Recent Packing Logs",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                // Optional: Export Feature
                IconButton(
                  icon: const Icon(
                    Icons.download,
                    size: 20,
                    color: Colors.grey,
                  ),
                  onPressed: () =>
                      Get.snackbar("Info", "Export to CSV coming soon"),
                ),
              ],
            ),

            Obx(() {
              if (controller.inventoryList.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(Icons.inbox, size: 40, color: Colors.grey),
                        SizedBox(height: 10),
                        Text(
                          "No cartons recorded yet.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                // FIX: Limit to 10 items, but keep ORIGINAL order (Newest First)
                itemCount: controller.inventoryList.length > 10
                    ? 10
                    : controller.inventoryList.length,
                itemBuilder: (context, index) {
                  // FIX: Removed .reversed so we see the newest item at the top
                  final item = controller.inventoryList[index];

                  return Card(
                    elevation: 0,
                    color: isDark ? TColors.dark : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: TColors.packing.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: TColors.packing,
                        ),
                      ),
                      title: Text(
                        "Carton #${item['cartonNo']}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Size: ${item['category']}  |  Qty: ${item['totalPieces']} Pcs",
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Packed",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
            const SizedBox(height: 50), // Bottom padding for scrolling
          ],
        ),
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildMainInventoryCard(PackingController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TSizes.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [TColors.packing, TColors.packing.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: TColors.packing.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "TOTAL STOCK IN FACTORY",
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: TSizes.sm),
          Obx(
            () => Text(
              "${controller.totalPiecesInFactory}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            "Ready for Dispatch",
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeBox(String label, int count, Color color, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "$count",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Cartons",
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
