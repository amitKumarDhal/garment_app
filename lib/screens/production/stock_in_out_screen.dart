import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/production/stock_in_out_controller.dart';
import '../../utils/constants/colors.dart';

class StockInOutScreen extends StatelessWidget {
  const StockInOutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StockInOutController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text("Stock Update", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: -0.5)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. STOCK ACTION ---
            _buildLabel("1. Stock Action", isDark),
            Obx(() => _buildDropdown(
              value: controller.selectedTransactionType.value,
              hint: "Select Action",
              items: controller.transactionTypes,
              isDark: isDark,
              onChanged: (val) {
                controller.selectedTransactionType.value = val ?? 'Stock In';
                controller.vendorController.clear();
              },
            )),
            const SizedBox(height: 20),

            // --- 2. PRODUCT ---
            _buildLabel("2. Product", isDark),
            Obx(() => _buildDropdown(
              value: controller.selectedProduct.value.isEmpty ? null : controller.selectedProduct.value,
              hint: "Select Product",
              items: controller.products,
              isDark: isDark,
              onChanged: (val) {
                controller.selectedProduct.value = val ?? '';
                controller.resetFields();
              },
            )),
            const SizedBox(height: 24),

            // --- 3. DYNAMIC FORM (FABRIC vs COLLAR&RIB) ---
            Obx(() {
              String product = controller.selectedProduct.value.toLowerCase();
              if (product.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // --- COLLAR & RIB FLOW ---
                  if (controller.isPcs) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.blueGrey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: TColors.primary.withValues(alpha: 0.3), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.checkroom_rounded, color: TColors.primary, size: 18),
                              const SizedBox(width: 8),
                              Text("Collar Details", style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ✅ NEW: Collar Style Dropdown
                          _buildLabel("Style", isDark),
                          _buildDropdown(
                            value: controller.selectedCollarStyle.value,
                            hint: "Select Style",
                            items: controller.collarStyles,
                            isDark: isDark,
                            onChanged: (val) => controller.selectedCollarStyle.value = val ?? 'Solid color',
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildColorDropdown(
                                  value: controller.selectedColor.value.isEmpty ? null : controller.selectedColor.value,
                                  hint: "Color",
                                  items: controller.allColors,
                                  isDark: isDark,
                                  onChanged: (val) => controller.selectedColor.value = val ?? '',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: _buildTextField("Qty (pcs)", isDark, controller: controller.qtyController, isNumber: true),
                              ),
                            ],
                          ),

                          _buildBalanceCard(controller, isDark),

                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),

                          if (!controller.hasRib.value)
                            OutlinedButton.icon(
                              onPressed: () => controller.hasRib.value = true,
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text("Add Rib", style: TextStyle(fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: TColors.primary,
                                side: const BorderSide(color: TColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            )
                          else ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildLabel("+ Rib Details", isDark),
                                GestureDetector(
                                  onTap: () {
                                    controller.hasRib.value = false;
                                    controller.ribQtyController.clear();
                                    controller.selectedRibColor.value = '';
                                    controller.selectedRibStyle.value = 'Solid color';
                                  },
                                  child: const Text("Remove", style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),

                            // ✅ NEW: Rib Style Dropdown
                            _buildLabel("Style", isDark),
                            _buildDropdown(
                              value: controller.selectedRibStyle.value,
                              hint: "Select Style",
                              items: controller.collarStyles,
                              isDark: isDark,
                              onChanged: (val) => controller.selectedRibStyle.value = val ?? 'Solid color',
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _buildColorDropdown(
                                    value: controller.selectedRibColor.value.isEmpty ? null : controller.selectedRibColor.value,
                                    hint: "Color",
                                    items: controller.allColors,
                                    isDark: isDark,
                                    onChanged: (val) => controller.selectedRibColor.value = val ?? '',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: _buildTextField("Qty (pcs)", isDark, controller: controller.ribQtyController, isNumber: true),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ]

                  // --- STANDARD FABRIC FLOW ---
                  else ...[
                    _buildLabel("3. Color", isDark),
                    // ✅ NEW: Unified Custom Color Dropdown
                    _buildColorDropdown(
                      value: controller.selectedColor.value.isEmpty ? null : controller.selectedColor.value,
                      hint: "Choose Color",
                      items: controller.allColors,
                      isDark: isDark,
                      onChanged: (val) => controller.selectedColor.value = val ?? '',
                    ),

                    _buildBalanceCard(controller, isDark),
                    const SizedBox(height: 8),

                    _buildLabel("4. Quantity (KG)", isDark),
                    _buildTextField("Qty (KG)", isDark, controller: controller.qtyController, isNumber: true),
                  ],

                  // --- UNIVERSAL FIELDS (Vendor & Date) ---
                  if (controller.selectedTransactionType.value == 'Stock In') ...[
                    const SizedBox(height: 20),
                    _buildLabel("Vendor Name", isDark),
                    _buildTextField("Enter vendor name", isDark, controller: controller.vendorController),
                  ],
                  const SizedBox(height: 20),

                  _buildLabel("Date", isDark),
                  _buildDateSelector(controller, context, isDark),
                ],
              );
            }),

            const SizedBox(height: 40),

            // --- SUBMIT BUTTON ---
            Obx(() => SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: controller.isLoading.value ? null : () => controller.submitStock(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: controller.selectedTransactionType.value == 'Stock In' ? Colors.green : Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: controller.isLoading.value
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("SUBMIT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
              ),
            )),

            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 24),

            // --- RECENT ACTIVITY FEED ---
            Text("Recent Activity Feed", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 16),
            _buildRecentActivity(controller, isDark),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- UI Helpers ---

  // ✅ NEW: Advanced Custom Color Dropdown Builder
  Widget _buildColorDropdown({
    required String? value,
    required String hint,
    required List<Map<String, dynamic>> items,
    required bool isDark,
    required Function(String?) onChanged
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.white,
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(hint, style: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : Colors.black45)),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? Colors.white54 : Colors.black54),
          dropdownColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          items: items.map((colorMap) {
            bool isReg = colorMap['isRegular'];
            return DropdownMenuItem<String>(
              value: colorMap['name'],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  // Highlight Regular colors slightly
                  color: isReg ? Colors.blue.withValues(alpha: 0.05) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // The Color Dot
                    Container(
                      width: 16, height: 16,
                      decoration: BoxDecoration(
                        color: Color(colorMap['hex']),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade400, width: 1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Color Name
                    Expanded(
                      child: Text(
                        colorMap['name'],
                        style: TextStyle(
                          fontWeight: isReg ? FontWeight.bold : FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Regular Badge
                    if (isReg)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text("Regular", style: TextStyle(fontSize: 9, color: TColors.primary, fontWeight: FontWeight.bold)),
                      )
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildRecentActivity(StockInOutController controller, bool isDark) {
    return Obx(() {
      if (controller.recentHistory.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text("No recent activity found.", style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.w600)),
          ),
        );
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.recentHistory.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          var log = controller.recentHistory[index];
          bool isIn = log['type'] == 'IN';
          Color actionColor = isIn ? Colors.green : Colors.redAccent;

          String product = log['product'] ?? '';
          String colorName = log['color'] ?? '';
          String style = log['style'] != null && log['style'] != 'N/A' ? " (${log['style']})" : "";
          double qty = (log['qty'] as num?)?.toDouble() ?? 0.0;
          String unit = log['unit'] ?? '';
          String supervisor = log['supervisorName'] ?? 'Unknown';

          DateTime date = DateTime.now();
          if (log['timestamp'] != null) {
            date = (log['timestamp'] as Timestamp).toDate();
          } else if (log['date'] != null) {
            date = (log['date'] as Timestamp).toDate();
          }
          String dateStr = DateFormat('dd MMM, hh:mm a').format(date);

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: actionColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(isIn ? Icons.arrow_downward : Icons.arrow_upward, color: actionColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Showing color, product, and style (if collar)
                      Text("$colorName $product$style", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
                      const SizedBox(height: 4),
                      Text("$dateStr • $supervisor", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white54 : Colors.black54)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("${isIn ? '+' : '-'}$qty $unit", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: actionColor)),
                  ],
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildBalanceCard(StockInOutController controller, bool isDark) {
    return Obx(() {
      if (controller.selectedColor.value.isEmpty) return const SizedBox.shrink();

      bool inStock = controller.currentBalance.value > 0;
      Color cardColor = inStock ? Colors.green : Colors.orange;

      return Container(
        margin: const EdgeInsets.only(top: 16, bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardColor.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2_rounded, color: cardColor, size: 20),
                const SizedBox(width: 8),
                Text("Available Balance", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? Colors.white70 : Colors.black87)),
              ],
            ),
            controller.isFetchingBalance.value
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(
              "${controller.currentBalance.value} ${controller.isPcs ? 'pcs' : 'kg'}",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: cardColor),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLabel(String text, bool isDark) => Padding(
    padding: const EdgeInsets.only(bottom: 6, left: 2),
    child: Text(text, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
  );

  Widget _buildDropdown({required String? value, required String hint, required List<String> items, required bool isDark, required Function(String?) onChanged}) => InputDecorator(
    decoration: InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      filled: true, fillColor: isDark ? Colors.black26 : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TColors.primary, width: 1.5)),
    ),
    isEmpty: value == null || value.isEmpty,
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        hint: Text(hint, style: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : Colors.black45)),
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? Colors.white54 : Colors.black54),
        dropdownColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14, fontWeight: FontWeight.w700),
        items: items.map((String item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
      ),
    ),
  );

  Widget _buildTextField(String hint, bool isDark, {TextEditingController? controller, bool isNumber = false}) => TextField(
    controller: controller,
    keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w700),
    decoration: InputDecoration(
      hintText: hint, hintStyle: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : Colors.black45),
      filled: true, fillColor: isDark ? Colors.black26 : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TColors.primary, width: 1.5)),
    ),
  );

  Widget _buildDateSelector(StockInOutController controller, BuildContext context, bool isDark) => GestureDetector(
    onTap: () => controller.pickDate(context),
    child: Container(
      height: 52, padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded, size: 20, color: TColors.primary),
          const SizedBox(width: 12),
          Obx(() => Text(DateFormat('dd MMM yyyy').format(controller.selectedDate.value), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87))),
        ],
      ),
    ),
  );
}