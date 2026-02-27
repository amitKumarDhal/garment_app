import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../utils/constants/colors.dart';
import '../../../controllers/sales/sales_manager_controller.dart';
import '../../../data/models/order_model.dart';
import 'order_approval_screen.dart';

class SalesManagerApprovals extends StatelessWidget {
  const SalesManagerApprovals({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SalesManagerController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatCurrency = NumberFormat('#,##,##0', 'en_IN');

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),

      // ✅ PREMIUM APP BAR
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        title: Text(
          "Action Required",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
      ),

      body: RefreshIndicator(
        color: TColors.primary,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        onRefresh: () async => controller.fetchPendingOrders(),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator(color: TColors.primary));
          }

          if (controller.pendingOrders.isEmpty) {
            return _buildEmptyState(isDark);
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Tighter vertical padding
            itemCount: controller.pendingOrders.length,
            itemBuilder: (context, index) {
              final order = controller.pendingOrders[index];
              return _buildPremiumApprovalCard(context, order, isDark, formatCurrency);
            },
          );
        }),
      ),
    );
  }

  // ✅ COMPACT PREMIUM ORDER CARD
  Widget _buildPremiumApprovalCard(BuildContext context, OrderModel order, bool isDark, NumberFormat formatCurrency) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Reduced gap between cards
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16), // Slightly tighter border radius
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
          width: 1.5,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Get.to(() => OrderApprovalScreen(order: order)),
          child: Padding(
            padding: const EdgeInsets.all(14), // Reduced internal padding from 16 to 14
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Client Name & Pending Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        order.clientName,
                        style: TextStyle(
                          fontSize: 16, // Slightly smaller
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Tighter badge
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "PENDING",
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 9, // Slightly smaller text
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10), // Tighter gap

                // Middle Row: Product Info & Associate Name
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8), // Smaller icon background
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        size: 18, // Smaller icon
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${order.quantity}x ${order.productName}",
                            style: TextStyle(
                              fontSize: 13, // Slightly smaller
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "By ${order.marketingPersonName}",
                            style: TextStyle(
                              fontSize: 11, // Slightly smaller
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8), // Tighter divider padding
                  child: Divider(height: 1),
                ),

                // Bottom Row: Price & Action Arrow
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total Amount",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                          ),
                        ),
                        Text(
                          "₹${formatCurrency.format(order.totalAmount)}",
                          style: TextStyle(
                            fontSize: 16, // Slightly smaller
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Tighter button
                      decoration: BoxDecoration(
                        color: TColors.cyberYellow.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Text(
                            "Review",
                            style: TextStyle(
                              color: TColors.cyberYellow, // Using the new vibrant color
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 12, color: TColors.cyberYellow),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ PREMIUM EMPTY STATE
  Widget _buildEmptyState(bool isDark) {
    return Stack(
      children: [
        ListView(), // Enables pull-to-refresh even when empty
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.task_alt_rounded,
                  size: 64,
                  color: isDark ? Colors.white30 : Colors.black26,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "You're all caught up!",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "There are no pending orders\nwaiting for your approval.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.black54,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}