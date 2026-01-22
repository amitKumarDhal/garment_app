import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/sizes.dart';
import '../../utils/constants/text_strings.dart';
import '../../utils/widgets/custom_text_field.dart';
import '../../controllers/floor_management/stitching_controller.dart';

class StitchingEntryScreen extends StatelessWidget {
  const StitchingEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StitchingController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : TColors.light,
      appBar: AppBar(
        title: const Text("Stitching Section Entry"),
        centerTitle: true,
        backgroundColor: TColors.stitching,
        foregroundColor: TColors.textWhite,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.md),
        child: Form(
          key: controller.stitchingFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Section 1: Worker Assignment ---
              _buildSectionHeader(context, "Worker Assignment", Icons.person_add_alt_1_outlined),
              Container(
                padding: const EdgeInsets.all(TSizes.md),
                decoration: _buildBoxDecoration(context),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      dropdownColor: isDark ? TColors.dark : Colors.white,
                      style: TextStyle(color: isDark ? Colors.white : TColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: "Select Worker",
                        prefixIcon: const Icon(Icons.badge_outlined, color: TColors.stitching),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(TSizes.sm)),
                      ),
                      items: controller.availableWorkers.map((String worker) {
                        return DropdownMenuItem(value: worker, child: Text(worker));
                      }).toList(),
                      onChanged: (value) => controller.workerName.text = value ?? "",
                      validator: (value) => value == null ? "Required" : null,
                    ),
                    const SizedBox(height: TSizes.inputFieldSpacing),
                    Row(
                      children: [
                        Expanded(
                          child: TCustomTextField(
                            label: "Style No",
                            controller: controller.styleNo,
                            prefixIcon: Icons.style_outlined,
                            validator: (val) => val!.isEmpty ? "Required" : null,
                          ),
                        ),
                        const SizedBox(width: TSizes.md),
                        Expanded(
                          child: TCustomTextField(
                            label: "Operation",
                            controller: controller.operationType,
                            prefixIcon: Icons.precision_manufacturing_outlined,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: TSizes.xl),

              // --- Section 2: Production Logs ---
              _buildSectionHeader(context, "Production Logs", Icons.history_edu_outlined),
              Container(
                padding: const EdgeInsets.all(TSizes.md),
                decoration: _buildBoxDecoration(context),
                child: Column(
                  children: [
                    TCustomTextField(
                      label: "Total Pieces Assigned",
                      controller: controller.assignedQty,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.assignment_outlined,
                      onChanged: (value) => controller.calculateStitchingStats(),
                    ),
                    const SizedBox(height: TSizes.inputFieldSpacing),
                    Row(
                      children: [
                        Expanded(
                          child: TCustomTextField(
                            label: "Completed",
                            controller: controller.completedQty,
                            keyboardType: TextInputType.number,
                            onChanged: (value) => controller.calculateStitchingStats(),
                          ),
                        ),
                        const SizedBox(width: TSizes.md),
                        Expanded(
                          child: TCustomTextField(
                            label: "Rejected",
                            controller: controller.rejectedQty,
                            keyboardType: TextInputType.number,
                            onChanged: (value) => controller.calculateStitchingStats(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: TSizes.xl),

              // --- Section 3: Live Efficiency Summary ---
              Obx(() => Container(
                padding: const EdgeInsets.all(TSizes.lg),
                decoration: BoxDecoration(
                  color: isDark ? TColors.dark : Colors.white,
                  borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                  border: const Border(left: BorderSide(color: TColors.stitching, width: 6)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    _statusRow(context, "Balance to Finish:", "${controller.balanceQty.value}", isDark ? Colors.white : TColors.textPrimary),
                    const Divider(height: 30),
                    _statusRow(
                      context,
                      "Worker Efficiency:",
                      "${controller.efficiency.value.toStringAsFixed(1)}%",
                      controller.efficiency.value > 80 ? TColors.stitching : Colors.orange,
                    ),
                  ],
                ),
              )),

              const SizedBox(height: TSizes.xl),

              // --- Action Button with Loading State ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value ? null : () => controller.submitStitchingEntry(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.stitching,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.sm)),
                  ),
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(TTexts.save.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Helpers ---
  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.sm, left: TSizes.xs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: TColors.stitching),
          const SizedBox(width: TSizes.sm),
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : TColors.textPrimary)),
        ],
      ),
    );
  }

  BoxDecoration _buildBoxDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? TColors.dark : Colors.white,
      borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
    );
  }

  Widget _statusRow(BuildContext context, String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }
}