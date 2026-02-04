import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:yoobbel/screens/floor_management/marketing_upload_screen.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/sizes.dart';
import '../../controllers/sales/sales_history_controller.dart';
import '../../controllers/floor_management/marketing_upload_controller.dart';
import '../../data/models/order_model.dart';

class SalesOrderHistoryScreen extends StatelessWidget {
  const SalesOrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SalesHistoryController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : TColors.light,
      appBar: AppBar(
        title: const Text("Order History"),
        centerTitle: true,
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- 1. SEARCH & FILTERS HEADER ---
          Container(
            padding: const EdgeInsets.all(TSizes.md),
            color: isDark ? Colors.black12 : Colors.white,
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => controller.searchOrders(val),
                  decoration: InputDecoration(
                    hintText: "Search Client, Agent, or ID...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(controller, "All"),
                        const SizedBox(width: 8),
                        _buildFilterChip(controller, "Pending"),
                        const SizedBox(width: 8),
                        _buildFilterChip(controller, "Approved"),
                        const SizedBox(width: 8),
                        _buildFilterChip(controller, "Rejected"),
                      ],
                    ),
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
                      Icon(Icons.history, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        "No orders found",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(TSizes.md),
                itemCount: controller.displayedOrders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
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

  Widget _buildFilterChip(SalesHistoryController controller, String label) {
    bool isSelected = controller.currentFilter.value == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) controller.filterByStatus(label);
      },
      selectedColor: Colors.purple,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      backgroundColor: Colors.grey[200],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    OrderModel order,
    bool isDark,
  ) {
    return InkWell(
      onTap: () => _showOrderDetails(context, order, isDark),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.manualOrderNo ?? "No ID",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                Text(
                  DateFormat('dd-MM-yyyy').format(order.orderDate),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  order.clientName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  "₹${order.totalAmount.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    // ✅ Changed: Shows Unit Price instead of Product Name
                    "${order.quantity} Pcs • ₹${_calculateUnitPrice(order)} / pc",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(order.status),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetails(BuildContext context, OrderModel order, bool isDark) {
    final bool isLocked = order.status.toLowerCase() == 'approved';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Order Summary",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (!isLocked)
                    IconButton(
                      onPressed: () => _confirmDelete(context, order),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                    )
                  else
                    const Icon(
                      Icons.lock_outline,
                      color: Colors.grey,
                      size: 20,
                    ),
                ],
              ),
              const Divider(),

              _modalRow("Order Number", order.manualOrderNo ?? "N/A"),
              _modalRow("Client Name", order.clientName),
              _modalRow("Organization", order.organization ?? "Individual"),
              _modalRow("Phone", order.clientPhone ?? "N/A"),
              _modalRow("Agent", order.marketingPersonName),

              const SizedBox(height: 15),
              const Text(
                "Product Specs",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              const Divider(),
              // ✅ UNIT PRICE: Using the reverse calculation helper
              _modalRow("Unit Price", "₹${_calculateUnitPrice(order)}"),
              _modalRow("Product Code", order.productCode ?? "N/A"),
              _modalRow("Quantity", "${order.quantity} Pcs"),
              _modalRow("Description", order.productDetails ?? "No notes"),

              const SizedBox(height: 15),
              const Text(
                "Payment & Status",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const Divider(),
              _modalRow("Tax Percentage", "${order.gstPercentage}%"),
              _modalRow(
                "Grand Total",
                "₹${order.totalAmount.toStringAsFixed(2)}",
                isBold: true,
              ),
              _modalRow("Status", order.status.toUpperCase(), isStatus: true),

              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isLocked
                          ? null
                          : () {
                              Navigator.pop(context);
                              final uploadController = Get.put(
                                MarketingUploadController(),
                              );
                              uploadController.loadOrderData(order);
                              Get.to(() => const MarketingUploadScreen());
                            },
                      icon: Icon(isLocked ? Icons.lock : Icons.edit, size: 18),
                      label: Text(isLocked ? "Locked" : "Edit Order"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isLocked ? Colors.grey : Colors.blue,
                        side: BorderSide(
                          color: isLocked ? Colors.grey : Colors.blue,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        "Close",
                        style: TextStyle(color: Colors.white),
                      ),
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
      middleText: "This action cannot be undone.",
      textConfirm: "Delete",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.find<SalesHistoryController>().deleteOrder(order);
        Navigator.pop(context);
        Navigator.pop(context);
      },
    );
  }

  Widget _modalRow(
    String label,
    String value, {
    bool isStatus = false,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: (isBold || isStatus)
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontSize: 14,
                color: isStatus ? _getStatusColor(value) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  // ✅ HELPER: Reverses the total calculation to show the base Unit Price
  String _calculateUnitPrice(OrderModel order) {
    try {
      if (order.quantity <= 0) return "0.00";
      // Formula: Base Total = Grand Total / (1 + (GST% / 100))
      double baseTotal = order.totalAmount / (1 + (order.gstPercentage / 100));
      // Unit Price = Base Total / Quantity
      double unitPrice = baseTotal / order.quantity;
      return unitPrice.toStringAsFixed(2);
    } catch (e) {
      return "0.00";
    }
  }
}
