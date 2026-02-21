import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../data/models/order_model.dart';
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
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    // --- Calculate Client Aggregate Data ---
    double totalRevenue = 0;
    double totalBalanceDue = 0;
    for (var o in orders) {
      totalRevenue += o.totalAmount;
      totalBalanceDue += o.balanceDue;
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: () => Get.back(),
        ),
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        title: Text(
          "Client Portfolio",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: -0.5),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. CLIENT AGGREGATE SUMMARY ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: TColors.primary.withValues(alpha:0.3), width: 1.5),
                boxShadow: [if (!isDark) BoxShadow(color: TColors.primary.withValues(alpha:0.1), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(clientName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone_rounded, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Text(orders.first.clientPhone ?? "No Contact Provided", style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildDashedDivider(isDark),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryMetric("TOTAL ORDERS", orders.length.toString(), isDark),
                      _buildSummaryMetric("LIFETIME REVENUE", currency.format(totalRevenue), isDark, valueColor: Colors.green),
                      _buildSummaryMetric("PENDING DUES", currency.format(totalBalanceDue), isDark, valueColor: Colors.redAccent),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- 2. ORDER HISTORY HEADER ---
            Row(
              children: [
                Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: TColors.primary.withValues(alpha:0.15), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.history_rounded, size: 16, color: TColors.primary)),
                const SizedBox(width: 10),
                Text("Transaction History", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
              ],
            ),
            const SizedBox(height: 16),

            // --- 3. EXPANDABLE ORDER LIST ---
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = orders[index];
                Color statusColor = _getStatusColor(order.status);

                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? Colors.white.withValues(alpha:0.05) : Colors.black.withValues(alpha:0.03)),
                    boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withValues(alpha:0.02), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  // Wrapping ExpansionTile in Theme to remove default borders
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                      iconColor: TColors.primary,
                      collapsedIconColor: Colors.grey.shade400,

                      // --- COLLAPSED VIEW ---
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: TColors.primary.withValues(alpha:0.1), borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              order.manualOrderNo ?? "NO ID",
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: TColors.primary, letterSpacing: 0.5),
                            ),
                          ),
                          Text(
                            currency.format(order.totalAmount),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.green),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat('MMM dd, yyyy').format(order.orderDate), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: statusColor.withValues(alpha:0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: statusColor.withValues(alpha:0.3))),
                              child: Text(order.status.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, color: statusColor, fontSize: 9, letterSpacing: 0.5)),
                            ),
                          ],
                        ),
                      ),

                      // --- EXPANDED DETAILS ---
                      children: [
                        _buildDashedDivider(isDark),
                        const SizedBox(height: 16),

                        // Internal Items List (Handling dynamic products array)
                        ...order.products.map((item) {
                          double iPrice = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
                          int iQty = int.tryParse(item['qty']?.toString() ?? '0') ?? 0;
                          double iTotal = double.tryParse(item['total']?.toString() ?? '0') ?? (iPrice * iQty);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black.withValues(alpha:0.04), borderRadius: BorderRadius.circular(8)),
                                  child: Icon(Icons.inventory_2_outlined, size: 16, color: isDark ? Colors.white70 : Colors.black54),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['productName'] ?? "Unknown Item", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: isDark ? Colors.white : Colors.black87)),
                                      const SizedBox(height: 2),
                                      Text("${item['qty']} Units × ${currency.format(iPrice)}", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                                      if (item['sizeDescription'] != null && item['sizeDescription'].toString().isNotEmpty)
                                        Text("Sizes: ${item['sizeDescription']}", style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                    ],
                                  ),
                                ),
                                Text(currency.format(iTotal), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: isDark ? Colors.white : Colors.black87)),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 8),
                        _buildDashedDivider(isDark),
                        const SizedBox(height: 12),

                        // Financial Footers
                        _buildFinanceRow("Advance Paid", "- ${currency.format(order.advanceAmount)}", isDark, color: Colors.green),
                        const SizedBox(height: 4),
                        _buildFinanceRow("Balance Due", currency.format(order.balanceDue), isDark, color: Colors.redAccent, isBold: true),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildSummaryMetric(String label, String value, bool isDark, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey.shade500, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: valueColor ?? (isDark ? Colors.white : Colors.black87))),
      ],
    );
  }

  Widget _buildFinanceRow(String label, String value, bool isDark, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontWeight: isBold ? FontWeight.bold : FontWeight.w600)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.w900 : FontWeight.w700, color: color ?? (isDark ? Colors.white : Colors.black87))),
      ],
    );
  }

  Widget _buildDashedDivider(bool isDark) {
    return Row(
      children: List.generate(40, (index) => Expanded(child: Container(color: index % 2 == 0 ? Colors.transparent : (isDark ? Colors.grey.shade800 : Colors.grey.shade300), height: 1.5))),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return const Color(0xFF4CAF50);
      case 'cutting': return const Color(0xFF2196F3);
      case 'stitching': return const Color(0xFF3F51B5);
      case 'printing': return const Color(0xFF9C27B0);
      case 'packing': return const Color(0xFFFF9800);
      case 'shipping': return const Color(0xFF009688);
      case 'delivered': return const Color(0xFF1B5E20);
      case 'rejected': return const Color(0xFFF44336);
      case 'pending': return const Color(0xFFFFC107);
      default: return Colors.blueGrey;
    }
  }
}