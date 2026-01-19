import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/sizes.dart';
import '../../utils/constants/text_strings.dart';
import '../../utils/widgets/custom_text_field.dart';
import '../../controllers/floor_management/cutting_controller.dart';

class CuttingEntryScreen extends StatelessWidget {
  const CuttingEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CuttingController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Background adapts to theme
      backgroundColor: isDark ? TColors.dark : TColors.light,
      appBar: AppBar(
        title: const Text(TTexts.cuttingTitle),
        centerTitle: true,
        backgroundColor: TColors.cutting,
        foregroundColor: TColors.textWhite,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.md),
        child: Form(
          key: controller.cuttingFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Section 1: Job Details Card ---
              _buildSectionHeader(
                context,
                "Job Details",
                Icons.assignment_outlined,
              ),
              Container(
                padding: const EdgeInsets.all(TSizes.md),
                decoration: _buildBoxDecoration(context),
                child: Column(
                  children: [
                    TCustomTextField(
                      label: "Style Number",
                      controller: controller.styleNo,
                      prefixIcon: Icons.tag,
                      validator: (value) => value!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: TSizes.inputFieldSpacing),
                    Row(
                      children: [
                        Expanded(
                          child: TCustomTextField(
                            label: "Lot No",
                            controller: controller.lotNo,
                          ),
                        ),
                        const SizedBox(width: TSizes.md),
                        Expanded(
                          child: TCustomTextField(
                            label: "Fabric",
                            controller: controller.fabricType,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: TSizes.xl),

              // --- Section 2: Size-Wise Quantity Card ---
              _buildSectionHeader(
                context,
                "Size-Wise Quantity",
                Icons.straighten_outlined,
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
                  itemCount: controller.sizeQuantities.length,
                  itemBuilder: (context, index) {
                    String sizeKey = controller.sizeQuantities.keys.elementAt(
                      index,
                    );

                    return TCustomTextField(
                      label: "Qty",
                      controller: controller.sizeQuantities[sizeKey],
                      keyboardType: TextInputType.number,
                      prefixText: "$sizeKey: ",
                      onChanged: (value) => controller.calculateTotal(),
                    );
                  },
                ),
              ),

              const SizedBox(height: TSizes.xl),

              // --- Section 3: Summary & Action ---
              Container(
                padding: const EdgeInsets.all(TSizes.lg),
                decoration: BoxDecoration(
                  color: isDark ? TColors.dark : Colors.white,
                  borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                  border: const Border(
                    bottom: BorderSide(color: TColors.cutting, width: 4),
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
                          "Total Pieces:",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : TColors.textPrimary,
                          ),
                        ),
                        Obx(
                          () => Text(
                            "${controller.totalQuantity.value}",
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: TColors.cutting,
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
                        onPressed: () => controller.submitCuttingData(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TColors.cutting,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(TSizes.sm),
                          ),
                        ),
                        child: Text(
                          TTexts.submit.toUpperCase(),
                          style: const TextStyle(
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
