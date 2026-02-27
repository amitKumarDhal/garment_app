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
                              _buildFilterChip(controller, "Trash", isDark), // ✅ ADD THIS LINE
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
                separatorBuilder: (_, _) => const SizedBox(height: 10),
// Look for this part in your body:
                itemBuilder: (context, index) {
                  final order = controller.displayedOrders[index];
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Get.to(() => SalesManagerOrderDetails(order: order));
                    },
                    // ✅ CHANGE THIS LINE FROM _buildCompactOrderCard to:
                    child: _buildRedesignedOrderCard(context, order, isDark),
                  );
                },              );
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

  // ✅ UPGRADED COMPACT CARD
  Widget _buildRedesignedOrderCard(BuildContext context, OrderModel order, bool isDark) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final Color statusColor = _getStatusColor(order.status);

    // Compact Math
    final int qty = order.quantity;
    final double unitPrice = qty > 0 ? (order.totalAmount / qty) : 0.0;

    return Container(
      padding: const EdgeInsets.all(12), // Compact padding
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
            width: 1.2
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header: ID & Status ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orange, width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  order.manualOrderNo ?? "---",
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
              Text(
                order.status.toUpperCase(),
                style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // --- Client & Product (Shortened) ---
          Text(
            order.clientName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87),
          ),
          Text(
            order.productName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
          ),
          const SizedBox(height: 6),

          // --- Meta: Associate & Date Time ---
          Row(
            children: [
              Icon(Icons.person, size: 12, color: Colors.grey.shade500),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  order.marketingPersonName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ),
              // ✅ TIME ADDED BACK HERE
              Icon(Icons.access_time_rounded, size: 10, color: Colors.grey.shade500),
              const SizedBox(width: 3),
              Text(
                DateFormat('MMM dd • hh:mm a').format(order.orderDate),
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ],
          ),

          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, thickness: 0.5)),

          // --- Bottom: Units & Total ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$qty × ${currency.format(unitPrice)}",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54),
              ),
              Text(
                currency.format(order.totalAmount),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87),
              ),
            ],
          ),
        ],
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
      case 'delivered': return const Color(0xFF13D421); // ✅ Made much lighter/brighter green
      case 'rejected': return const Color(0xFFF44336);
      case 'pending': return const Color(0xFFFFC107);
      default: return Colors.blueGrey;
    }
  }
}