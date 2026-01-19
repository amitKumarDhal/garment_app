import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/sizes.dart';
import '../../utils/widgets/custom_text_field.dart';
import '../../controllers/floor_management/printing_controller.dart';

class PrintingEntryScreen extends StatelessWidget {
  const PrintingEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PrintingController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : TColors.light,
      appBar: AppBar(
        title: const Text("Printing Section Entry"),
        centerTitle: true,
        backgroundColor: TColors.printing,
        foregroundColor: TColors.textWhite,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.md),
        child: Form(
          key: controller.printingFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Section 1: Verification Card ---
              _buildSectionHeader(
                context,
                "Verification",
                Icons.verified_user_outlined,
              ),
              Container(
                padding: const EdgeInsets.all(TSizes.md),
                decoration: _buildBoxDecoration(context),
                child: Row(
                  children: [
                    Expanded(
                      child: TCustomTextField(
                        label: "Style No",
                        controller: controller.styleNo,
                        prefixIcon: Icons.tag,
                      ),
                    ),
                    const SizedBox(width: TSizes.md),
                    Expanded(
                      child: TCustomTextField(
                        label: "Total Received",
                        controller: controller.receivedFromCutting,
                        keyboardType: TextInputType.number,
                        onChanged: (value) =>
                            controller.calculatePrintingTotals(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: TSizes.xl),

              // --- Section 2: Damage Entry Card ---
              _buildSectionHeader(
                context,
                "Damages per Size",
                Icons.report_problem_outlined,
                color: Colors.red,
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
                  itemCount: controller.damagedQuantities.length,
                  itemBuilder: (context, index) {
                    String sizeKey = controller.damagedQuantities.keys
                        .elementAt(index);
                    return TCustomTextField(
                      label: "Damage",
                      controller: controller.damagedQuantities[sizeKey],
                      keyboardType: TextInputType.number,
                      prefixText: "$sizeKey: ",
                      onChanged: (value) =>
                          controller.calculatePrintingTotals(),
                    );
                  },
                ),
              ),

              const SizedBox(height: TSizes.xl),

              // --- Section 3: Result Summary Card ---
              Container(
                padding: const EdgeInsets.all(TSizes.lg),
                decoration: BoxDecoration(
                  color: isDark ? TColors.dark : Colors.white,
                  borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                  border: const Border(
                    left: BorderSide(color: TColors.printing, width: 6),
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
                    _summaryRow(
                      context,
                      "Total Damaged:",
                      controller.totalDamaged,
                      Colors.red,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: TSizes.sm),
                      child: Divider(),
                    ),
                    _summaryRow(
                      context,
                      "Net Good Pieces:",
                      controller.netGoodPieces,
                      TColors.stitching,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: TSizes.xl),

              // --- Action Button ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => controller.submitPrintingData(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.printing,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(TSizes.sm),
                    ),
                  ),
                  child: const Text(
                    "SEND TO STITCHING",
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
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon, {
    Color? color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.sm, left: TSizes.xs),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: color ?? (isDark ? Colors.grey[400] : TColors.textSecondary),
          ),
          const SizedBox(width: TSizes.sm),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color ?? (isDark ? Colors.white : TColors.textPrimary),
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

  Widget _summaryRow(
    BuildContext context,
    String label,
    RxInt value,
    Color textColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[400] : TColors.textSecondary,
          ),
        ),
        Obx(
          () => Text(
            "${value.value}",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}
