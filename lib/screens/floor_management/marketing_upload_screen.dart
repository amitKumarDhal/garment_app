import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/sizes.dart';
import '../../utils/widgets/custom_text_field.dart';
import '../../controllers/floor_management/marketing_upload_controller.dart';

class MarketingUploadScreen extends StatelessWidget {
  const MarketingUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MarketingUploadController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("New Order Entry"),
        backgroundColor: TColors.marketing,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.md),
        child: Form(
          key: controller.uploadFormKey,
          child: Column(
            children: [
              // --- Group 1: Client Info ---
              _buildSectionHeader(
                "Order & Client Info",
                Icons.assignment_ind_outlined,
              ),
              _buildFormCard(isDark, [
                TCustomTextField(
                  label: "Order Number",
                  controller: controller.orderNo,
                  prefixIcon: Icons.tag,
                  hintText: "e.g., ORD-2026-001",
                  validator: (val) => val!.isEmpty ? "Enter Order #" : null,
                ),
                const SizedBox(height: TSizes.md),
                TCustomTextField(
                  label: "Client Name",
                  controller: controller.clientName,
                  prefixIcon: Icons.person_outline,
                  hintText: "Full Name",
                  validator: (val) => val!.isEmpty ? "Enter Client Name" : null,
                ),
                const SizedBox(height: TSizes.md),
                TCustomTextField(
                  label: "Organization",
                  controller: controller.organization,
                  prefixIcon: Icons.business,
                  hintText: "Company Name",
                ),
                const SizedBox(height: TSizes.md),
                TCustomTextField(
                  label: "Phone Number",
                  controller: controller.phone,
                  prefixIcon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  hintText: "+91 ...",
                ),
              ]),

              const SizedBox(height: TSizes.lg),

              // --- Group 2: Product Details ---
              _buildSectionHeader(
                "Product & Value",
                Icons.inventory_2_outlined,
              ),
              _buildFormCard(isDark, [
                TCustomTextField(
                  label: "Product Details",
                  controller: controller.productDetails,
                  prefixIcon: Icons.description_outlined,
                  hintText: "Items, Colors, Sizes...",
                ),
                const SizedBox(height: TSizes.md),
                Row(
                  children: [
                    Expanded(
                      child: TCustomTextField(
                        label: "Qty",
                        controller: controller.quantity,
                        keyboardType: TextInputType.number,
                        hintText: "Pcs",
                      ),
                    ),
                    const SizedBox(width: TSizes.md),
                    Expanded(
                      child: TCustomTextField(
                        label: "Value (₹)",
                        controller: controller.orderValue,
                        keyboardType: TextInputType.number,
                        hintText: "Total Amt",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TSizes.md),
                Row(
                  children: [
                    Expanded(
                      child: TCustomTextField(
                        label: "GST",
                        controller: controller.gstInfo,
                        hintText: "18%",
                      ),
                    ),
                    const SizedBox(width: TSizes.md),
                    // --- CALENDAR FIELD ---
                    Expanded(
                      child: GestureDetector(
                        onTap: () => controller.chooseDate(context),
                        child: AbsorbPointer(
                          child: TCustomTextField(
                            label: "Deadline",
                            controller: controller.deadline,
                            prefixIcon: Icons.calendar_today,
                            hintText: "Select Date",
                            validator: (val) =>
                                val!.isEmpty ? "Required" : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ]),

              const SizedBox(height: TSizes.xl),

              // --- Action Button ---
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () => controller.submitOrder(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColors.marketing,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(TSizes.sm),
                      ),
                    ),
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "UPLOAD ORDER DATA",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: TSizes.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: TColors.marketing),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(bool isDark, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}
