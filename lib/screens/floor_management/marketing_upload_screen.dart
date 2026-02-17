import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../utils/constants/colors.dart';
import '../../utils/widgets/custom_text_field.dart';
import '../../controllers/floor_management/marketing_upload_controller.dart';

class MarketingUploadScreen extends StatelessWidget {
  const MarketingUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MarketingUploadController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 24,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        title: Text(
          "Create Order",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: TColors.primary,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        onRefresh: () async => await controller.fetchLastOrderSerial(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 10,
            bottom: 120, // Prevents hiding behind the floating dock
          ),
          child: Form(
            key: controller.uploadFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // --- TOP ALERT: LAST ORDER SERIAL STATUS ---
                Obx(
                      () => Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.blue.withOpacity(0.1) : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.info_outline_rounded, size: 16, color: Colors.blue),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Last Synced Serial in Database",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.blue.shade200 : Colors.blue.shade800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                controller.isLoading.value ? "Fetching..." : controller.lastOrderSerial.value,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: isDark ? Colors.white : Colors.black87,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            controller.fetchLastOrderSerial();
                          },
                          icon: controller.isLoading.value
                              ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue)
                          )
                              : const Icon(Icons.sync_rounded, color: Colors.blue),
                          splashRadius: 24,
                        ),
                      ],
                    ),
                  ),
                ),

                // --- SECTION 1: DESIGN MOCKUP ---
                _buildSectionHeader("Design Mockup", Icons.palette_outlined, isDark),
                _buildImagePicker(isDark, controller),
                const SizedBox(height: 28),

                // --- SECTION 2: ORDER & CLIENT INFO ---
                _buildSectionHeader("Order & Client Details", Icons.business_center_outlined, isDark),
                _buildFormCard(isDark, [
                  // ✅ NEW ORDER ID FIELD
                  TCustomTextField(
                    label: "New Order ID (Auto-Generated)",
                    controller: controller.orderNo,
                    prefixIcon: Icons.tag_rounded,
                    readOnly: true, // Locked so agents can't mess up the sequence
                    hintText: "Syncing...",
                  ),
                  const SizedBox(height: 16),
                  TCustomTextField(
                    label: "Client Name",
                    controller: controller.clientName,
                    prefixIcon: Icons.person_outline_rounded,
                    validator: (val) => val!.isEmpty ? "Client name required" : null,
                  ),
                  const SizedBox(height: 16),
                  TCustomTextField(
                    label: "Organization / Business",
                    controller: controller.organization,
                    prefixIcon: Icons.domain_rounded,
                  ),
                  const SizedBox(height: 16),
                  TCustomTextField(
                    label: "Phone Number",
                    controller: controller.phone,
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TCustomTextField(
                    label: "Billing / Shipping Address",
                    controller: controller.address,
                    prefixIcon: Icons.location_on_outlined,
                    maxLines: 2,
                    hintText: "Full address...",
                  ),
                ]),
                const SizedBox(height: 28),

                // --- SECTION 3: PRODUCT & PRICING ---
                _buildSectionHeader("Product Specs", Icons.inventory_2_outlined, isDark),
                _buildFormCard(isDark, [
                  TCustomTextField(
                    label: "Product Code / SKU",
                    controller: controller.productCode,
                    prefixIcon: Icons.qr_code_rounded,
                    validator: (val) => val!.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: TCustomTextField(
                          label: "Qty",
                          controller: controller.quantity,
                          prefixIcon: Icons.numbers_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 6,
                        child: TCustomTextField(
                          label: "Unit Price",
                          controller: controller.orderValue,
                          prefixIcon: Icons.currency_rupee_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TCustomTextField(
                    label: "GST Percentage (%)",
                    controller: controller.gstInfo,
                    prefixIcon: Icons.percent_rounded,
                    keyboardType: TextInputType.number,
                    hintText: "e.g., 18",
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => controller.chooseDate(context),
                    child: AbsorbPointer(
                      child: TCustomTextField(
                        label: "Delivery Deadline",
                        controller: controller.deadline,
                        prefixIcon: Icons.calendar_month_rounded,
                        validator: (val) => val!.isEmpty ? "Date required" : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TCustomTextField(
                    label: "Detailed Description",
                    controller: controller.productDetails,
                    prefixIcon: Icons.notes_rounded,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TCustomTextField(
                    label: "Order Sizes",
                    controller: controller.sizeDescription,
                    prefixIcon: Icons.straighten_rounded,
                    hintText: "e.g., S:10, M:20, XL:5",
                  ),
                ]),
                const SizedBox(height: 28),

                // --- SECTION 4: FINANCIAL SUMMARY ---
                _buildSectionHeader("Financial Summary", Icons.receipt_long_rounded, isDark),
                _buildCalculationSummary(isDark, controller),
                const SizedBox(height: 32),

                // --- SUBMIT BUTTON ---
                Obx(
                      () => Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: controller.isLoading.value
                            ? [Colors.grey.shade400, Colors.grey.shade500]
                            : [const Color(0xFF9C27B0), const Color(0xFF6A1B9A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        if (!controller.isLoading.value)
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: controller.isLoading.value ? null : () {
                          HapticFeedback.mediumImpact();
                          controller.submitOrder();
                        },
                        child: Center(
                          child: controller.isLoading.value
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : const Text(
                            "SUBMIT ORDER",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- MODERN SECTION HEADER ---
  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: TColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: TColors.primary),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // --- PREMIUM FORM CARD ---
  Widget _buildFormCard(bool isDark, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
          width: 1,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  // --- SLEEK IMAGE PICKER ---
  Widget _buildImagePicker(bool isDark, MarketingUploadController controller) {
    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E).withOpacity(0.5) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => controller.pickImage(),
          child: Obx(
                () => controller.selectedImagePath.value.isEmpty
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cloud_upload_outlined, size: 28, color: TColors.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  "Tap to upload mockup",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text("JPG, PNG up to 5MB", style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            )
                : ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.file(
                File(controller.selectedImagePath.value),
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- RECEIPT-STYLE FINANCIAL SUMMARY ---
  Widget _buildCalculationSummary(bool isDark, MarketingUploadController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.green.withOpacity(isDark ? 0.3 : 0.5),
          width: 1.5,
        ),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.green.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Editable Adjustments
          Row(
            children: [
              Expanded(child: _buildSmallInput(controller.shippingCharge, "Shipping (₹)", isDark, icon: Icons.local_shipping_outlined)),
              const SizedBox(width: 12),
              Expanded(child: _buildSmallInput(controller.advanceAmount, "Advance (₹)", isDark, isBold: true, icon: Icons.payments_outlined)),
            ],
          ),

          const SizedBox(height: 20),
          _buildDashedDivider(isDark),
          const SizedBox(height: 16),

          // Ledger Rows
          Obx(() => _buildLedgerRow("Base Subtotal", "₹${controller.subTotal.value.toStringAsFixed(2)}", isDark)),
          const SizedBox(height: 8),
          Obx(() => _buildLedgerRow("Tax & Shipping", "+ ₹${(controller.taxAmount.value + (double.tryParse(controller.shippingCharge.text) ?? 0)).toStringAsFixed(2)}", isDark)),
          const SizedBox(height: 8),
          Obx(() => _buildLedgerRow("Grand Total", "₹${controller.grandTotal.value.toStringAsFixed(2)}", isDark, isBold: true)),
          const SizedBox(height: 8),
          _buildLedgerRow("Less Advance", "- ₹${(double.tryParse(controller.advanceAmount.text) ?? 0).toStringAsFixed(2)}", isDark, isRed: true),

          const SizedBox(height: 16),
          _buildDashedDivider(isDark),
          const SizedBox(height: 16),

          // Final Balance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "BALANCE DUE",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5, color: Colors.grey),
              ),
              Obx(
                    () => Text(
                  "₹${controller.balanceDue.value.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    color: Colors.green, // Highly visible final number
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper: Dashed line for receipt feel
  Widget _buildDashedDivider(bool isDark) {
    return Row(
      children: List.generate(
        40,
            (index) => Expanded(
          child: Container(
            color: index % 2 == 0
                ? Colors.transparent
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
            height: 1.5,
          ),
        ),
      ),
    );
  }

  // Helper: Sleek mini-inputs for the summary box
  Widget _buildSmallInput(TextEditingController controller, String label, bool isDark, {bool isBold = false, required IconData icon}) {
    return Container(
      height: 48,
      padding: const EdgeInsets.only(left: 12, right: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isBold ? Colors.green.withOpacity(0.5) : (isDark ? Colors.white10 : Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: isBold ? Colors.green : Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: label,
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontWeight: FontWeight.normal),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Clean ledger rows
  Widget _buildLedgerRow(String label, String val, bool isDark, {bool isRed = false, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          val,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
            fontSize: isBold ? 15 : 14,
            color: isRed ? Colors.redAccent : (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }
}