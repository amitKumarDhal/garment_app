import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/sales/sales_manager_controller.dart';
import '../../../data/models/order_model.dart';

class OrderApprovalScreen extends StatelessWidget {
  final OrderModel order; // Received from the list screen
  const OrderApprovalScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    // Access the manager controller logic
    final controller = Get.find<SalesManagerController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify Order"),
        centerTitle: true,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- 1. CLIENT & AGENT SECTION ---
            _buildDetailCard("Identity", [
              _buildRow("Client", order.clientName),
              _buildRow("Organization", order.organization ?? "Individual"),
              _buildRow("Associate", order.marketingPersonName),
            ], isDark),

            const SizedBox(height: 16),

            // --- 2. PRODUCT SECTION ---
            _buildDetailCard("Order Specifics", [
              _buildRow("Product", order.productName),
              _buildRow("Quantity", "${order.quantity} Pcs"),
              _buildRow(
                "Total Amount",
                "₹${order.totalAmount}",
                color: Colors.green,
              ),
              _buildRow("Manual No.", order.manualOrderNo ?? "N/A"),
            ], isDark),

            const SizedBox(height: 40),

            // --- 3. ACTION BUTTONS ---
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        _confirmAction(context, "Reject", Colors.red, () {
                          controller.rejectOrder(order.id!);
                          Get.back(); // Close this screen after rejection
                        }),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "REJECT",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        _confirmAction(context, "Approve", Colors.green, () {
                          controller.approveOrder(order.id!);
                          Get.back(); // Close this screen after approval
                        }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "APPROVE",
                      style: TextStyle(fontWeight: FontWeight.bold),
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

  // --- UI HELPERS ---

  Widget _buildDetailCard(String title, List<Widget> children, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const Divider(),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  void _confirmAction(
    BuildContext context,
    String action,
    Color color,
    VoidCallback onConfirm,
  ) {
    Get.defaultDialog(
      title: "$action Order?",
      middleText: "Are you sure you want to $action this transaction?",
      textConfirm: "Confirm",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: color,
      onConfirm: () {
        onConfirm();
        Get.back(); // Closes the dialog
      },
    );
  }
}
