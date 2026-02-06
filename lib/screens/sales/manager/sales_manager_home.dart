import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/sales/sales_manager_controller.dart';
import '../../../utils/constants/colors.dart';
import '../../../data/models/order_model.dart';
import 'order_approval_screen.dart';
import 'sales_manager_history_screen.dart';
import 'sales_manager_approvals.dart';

class SalesManagerHome extends StatelessWidget {
  const SalesManagerHome({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SalesManagerController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Dashboard",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Obx(
              () => Text(
                DateFormat('MMMM yyyy').format(controller.selectedMonth.value),
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _pickMonth(context, controller),
            icon: const Icon(Icons.calendar_month),
          ),
          IconButton(
            onPressed: () => controller.fetchAllData(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => controller.fetchAllData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. STATS ROW ---
              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => _buildStatCard(
                        context,
                        "Revenue (${DateFormat('MMM').format(controller.selectedMonth.value)})",
                        "₹${(controller.totalRevenue.value / 100000).toStringAsFixed(2)}L",
                        Colors.green,
                        Icons.currency_rupee_rounded,
                        onTap: () {},
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Pending Requests (Redirects to Approvals)
                  Expanded(
                    child: Obx(
                      () => _buildStatCard(
                        context,
                        "Pending Requests",
                        controller.pendingOrders.length.toString(),
                        Colors.orange,
                        Icons.pending_actions,
                        onTap: () =>
                            Get.to(() => const SalesManagerApprovals()),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // History Link
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Get.to(
                    () => const SalesManagerHistoryScreen(),
                    arguments: "Approved",
                  ),
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text("View Approved History"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: isDark ? Colors.white10 : Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // --- 2. PENDING PREVIEW (First 3 Items) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Requires Action",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () =>
                        Get.to(() => const SalesManagerApprovals()),
                    child: const Text("See All"),
                  ),
                ],
              ),

              Obx(() {
                if (controller.pendingOrders.isEmpty) {
                  return _buildEmptyState(
                    isDark,
                    "No pending orders",
                    Icons.check_circle_outline,
                  );
                }

                // Show only the first 3 on the dashboard
                var previewList = controller.pendingOrders.take(3).toList();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: previewList.length,
                  itemBuilder: (context, index) {
                    final order = previewList[index];
                    // ✅ Calling the updated widget at the bottom
                    return _buildPendingOrderCard(context, order, isDark);
                  },
                );
              }),

              const SizedBox(height: 24),

              // --- 3. TOP Associates ---
              Obx(
                () => Text(
                  "Top Associates (${DateFormat('MMMM').format(controller.selectedMonth.value)})",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Obx(() {
                if (controller.topAgents.isEmpty) {
                  return _buildEmptyState(
                    isDark,
                    "No data for selected month",
                    Icons.analytics_outlined,
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.topAgents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final agent = controller.topAgents[index];
                    return _buildAgentRow(
                      index + 1,
                      agent['name'],
                      agent['formatted'],
                      isDark,
                    );
                  },
                );
              }),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS ---

  // ✅ UPDATED: Now calculates and shows Unit Price
  Widget _buildPendingOrderCard(
    BuildContext context,
    OrderModel order,
    bool isDark,
  ) {
    // 1. Calculate Unit Price Logic
    String unitPriceDisplay = "₹0.00";
    if (order.quantity > 0) {
      double amountWithoutShipping = order.totalAmount - order.shippingCharge;
      double gstMultiplier = 1 + (order.gstPercentage / 100);
      double baseTotal = amountWithoutShipping / gstMultiplier;
      double unitPrice = baseTotal / order.quantity;
      unitPriceDisplay = "₹${unitPrice.toStringAsFixed(2)}";
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        onTap: () => Get.to(() => OrderApprovalScreen(order: order)),
        leading: CircleAvatar(
          backgroundColor: Colors.orange.withOpacity(0.1),
          child: const Icon(
            Icons.priority_high,
            color: Colors.orange,
            size: 20,
          ),
        ),
        title: Text(
          order.clientName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(order.productName),
            const SizedBox(height: 2),
            // ✅ SHOW QUANTITY & UNIT PRICE
            Text(
              "${order.quantity} pcs @ $unitPriceDisplay/unit",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              "Total: ₹${order.totalAmount.toStringAsFixed(2)}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    Color color,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentRow(int rank, String name, String amount, bool isDark) {
    Color badgeColor = rank == 1
        ? const Color(0xFFFFD700)
        : (rank == 2
              ? const Color(0xFFC0C0C0)
              : (rank == 3 ? const Color(0xFFCD7F32) : Colors.grey[200]!));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                "#$rank",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? Colors.white : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Future<void> _pickMonth(
    BuildContext context,
    SalesManagerController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedMonth.value,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      helpText: "SELECT MONTH",
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          primaryColor: Colors.purple,
          colorScheme: const ColorScheme.light(primary: Colors.purple),
        ),
        child: child!,
      ),
    );
    if (picked != null) controller.changeMonth(picked);
  }
}
