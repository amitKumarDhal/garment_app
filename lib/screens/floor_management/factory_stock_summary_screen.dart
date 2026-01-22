import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/sizes.dart';
import '../../controllers/floor_management/packing_controller.dart';

class FactoryStockSummaryScreen extends StatelessWidget {
  const FactoryStockSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PackingController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Factory Inventory Stock"),
        centerTitle: true,
        backgroundColor: TColors.packing,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(TSizes.md),
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
                childAspectRatio: 1.4, // Adjusted for better fit
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
                  ), // Added XXL
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
                TextButton(onPressed: () {}, child: const Text("View All")),
              ],
            ),

            Obx(() {
              if (controller.inventoryList.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      "No cartons recorded yet.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.inventoryList.length > 5
                    ? 5
                    : controller.inventoryList.length,
                itemBuilder: (context, index) {
                  final item = controller.inventoryList.reversed
                      .toList()[index];
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
                          color: TColors.packing.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: TColors.packing,
                        ),
                      ),
                      title: Text("Carton #${item['cartonNo']}"),
                      subtitle: Text(
                        "Size: ${item['category']} | Qty: ${item['totalPieces']}",
                      ),
                      trailing: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                  );
                },
              );
            }),
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
        color: TColors.packing,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
      ),
      child: Column(
        children: [
          const Text(
            "TOTAL STOCK IN FACTORY",
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: TSizes.sm),
          Obx(
            () => Text(
              "${controller.totalPiecesInFactory}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeBox(String label, int count, Color color, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? TColors.dark : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
        border: Border.all(color: color.withOpacity(0.5)),
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
          const SizedBox(height: 4),
          Text(
            "$count",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const Text(
            "Cartons",
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
