import 'package:flutter/material.dart';
import '../../data/models/order_model.dart';
import 'package:intl/intl.dart';
import '../../utils/constants/colors.dart';

class SalesClientDetailScreen extends StatelessWidget {
  final String clientName;
  final List<OrderModel> orders;

  const SalesClientDetailScreen({
    super.key,
    required this.clientName,
    required this.orders,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: Text(clientName),
        backgroundColor: TColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Full Order History",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ExpansionTile(
                    shape: const RoundedRectangleBorder(side: BorderSide.none),
                    title: Text(
                      "Order: ${order.manualOrderNo ?? 'N/A'}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: TColors.primary,
                      ),
                    ),
                    subtitle: Text(
                      DateFormat(
                        'dd MMM yyyy, hh:mm a',
                      ).format(order.orderDate),
                      style: const TextStyle(fontSize: 12),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _detailRow(
                              "Product Name",
                              order.productName,
                              isDark,
                            ),
                            _detailRow(
                              "Product Code",
                              order.productCode ?? 'N/A',
                              isDark,
                            ),
                            _detailRow(
                              "Quantity",
                              "${order.quantity} Pcs",
                              isDark,
                            ),
                            _detailRow(
                              "Total Amount",
                              "₹${order.totalAmount.toStringAsFixed(2)}",
                              isDark,
                              isBold: true,
                            ),

                            // ✅ FIXED: Using ?? to handle the Nullable String error
                            _detailRow(
                              "Organization",
                              order.organization ?? "N/A",
                              isDark,
                            ),

                            // ✅ Use the null-coalescing operator to provide a default string
                            _detailRow(
                              "Phone",
                              order.clientPhone ?? "No Phone Number",
                              isDark,
                            ),
                            _detailRow(
                              "Status",
                              order.status,
                              isDark,
                              isStatus: true,
                            ),

                            const SizedBox(height: 10),
                            if (order.productName.isNotEmpty)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Details: ${order.productName}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value,
    bool isDark, {
    bool isStatus = false,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: (isStatus || isBold)
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: isStatus
                    ? (value.toLowerCase() == 'approved'
                          ? Colors.green
                          : Colors.orange)
                    : (isDark ? Colors.white : Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
