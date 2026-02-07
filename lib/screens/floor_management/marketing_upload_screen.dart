import 'dart:io';
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
    // 1. Initialize Controller
    final controller = Get.put(MarketingUploadController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : TColors.light,
      appBar: AppBar(
        title: const Text("Create New Order"),
        centerTitle: true,
        backgroundColor: TColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        color: TColors.primary,
        backgroundColor: isDark ? TColors.dark : Colors.white,
        onRefresh: () async {
          await controller.fetchLastOrderSerial();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                  // Serial Number Display
                  Obx(
                    () => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Last Order Serial:",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.grey[300]
                                      : Colors.grey[700],
                                ),
                              ),
                              Text(
                                controller.lastOrderSerial.value,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => controller.fetchLastOrderSerial(),
                            icon: const Icon(Icons.refresh, color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ✅ UI for Auto-Increment Field
                  Row(
                    children: [
                      Expanded(
                        child: // ✅ FINAL UI POLISH: Auto-ID Feedback
                            // ✅ FINAL UI POLISH: Auto-ID Feedback
                            TCustomTextField(
                              label: "Order ID (Auto-Generated)",
                              controller: controller.orderNo,
                              prefixIcon: Icons.tag,
                              readOnly: true, // 🔒 Lock it so they can't type
                              hintText: "Generated automatically on submit...",
                              // removed fillColor and filled to fix the error
                            ),
                      ),
                      const SizedBox(width: 8),
                      // The "Spinning" Refresh Button
                      Obx(
                        () => IconButton(
                          onPressed: () => controller.fetchLastOrderSerial(),
                          icon: controller.isLoading.value
                              ? CircularProgressIndicator() // Spins when fetching
                              : Icon(Icons.autorenew),
                        ),
                      ),
                    ],
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

                  // ✅ NEW: ADDRESS FIELD
                  const SizedBox(height: TSizes.md),
                  TCustomTextField(
                    label: "Billing / Shipping Address",
                    controller: controller.address,
                    prefixIcon: Icons.location_on_outlined,
                    maxLines: 2,
                    hintText: "Full address...",
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
                  Row(
                    children: [
                      Expanded(
                        child: TCustomTextField(
                          label: "Quantity",
                          controller: controller.quantity,
                          prefixIcon: Icons.numbers,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: TSizes.md),
                      Expanded(
                        child: TCustomTextField(
                          label: "Unit Price (₹)",
                          controller: controller.orderValue,
                          prefixIcon: Icons.currency_rupee,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TSizes.md),
                  Row(
                    children: [
                      Expanded(
                        child: TCustomTextField(
                          label: "GST (%)",
                          controller: controller.gstInfo,
                          prefixIcon: Icons.percent,
                          keyboardType: TextInputType.number,
                          hintText: "e.g., 18",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TSizes.md),
                  GestureDetector(
                    onTap: () => controller.chooseDate(context),
                    child: AbsorbPointer(
                      child: TCustomTextField(
                        label: "Delivery Deadline",
                        controller: controller.deadline,
                        prefixIcon: Icons.calendar_today,
                        validator: (val) =>
                            val!.isEmpty ? "Date required" : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: TSizes.md),
                  TCustomTextField(
                    label: "Detailed Description",
                    controller: controller.productDetails,
                    prefixIcon: Icons.notes,
                    maxLines: 2,
                  ),
                  const SizedBox(height: TSizes.md),
                  TCustomTextField(
                    label: "Order Sizes",
                    controller: controller.sizeDescription,
                    prefixIcon: Icons.straighten,
                    hintText: "e.g., S:10, M:20, XL:5",
                  ),
                ]),

                const SizedBox(height: TSizes.lg),

                // --- SECTION 4: FINANCIAL SUMMARY ---
                _buildSectionHeader(
                  "Financial Summary",
                  Icons.calculate_outlined,
                ),

                // ✅ UPDATED: Safe Financial Summary (No logic in build)
                _buildCalculationSummary(isDark, controller),

                const SizedBox(height: TSizes.xl),

                // --- SUBMIT BUTTON ---
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
      ),
    );
  }

  // --- Image Picker ---
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
                  child: Image.file(
                    File(controller.selectedImagePath.value),
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
        ),
      ),
    );
  }

  // ✅ UPDATED: Safe Financial Summary
  Widget _buildCalculationSummary(
    bool isDark,
    MarketingUploadController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.green.withValues(alpha: 0.05) : Colors.green[50],
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Inputs (These do NOT need Obx, they have their own listeners)
          _buildSmallInput(
            controller.shippingCharge,
            "Shipping Charge",
            isDark,
          ),
          const SizedBox(height: 8),
          _buildSmallInput(
            controller.advanceAmount,
            "Advance Received (₹)",
            isDark,
            isBold: true,
          ),

          const Divider(height: 24),

          // ✅ Obx only wraps the text that changes
          Obx(
            () => _buildRow(
              "Subtotal",
              "₹${controller.subTotal.value.toStringAsFixed(2)}",
              isDark,
            ),
          ),

          // Note: For complex strings combining Rx and text, make sure to read .value
          Obx(
            () => _buildRow(
              "Tax & Shipping",
              "+ ₹${(controller.taxAmount.value + (double.tryParse(controller.shippingCharge.text) ?? 0)).toStringAsFixed(2)}",
              isDark,
            ),
          ),

          Obx(
            () => _buildRow(
              "Grand Total",
              "₹${controller.grandTotal.value.toStringAsFixed(2)}",
              isDark,
              isBold: true,
            ),
          ),

          const SizedBox(height: 8),
          // We can use Obx for Advance text too if we want, but reading controller.text is fine here
          // However, to fix the specific error, we avoid large Obx blocks.
          _buildRow(
            "Less: Advance",
            "- ₹${(double.tryParse(controller.advanceAmount.text) ?? 0).toStringAsFixed(2)}",
            isDark,
            isRed: true,
          ),

          const Divider(),

          // Balance Due
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "BALANCE DUE",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.redAccent,
                ),
              ),
              Obx(
                () => Text(
                  "₹${controller.balanceDue.value.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ Helper for Small Inputs inside Summary
  Widget _buildSmallInput(
    TextEditingController controller,
    String label,
    bool isDark, {
    bool isBold = false,
  }) {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isBold ? Colors.green : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 12,
            color: isBold ? Colors.green : Colors.grey,
          ),
          contentPadding: const EdgeInsets.only(bottom: 6),
        ),
      ),
    );
  }

  Widget _buildRow(
    String label,
    String val,
    bool isDark, {
    bool isRed = false,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          val,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
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
