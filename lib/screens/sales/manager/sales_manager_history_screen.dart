import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/sales/sales_manager_history_controller.dart';
import '../../../data/models/order_model.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import 'sales_manager_order_details.dart'; // ✅ Import the Details Screen

class SalesManagerHistoryScreen extends StatelessWidget {
  const SalesManagerHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SalesManagerHistoryController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : Colors.grey[50],
      appBar: AppBar(
        title: const Text("All Orders History"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- 1. SEARCH & FILTER HEADER ---
          Container(
            padding: const EdgeInsets.all(TSizes.md),
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  onChanged: (val) => controller.searchOrders(val),
                  decoration: InputDecoration(
                    hintText: "Search Agent, Client, or Order ID...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: isDark ? Colors.black : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
                const SizedBox(height: 12),

                // Date Button + Status Chips Row
                Row(
                  children: [
                    // A. Date Filter Button
                    Obx(() {
                      bool hasDate = controller.selectedDateRange.value != null;
                      return OutlinedButton.icon(
                        onPressed: () {
                          if (hasDate) {
                            controller.clearDateFilter();
                          } else {
                            controller.pickDateRange(context);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: hasDate
                              ? Colors.purple.withValues(alpha: 0.1)
                              : null,
                          side: BorderSide(
                            color: hasDate ? Colors.purple : Colors.grey[400]!,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        icon: Icon(
                          hasDate ? Icons.close : Icons.calendar_today,
                          size: 16,
                          color: hasDate ? Colors.purple : Colors.grey[600],
                        ),
                        label: Text(
                          hasDate
                              ? "${DateFormat('MMM dd').format(controller.selectedDateRange.value!.start)} - ${DateFormat('MMM dd').format(controller.selectedDateRange.value!.end)}"
                              : "Date",
                          style: TextStyle(
                            fontSize: 12,
                            color: hasDate ? Colors.purple : Colors.black,
                          ),
                        ),
                      );
                    }),

                    const SizedBox(width: 10),

                    // B. Status Chips (Scrollable)
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Obx(
                          () => Row(
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
                      Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        "No orders found for this selection",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: controller.displayedOrders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final order = controller.displayedOrders[index];

                  // ✅ CLICKABLE CARD WRAPPER
                  return GestureDetector(
                    onTap: () =>
                        Get.to(() => SalesManagerOrderDetails(order: order)),
                    child: _buildOrderCard(order, isDark),
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

  Widget _buildFilterChip(
    SalesManagerHistoryController controller,
    String label,
  ) {
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

  Widget _buildOrderCard(OrderModel order, bool isDark) {
    Color statusColor = _getStatusColor(order.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
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
                DateFormat('MMM dd, yyyy').format(order.orderDate),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.clientName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          Text(
            "Agent: ${order.marketingPersonName}",
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Total Amount",
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.status.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
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
}
