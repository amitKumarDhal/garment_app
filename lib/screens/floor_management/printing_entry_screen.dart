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
        backgroundColor: TColors.printing,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.md),
        child: Form(
          key: controller.printingFormKey,
          child: Column(
            children: [
              // Verification Section
              _buildCard(context, [
                TCustomTextField(
                  label: "Style No",
                  controller: controller.styleNo,
                  prefixIcon: Icons.tag,
                ),
                const SizedBox(height: TSizes.md),
                TCustomTextField(
                  label: "Total Received",
                  controller: controller.receivedFromCutting,
                  keyboardType: TextInputType.number,
                  onChanged: (v) => controller.calculatePrintingTotals(),
                ),
              ]),

              const SizedBox(height: TSizes.xl),

              // Damage Section
              _buildCard(context, [
                const Text(
                  "Damages per Size",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: TSizes.md),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: controller.damagedQuantities.length,
                  itemBuilder: (context, index) {
                    String key = controller.damagedQuantities.keys.elementAt(
                      index,
                    );
                    return TCustomTextField(
                      label: key,
                      controller: controller.damagedQuantities[key],
                      keyboardType: TextInputType.number,
                      onChanged: (v) => controller.calculatePrintingTotals(),
                    );
                  },
                ),
              ]),

              const SizedBox(height: TSizes.xl),

              // Result Section
              Obx(
                () => _buildCard(context, [
                  _row(
                    "Total Damaged:",
                    "${controller.totalDamaged.value}",
                    Colors.red,
                  ),
                  const Divider(),
                  _row(
                    "Net Good Pieces:",
                    "${controller.netGoodPieces.value}",
                    Colors.green,
                  ),
                ]),
              ),

              const SizedBox(height: TSizes.xl),

              // Submission Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: Obx(
                  () => ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () => controller.submitPrintingData(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColors.printing,
                    ),
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "SEND TO STITCHING",
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

  Widget _buildCard(BuildContext context, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? TColors.dark
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(children: children),
    );
  }

  Widget _row(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
