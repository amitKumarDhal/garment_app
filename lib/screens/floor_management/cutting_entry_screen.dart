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
      backgroundColor: isDark ? TColors.dark : TColors.light,
      appBar: AppBar(
        title: const Text(TTexts.cuttingTitle),
        centerTitle: true,
        backgroundColor: TColors.cutting,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.md),
        child: Form(
          key: controller.cuttingFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 1: Job Details
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
                            prefixIcon: Icons.numbers,
                          ),
                        ),
                        const SizedBox(width: TSizes.md),
                        Expanded(
                          child: TCustomTextField(
                            label: "Fabric",
                            controller: controller.fabricType,
                            prefixIcon: Icons.layers_outlined,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: TSizes.xl),

              // Section 2: Size Breakdown
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

              // Section 3: Summary and Submission
              Container(
                padding: const EdgeInsets.all(TSizes.lg),
                decoration: _buildBoxDecoration(context).copyWith(
                  border: const Border(
                    bottom: BorderSide(color: TColors.cutting, width: 4),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total Pieces:",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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

                    // Reactive Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: Obx(
                        () => ElevatedButton(
                          onPressed: controller.isLoading.value
                              ? null
                              : () => controller.submitCuttingData(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TColors.cutting,
                          ),
                          child: controller.isLoading.value
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  TTexts.submit.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
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

  // Helper methods for UI consistency
  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: TColors.cutting),
          const SizedBox(width: TSizes.sm),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
