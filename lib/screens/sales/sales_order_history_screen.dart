import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/floor_management/marketing_upload_controller.dart';
import '../../utils/constants/colors.dart';
import '../../controllers/sales/sales_history_controller.dart';
import '../../data/models/order_model.dart';
// ✅ IMPORT THE REUSABLE UPLOAD SCREEN FOR EDITING
import '../floor_management/marketing_upload_screen.dart';

class SalesOrderHistoryScreen extends StatelessWidget {
  const SalesOrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SalesHistoryController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
        elevation: 0,
        centerTitle: false,
        titleSpacing: 24,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        title: Text(
          "My Ledger",
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
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            decoration: BoxDecoration(color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9)),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  onChanged: (val) => controller.searchOrders(val),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: "Search ID or Client...",
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

                // Scrollable Status Chips
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
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
                        child: Icon(Icons.receipt_long_rounded, size: 48, color: isDark ? Colors.white54 : Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Text("No orders found.", style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                // ✅ 120px padding ensures bottom cards clear the Floating Glass Dock!
                padding: const EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 120),
                physics: const BouncingScrollPhysics(),
                itemCount: controller.displayedOrders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final order = controller.displayedOrders[index];
                  return _buildHistoryCard(context, order, isDark);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildFilterChip(SalesHistoryController controller, String label, bool isDark) {
    return Obx(() {
      bool isSelected = controller.currentFilter.value == label;
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          controller.filterByStatus(label);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? TColors.primary : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? TColors.primary : (isDark ? Colors.white10 : Colors.black.withValues(alpha:0.05))),
            boxShadow: isSelected ? [BoxShadow(color: TColors.primary.withValues(alpha:0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
          ),
          child: Center(
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
        ),
      );
    });
  }

  // ✅ UPGRADED EXECUTIVE CARD (Matches Manager Ledger)
  Widget _buildHistoryCard(BuildContext context, OrderModel order, bool isDark) {
    Color statusColor = _getStatusColor(order.status);

    // Smart Summary Logic
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

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showOrderDetails(context, order, isDark);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha:0.05) : Colors.black.withValues(alpha:0.03)),
          boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withValues(alpha:0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: TColors.primary.withValues(alpha:0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(order.manualOrderNo ?? "NO ID", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: TColors.primary, letterSpacing: 0.5)),
                    ),
                    const SizedBox(height: 8),
                    Text(order.clientName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 2),
                    Text(productSummary, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(qtyPriceSummary, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: TColors.primary, fontSize: 11, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(DateFormat('MMM dd, yyyy').format(order.orderDate), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // --- RIGHT SIDE: Price & Status ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("₹${order.totalAmount.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.green)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withValues(alpha:0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: statusColor.withValues(alpha:0.3))),
                    child: Text(order.status.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, color: statusColor, fontSize: 9, letterSpacing: 0.5)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ PREMIUM BOTTOM SHEET (Itemized Details)
// ✅ PREMIUM BOTTOM SHEET (Itemized Details)
  void _showOrderDetails(BuildContext context, OrderModel order, bool isDark) {
    // 🔒 SECURITY FIX: Added 'shipping' to the locked list
    final lockedStatuses = ['shipping', 'shipped', 'delivered', 'rejected'];

    // Check if the current status is in the locked list
    final bool isLocked = lockedStatuses.contains(order.status.toLowerCase());

    // Safety lock for deleting (only allowed in early stages)
    final bool canDelete = ['pending', 'placed'].contains(order.status.toLowerCase());

    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 24),

              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Ledger Details", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: -0.5)),
                  if (canDelete)
                    IconButton(
                      onPressed: () => _confirmDelete(context, order),
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      tooltip: "Delete Order",
                    )
                  else
                    Tooltip(message: "Cannot delete active/completed orders", child: Icon(Icons.lock_outline_rounded, color: Colors.grey.shade400, size: 20)),
                ],
              ),
              const SizedBox(height: 16),

              // ROOT DETAILS
              _modalRow("Order Number", order.manualOrderNo ?? "N/A", isDark, isBold: true, valueColor: TColors.primary),
              _modalRow("Client Name", order.clientName, isDark, isBold: true),
              _modalRow("Organization", order.organization ?? "N/A", isDark),
              _modalRow("Phone", order.clientPhone ?? "N/A", isDark),
              _modalRow("Deadline", DateFormat('MMM dd, yyyy').format(order.deliveryDate), isDark),
              _modalRow("Status", order.status.toUpperCase(), isDark, isStatus: true),

              const SizedBox(height: 24),
              Text("ITEMIZED PRODUCTS", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey.shade500, fontSize: 11, letterSpacing: 1)),
              const SizedBox(height: 12),

              // DYNAMIC PRODUCTS LIST
              ...order.products.map((item) {
                double iPrice = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
                int iQty = int.tryParse(item['qty']?.toString() ?? '0') ?? 0;
                double iTotal = double.tryParse(item['total']?.toString() ?? '0') ?? (iPrice * iQty);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black.withValues(alpha:0.03), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 16, color: isDark ? Colors.white70 : Colors.black54),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['productName'] ?? "Unknown", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: isDark ? Colors.white : Colors.black87)),
                            const SizedBox(height: 2),
                            Text("${item['qty']} Units × ${currency.format(iPrice)}", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                      Text(currency.format(iTotal), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: isDark ? Colors.white : Colors.black87)),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),
              Text("FINANCIAL SUMMARY", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey.shade500, fontSize: 11, letterSpacing: 1)),
              const SizedBox(height: 12),

              _modalRow("Shipping Charge", currency.format(order.shippingCharge), isDark),
              _modalRow("Advance Paid", "- ${currency.format(order.advanceAmount)}", isDark, valueColor: Colors.green),
              _modalRow("Grand Total", currency.format(order.totalAmount), isDark, isBold: true),
              const SizedBox(height: 8),
              _modalRow("Balance Due", currency.format(order.balanceDue), isDark, isBold: true, valueColor: Colors.redAccent),

              const SizedBox(height: 32),

              // ACTION BUTTONS
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isLocked
                          ? null
                          : () async {
                        Navigator.pop(context); // 1. Close the bottom sheet

                        // ✅ CRITICAL FIX TO PREVENT CRASH: Destroy old form memory
                        Get.delete<MarketingUploadController>();

                        // 2. Go to the Edit screen and WAIT until the user comes back
                        await Get.to(() => MarketingUploadScreen(existingOrder: order));

                        // 3. Refresh the history screen when we get back
                        Get.find<SalesHistoryController>().fetchHistory();
                      },
                      icon: Icon(isLocked ? Icons.lock_outline_rounded : Icons.edit_rounded, size: 18),
                      label: Text(isLocked ? "Locked" : "Edit Order", style: const TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isLocked ? Colors.grey : TColors.primary,
                        side: BorderSide(color: isLocked ? Colors.grey.shade300 : TColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white24 : Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text("Close", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  void _confirmDelete(BuildContext context, OrderModel order) {
    Get.defaultDialog(
      title: "Delete Order?",
      titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      middleText: "This action cannot be undone.",
      textConfirm: "Delete",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      cancelTextColor: Colors.black87,
      onConfirm: () {
        Get.find<SalesHistoryController>().deleteOrder(order);
        Navigator.pop(context);
        Navigator.pop(context);
      },
    );
  }

  Widget _modalRow(String label, String value, bool isDark, {bool isStatus = false, bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: (isBold || isStatus) ? FontWeight.w900 : FontWeight.w700,
                fontSize: 14,
                color: isStatus ? _getStatusColor(value) : (valueColor ?? (isDark ? Colors.white : Colors.black87)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return const Color(0xFF4CAF50);
      case 'cutting': return const Color(0xFF2196F3);
      case 'stitching': return const Color(0xFF3F51B5);
      case 'printing': return const Color(0xFF9C27B0);
      case 'packing': return const Color(0xFFFF9800);
      case 'shipping': return const Color(0xFF009688);
      case 'delivered': return const Color(0xFF13D421);
      case 'rejected': return const Color(0xFFF44336);
      case 'pending': return const Color(0xFFFFC107);
      case 'placed': return const Color(0xFFFFC107);
      default: return Colors.blueGrey;
    }
  }
}