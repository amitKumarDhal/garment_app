import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../utils/constants/colors.dart';
import '../../controllers/sales/make_quotation_controller.dart';

class MakeQuotationScreen extends StatelessWidget {
  const MakeQuotationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MakeQuotationController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = NumberFormat('#,##,##0.00', 'en_IN');

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 1,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        title: Text(
          "Make Quotation",
          style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, fontSize: 18),
        ),
      ),
      body: Obx(() {
        // Show a brief loading indicator while fetching the next sequential Quotation Number
        if (controller.isLoadingInitialData.value) {
          return const Center(child: CircularProgressIndicator(color: TColors.primary));
        }

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. CLIENT DETAILS ---
                    _buildSectionTitle("Client Information", Icons.person_outline, isDark),
                    _buildCardContainer(isDark, [
                      // ✅ Locked field for auto-generated Quotation Number
                      _buildTextField(controller.quotationNoCtrl, "Quotation Number", isDark, isReadOnly: true),
                      const SizedBox(height: 12),
                      _buildTextField(controller.clientNameCtrl, "Client Name*", isDark),
                      const SizedBox(height: 12),
                      _buildTextField(controller.clientAddressCtrl, "Client Address", isDark, maxLines: 2),
                      const SizedBox(height: 12),
                      _buildTextField(controller.clientGstCtrl, "GST Number (Optional)", isDark),
                    ]),

                    const SizedBox(height: 24),

                    // --- 2. PRODUCT DETAILS (DYNAMIC LIST) ---
                    _buildSectionTitle("Product Details", Icons.inventory_2_outlined, isDark),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.items.length,
                      itemBuilder: (context, index) {
                        final item = controller.items[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: TColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Item ${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: TColors.primary)),
                                  if (controller.items.length > 1)
                                    GestureDetector(
                                      onTap: () => controller.removeItem(index),
                                      child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                    )
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(item.nameCtrl, "Product Name", isDark),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: _buildTextField(item.priceCtrl, "Unit Price (₹)", isDark, isNumber: true)),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildTextField(item.qtyCtrl, "Quantity", isDark, isNumber: true)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(item.gstCtrl, "GST % (Optional)", isDark, isNumber: true),
                            ],
                          ),
                        );
                      },
                    ),

                    // Add Item Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: controller.addNewItem,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text("Add Another Item"),
                        style: TextButton.styleFrom(foregroundColor: TColors.primary),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- 3. SHIPPING ---
                    _buildSectionTitle("Additional Charges", Icons.local_shipping_outlined, isDark),
                    _buildCardContainer(isDark, [
                      _buildTextField(controller.shippingCtrl, "Shipping Charges (₹)", isDark, isNumber: true),
                    ]),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // --- 4. FLOATING SUMMARY & ACTIONS BOTTOM BAR ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSummaryRow("Sub Total:", "₹${currency.format(controller.subTotal.value)}", isDark),
                  _buildSummaryRow("Total GST:", "+ ₹${currency.format(controller.totalGst.value)}", isDark),
                  _buildSummaryRow("Shipping:", "+ ₹${currency.format(controller.shippingCharge.value)}", isDark),
                  const Divider(height: 16),
                  _buildSummaryRow("TOTAL DUE:", "₹${currency.format(controller.grandTotal.value)}", isDark, isBold: true),
                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Get.snackbar("Share", "Sharing Quotation...");
                          },
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: const Text("Share"),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: TColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: controller.isSaving.value ? null : () => controller.saveAndGenerateQuotation(),
                          icon: controller.isSaving.value ? const SizedBox.shrink() : const Icon(Icons.download_rounded, size: 18),
                          label: controller.isSaving.value
                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text("Save & Download PDF"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  // --- Helpers ---
  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: TColors.primary),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildCardContainer(bool isDark, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(children: children),
    );
  }

  // ✅ Added the isReadOnly parameter here
  Widget _buildTextField(TextEditingController controller, String label, bool isDark, {bool isNumber = false, int maxLines = 1, bool isReadOnly = false}) {
    return TextField(
      controller: controller,
      readOnly: isReadOnly, // This locks the field
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      maxLines: maxLines,
      style: TextStyle(
        color: isReadOnly ? Colors.grey.shade500 : (isDark ? Colors.white : Colors.black87), // Dim the text if it's locked
        fontSize: 14,
        fontWeight: isReadOnly ? FontWeight.bold : FontWeight.normal,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isDark, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.w900 : FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54, fontSize: isBold ? 16 : 14)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.w900 : FontWeight.w700, color: isBold ? TColors.primary : (isDark ? Colors.white : Colors.black87), fontSize: isBold ? 20 : 14)),
        ],
      ),
    );
  }
}