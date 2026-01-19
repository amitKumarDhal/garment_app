import 'package:flutter/material.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/sizes.dart';

class OrderSummaryScreen extends StatelessWidget {
  final Map<String, dynamic> orderData; // Pass data from the list or controller
  const OrderSummaryScreen({super.key, required this.orderData});

  @override
  Widget build(BuildContext context) {
    // final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Order: ${orderData['orderNo']}"),
        backgroundColor: TColors.marketing,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.md),
        child: Column(
          children: [
            _buildInfoCard(context, "Client Identity", [
              _buildDetailRow("Client Name", orderData['clientName']),
              _buildDetailRow("Organization", orderData['org']),
              _buildDetailRow("Contact", orderData['phone']),
            ]),
            const SizedBox(height: TSizes.md),
            _buildInfoCard(context, "Order Details", [
              _buildDetailRow("Product", orderData['details']),
              _buildDetailRow("Quantity", "${orderData['qty']} Pcs"),
              _buildDetailRow("Total Value", "₹${orderData['value']}"),
              _buildDetailRow("GST Applied", orderData['gst']),
              _buildDetailRow(
                "Target Date",
                orderData['deadline'],
                isHighlight: true,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: TColors.marketing, width: 5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: TColors.marketing,
            ),
          ),
          const Divider(),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String? value, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value ?? "N/A",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isHighlight ? Colors.redAccent : null,
            ),
          ),
        ],
      ),
    );
  }
}
