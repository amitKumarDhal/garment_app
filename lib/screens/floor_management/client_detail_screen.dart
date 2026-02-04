import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../utils/constants/colors.dart';

class ClientDetailScreen extends StatelessWidget {
  final Map<String, dynamic> client;
  const ClientDetailScreen({super.key, required this.client});

  // --- Helper for Phone Calls ---
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      }
    } catch (e) {
      debugPrint("Could not launch dialer: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Formatting the Date safely
    String displayDate = "N/A";
    if (client['orderDate'] != null) {
      // If it's a Firestore Timestamp or a DateTime object
      var date = client['orderDate'];
      displayDate = DateFormat(
        'dd MMM yyyy',
      ).format(date is DateTime ? date : date.toDate());
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Order Details"),
        centerTitle: true,
        backgroundColor: TColors.marketing,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- 1. TOP STATUS CARD ---
            _buildInfoCard(
              context,
              "Order Status",
              (client['status'] ?? "Pending").toString().toUpperCase(),
              color: _getStatusColor(client['status'] ?? ""),
            ),
            const SizedBox(height: 16),

            // --- 2. INFORMATION GRID ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Identity Details (Left Side)
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildInfoBox(
                        context,
                        "Client Name",
                        client['clientName'] ?? "Unknown",
                        Icons.person,
                      ),
                      _buildInfoBox(
                        context,
                        "Organization",
                        client['organization'] ?? "Individual",
                        Icons.business,
                      ),

                      // Interactive Phone Box
                      InkWell(
                        onTap: () =>
                            _makePhoneCall(client['clientPhone'] ?? ""),
                        borderRadius: BorderRadius.circular(8),
                        child: _buildInfoBox(
                          context,
                          "Phone (Tap to Call)",
                          client['clientPhone'] ?? "N/A",
                          Icons.phone,
                          color: Colors.green,
                        ),
                      ),

                      _buildInfoBox(
                        context,
                        "Product Details",
                        client['productName'] ?? "N/A",
                        Icons.shopping_bag,
                        color: TColors.marketing,
                      ),
                      _buildInfoBox(
                        context,
                        "GST Info",
                        "${client['gstPercentage']}% Tax Applied",
                        Icons.receipt_long,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Order Specifics (Right Side)
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildInfoBox(
                        context,
                        "Quantity",
                        "${client['quantity']} Pcs",
                        Icons.inventory,
                      ),
                      _buildInfoBox(
                        context,
                        "Grand Total",
                        "₹${client['totalAmount']}",
                        Icons.payments,
                        color: Colors.green,
                      ),
                      _buildInfoBox(
                        context,
                        "Order Date",
                        displayDate,
                        Icons.event,
                        color: Colors.blue,
                      ),
                      _buildInfoBox(
                        context,
                        "Manual No",
                        client['manualOrderNo'] ?? "N/A",
                        Icons.tag,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      // --- 3. BOTTOM ACTION BAR ---
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: () {
            // Future: Generate PDF or WhatsApp share
          },
          icon: const Icon(Icons.share, color: Colors.white),
          label: const Text(
            "SHARE ORDER SUMMARY",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: TColors.marketing,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  // --- HELPER METHODS ---

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "approved":
      case "delivered":
        return Colors.green;
      case "pending":
      case "processing":
        return Colors.orange;
      case "rejected":
      case "cancelled":
        return Colors.red;
      case "dispatched":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoCard(
    BuildContext context,
    String label,
    String value, {
    Color? color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
          ),
        ],
        border: Border(left: BorderSide(color: color ?? Colors.grey, width: 8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color ?? (isDark ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(
    BuildContext context,
    String label,
    dynamic value,
    IconData icon, {
    Color? color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color ?? Colors.grey),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value?.toString() ?? "N/A",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
