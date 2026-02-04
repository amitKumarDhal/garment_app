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
        title: const Text("Factory Production Summary"),
        centerTitle: true,
        backgroundColor: TColors.packing,
        foregroundColor: Colors.white,
        elevation: 0,
        // Pro-Tip: Add a back button that explicitly returns to Packing Entry
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(TSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. TOTAL STOCK & GOAL PROGRESS ---
              _buildMainInventoryCard(controller),

              const SizedBox(height: TSizes.lg),

              // --- 2. ACTION: RETURN TO PACKING ---
              _buildPackNextButton(),

              const SizedBox(height: TSizes.xl),

              // --- 3. SIZE BREAKDOWN GRID ---
              const Text(
                "Stock by Size Category",
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
                  childAspectRatio: 1.6,
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
                      "XXL",
                      controller.countXXL,
                      Colors.purple,
                      isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: TSizes.xl),
              const Divider(),
              const SizedBox(height: TSizes.md),

              // --- 4. SEARCH & RECENT LOGS ---
              _buildSearchAndFilterSection(context, controller, isDark),
              const SizedBox(height: TSizes.md),
              _buildLogList(controller, isDark),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Components ---

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
            "TOTAL FACTORY PACKED STOCK",
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => Text(
              "${controller.totalPiecesInFactory}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // --- TARGET PROGRESS BAR (Practical Requirement) ---
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Daily Goal Progress",
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              Text(
                "75%",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 0.75, // Replace with dynamic calculation later
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackNextButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Get.back(),
        icon: const Icon(Icons.add_box_rounded),
        label: const Text("PACK ANOTHER CARTON"),
        style: ElevatedButton.styleFrom(
          backgroundColor: TColors.packing.withValues(alpha: 0.1),
          foregroundColor: TColors.packing,
          elevation: 0,
          side: const BorderSide(color: TColors.packing),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterSection(
    BuildContext context,
    PackingController controller,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.shade300,
            ),
          ),
          child: TextField(
            onChanged: (val) => controller.searchQuery.value = val,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              icon: const Icon(Icons.search, color: TColors.packing),
              hintText: "Find Carton # or Style...",
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: InputBorder.none,
              suffixIcon: Obx(
                () => controller.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => controller.searchQuery.value = '',
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              "All",
              "S",
              "M",
              "L",
              "XL",
              "XXL",
            ].map((size) => _buildFilterChip(size, controller)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, PackingController controller) {
    return Obx(() {
      final isSelected = controller.activeFilter.value == label;
      return Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: ChoiceChip(
          label: Text(label),
          selected: isSelected,
          showCheckmark: false,
          selectedColor: TColors.packing,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
          backgroundColor: Colors.transparent,
          side: BorderSide(
            color: isSelected
                ? TColors.packing
                : Colors.grey.withValues(alpha: 0.3),
          ),
          onSelected: (val) {
            if (val) controller.activeFilter.value = label;
          },
        ),
      );
    });
  }

  Widget _buildLogList(PackingController controller, bool isDark) {
    return Obx(() {
      final list = controller.filteredInventory;
      if (list.isEmpty) {
        return const Center(child: Text("No matching cartons."));
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index];
          return Card(
            elevation: 0,
            color: isDark ? TColors.dark : Colors.white,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
              ),
            ),
            child: ListTile(
              leading: const Icon(Icons.inventory_2, color: TColors.packing),
              title: Text(
                "#${item['cartonNo'] ?? '?'}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "Style: ${item['styleNo']} | Size ${item['category']}",
              ),
              trailing: Text(
                "${item['totalPieces']} pcs",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: TColors.packing,
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildSizeBox(String label, int count, Color color, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
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
          const SizedBox(height: 5),
          Text(
            "$count",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
