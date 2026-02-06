import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/sales/sales_manager_controller.dart';
import '../../../data/models/order_model.dart';
import '../../../utils/constants/colors.dart';

class OrderApprovalScreen extends StatelessWidget {
  final OrderModel order;
  const OrderApprovalScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    // Inject the controller
    final controller = Get.put(SalesManagerController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : Colors.grey[50],
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
            _buildDetailCard("Identity Info", [
              _buildRow("Client Name", order.clientName),
              _buildRow("Organization", order.organization ?? "N/A"),
              _buildRow("Phone", order.clientPhone ?? "N/A"),
              const Divider(),
              _buildRow(
                "Sales Associate",
                order.marketingPersonName,
                color: Colors.blue,
              ),
              _buildRow("Order Date", _formatDate(order.orderDate)),
            ], isDark),

            const SizedBox(height: 16),

            // --- 2. PRODUCT & SIZES SECTION ---
            _buildDetailCard("Product Details", [
              _buildRow("Product Name:", order.productName),
              _buildRow("SKU / Code:", order.productCode ?? "N/A"),
              _buildRow("Total Quantity:", "${order.quantity} Pcs"),

              // ✅ NEW: UNIT PRICE ROW
              _buildRow(
                "Unit Price:",
                _calculateUnitPrice(order),
                color: Colors.red,
                isBold: true,
              ),

              const SizedBox(height: 8),
              const Text(
                "Size Breakdown:",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Text(
                  order.sizeDescription?.isNotEmpty == true
                      ? order.sizeDescription!
                      : "No specific size breakdown provided.",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),

              if (order.productDetails?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                const Text(
                  "Special Notes:",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  order.productDetails!,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ], isDark),

            const SizedBox(height: 16),

            // --- 3. FINANCIAL SUMMARY ---
            _buildDetailCard("Financials", [
              _buildRow("GST Percentage", "${order.gstPercentage}%"),
              _buildRow(
                "Shipping Charge",
                "₹${order.shippingCharge.toStringAsFixed(2)}",
              ),
              const Divider(),
              _buildRow(
                "TOTAL AMOUNT",
                "₹${order.totalAmount.toStringAsFixed(2)}",
                color: Colors.green,
                isBold: true,
                size: 18,
              ),
            ], isDark),

            const SizedBox(height: 40),

            // --- 4. ACTION BUTTONS ---
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        _confirmAction(context, "Reject", Colors.red, () {
                          controller.rejectOrder(order.id!);
                          Get.back();
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
                          Get.back();
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
            const SizedBox(height: 20),
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
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  // ✅ FIXED: Using Expanded to prevent Overflow
  Widget _buildRow(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
    double size = 14,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start, // Align to top
        children: [
          // Label
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),

          const SizedBox(width: 16),
          // Value (Wrapped in Expanded)
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: color,
                fontSize: size,
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  // ✅ NEW HELPER: Calculate Unit Price
  String _calculateUnitPrice(OrderModel order) {
    if (order.quantity == 0) return "₹0.00";

    // 1. Remove Shipping
    double amountWithoutShipping = order.totalAmount - order.shippingCharge;

    // 2. Remove GST (Reverse calculation: Total / 1.18 if GST is 18%)
    double gstMultiplier = 1 + (order.gstPercentage / 100);
    double baseTotal = amountWithoutShipping / gstMultiplier;

    // 3. Divide by Quantity
    double unitPrice = baseTotal / order.quantity;

    return "₹${unitPrice.toStringAsFixed(2)}";
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
        Get.back(); // Close dialog
      },
    );
  }
}
