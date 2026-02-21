import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/sales/sales_manager_history_controller.dart';
import '../../../data/models/order_model.dart';
import '../../../utils/constants/colors.dart';
import 'sales_manager_order_details.dart';

class SalesManagerHistoryScreen extends StatelessWidget {
  const SalesManagerHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SalesManagerHistoryController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Force "All" filter on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.currentFilter.value != "All") {
        controller.filterByStatus("All");
      }
    });

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
          "Master Ledger",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          // --- 1. CLEAN SEARCH & FILTER HEADER ---
          Container(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  onChanged: (val) => controller.searchOrders(val),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: "Search ID, Agent, or Client...",
                    hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black38, fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white70 : TColors.primary, size: 20),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: isDark ? BorderSide.none : BorderSide(color: Colors.black.withValues(alpha:0.05))
                    ),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: TColors.primary, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),

                // Date Button + Status Chips
                Row(
                  children: [
                    // Date Filter Button
                    Obx(() {
                      bool hasDate = controller.selectedDateRange.value != null;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          hasDate ? controller.clearDateFilter() : controller.pickDateRange(context);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: hasDate ? TColors.primary : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: hasDate ? TColors.primary : (isDark ? Colors.white10 : Colors.black.withValues(alpha:0.05))),
                          ),
                          child: Row(
                            children: [
                              Icon(hasDate ? Icons.close_rounded : Icons.calendar_month_rounded, size: 14, color: hasDate ? Colors.white : (isDark ? Colors.white70 : Colors.black54)),
                              if (hasDate) ...[
                                const SizedBox(width: 6),
                                Text(
                                  "${DateFormat('MMM dd').format(controller.selectedDateRange.value!.start)} - ${DateFormat('dd').format(controller.selectedDateRange.value!.end)}",
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ]
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(width: 10),

                    // Scrollable Status Chips
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Obx(
                              () => Row(
                            children: [
                              _buildFilterChip(controller, "All", isDark),
                              _buildFilterChip(controller, "Pending", isDark),
                              _buildFilterChip(controller, "Approved", isDark),
                              _buildFilterChip(controller, "Cutting", isDark),
                              _buildFilterChip(controller, "Stitching", isDark),
                              _buildFilterChip(controller, "Printing", isDark),
                              _buildFilterChip(controller, "Packing", isDark),
                              _buildFilterChip(controller, "Shipping", isDark),
                              _buildFilterChip(controller, "Delivered", isDark),
                              _buildFilterChip(controller, "Rejected", isDark),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- 2. ORDERS LIST ---
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.displayedOrders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black.withValues(alpha:0.05), shape: BoxShape.circle),
                        child: Icon(Icons.search_off_rounded, size: 48, color: isDark ? Colors.white54 : Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Text("No orders match your criteria.", style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 40, top: 0),
                physics: const BouncingScrollPhysics(),
                itemCount: controller.displayedOrders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10), // ✅ Tighter gap between cards
                itemBuilder: (context, index) {
                  final order = controller.displayedOrders[index];
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Get.to(() => SalesManagerOrderDetails(order: order));
                    },
                    child: _buildCompactOrderCard(order, isDark),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildFilterChip(SalesManagerHistoryController controller, String label, bool isDark) {
    bool isSelected = controller.currentFilter.value == label;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        controller.filterByStatus(label);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? TColors.primary : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? TColors.primary : (isDark ? Colors.white10 : Colors.black.withValues(alpha:0.05))),
          boxShadow: isSelected ? [BoxShadow(color: TColors.primary.withValues(alpha:0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // ✅ NEW COMPACT CARD LAYOUT
// ✅ UPGRADED COMPACT CARD WITH PRODUCT SUMMARY
// ✅ UPGRADED COMPACT CARD WITH SMART QTY/PRICE SUMMARY
// ✅ UPGRADED COMPACT CARD (Price Top-Right, Status Bottom-Right, Date Bottom-Left)
  Widget _buildCompactOrderCard(OrderModel order, bool isDark) {
    Color statusColor = _getStatusColor(order.status);

    // ✅ SMART SUMMARY LOGIC
    String productSummary = "No Items";
    String qtyPriceSummary = "";

    if (order.products.isNotEmpty) {
      String firstItem = order.products.first['productName'] ?? "Unknown Item";
      int extraCount = order.products.length - 1;

      if (extraCount > 0) {
        int totalQty = order.products.fold(0, (sum, item) => sum + (int.tryParse(item['qty']?.toString() ?? '0') ?? 0));
        productSummary = "$firstItem + $extraCount more";
        qtyPriceSummary = "$totalQty Total Units";
      } else {
        productSummary = firstItem;
        int qty = int.tryParse(order.products.first['qty']?.toString() ?? '0') ?? 0;
        double price = double.tryParse(order.products.first['price']?.toString() ?? '0') ?? 0.0;
        qtyPriceSummary = "$qty Units × ₹${price.toStringAsFixed(0)}";
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha:0.05) : Colors.black.withValues(alpha:0.03)),
        boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withValues(alpha:0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      // ✅ IntrinsicHeight forces the right column to stretch to the exact height of the left column
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- LEFT SIDE: Order Info ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // ID (Moved Date away from here)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: TColors.primary.withValues(alpha:0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      order.manualOrderNo ?? "NO ID",
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: TColors.primary, letterSpacing: 0.5),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Client Name
                  Text(
                    order.clientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: isDark ? Colors.white : Colors.black87),
                  ),

                  // Product Name Summary
                  const SizedBox(height: 2),
                  Text(
                    productSummary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 12, fontWeight: FontWeight.w600),
                  ),

                  // Smart Qty/Price Summary
                  const SizedBox(height: 2),
                  Text(
                    qtyPriceSummary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: TColors.primary, fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),

                  // Agent
                  Row(
                    children: [
                      Icon(Icons.support_agent_rounded, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          order.marketingPersonName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // ✅ NEW POSITION: Date & Time
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM dd, yyyy • hh:mm a').format(order.orderDate),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // --- RIGHT SIDE: Price & Status ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              // ✅ SpaceBetween locks Price to Top and Status to Bottom
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ✅ Top Right: Price
                Text(
                  "₹${order.totalAmount.toStringAsFixed(0)}",
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.green),
                ),

                // ✅ Bottom Right: Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha:0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha:0.3)),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: TextStyle(fontWeight: FontWeight.w900, color: statusColor, fontSize: 9, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return const Color(0xFF4CAF50);
      case 'cutting': return const Color(0xFF2196F3);
      case 'stitching': return const Color(0xFF3F51B5);
      case 'printing': return const Color(0xFF9C27B0);
      case 'packing': return const Color(0xFFFF9800);
      case 'shipping': return const Color(0xFF009688);
      case 'delivered': return const Color(0xFF1B5E20);
      case 'rejected': return const Color(0xFFF44336);
      case 'pending': return const Color(0xFFFFC107);
      default: return Colors.blueGrey;
    }
  }
}