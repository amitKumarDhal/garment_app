import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // Add this package to pubspec.yaml if missing
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
    
    // Date Controller (Local for UI display)
    final TextEditingController dateController = TextEditingController(
      text: DateFormat('dd MMM yyyy').format(DateTime.now()),
    );

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : Colors.grey[100],
      appBar: AppBar(
        title: const Text(TTexts.cuttingTitle),
        centerTitle: true,
        backgroundColor: TColors.cutting,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Practical: Quick History Button
          IconButton(
            onPressed: () => Get.snackbar("History", "Showing last 5 entries..."),
            icon: const Icon(Icons.history),
            tooltip: "Recent Logs",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.md),
        child: Form(
          key: controller.cuttingFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // --- 1. DATE & SHIFT (Context) ---
              Row(
                children: [
                  Expanded(
                    child: _buildReadOnlyField(
                      context, 
                      icon: Icons.calendar_today, 
                      label: "Date", 
                      value: dateController.text
                    ),
                  ),
                  const SizedBox(width: TSizes.md),
                  Expanded(
                    child: _buildReadOnlyField(
                      context, 
                      icon: Icons.access_time, 
                      label: "Shift", 
                      value: "Morning (A)" // You can make this dynamic later
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TSizes.md),

              // --- 2. JOB DETAILS (With Scanner) ---
              _buildSectionHeader("Job Sheet Details", Icons.assignment_outlined),
              Container(
                padding: const EdgeInsets.all(TSizes.md),
                decoration: _buildBoxDecoration(context),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TCustomTextField(
                            label: "Style Number",
                            controller: controller.styleNo,
                            prefixIcon: Icons.tag,
                            textInputAction: TextInputAction.next,
                            validator: (value) => value!.isEmpty ? "Required" : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Practical: Scan Button
                        Container(
                          decoration: BoxDecoration(
                            color: TColors.cutting.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.qr_code_scanner, color: TColors.cutting),
                            onPressed: () {
                              // Simulate Scan
                              controller.styleNo.text = "STY-2024-001";
                              Get.snackbar("Scanned", "Style No Auto-filled");
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TSizes.inputFieldSpacing),
                    Row(
                      children: [
                        Expanded(
                          child: TCustomTextField(
                            label: "Lot No",
                            controller: controller.lotNo,
                            prefixIcon: Icons.numbers,
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: TSizes.md),
                        Expanded(
                          child: TCustomTextField(
                            label: "Fabric Type",
                            controller: controller.fabricType,
                            prefixIcon: Icons.layers_outlined,
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: TSizes.lg),

              // --- 3. QUANTITY BREAKDOWN (Grid) ---
              _buildSectionHeader("Size Breakdown", Icons.straighten_outlined),
              Container(
                padding: const EdgeInsets.all(TSizes.md),
                decoration: _buildBoxDecoration(context),
                child: Column(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, // 3 columns is better for numeric pads
                        childAspectRatio: 1.8,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: controller.sizeQuantities.length,
                      itemBuilder: (context, index) {
                        String sizeKey = controller.sizeQuantities.keys.elementAt(index);
                        return TextFormField(
                          controller: controller.sizeQuantities[sizeKey],
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          onChanged: (val) => controller.calculateTotal(),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            labelText: sizeKey,
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            filled: true,
                            fillColor: isDark ? Colors.black12 : Colors.grey[50],
                          ),
                        );
                      },
                    ),
                    const Divider(height: 24),
                    // Practical: Remarks Field
                    TextFormField(
                       decoration: InputDecoration(
                         prefixIcon: const Icon(Icons.note_alt_outlined),
                         labelText: "Remarks / Defects (Optional)",
                         hintText: "e.g. Fabric shortage in roll #2",
                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                       ),
                       maxLines: 2,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: TSizes.lg),

              // --- 4. SUMMARY & ACTION ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [TColors.cutting, TColors.cutting.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: TColors.cutting.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total Production",
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text("Pcs", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const SizedBox(height: 4),
                    Obx(
                      () => Text(
                        "${controller.totalQuantity.value}",
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Obx(
                        () => ElevatedButton(
                          onPressed: controller.isLoading.value
                              ? null
                              : () => controller.submitCuttingData(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: TColors.cutting,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  height: 24, 
                                  width: 24, 
                                  child: CircularProgressIndicator(strokeWidth: 2)
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle_outline),
                                    const SizedBox(width: 8),
                                    Text(
                                      TTexts.submit.toUpperCase(),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 13, 
              fontWeight: FontWeight.bold, 
              color: Colors.grey[600], 
              letterSpacing: 1.1
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(BuildContext context, {required IconData icon, required String label, required String value}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? TColors.dark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: TColors.cutting),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          )
        ],
      ),
    );
  }

  BoxDecoration _buildBoxDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? TColors.dark : Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}