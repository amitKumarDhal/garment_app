import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/order_model.dart';
import '../../../utils/constants/colors.dart';

class SalesManagerOrderDetails extends StatefulWidget {
  final OrderModel order;

  const SalesManagerOrderDetails({super.key, required this.order});

  @override
  State<SalesManagerOrderDetails> createState() =>
      _SalesManagerOrderDetailsState();
}

class _SalesManagerOrderDetailsState extends State<SalesManagerOrderDetails> {
  // ✅ Local state variable to hold the latest order data
  late OrderModel currentOrder;

  @override
  void initState() {
    super.initState();
    // Initialize with the data passed from the previous screen
    currentOrder = widget.order;
  }

  // ✅ Logic to Fetch Fresh Data from Firestore
  Future<void> _refreshOrder() async {
    try {
      if (widget.order.id == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.order.id)
          .get();

      if (doc.exists) {
        final updatedOrder = OrderModel.fromSnapshot(doc);
        setState(() {
          currentOrder = updatedOrder;
        });
      }
    } catch (e) {
      Get.snackbar("Error", "Could not refresh order details.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    // ✅ EXTRACT UNIT PRICE SAFELY (Using currentOrder)
    double unitPrice = 0.0;
    if (currentOrder.products.isNotEmpty) {
      unitPrice =
          double.tryParse(currentOrder.products.first['price'].toString()) ??
          0.0;
    }

    // ✅ CALCULATE SUBTOTAL
    double subTotal = unitPrice * currentOrder.quantity;

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : Colors.grey[50],
      appBar: AppBar(
        title: Text("Order #${currentOrder.manualOrderNo ?? '---'}"),
        backgroundColor: _getStatusColor(currentOrder.status),
        foregroundColor: Colors.white,
      ),
      // ✅ WRAP BODY IN REFRESH INDICATOR
      body: RefreshIndicator(
        onRefresh: _refreshOrder,
        color: Colors.white,
        backgroundColor: Colors.blueAccent,
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(), // Ensures pull works even if content is short
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. KEY INFO CARD ---
              _buildSectionTitle("Order Information"),
              _buildCard(isDark, [
                _buildDetailRow(
                  Icons.person,
                  "Sales Associate",
                  currentOrder.marketingPersonName,
                ),
                const Divider(),
                _buildDetailRow(
                  Icons.business,
                  "Client Name",
                  currentOrder.clientName,
                ),
                const Divider(),
                _buildDetailRow(
                  Icons.phone,
                  "Phone",
                  currentOrder.clientPhone ?? "N/A",
                ),
                const Divider(),
                _buildDetailRow(
                  Icons.location_on,
                  "Address",
                  currentOrder.clientAddress ?? "No Address Provided",
                ),
                const Divider(),
                _buildDetailRow(
                  Icons.calendar_today,
                  "Delivery Date",
                  DateFormat('MMM dd, yyyy').format(currentOrder.deliveryDate),
                  color: Colors.redAccent,
                ),
              ]),

              const SizedBox(height: 20),

              // --- 2. PRODUCT DETAILS ---
              _buildSectionTitle("Product Details"),
              _buildCard(isDark, [
                _buildDetailRow(
                  Icons.qr_code,
                  "Product Code",
                  currentOrder.productCode ?? "N/A",
                ),
                const Divider(),
                _buildDetailRow(
                  Icons.description,
                  "Description",
                  currentOrder.productDetails ?? "N/A",
                ),
                const Divider(),
                _buildDetailRow(
                  Icons.straighten,
                  "Size Info",
                  currentOrder.sizeDescription ?? "N/A",
                ),
              ]),

              const SizedBox(height: 20),

              // --- 3. FINANCIAL BREAKDOWN ---
              _buildSectionTitle("Financial Summary"),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildFinanceRow("Unit Price", currency.format(unitPrice)),
                    _buildFinanceRow("Quantity", "x ${currentOrder.quantity}"),
                    const Divider(),
                    _buildFinanceRow("Subtotal", currency.format(subTotal)),
                    _buildFinanceRow(
                      "GST (${currentOrder.gstPercentage.toStringAsFixed(0)}%)",
                      "+ ${currency.format((subTotal * currentOrder.gstPercentage) / 100)}",
                    ),
                    _buildFinanceRow(
                      "Shipping",
                      "+ ${currency.format(currentOrder.shippingCharge)}",
                    ),
                    const Divider(thickness: 1.5),
                    _buildFinanceRow(
                      "Grand Total",
                      currency.format(currentOrder.totalAmount),
                      isBold: true,
                      fontSize: 18,
                    ),
                    const SizedBox(height: 8),
                    _buildFinanceRow(
                      "Less: Advance",
                      "- ${currency.format(currentOrder.advanceAmount)}",
                      color: Colors.green,
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "BALANCE DUE",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: Colors.redAccent,
                          ),
                        ),
                        Text(
                          currency.format(currentOrder.balanceDue),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- 4. ACTION BUTTONS ---
              if (currentOrder.status == 'Pending') ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text(
                          "Reject",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Connect to Controller Approve Logic here
                          Get.back();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          "Approve Order",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.print, color: Colors.white),
                    label: const Text(
                      "Print Invoice",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildCard(bool isDark, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 14,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              color: Colors.grey[600],
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
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
