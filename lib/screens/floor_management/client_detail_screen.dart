import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatCurrency = NumberFormat('#,##,##0', 'en_IN');

    // Formatting the Date safely
    String displayDate = "N/A";
    if (client['orderDate'] != null) {
      var date = client['orderDate'];
      displayDate = DateFormat('dd MMM yyyy').format(date is DateTime ? date : date.toDate());
    }

    final String status = (client['status'] ?? "Pending").toString().toUpperCase();
    final Color statusColor = _getStatusColor(status);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),

      // ✅ 1. SLEEK TRANSPARENT APP BAR
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        title: Text(
          "Transaction Details",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 2. PREMIUM STATUS HEADER ---
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: statusColor.withValues(alpha:0.3), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // --- 3. CLIENT IDENTITY CARD ---
            _buildSectionHeader("Client Information", Icons.person_outline_rounded, isDark),
            _buildPremiumCard(isDark, [
              _buildDetailRow(Icons.badge_rounded, "Client Name", client['clientName'] ?? "Unknown", isDark),
              _buildDetailRow(Icons.business_rounded, "Organization", client['organization'] ?? "Individual", isDark),

              // Interactive Phone Row
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _makePhoneCall(client['clientPhone'] ?? "");
                },
                child: Container(
                  color: Colors.transparent, // Captures tap across the whole row
                  child: _buildDetailRow(
                    Icons.phone_rounded,
                    "Phone Number",
                    client['clientPhone'] ?? "N/A",
                    isDark,
                    valueColor: Colors.blueAccent,
                    isAction: true,
                  ),
                ),
              ),
            ]),

            const SizedBox(height: 28),

            // --- 4. ORDER SPECIFICATIONS ---
            _buildSectionHeader("Order Specifications", Icons.inventory_2_outlined, isDark),
            _buildPremiumCard(isDark, [
              _buildDetailRow(Icons.tag_rounded, "Order ID", client['manualOrderNo'] ?? "N/A", isDark, isBold: true),
              _buildDetailRow(Icons.calendar_today_rounded, "Order Date", displayDate, isDark),
              _buildDetailRow(Icons.shopping_bag_rounded, "Product", client['productName'] ?? "N/A", isDark, valueColor: TColors.marketing),
              _buildDetailRow(Icons.layers_rounded, "Quantity", "${client['quantity'] ?? 0} Pcs", isDark),
            ]),

            const SizedBox(height: 28),

            // --- 5. FINANCIAL BREAKDOWN ---
            _buildSectionHeader("Financials", Icons.receipt_long_rounded, isDark),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.green.withValues(alpha:isDark ? 0.3 : 0.5), width: 1.5),
                boxShadow: [
                  if (!isDark) BoxShadow(color: Colors.green.withValues(alpha:0.05), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                children: [
                  _buildFinanceRow("Tax Application", "${client['gstPercentage'] ?? 0}% GST Applied", isDark),
                  const SizedBox(height: 12),
                  _buildDashedDivider(isDark),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("GRAND TOTAL", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.grey, letterSpacing: 0.5)),
                      Text(
                        "₹${formatCurrency.format(client['totalAmount'] ?? 0)}",
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Colors.green),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),

      // --- 6. FLOATING ACTION BOTTOM BAR ---
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFC2185B)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: const Color(0xFFE91E63).withValues(alpha:0.3), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                // Future: Generate PDF or WhatsApp share
              },
              icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
              label: const Text(
                "SHARE SUMMARY",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===================== MODERN HELPERS =====================

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: TColors.marketing.withValues(alpha:0.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: TColors.marketing),
          ),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildPremiumCard(bool isDark, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha:0.05) : Colors.black.withValues(alpha:0.03), width: 1),
        boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withValues(alpha:0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, bool isDark, {Color? valueColor, bool isBold = false, bool isAction = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: Text(label, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13))),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                        fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
                        fontSize: 14,
                        color: valueColor ?? (isDark ? Colors.white : Colors.black87)
                    ),
                  ),
                ),
                if (isAction) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.open_in_new_rounded, size: 14, color: valueColor),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
      ],
    );
  }

  Widget _buildDashedDivider(bool isDark) {
    return Row(
      children: List.generate(
        40,
            (index) => Expanded(
          child: Container(color: index % 2 == 0 ? Colors.transparent : (isDark ? Colors.grey.shade800 : Colors.grey.shade300), height: 1.5),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "approved":
      case "delivered":
        return Colors.green;
      case "pending":
      case "processing":
      case "placed":
        return Colors.orange;
      case "rejected":
      case "cancelled":
        return Colors.redAccent;
      case "dispatched":
      case "shipping":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}