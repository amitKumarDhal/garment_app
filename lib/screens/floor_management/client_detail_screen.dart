import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Import for phone calls
import '../../utils/constants/colors.dart';

class ClientDetailScreen extends StatelessWidget {
  final Map<String, dynamic> client;
  const ClientDetailScreen({super.key, required this.client});

  // Helper for Phone Calls
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    // final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Order Details"),
        backgroundColor: TColors.marketing,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Top Status Summary
            _buildInfoCard(
              context,
              "Order Status",
              client['status'] ?? "Unknown",
              color: _getStatusColor(client['status'] ?? ""),
            ),
            const SizedBox(height: 16),

            // Information Grid
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Identity Details
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildInfoBox(
                        context,
                        "Client Name",
                        client['name'],
                        Icons.person,
                      ),
                      _buildInfoBox(
                        context,
                        "Organization",
                        client['org'],
                        Icons.business,
                      ),

                      // --- UPDATED: INTERACTIVE PHONE BOX ---
                      InkWell(
                        onTap: () => _makePhoneCall(client['phone'] ?? ""),
                        child: _buildInfoBox(
                          context,
                          "Phone (Tap to Call)",
                          client['phone'],
                          Icons.phone,
                          color: Colors.green,
                        ),
                      ),

                      _buildInfoBox(
                        context,
                        "Address",
                        client['address'],
                        Icons.location_on,
                      ),
                      _buildInfoBox(
                        context,
                        "GST Info",
                        client['gst'],
                        Icons.receipt_long,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Order Specifics
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildInfoBox(
                        context,
                        "Quantity",
                        "${client['qty']} units",
                        Icons.inventory,
                      ),
                      _buildInfoBox(
                        context,
                        "Order Value",
                        client['value'],
                        Icons.payments,
                      ),
                      _buildInfoBox(
                        context,
                        "Target Date",
                        client['targetDate'],
                        Icons.event,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      // --- ADDED: BOTTOM ACTION BAR ---
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: () {
            // Placeholder for future feature
          },
          icon: const Icon(Icons.download, color: Colors.white),
          label: const Text(
            "DOWNLOAD ORDER SLIP",
            style: TextStyle(color: Colors.white),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case "Delivered":
        return Colors.green;
      case "Processing":
        return Colors.orange;
      case "Cancelled":
        return Colors.red;
      case "Dispatched":
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
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
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
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
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
