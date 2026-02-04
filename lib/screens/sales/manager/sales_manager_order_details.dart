import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/order_model.dart';
import '../../../utils/constants/colors.dart';

class SalesManagerOrderDetails extends StatelessWidget {
  final OrderModel order;

  const SalesManagerOrderDetails({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : Colors.grey[50],
      appBar: AppBar(
        title: Text("Order #${order.manualOrderNo ?? '---'}"),
        backgroundColor: _getStatusColor(order.status),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. HEADER CARD (Status & Agent) ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    Icons.person,
                    "Agent",
                    order.marketingPersonName,
                  ),
                  const Divider(),
                  _buildDetailRow(Icons.business, "Client", order.clientName),
                  const Divider(),
                  _buildDetailRow(
                    Icons.calendar_today,
                    "Date",
                    DateFormat(
                      'MMM dd, yyyy - hh:mm a',
                    ).format(order.orderDate),
                  ),
                  const Divider(),
                  _buildDetailRow(
                    Icons.info_outline,
                    "Status",
                    order.status.toUpperCase(),
                    color: _getStatusColor(order.status),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              "Product List",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // --- 2. PRODUCT LIST ---
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: order.products.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final product = order.products[index];
                  // Handle dynamic types safely
                  final qty = product['qty'] ?? 0;
                  final price = product['price'] ?? 0.0; // ✅ Now used below
                  final total = product['total'] ?? 0.0;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${qty}x",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ),
                    title: Text(
                      product['productName'] ?? 'Unknown Item',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    // ✅ ADDED: Subtitle showing the Unit Rate
                    subtitle: Text(
                      "Rate: ₹$price",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    trailing: Text(
                      "₹$total",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // --- 3. TOTALS SECTION ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getStatusColor(order.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getStatusColor(order.status).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Grand Total",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(order.status),
                    ),
                  ),
                  Text(
                    "₹${order.totalAmount.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(order.status),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- 4. ACTION BUTTONS (PDF) ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Get.snackbar(
                    "Coming Soon",
                    "PDF Invoice generation will be added next!",
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                label: const Text(
                  "Download Invoice",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: color,
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
}
