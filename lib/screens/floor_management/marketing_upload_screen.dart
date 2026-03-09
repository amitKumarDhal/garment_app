import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../data/models/order_model.dart';
import '../../utils/constants/colors.dart';
import '../../utils/widgets/custom_text_field.dart';
import '../../controllers/floor_management/marketing_upload_controller.dart';

class MarketingUploadScreen extends StatefulWidget {
  // ✅ OPTIONAL PARAMETER: If passed, the screen enters Edit Mode
  final OrderModel? existingOrder;

  const MarketingUploadScreen({super.key, this.existingOrder});

  @override
  State<MarketingUploadScreen> createState() => _MarketingUploadScreenState();
}

class _MarketingUploadScreenState extends State<MarketingUploadScreen> {
  final controller = Get.put(MarketingUploadController());

  @override
  void initState() {
    super.initState();

    // ✅ Check if we are editing an existing order or creating a new one
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.existingOrder != null) {
        controller.loadOrderData(widget.existingOrder!);
      } else {
        controller.fetchLastOrderSerial();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ Dynamic UI text based on mode
    final bool isEditMode = widget.existingOrder != null;
    final String pageTitle = isEditMode ? "Edit Ledger Entry" : "Create Order";
    final String submitText = isEditMode ? "UPDATE ORDER" : "SUBMIT ORDER";

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: isEditMode ? 0 : 24, // Tighter spacing if showing back button
        leading: isEditMode
            ? IconButton(
          icon: Icon(Icons.close_rounded, color: isDark ? Colors.white : Colors.black87, size: 24),
          onPressed: () {
            controller.clearForm(); // Clean up before leaving
            Get.back();
          },
        )
            : null,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        title: Text(
          pageTitle,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: -0.5),
        ),
      ),
      body: RefreshIndicator(
        color: TColors.primary,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        onRefresh: () async {
          if (!isEditMode) await controller.fetchLastOrderSerial();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 120),
          child: Form(
            key: controller.uploadFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- TOP ALERT (Only show sync box if it's a NEW order) ---
                if (!isEditMode)
                  Obx(
                        () => Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.blue.withValues(alpha:0.1) : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.withValues(alpha:0.3), width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.blue.withValues(alpha:0.2), shape: BoxShape.circle),
                            child: const Icon(Icons.info_outline_rounded, size: 16, color: Colors.blue),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Last Synced Serial in Database", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.blue.shade200 : Colors.blue.shade800)),
                                const SizedBox(height: 2),
                                Text(controller.isLoading.value ? "Fetching..." : controller.lastOrderSerial.value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : Colors.black87, letterSpacing: 1)),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              controller.fetchLastOrderSerial();
                            },
                            icon: controller.isLoading.value ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue)) : const Icon(Icons.sync_rounded, color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  ),

                // --- SECTION 1: DESIGN ---
                _buildSectionHeader("Design Mockup", Icons.palette_outlined, isDark),
                _buildImagePicker(isDark),
                const SizedBox(height: 28),

                // --- SECTION 2: CLIENT INFO ---
                _buildSectionHeader("Order & Client Details", Icons.business_center_outlined, isDark),
                _buildFormCard(isDark, [
                  TCustomTextField(
                      label: isEditMode ? "Order ID" : "New Order ID (Auto-Generated)",
                      controller: controller.orderNo,
                      prefixIcon: Icons.tag_rounded,
                      readOnly: true,
                      hintText: isEditMode ? "" : "Syncing..."
                  ),
                  const SizedBox(height: 16),
                  TCustomTextField(label: "Client Name", controller: controller.clientName, prefixIcon: Icons.person_outline_rounded, validator: (val) => val!.isEmpty ? "Required" : null),
                  const SizedBox(height: 16),

                  // ✅ NEW: PIN CODE & STATE ROW
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: TCustomTextField(
                          label: "PIN Code",
                          controller: controller.pincode, // Make sure to add this to your Controller
                          prefixIcon: Icons.pin_drop_rounded,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Obx(() => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black26 : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                  Icons.map_rounded,
                                  size: 20,
                                  color: controller.selectedState.value.isEmpty ? Colors.grey : TColors.primary
                              ),
                              const SizedBox(width: 10),
                              Text(
                                controller.selectedState.value.isEmpty ? "State" : controller.selectedState.value,
                                style: TextStyle(
                                  color: controller.selectedState.value.isEmpty ? Colors.grey : (isDark ? Colors.white : Colors.black87),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TCustomTextField(label: "Organization / Business", controller: controller.organization, prefixIcon: Icons.domain_rounded),
                  const SizedBox(height: 16),
                  TCustomTextField(label: "Phone Number", controller: controller.phone, prefixIcon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),

                  // ✅ Detailed Address (Used for House/Street)
                  TCustomTextField(label: "Street Address / Area", controller: controller.address, prefixIcon: Icons.location_on_outlined, maxLines: 2),
                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: () => controller.chooseDate(context),
                    child: AbsorbPointer(
                      child: TCustomTextField(label: "Delivery Deadline", controller: controller.deadline, prefixIcon: Icons.calendar_month_rounded, validator: (val) => val!.isEmpty ? "Date required" : null),
                    ),
                  ),
                ]),

                // --- SECTION 3: DYNAMIC PRODUCTS ---
                _buildSectionHeader("Product Specs", Icons.inventory_2_outlined, isDark),

                const SizedBox(height: 16),

                Obx(
                      () => Column(
                    children: [
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final itemForm = controller.items[index];
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: isDark ? Colors.white.withValues(alpha:0.05) : Colors.black.withValues(alpha:0.03)),
                              boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withValues(alpha:0.03), blurRadius: 15, offset: const Offset(0, 5))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: TColors.primary.withValues(alpha:0.1), borderRadius: BorderRadius.circular(8)),
                                      child: Text("ITEM #${index + 1}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: TColors.primary, letterSpacing: 1.5)),
                                    ),
                                    if (index > 0)
                                      GestureDetector(
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          controller.removeItem(index);
                                        },
                                        child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // ✅ ROW 1: Product Name / Details (Full Width & Taller)
                                TCustomTextField(
                                    label: "Product Name / Details",
                                    controller: itemForm.productDetails,
                                    prefixIcon: Icons.notes_rounded,
                                    maxLines: 2,
                                    validator: (val) => val!.isEmpty ? "Required" : null
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start, // Align to top
                                  children: [
                                    Expanded(
                                      child: Obx(() => _buildDropdown(
                                        label: "Neck Type", // Shortened label to prevent overflow
                                        value: itemForm.selectedNeckType.value,
                                        items: controller.neckTypes,
                                        icon: Icons.checkroom_rounded,
                                        isDark: isDark,
                                        onChanged: (val) => itemForm.selectedNeckType.value = val,
                                      )),
                                    ),
                                    const SizedBox(width: 8), // Reduced gap slightly
                                    Expanded(
                                      child: Obx(() => _buildDropdown(
                                        label: "Category", // Shortened label
                                        value: itemForm.selectedProductType.value,
                                        items: controller.productTypes,
                                        icon: Icons.category_rounded,
                                        isDark: isDark,
                                        onChanged: (val) => itemForm.selectedProductType.value = val,
                                      )),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // ✅ ROW 2: Sizes (Full Width & Taller for large size lists)
                                TCustomTextField(
                                  label: "Sizes Breakdown (e.g., S:10, M:20, L:15)",
                                  controller: itemForm.sizeDescription,
                                  prefixIcon: Icons.straighten_rounded,
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 12),

                                // ✅ ROW 3: Code & Qty (Compact)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                        flex: 3,
                                        child: TCustomTextField(label: "Code/SKU", controller: itemForm.productCode, prefixIcon: Icons.qr_code_rounded)
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        flex: 2,
                                        child: TCustomTextField(label: "Qty", controller: itemForm.quantity, prefixIcon: Icons.numbers_rounded, keyboardType: TextInputType.number)
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // ✅ ROW 4: Price & GST (Compact)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                        flex: 3,
                                        child: TCustomTextField(label: "Unit Price", controller: itemForm.orderValue, prefixIcon: Icons.currency_rupee_rounded, keyboardType: TextInputType.number)
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        flex: 2,
                                        child: TCustomTextField(label: "GST (%)", controller: itemForm.gstInfo, prefixIcon: Icons.percent_rounded, keyboardType: TextInputType.number)
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      // "ADD ANOTHER ITEM" BUTTON
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            controller.addNewItem();
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: TColors.primary.withValues(alpha:0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: TColors.primary.withValues(alpha:0.3), width: 1.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_circle_rounded, color: TColors.accent, size: 20),
                                const SizedBox(width: 8),
                                const Text("ADD ANOTHER ITEM", style: TextStyle(color: TColors.accent, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                      gradient: LinearGradient(colors: controller.isLoading.value ? [Colors.grey.shade400, Colors.grey.shade500] : [const Color(0xFF9C27B0), const Color(0xFF6A1B9A)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [if (!controller.isLoading.value) BoxShadow(color: Colors.purple.withValues(alpha:0.3), blurRadius: 12, offset: const Offset(0, 6))],
                    ),
                    child: ElevatedButton(
                      onPressed: controller.isLoading.value ? null : () {
                        HapticFeedback.mediumImpact();
                        controller.submitOrder();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                      child: controller.isLoading.value
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : Text(submitText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2)),
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


  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required bool isDark,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,

      isExpanded: true,

      icon: Icon(Icons.keyboard_arrow_down_rounded,
          color: isDark ? Colors.white70 : Colors.black54, size: 18),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 12),
        prefixIcon: Icon(icon, color: isDark ? Colors.white70 : Colors.black54, size: 18),
        filled: true,
        fillColor: isDark ? Colors.black26 : Colors.grey.shade50,

        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),

        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05))),
      ),
      dropdownColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: TColors.primary.withValues(alpha:0.15), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: TColors.primary)),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildFormCard(bool isDark, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha:0.05) : Colors.black.withValues(alpha:0.03)),
        boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withValues(alpha:0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  // ✅ "COMING SOON" PLACEHOLDER
  Widget _buildImagePicker(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E).withValues(alpha:0.5) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded, size: 28, color: Colors.amber),
          ),
          const SizedBox(height: 16),
          Text(
            "Mockup Uploads",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We are currently upgrading our cloud storage. This feature is coming soon!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "COMING SOON",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ UPDATED SUMMARY: Locks "Advance" in Edit Mode
  Widget _buildCalculationSummary(bool isDark, MarketingUploadController controller) {
    final bool isEditMode = controller.isEditing.value;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.withValues(alpha:isDark ? 0.3 : 0.5), width: 1.5),
        boxShadow: [if (!isDark) BoxShadow(color: Colors.green.withValues(alpha:0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: _buildSmallInput(
                      controller.shippingCharge,
                      "Shipping (₹)",
                      isDark,
                      icon: Icons.local_shipping_outlined
                  )
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildSmallInput(
                      controller.advanceAmount,
                      "Advance (₹)",
                      isDark,
                      isBold: true,
                      icon: Icons.payments_outlined,
                      readOnly: isEditMode, // 🔒 Lock advance field when editing
                      hintText: isEditMode ? "Locked" : "Advance (₹)"
                  )
              ),
            ],
          ),

          if (isEditMode)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Text(
                "*Use the 'Record Payment' button on your ledger to update payments.",
                style: TextStyle(fontSize: 10, color: Colors.orange.shade400, fontStyle: FontStyle.italic),
              ),
            ),

          const SizedBox(height: 20),
          _buildDashedDivider(isDark),
          const SizedBox(height: 16),
          Obx(() => _buildLedgerRow("Base Subtotal", "₹${controller.subTotal.value.toStringAsFixed(2)}", isDark)),
          const SizedBox(height: 8),
          Obx(() => _buildLedgerRow("Total Tax (GST)", "+ ₹${controller.taxAmount.value.toStringAsFixed(2)}", isDark)),
          const SizedBox(height: 8),
          Obx(() => _buildLedgerRow("Grand Total", "₹${controller.grandTotal.value.toStringAsFixed(2)}", isDark, isBold: true)),
          const SizedBox(height: 8),
          // ✅ THE FIXED CODE
          Obx(() {
            // We do a "dummy read" of an observable so GetX knows when to rebuild this row
            final _ = controller.balanceDue.value;

            return _buildLedgerRow(
                "Less Advance",
                "- ₹${(double.tryParse(controller.advanceAmount.text) ?? 0).toStringAsFixed(2)}",
                isDark,
                isRed: true
            );
          }),
          const SizedBox(height: 16),
          _buildDashedDivider(isDark),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("BALANCE DUE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5, color: Colors.grey)),
              Obx(() => Text("₹${controller.balanceDue.value.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Colors.green))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashedDivider(bool isDark) {
    return Row(children: List.generate(40, (index) => Expanded(child: Container(color: index % 2 == 0 ? Colors.transparent : (isDark ? Colors.grey.shade800 : Colors.grey.shade300), height: 1.5))));
  }

  // ✅ UPDATED INPUT HELPER: Supports Read-Only State
  Widget _buildSmallInput(TextEditingController controller, String label, bool isDark, {bool isBold = false, required IconData icon, bool readOnly = false, String? hintText}) {
    return Container(
      height: 48,
      padding: const EdgeInsets.only(left: 12, right: 8),
      decoration: BoxDecoration(
        color: readOnly ? (isDark ? Colors.grey.shade900 : Colors.grey.shade200) : (isDark ? Colors.black26 : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isBold && !readOnly ? Colors.green.withValues(alpha:0.5) : (isDark ? Colors.white10 : Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: readOnly ? Colors.grey : (isBold ? Colors.green : Colors.grey)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              readOnly: readOnly,
              style: TextStyle(
                  color: readOnly ? Colors.grey : (isDark ? Colors.white : Colors.black),
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                  fontSize: 14
              ),
              decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: hintText ?? label,
                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontWeight: FontWeight.normal)
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerRow(String label, String val, bool isDark, {bool isRed = false, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.w500)),
        Text(val, style: TextStyle(fontWeight: isBold ? FontWeight.w900 : FontWeight.w600, fontSize: isBold ? 15 : 14, color: isRed ? Colors.redAccent : (isDark ? Colors.white : Colors.black87))),
      ],
    );
  }
}