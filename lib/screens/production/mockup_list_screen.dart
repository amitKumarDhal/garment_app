import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/production/unit_supervisor_controller.dart';
import '../../utils/constants/colors.dart';
import 'mockup_design_screen.dart';

class MockupListScreen extends StatelessWidget {
  const MockupListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = UnitSupervisorController.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleSpacing: 20,
          title: Text(
              "Mockup Designs",
              style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, fontSize: 20)
          ),
          bottom: TabBar(
            indicatorColor: TColors.primary,
            indicatorWeight: 3,
            unselectedLabelColor: Colors.grey.shade500,
            labelColor: TColors.primary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            tabs: const [
              Tab(text: "MockUp Pending"),
              Tab(text: "Mockup Done"),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator(color: TColors.primary));
          }

          return TabBarView(
            children: [
              // 1. PENDING TAB
              _buildOrderList(controller.pendingMockupOrders, isDark, controller, isDoneList: false),
              // 2. DONE TAB
              _buildOrderList(controller.doneMockupOrders, isDark, controller, isDoneList: true),
            ],
          );
        }),
      ),
    );
  }

  // --- Helper to build the ListView ---
  Widget _buildOrderList(List<dynamic> orders, bool isDark, UnitSupervisorController controller, {required bool isDoneList}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isDoneList ? Icons.check_circle_outline : Icons.inbox_outlined, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
                isDoneList ? "No completed mockups yet." : "All mockups are done!",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w600)
            ),
          ],
        ),
      );
    }

    // =========================================================================
    // ✅ SORTING LOGIC: Nearest Deadlines at the top!
    // =========================================================================
    final sortedOrders = List<dynamic>.from(orders);
    sortedOrders.sort((a, b) {
      // Fallback to year 2099 if deadline is missing so it goes to the bottom
      DateTime dateA = a.deliveryDate ?? DateTime(2099);
      DateTime dateB = b.deliveryDate ?? DateTime(2099);

      return dateA.compareTo(dateB); // Ascending order
    });

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: sortedOrders.length, // ✅ Use the sorted list
      itemBuilder: (context, index) {
        final order = sortedOrders[index]; // ✅ Use the sorted list
        return OrderCardForMockup(
          order: order,
          isDark: isDark,
          isDone: isDoneList,
          onCardTap: () => Get.to(() => MockupDesignScreen(order: order, isMockupDone: isDoneList)),
        );
      },
    );
  }
}

// ================= ================= ================= ================= =
// ✅ HELPER WIDGET: THE ORDER CARD
// ================= ================= ================= ================= =
class OrderCardForMockup extends StatelessWidget {
  const OrderCardForMockup({
    super.key,
    required this.order,
    required this.isDark,
    required this.isDone,
    required this.onCardTap,
  });

  final dynamic order;
  final bool isDark;
  final bool isDone;
  final VoidCallback onCardTap;

  @override
  Widget build(BuildContext context) {
    // Format dates safely
    String orderDateStr = order.orderDate != null ? DateFormat('dd MMM yyyy').format(order.orderDate) : 'N/A';
    String deadlineStr = order.deliveryDate != null ? DateFormat('dd MMM yyyy').format(order.deliveryDate) : 'N/A';

    // Extract Current Status
    String currentStatus = order.status ?? "Unknown";

    // Safely get product details and calculate total quantity
    String productDetail = "Unknown Product";
    int calculatedTotalQuantity = 0;

    if (order.products != null && order.products.isNotEmpty) {
      productDetail = order.products[0]['productName'] ?? "Unknown Product";
      if (order.products.length > 1) {
        productDetail += " (+${order.products.length - 1} more)";
      }

      for (var product in order.products) {
        calculatedTotalQuantity += int.tryParse(product['qty']?.toString() ?? '0') ?? 0;
      }
    }

    // =========================================================================
    // ✅ STRICTLY EXTRACT THE "MOCKUP APPROVED BY" NAME
    // =========================================================================
    String? approvedByName;
    try {
      if (order.mockupApprovedBy != null && order.mockupApprovedBy.toString().isNotEmpty) {
        approvedByName = order.mockupApprovedBy;
      }
    } catch (e) {
      // Ignore if the field doesn't exist on older orders
    }

    return GestureDetector(
      onTap: onCardTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ✅ Top Row: Order No & CURRENT STATUS BADGE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: TColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                      "Order: ${order.manualOrderNo ?? order.id}",
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: TColors.primary)
                  ),
                ),

                // STATUS BADGE
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    currentStatus.toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.orange),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Detailed Rows
            _buildDetailRow("Order Date:", orderDateStr, isDark),
            _buildDetailRow("Associate:", order.marketingPersonName ?? "N/A", isDark),
            _buildDetailRow("Deadline:", deadlineStr, isDark, isAlert: true),
            _buildDetailRow("Order details:", productDetail, isDark),
            _buildDetailRow("Quantity:", "$calculatedTotalQuantity pieces", isDark),

            // ✅ STRICTLY SHOW WHO APPROVED IT (Only visible on the 'Done' tab if the name exists)
            if (isDone && approvedByName != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: Divider(height: 1, thickness: 1, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
              ),
              _buildDetailRow("Approved By:", approvedByName, isDark, color: Colors.green, isBold: true),
            ]

          ],
        ),
      ),
    );
  }

  // Helper for the detail rows
  Widget _buildDetailRow(String label, String value, bool isDark, {bool isAlert = false, Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 100,
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey))
          ),
          Expanded(
              child: Text(
                  value,
                  style: TextStyle(
                      fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
                      fontSize: 13,
                      color: color ?? (isAlert ? Colors.redAccent : (isDark ? Colors.white : Colors.black87))
                  )
              )
          ),
        ],
      ),
    );
  }
}