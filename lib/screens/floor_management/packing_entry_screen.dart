import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../utils/constants/colors.dart';
import '../../utils/constants/sizes.dart';
import '../../utils/widgets/custom_text_field.dart';
import '../../controllers/floor_management/packing_controller.dart';
// import '../../routes/route_names.dart'; // No longer needed if we aren't navigating

class PackingEntryScreen extends StatelessWidget {
  const PackingEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // FIX: Use Get.find() to retrieve the persistent controller instance
    final controller = Get.find<PackingController>();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : 2;

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : TColors.light,
      appBar: AppBar(
        title: const Text("Factory Packing Entry"),
        centerTitle: true,
        backgroundColor: TColors.packing,
        foregroundColor: Colors.white,
        elevation: 0,
        // REMOVED: The 'actions' list with the analytics button is gone.
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.md),
        child: Form(
          key: controller.packingFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SECTION 1: CARTON CATEGORIZATION ---
              _buildSectionHeader(
                context,
                "Carton Type",
                Icons.category_outlined,
              ),
              Container(
                padding: const EdgeInsets.all(TSizes.md),
                decoration: _buildBoxDecoration(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TCustomTextField(
                      label: "Carton Serial #",
                      controller: controller.cartonNo,
                      prefixIcon: Icons.qr_code_scanner,
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value == null || value.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: TSizes.md),

                    // Style Number Field
                    TCustomTextField(
                      label: "Style Number",
                      controller: controller.styleNo,
                      prefixIcon: Icons.style,
                      validator: (value) =>
                          value == null || value.isEmpty ? "Required" : null,
                    ),

                    const SizedBox(height: TSizes.md),
                    const Text(
                      "Select Primary Size Category:",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Horizontal Size Toggle Selector
                    Obx(
                      () => SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: controller.sizeOptions.map((size) {
                            bool isSelected =
                                controller.selectedCartonSize.value == size;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(
                                  size,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark
                                              ? Colors.white70
                                              : Colors.black),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: TColors.packing,
                                backgroundColor: isDark
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                                onSelected: (selected) {
                                  if (selected) {
                                    controller.selectedCartonSize.value = size;
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: TSizes.xl),

              // --- SECTION 2: PIECE COUNT ---
              _buildSectionHeader(
                context,
                "Pieces Inside Carton",
                Icons.list_alt_outlined,
              ),
              Container(
                padding: const EdgeInsets.all(TSizes.md),
                decoration: _buildBoxDecoration(context),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 2.8,
                    crossAxisSpacing: TSizes.md,
                    mainAxisSpacing: TSizes.md,
                  ),
                  itemCount: controller.boxContents.length,
                  itemBuilder: (context, index) {
                    final sizeKey = controller.boxContents.keys.elementAt(
                      index,
                    );
                    return TCustomTextField(
                      label: "Qty",
                      controller: controller.boxContents[sizeKey],
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      prefixText: "$sizeKey : ",
                      onChanged: (_) => controller.calculateBoxTotal(),
                    );
                  },
                ),
              ),

              const SizedBox(height: TSizes.xl),

              // --- SECTION 3: TOTAL & SUBMIT ---
              Container(
                padding: const EdgeInsets.all(TSizes.lg),
                decoration: BoxDecoration(
                  color: isDark ? TColors.dark : Colors.white,
                  borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                  border: const Border(
                    bottom: BorderSide(color: TColors.packing, width: 4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total Pieces in Box:",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Obx(
                          () => Text(
                            "${controller.totalInBox.value}",
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: TColors.packing,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TSizes.md),
                    Obx(
                      () => SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed:
                              controller.totalInBox.value == 0 ||
                                  controller.isSubmitting.value
                              ? null
                              : () => controller.submitCarton(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TColors.packing,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(TSizes.sm),
                            ),
                          ),
                          child: controller.isSubmitting.value
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "SEAL & ADD TO STOCK",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.sm, left: TSizes.xs),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? Colors.grey[400] : TColors.textSecondary,
          ),
          const SizedBox(width: TSizes.sm),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : TColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _buildBoxDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? TColors.dark : Colors.white,
      borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
