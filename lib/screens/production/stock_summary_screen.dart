// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/production/stock_summary_controller.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/inventory_constants.dart';
import 'stock_detail_screen.dart';

class StockSummaryScreen extends StatelessWidget {
  const StockSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StockSummaryController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        title: Text("Stock Display", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: -0.5)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: isDark ? Colors.white : Colors.black87),
            onPressed: () => controller.fetchInventory(),
            tooltip: "Refresh Stock",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // --- 1. SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: controller.updateSearch,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: "Search fabric or color...",
                prefixIcon: const Icon(Icons.search_rounded, color: TColors.primary),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- 2. CATEGORY CHIPS ---
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: controller.categories.length,
              itemBuilder: (context, index) {
                String cat = controller.categories[index];
                return Obx(() {
                  bool isSelected = controller.selectedCategory.value == cat;
                  return GestureDetector(
                    onTap: () => controller.updateCategory(cat),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? TColors.primary : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? TColors.primary : (isDark ? Colors.white10 : Colors.black12)),
                      ),
                      child: Center(
                        child: Text(cat, style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87), fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  );
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          // --- 3. DYNAMIC GRADIENT CARDS ---
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
              if (controller.groupedStock.isEmpty) return const Center(child: Text("No stock found."));

              return RefreshIndicator(
                onRefresh: () async => controller.fetchInventory(),
                color: TColors.primary,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: controller.groupedStock.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    var group = controller.groupedStock[index];
                    List colorsList = group['colorsList'];
                    String prodName = group['product'].toString().toLowerCase();

                    bool isPcs = prodName.contains('collar') || prodName.contains('rib') || prodName == 'others';
                    String unit = isPcs ? "pcs" : "kg";

                    Map<String, dynamic>? latestLog;
                    for (var c in colorsList) {
                      if (c['history'] != null && c['history'].isNotEmpty) {
                        var log = c['history'].first;
                        if (latestLog == null || (log['date'] as DateTime).isAfter(latestLog['date'] as DateTime)) {
                          latestLog = log;
                        }
                      }
                    }

                    bool isLatestIn = latestLog?['type'] == 'IN';
                    Color actionColor = latestLog == null ? TColors.primary : (isLatestIn ? Colors.green : Colors.redAccent);

                    String dateStr = latestLog != null ? DateFormat('dd MMM, hh:mm a').format(latestLog['date']) : '';
                    String latestUpdater = latestLog?['supervisorName'] ?? "Unknown";

                    return GestureDetector(
                      onTap: () => Get.to(() => StockDetailScreen(groupData: group, unit: unit, isDark: isDark)),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [
                              actionColor.withValues(alpha: isDark ? 0.15 : 0.08),
                              isDark ? const Color(0xFF1E1E1E) : Colors.white
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: actionColor.withValues(alpha: 0.3), width: 1.5),
                          boxShadow: [
                            if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: actionColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      isPcs ? Icons.checkroom_rounded : Icons.layers_rounded,
                                      color: actionColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      group['title'],
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: -0.5),
                                    ),
                                  ),

                                  if (latestLog != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: actionColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(isLatestIn ? Icons.arrow_downward : Icons.arrow_upward, size: 12, color: actionColor),
                                          const SizedBox(width: 4),
                                          Text(
                                              "${latestLog['qty']} $unit",
                                              style: TextStyle(fontWeight: FontWeight.w900, color: actionColor, fontSize: 12)
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            SizedBox(
                              height: 42,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                physics: const BouncingScrollPhysics(),
                                itemCount: colorsList.length,
                                itemBuilder: (context, cIndex) {
                                  var c = colorsList[cIndex];
                                  String styleLabel = "";
                                  if (c['history'] != null && c['history'].isNotEmpty) {
                                    String style = c['history'].first['style'] ?? 'N/A';
                                    if (style != 'N/A') styleLabel = " - $style";
                                  }

                                  return Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.black26 : Colors.white60,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.circle, size: 10, color: _getColorObj(c['color'])),
                                        const SizedBox(width: 8),
                                        Text(
                                          "${c['color']}$styleLabel: ",
                                          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w600, fontSize: 12),
                                        ),
                                        Text(
                                          "${c['balance']} $unit",
                                          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),

                            // --- ❌ FIX: FOOTER SECTION (Wrapped in Expanded/Flexible to prevent overflow) ---
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.02),
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "CURRENT BALANCE",
                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isDark ? Colors.white54 : Colors.black45, letterSpacing: 0.5),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "${group['totalGroupQty']} $unit",
                                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isDark ? Colors.white : Colors.black87),
                                      ),
                                    ],
                                  ),
                                  if (latestLog != null)
                                  // ✅ Expanded prevents the Row from taking too much horizontal space
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Icon(Icons.history_rounded, size: 12, color: actionColor),
                                              const SizedBox(width: 4),
                                              Text("Last updated", style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54, fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "$dateStr • $latestUpdater",
                                            maxLines: 1, // ✅ Forces single line
                                            overflow: TextOverflow.ellipsis, // ✅ Adds '...' for long names
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isDark ? Colors.white70 : Colors.black87),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Color _getColorObj(String colorName) {
    String cleanColorName = colorName.split(' (').first;
    return Color(InventoryConstants.getHexForColor(cleanColorName));
  }
}