import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/floor_management/finishing_controller.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/sizes.dart';
import '../../utils/widgets/custom_text_field.dart';

class FinishingEntryScreen extends StatelessWidget {
  const FinishingEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize Controller
    final controller = Get.put(FinishingController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : TColors.light,
      appBar: AppBar(
        title: const Text("Finishing & Packing"),
        backgroundColor: Colors.teal, // Distinct color for Finishing
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.md),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("Batch Details"),

              Container(
                padding: const EdgeInsets.all(TSizes.md),
                decoration: _boxDecoration(context),
                child: Column(
                  children: [
                    TCustomTextField(
                      label: "Checker / Packer Name",
                      controller: controller.checkerName,
                      prefixIcon: Icons.person_outline,
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: TSizes.md),
                    TCustomTextField(
                      label: "Style Number",
                      controller: controller.styleNo,
                      prefixIcon: Icons.style,
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: TSizes.lg),
              _buildSectionHeader("Process Counts"),

              Container(
                padding: const EdgeInsets.all(TSizes.md),
                decoration: _boxDecoration(context),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TCustomTextField(
                            label: "Received",
                            controller: controller.receivedQty,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: TSizes.md),
                        Expanded(
                          child: TCustomTextField(
                            label: "Ironed",
                            controller: controller.ironedQty,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TSizes.md),

                    // Highlight Packing as it is the final output
                    TCustomTextField(
                      label: "Final Packed Quantity",
                      controller: controller.packedQty,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.inventory_2_outlined,
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: TSizes.md),

                    TCustomTextField(
                      label: "Defective / Re-work",
                      controller: controller.defectiveQty,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.warning_amber_rounded,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: TSizes.xl),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: Obx(
                  () => ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () => controller.submitFinishingEntry(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(TSizes.sm),
                      ),
                    ),
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "CONFIRM SHIPMENT",
                            style: TextStyle(
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
      ),
    );
  }

  // --- UI Helpers ---
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.sm, left: TSizes.xs),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  BoxDecoration _boxDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
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
