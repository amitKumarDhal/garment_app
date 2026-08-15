// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/admin/inventory_controller.dart';
import '../../utils/constants/colors.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(InventoryController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
        elevation: 0,
        centerTitle: false,
        titleSpacing: 24,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: () => Get.back(),
        ),
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        title: Text(
          "Master Inventory",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
      ),

      // FAB for Transactions
      floatingActionButton: Obx(() {
        final role = controller.currentUserRole.value;
        if (role.contains('Supervisor') || role == 'Admin' || role == 'SM') {
          return FloatingActionButton.extended(
            onPressed: () {
              HapticFeedback.lightImpact();
              _showTransactionSheet(context, controller, isDark);
            },
            backgroundColor: TColors.primary,
            elevation: 4,
            icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
            label: const Text("New Entry", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          );
        }
        return const SizedBox.shrink();
      }),

      body: Column(
        children: [
          // Header (Search + Tabs)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            decoration: BoxDecoration(color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9)),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  onChanged: controller.updateSearch,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Search Fabric or Color...",
                    hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black38, fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white70 : TColors.primary, size: 20),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: TColors.primary, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
                const SizedBox(height: 16),

                // Custom Segmented Control
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildTabButton("Stock", Icons.inventory_2_rounded, controller, isDark)),
                      Expanded(child: _buildTabButton("Ledger", Icons.receipt_long_rounded, controller, isDark)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Content Area
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: TColors.primary));
              }

              if (controller.currentView.value == 'Stock') {
                return _buildStockView(controller, isDark);
              } else {
                return _buildLedgerView(controller, isDark);
              }
            }),
          ),
        ],
      ),
    );
  }

  // --- VIEWS ---

  Widget _buildStockView(InventoryController controller, bool isDark) {
    final list = controller.filteredStock;

    if (list.isEmpty) {
      return RefreshIndicator(
        color: TColors.primary,
        onRefresh: () => controller.fetchInventoryData(showSpinner: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: Get.height * 0.2),
            _buildEmptyState(isDark, "No stock found."),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: TColors.primary,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      onRefresh: () => controller.fetchInventoryData(showSpinner: false),
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index];

          // 🛡️ SAFE EXTRACTION to prevent "null" strings
          final String fabricType = item['fabricType']?.toString() ?? 'Unknown';
          final String color = item['color']?.toString() ?? 'Unknown';
          final double qty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
          final String unit = (item['unit']?.toString() ?? 'KG').toUpperCase();

          final bool isKG = unit == 'KG';
          final bool isLowStock = (isKG && qty < 50.0) || (!isKG && qty < 100.0);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isLowStock ? Colors.redAccent.withValues(alpha: 0.4) : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05))),
              boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isLowStock ? Colors.redAccent.withValues(alpha: 0.1) : TColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.texture_rounded, color: isLowStock ? Colors.redAccent : TColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fabricType, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
                      const SizedBox(height: 2),
                      Text("Color: $color", style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${qty.toStringAsFixed(isKG ? 1 : 0)} $unit",
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isLowStock ? Colors.redAccent : (isDark ? Colors.white : Colors.black87)),
                    ),
                    if (isLowStock)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(4)),
                        child: const Text("LOW STOCK", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                      )
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLedgerView(InventoryController controller, bool isDark) {
    final list = controller.filteredLogs;

    if (list.isEmpty) {
      return RefreshIndicator(
        color: TColors.primary,
        onRefresh: () => controller.fetchInventoryData(showSpinner: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: Get.height * 0.2),
            _buildEmptyState(isDark, "No transactions found."),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: TColors.primary,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      onRefresh: () => controller.fetchInventoryData(showSpinner: false),
      child: ListView.separated(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        itemCount: list.length,
        separatorBuilder: (_, _) => Divider(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05), height: 1),
        itemBuilder: (context, index) {
          final log = list[index];

          // 🛡️ SAFE EXTRACTION to prevent "null" strings
          final String fabricType = log['fabricType']?.toString() ?? 'Unknown';
          final String color = log['color']?.toString() ?? 'Unknown';
          final String addedBy = log['addedBy']?.toString() ?? 'System';
          final double qty = (log['quantity'] as num?)?.toDouble() ?? 0.0;
          final String unit = (log['unit']?.toString() ?? 'units').toLowerCase();

          final bool isIN = log['action'] == 'IN';
          final Color actColor = isIN ? Colors.green : Colors.orange;

          DateTime date = DateTime.now();
          if (log['timestamp'] != null) {
            date = log['timestamp'] is String
                ? (DateTime.tryParse(log['timestamp'].toString()) ?? DateTime.now())
                : (log['timestamp'] is DateTime ? log['timestamp'] as DateTime : DateTime.now());
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: actColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Icon(isIN ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: actColor, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("$fabricType • $color", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
                      const SizedBox(height: 2),
                      Text("By $addedBy on ${DateFormat('MMM dd, hh:mm a').format(date)}", style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                Text(
                  "${isIN ? '+' : '-'}${qty.toStringAsFixed(unit == 'kg' ? 1 : 0)} $unit",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: actColor),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- BOTTOM SHEET FORM ---

  void _showTransactionSheet(BuildContext context, InventoryController controller, bool isDark) {
    String selectedType = controller.fabricTypes.first;
    String selectedColor = controller.colors.first;
    String selectedAction = 'IN';
    final qtyCtrl = TextEditingController();

    Get.bottomSheet(
      StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("New Transaction", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 24),

                    // Action Toggle (IN / OUT)
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() => selectedAction = 'IN');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                  color: selectedAction == 'IN' ? Colors.green : (isDark ? Colors.white10 : Colors.grey.shade100),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: selectedAction == 'IN' ? Colors.green : Colors.transparent)
                              ),
                              alignment: Alignment.center,
                              child: Text("INWARD (Add)", style: TextStyle(color: selectedAction == 'IN' ? Colors.white : Colors.grey.shade500, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() => selectedAction = 'OUT');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                  color: selectedAction == 'OUT' ? Colors.orange : (isDark ? Colors.white10 : Colors.grey.shade100),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: selectedAction == 'OUT' ? Colors.orange : Colors.transparent)
                              ),
                              alignment: Alignment.center,
                              child: Text("OUTWARD (Consume)", style: TextStyle(color: selectedAction == 'OUT' ? Colors.white : Colors.grey.shade500, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Fabric Type Dropdown
                    Text("Fabric Type", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade300)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedType,
                          isExpanded: true,
                          dropdownColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                          items: controller.fabricTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: TextStyle(color: isDark ? Colors.white : Colors.black87)))).toList(),
                          onChanged: (val) => setState(() => selectedType = val!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Color Dropdown
                    Text("Color", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade300)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedColor,
                          isExpanded: true,
                          dropdownColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                          items: controller.colors.map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: isDark ? Colors.white : Colors.black87)))).toList(),
                          onChanged: (val) => setState(() => selectedColor = val!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quantity Field
                    Text("Quantity (${selectedType.contains('Collar') || selectedType.contains('Cuff') ? 'PCS' : 'KG'})", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: qtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? Colors.white10 : Colors.grey.shade50,
                        hintText: "Enter amount...",
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.transparent : Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TColors.primary, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          if (qtyCtrl.text.isEmpty) {
                            Get.snackbar("Error", "Please enter a quantity.", backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red);
                            return;
                          }
                          controller.addTransaction(
                            type: selectedType,
                            color: selectedColor,
                            action: selectedAction,
                            quantity: double.tryParse(qtyCtrl.text) ?? 0.0,
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: TColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text("Save Transaction", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          }
      ),
      isScrollControlled: true,
    );
  }

  // --- SMALL HELPERS ---

  Widget _buildTabButton(String title, IconData icon, InventoryController controller, bool isDark) {
    return Obx(() {
      bool isSelected = controller.currentView.value == title;
      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          controller.setView(title);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? (isDark ? const Color(0xFF2C2C2E) : Colors.white) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected && !isDark ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? (isDark ? Colors.white : Colors.black87) : Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? (isDark ? Colors.white : Colors.black87) : Colors.grey.shade500,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildEmptyState(bool isDark, String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: isDark ? Colors.white24 : Colors.black12),
          const SizedBox(height: 16),
          Text(msg, style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}