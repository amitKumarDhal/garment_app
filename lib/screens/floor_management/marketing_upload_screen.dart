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

    // ✅ Use Scaffold to restore the AppBar
    return Scaffold(
      backgroundColor: isDark ? TColors.dark : TColors.light,

      // ✅ Restored AppBar
      appBar: AppBar(
        title: const Text("Create New Order"),
        centerTitle: true,
        backgroundColor: TColors.primary,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.md),
        child: Form(
          key: controller.uploadFormKey,
          child: Column(
            children: [
              // --- SECTION 1: DESIGN MOCKUP ---
              _buildSectionHeader("Design Mockup", Icons.image_outlined),
              _buildImagePicker(isDark, controller),

              const SizedBox(height: TSizes.lg),

              // --- SECTION 2: CLIENT INFO ---
              _buildSectionHeader(
                "Order & Client Info",
                Icons.assignment_ind_outlined,
              ),
              _buildFormCard(isDark, [
                TCustomTextField(
                  label: "Order Number",
                  controller: controller.orderNo,
                  prefixIcon: Icons.tag,
                  hintText: "e.g., #ORD-101",
                ),
                const SizedBox(height: TSizes.md),
                TCustomTextField(
                  label: "Client Name",
                  controller: controller.clientName,
                  prefixIcon: Icons.person_outline,
                  validator: (val) =>
                      val!.isEmpty ? "Client name required" : null,
                ),
                const SizedBox(height: TSizes.md),
                TCustomTextField(
                  label: "Organization / Business",
                  controller: controller.organization,
                  prefixIcon: Icons.business,
                ),
                const SizedBox(height: TSizes.md),
                TCustomTextField(
                  label: "Phone Number",
                  controller: controller.phone,
                  prefixIcon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
              ]),

              const SizedBox(height: TSizes.lg),

              // --- SECTION 3: PRODUCT & PRICING ---
              _buildSectionHeader(
                "Product & Pricing",
                Icons.inventory_2_outlined,
              ),
              _buildFormCard(isDark, [
                TCustomTextField(
                  label: "Product Code / SKU",
                  controller: controller.productCode,
                  prefixIcon: Icons.qr_code,
                  validator: (val) => val!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: TSizes.md),
                TCustomTextField(
                  label: "Quantity (Pcs)",
                  controller: controller.quantity,
                  prefixIcon: Icons.numbers,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: TSizes.md),
                TCustomTextField(
                  label: "Unit Price (₹)",
                  controller: controller.orderValue,
                  prefixIcon: Icons.currency_rupee,
                  keyboardType: TextInputType.number,
                  hintText: "Price per single item",
                ),
                const SizedBox(height: TSizes.md),
                TCustomTextField(
                  label: "GST (%)",
                  controller: controller.gstInfo,
                  prefixIcon: Icons.percent,
                  keyboardType: TextInputType.number,
                  hintText: "e.g., 18",
                ),
                const SizedBox(height: TSizes.md),
                GestureDetector(
                  onTap: () => controller.chooseDate(context),
                  child: AbsorbPointer(
                    child: TCustomTextField(
                      label: "Delivery Deadline",
                      controller: controller.deadline,
                      prefixIcon: Icons.calendar_today,
                      validator: (val) => val!.isEmpty ? "Date required" : null,
                    ),
                  ),
                ),
                const SizedBox(height: TSizes.md),
                TCustomTextField(
                  label: "Detailed Description",
                  controller: controller.productDetails,
                  prefixIcon: Icons.notes,
                  maxLines: 3,
                ),
              ]),

              const SizedBox(height: TSizes.lg),

              // --- SECTION 4: CALCULATION ---
              _buildSectionHeader("Summary", Icons.calculate_outlined),
              _buildCalculationSummary(isDark, controller),

              const SizedBox(height: TSizes.xl),

              // --- SUBMIT ---
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () => controller.submitOrder(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(TSizes.sm),
                      ),
                    ),
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "SUBMIT ORDER",
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

  // --- Image Picker Widget ---
  Widget _buildImagePicker(bool isDark, MarketingUploadController controller) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        ),
      ),
      child: InkWell(
        onTap: () => controller.pickImage(),
        child: Obx(
          () => controller.selectedImagePath.value.isEmpty
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 30,
                      color: TColors.primary,
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Upload Mockup",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                  child: Image.network(
                    "https://via.placeholder.com/300",
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
        ),
      ),
    );
  }

  // --- Updated Calculation Summary ---
  Widget _buildCalculationSummary(
    bool isDark,
    MarketingUploadController controller,
  ) {
    return Obx(() {
      double qty = double.tryParse(controller.quantity.text) ?? 0;
      double unitPrice = double.tryParse(controller.orderValue.text) ?? 0;
      double subTotal = qty * unitPrice;
      double total = controller.grandTotal.value;
      double gstAmt = total - subTotal;

      return Container(
        padding: const EdgeInsets.all(TSizes.md),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.green.withValues(alpha: 0.05)
              : Colors.green[50],
          borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            _buildRow(
              "Subtotal ($qty × $unitPrice)",
              "₹${subTotal.toStringAsFixed(2)}",
              isDark,
            ),
            const SizedBox(height: 8),
            _buildRow(
              "Tax (GST ${controller.gstInfo.text}%)",
              "+ ₹${gstAmt.toStringAsFixed(2)}",
              isDark,
              isRed: true,
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "GRAND TOTAL",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "₹${total.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: TColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildRow(
    String label,
    String val,
    bool isDark, {
    bool isRed = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: 13,
          ),
        ),
        Text(
          val,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isRed ? Colors.red : (isDark ? Colors.white : Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 18, color: TColors.primary),
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

  Widget _buildFormCard(bool isDark, List<Widget> children) => Container(
    padding: const EdgeInsets.all(TSizes.md),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
      ],
    ),
    child: Column(children: children),
  );
}
