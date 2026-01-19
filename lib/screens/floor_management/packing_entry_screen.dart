import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/sizes.dart';
import '../../utils/widgets/custom_text_field.dart';
import '../../controllers/floor_management/packing_controller.dart';

class PackingEntryScreen extends StatelessWidget {
  const PackingEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PackingController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : TColors.light,
      appBar: AppBar(
        title: const Text("Packing & Export Entry"),
        centerTitle: true,
        backgroundColor: TColors.packing,
        foregroundColor: TColors.textWhite,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.md),
        child: Form(
          key: controller.packingFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                context,
                "Carton Logistics",
                Icons.local_shipping_outlined,
              ),
              Container(
                padding: const EdgeInsets.all(TSizes.md),
                decoration: _buildBoxDecoration(context),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TCustomTextField(
                            label: "Carton #",
                            controller: controller.cartonNo,
                            prefixIcon: Icons.inventory_2_outlined,
                          ),
                        ),
                        const SizedBox(width: TSizes.md),
                        Expanded(
                          child: TCustomTextField(
                            label: "Style No",
                            controller: controller.styleNo,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TSizes.inputFieldSpacing),
                    TCustomTextField(
                      label: "Destination / Buyer",
                      controller: controller.destination,
                      prefixIcon: Icons.location_on_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TSizes.xl),
              _buildSectionHeader(
                context,
                "Packing List (Size Wise)",
                Icons.list_alt_outlined,
              ),
              Container(
                padding: const EdgeInsets.all(TSizes.md),
                decoration: _buildBoxDecoration(context),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.8,
                    crossAxisSpacing: TSizes.md,
                    mainAxisSpacing: TSizes.md,
                  ),
                  itemCount: controller.boxContents.length,
                  itemBuilder: (context, index) {
                    String sizeKey = controller.boxContents.keys.elementAt(
                      index,
                    );
                    return TCustomTextField(
                      label: "Qty",
                      controller: controller.boxContents[sizeKey],
                      keyboardType: TextInputType.number,
                      prefixText: "$sizeKey: ",
                      onChanged: (value) => controller.calculateBoxTotal(),
                    );
                  },
                ),
              ),
              const SizedBox(height: TSizes.xl),
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
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.2 : 0.05,
                      ),
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
                        Text(
                          "Total Pieces in Box:",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : TColors.textPrimary,
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
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () => controller.submitCarton(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TColors.packing,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(TSizes.sm),
                          ),
                        ),
                        child: const Text(
                          "SEAL & FINISH",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
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
        ),
      ),
    );
  }

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
      border: isDark ? Border.all(color: Colors.white10) : null,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
