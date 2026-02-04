import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/constants/colors.dart';
import '../../../controllers/sales/sales_manager_controller.dart';
import 'order_approval_screen.dart';

class SalesManagerApprovals extends StatelessWidget {
  const SalesManagerApprovals({super.key});

  @override
  Widget build(BuildContext context) {
    // Finding the existing controller
    final controller = Get.put(SalesManagerController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : TColors.light,
      appBar: AppBar(
        title: const Text("Pending Approvals"),
        centerTitle: true,
        backgroundColor: TColors.marketing,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => controller.fetchPendingOrders(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => controller.fetchPendingOrders(),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.pendingOrders.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.pendingOrders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = controller.pendingOrders[index];

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  onTap: () => Get.to(() => OrderApprovalScreen(order: order)),
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.withOpacity(0.1),
                    child: const Icon(
                      Icons.pending_actions,
                      color: Colors.orange,
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
                      Text("Agent: ${order.marketingPersonName}"),
                      Text(
                        "Amount: ₹${order.totalAmount}",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Stack(
      children: [
        ListView(), // Enables pull-to-refresh even when empty
        const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.done_all, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                "No pending approvals",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
