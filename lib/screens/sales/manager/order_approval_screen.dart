// ignore_for_file: curly_braces_in_flow_control_structures, unused_element

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:yoobbel/controllers/sales/sales_manager_controller.dart';
import '../../../data/models/order_model.dart';
import '../../../data/services/api_service.dart';
import '../../../utils/constants/colors.dart';

class OrderApprovalScreen extends StatefulWidget {
  final OrderModel order;
  const OrderApprovalScreen({super.key, required this.order});

  @override
  State<OrderApprovalScreen> createState() => _OrderApprovalScreenState();
}

class _OrderApprovalScreenState extends State<OrderApprovalScreen> {
  late final SalesManagerController controller;

  // State Variables
  late String currentStatus;
  late double localAdvanceAmount;
  late double localBalanceDue;
  bool isProcessingPayment = false;

  late final NumberFormat _currency;
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    controller = Get.find<SalesManagerController>();

    currentStatus = widget.order.status;
    localAdvanceAmount = widget.order.advanceAmount;
    localBalanceDue = widget.order.balanceDue;

    _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          "Order Verification",
          style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: textColor),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _StatusHeader(order: order, currentStatus: currentStatus),
              const SizedBox(height: 24),

              // --- 0. DESIGN MOCKUP ---
              _MockupCard(order: order, isDark: isDark, textColor: textColor),

              // --- 1. IDENTITY & LOGISTICS INFO ---
              _ModernCard(
                title: "Identity & Logistics",
                icon: Icons.badge_outlined,
                isDark: isDark,
                textColor: textColor,
                children: [
                  _InfoRow(Icons.person_outline, "Client Name", order.clientName, subTextColor, textColor),
                  _InfoRow(Icons.business, "Organization", order.organization ?? "N/A", subTextColor, textColor),
                  _InfoRow(Icons.phone_outlined, "Phone", order.clientPhone ?? "N/A", subTextColor, textColor),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, thickness: 0.5, color: subTextColor.withValues(alpha: 0.3)),
                  ),

                  // ✅ LOCATION, STATE, AND PINCODE DISPLAYED HERE
                  _InfoRow(Icons.location_on_outlined, "Address", order.clientAddress ?? "N/A", subTextColor, textColor, isMultiLine: true),
                  _InfoRow(Icons.map_outlined, "State", order.state ?? "N/A", subTextColor, textColor),
                  _InfoRow(Icons.pin_drop_outlined, "PIN Code", order.pincode ?? "N/A", subTextColor, textColor, isBold: true, customValueColor: TColors.primary),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, thickness: 0.5, color: subTextColor.withValues(alpha: 0.3)),
                  ),

                  _InfoRow(Icons.support_agent, "Sales Associate", order.marketingPersonName, subTextColor, textColor, highlight: true),
                  _InfoRow(Icons.event_note, "Order Date", _formatDate(order.orderDate), subTextColor, textColor),
                  _InfoRow(
                    Icons.calendar_month_outlined, "Delivery Deadline",
                    _formatDate(order.deliveryDate), subTextColor, textColor,
                    isBold: true, customValueColor: Colors.redAccent,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- 2. MULTI-ITEM PRODUCT SPECIFICATIONS (WITH SIZES) ---
              _ProductSpecsCard(
                order: order,
                isDark: isDark,
                textColor: textColor,
                subTextColor: subTextColor,
                currency: _currency,
              ),
              const SizedBox(height: 20),

              // --- 3. FINANCIAL BREAKDOWN ---
              _ModernCard(
                title: "Financial Breakdown",
                icon: Icons.receipt_long,
                isDark: isDark,
                textColor: textColor,
                children: [
                  _FinanceRow("GST Percentage", "${order.gstPercentage.toStringAsFixed(1)}%", subTextColor, textColor),
                  _FinanceRow("Shipping Charges", _currency.format(order.shippingCharge), subTextColor, textColor),
                  const Divider(height: 24),
                  _FinanceRow("Grand Total", _currency.format(order.totalAmount), subTextColor, textColor, isTotal: true),
                  const SizedBox(height: 8),
                  _FinanceRow("Less: Advance", "- ${_currency.format(localAdvanceAmount)}", subTextColor, textColor, customValueColor: Colors.green),
                  const SizedBox(height: 16),
                  _BalanceDueBox(balanceDue: localBalanceDue, currency: _currency),
                ],
              ),

              const SizedBox(height: 16),
              _buildActionArea(
                context: context,
                isDark: isDark,
                hasPendingPayments: false,
                isCheckingPayments: false,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionArea({
    required BuildContext context,
    required bool isDark,
    required bool hasPendingPayments,
    required bool isCheckingPayments,
  }) {
    final String statusCheck = currentStatus.toLowerCase();

    // Show buttons ONLY if status is Placed or Pending
    if (statusCheck == 'placed' || statusCheck == 'pending') {
      return Column(
        children: [
          if (hasPendingPayments)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                "⚠️ Resolve pending payments to unlock order approval.",
                style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _confirmAction(context, "Reject", Colors.red, () async {
                      // ✅ OPTIMISTIC UPDATE: Change UI instantly
                      if (mounted) {
                        setState(() => currentStatus = 'Rejected');
                      }
                      await controller.rejectOrder(widget.order.id!);
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    side: const BorderSide(color: Colors.redAccent, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("REJECT", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: (hasPendingPayments || isCheckingPayments) ? null : () {
                    HapticFeedback.lightImpact();
                    _confirmAction(context, "Approve", Colors.green, () async {
                      // ✅ OPTIMISTIC UPDATE: Change UI instantly
                      if (mounted) {
                        setState(() => currentStatus = 'Approved');
                      }
                      await controller.approveOrderWithMargin(widget.order.id!, 0.0, widget.order.totalAmount);
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    disabledBackgroundColor: isDark ? Colors.white10 : Colors.grey.shade300,
                    disabledForegroundColor: isDark ? Colors.white30 : Colors.grey.shade500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: (hasPendingPayments || isCheckingPayments) ? 0 : 4,
                    shadowColor: Colors.green.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: isCheckingPayments
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("APPROVE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ],
      );
    }

    final bool isRejected = statusCheck == 'rejected';
    final Color themeColor = isRejected ? Colors.red : Colors.green;

    // ✅ ONCE UPDATED, THE BUTTONS VANISH AND THIS BEAUTIFUL BANNER APPEARS
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : themeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColor.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Text(
          "Order is currently ${currentStatus.toUpperCase()}",
          style: TextStyle(
            color: isDark ? (isRejected ? Colors.redAccent : Colors.greenAccent) : themeColor,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  // --- ACTIONS ---

  Future<void> _approvePaymentRequest(
      String requestId,
      double amount,
      String orderId,
      Map<String, dynamic> requestData,
      ) async {
    setState(() => isProcessingPayment = true);
    try {
      final res = await ApiService.post('/payments/$requestId/approve', {});
      if (res['success'] == true) {
        if (mounted) {
          setState(() {
            isProcessingPayment = false;
          });
        }
        Get.snackbar("Payment Approved", "Payment request approved cleanly", backgroundColor: Colors.green, colorText: Colors.white);
      }
    } catch (e) {
      if (mounted) setState(() => isProcessingPayment = false);
      Get.snackbar("Error", "Could not approve payment: $e", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _rejectPaymentRequest(String requestId) async {
    try {
      await ApiService.put('/payments/$requestId/reject', {});
      Get.snackbar("Payment Rejected", "The payment request has been dismissed.", backgroundColor: Colors.orange, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Could not reject payment: $e", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  String _formatDate(DateTime date) => _dateFormat.format(date);

  // ✅ PERFECTED CONFIRM ACTION
  void _confirmAction(BuildContext context, String action, Color color, Future<void> Function() onConfirm) {
    Get.defaultDialog(
      title: "$action Order",
      titleStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
      middleText: "Are you sure you want to $action this transaction?",
      barrierDismissible: false,
      confirm: ElevatedButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          Get.back(); // 1. Pop the dialog immediately

          // 2. Add a tiny delay so the dialog fully finishes its exit animation
          // before we aggressively swap the buttons for the "Approved" banner.
          Future.delayed(const Duration(milliseconds: 150), () {
            onConfirm(); // 3. Fire the optimistic update & background sync!
          });
        },
        style: ElevatedButton.styleFrom(backgroundColor: color),
        child: const Text("Confirm", style: TextStyle(color: Colors.white)),
      ),
      cancel: OutlinedButton(
        onPressed: () => Get.back(),
        child: const Text("Cancel"),
      ),
      radius: 12,
    );
  }
}

class _MockupCard extends StatelessWidget {
  final OrderModel order;
  final bool isDark;
  final Color textColor;

  const _MockupCard({required this.order, required this.isDark, required this.textColor});

  @override
  Widget build(BuildContext context) {
    if (order.mockupUrl == null || order.mockupUrl!.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        _ModernCard(
          title: "Design Mockup",
          icon: Icons.palette_outlined,
          isDark: isDark,
          textColor: textColor,
          children: [
            GestureDetector(
              onTap: () => _showFullScreenImage(order.mockupUrl!, order.manualOrderNo ?? "Unknown"),
              child: Container(
                width: double.infinity,
                height: 220,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: isDark ? Colors.black38 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                ),
                child: CachedNetworkImage(
                  imageUrl: order.mockupUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: TColors.primary)),
                  errorWidget: (context, url, error) => const Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                "Tap image to view full screen & download",
                style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _StatusHeader extends StatelessWidget {
  final OrderModel order;
  final String currentStatus;

  const _StatusHeader({required this.order, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.deepOrangeAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Order #${order.manualOrderNo ?? '---'}",
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  currentStatus.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Created on ${DateFormat('dd/MM/yyyy').format(order.orderDate)}",
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ModernCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;
  final Color textColor;
  final List<Widget> children;

  const _ModernCard({
    required this.title,
    required this.icon,
    required this.isDark,
    required this.textColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 20, color: TColors.primary),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
          ]),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Color labelColor;
  final Color valueColor;
  final bool isBold;
  final bool highlight;
  final bool isMultiLine;
  final Color? customValueColor;

  const _InfoRow(
      this.icon, this.label, this.value, this.labelColor, this.valueColor, {
        this.isBold = false,
        this.highlight = false,
        this.isMultiLine = false,
        this.customValueColor,
      });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: Text(label, style: TextStyle(color: labelColor, fontSize: 13))),
          Expanded(
            flex: 4,
            child: Text(
              value ?? "N/A",
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: isBold || highlight ? FontWeight.bold : FontWeight.w500,
                color: customValueColor ?? (highlight ? Colors.blue : valueColor),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;
  final bool isTotal;
  final Color? customValueColor;

  const _FinanceRow(
      this.label, this.value, this.labelColor, this.valueColor, {
        this.isTotal = false,
        this.customValueColor,
      });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isTotal ? valueColor : labelColor,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: customValueColor ?? valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceDueBox extends StatelessWidget {
  final double balanceDue;
  final NumberFormat currency;

  const _BalanceDueBox({required this.balanceDue, required this.currency});

  @override
  Widget build(BuildContext context) {
    final bool isPaid = balanceDue <= 0;
    final Color color = isPaid ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: isPaid ? 0.3 : 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isPaid ? "FULLY PAID" : "BALANCE DUE",
            style: TextStyle(color: color, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          Text(
            currency.format(balanceDue),
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 20),
          ),
        ],
      ),
    );
  }
}

class _ProductSpecsCard extends StatelessWidget {
  final OrderModel order;
  final bool isDark;
  final Color textColor;
  final Color subTextColor;
  final NumberFormat currency;

  const _ProductSpecsCard({
    required this.order,
    required this.isDark,
    required this.textColor,
    required this.subTextColor,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return _ModernCard(
      title: "Product Specifications (${order.products.length} Items)",
      icon: Icons.inventory_2_outlined,
      isDark: isDark,
      textColor: textColor,
      children: [
        for (final item in order.products) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name & Total Qty
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item['productName'] ?? "Unknown Item",
                        style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${item['qty'] ?? 0} Units",
                        style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blue, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Granular Attributes
                _buildProductDetailRow("SKU / Code", item['productCode'] ?? 'N/A'),
                _buildProductDetailRow("Product Type", item['productType'] ?? 'N/A'),
                _buildProductDetailRow("Neck Type", item['neckType'] ?? 'N/A'),

                const SizedBox(height: 12),

                // Pricing Breakdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Unit Price", style: TextStyle(color: subTextColor, fontSize: 12)),
                    Text(
                        currency.format(double.tryParse(item['price']?.toString() ?? '0') ?? 0),
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Item Total", style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(
                        currency.format(double.tryParse(item['total']?.toString() ?? '0') ?? 0),
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 14)
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ✅ SIZES DISPLAY (Robust extraction)
                const Text("Size Breakdown", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    _extractSizes(item),
                    style: TextStyle(fontSize: 14, color: textColor, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],

        if (order.productDetails?.isNotEmpty == true) ...[
          const SizedBox(height: 8),
          const Text("Overall Notes", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(order.productDetails!, style: TextStyle(fontStyle: FontStyle.italic, color: subTextColor, height: 1.4)),
        ],
      ],
    );
  }

  // ✅ SAFELY EXTRACT SIZES
  String _extractSizes(dynamic item) {
    if (item['sizeDescription'] != null && item['sizeDescription'].toString().trim().isNotEmpty) {
      return item['sizeDescription'].toString();
    }

    if (item['sizes'] != null && item['sizes'] is Map) {
      final Map sizesMap = item['sizes'];
      if (sizesMap.isNotEmpty) {
        final validSizes = sizesMap.entries
            .where((e) => e.value.toString() != "0" && e.value.toString().isNotEmpty)
            .map((e) => "${e.key}: ${e.value}")
            .join(", ");
        if (validSizes.isNotEmpty) return validSizes;
      }
    }

    return "No specific sizes requested.";
  }

  Widget _buildProductDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(color: subTextColor, fontSize: 13)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String error;
  const _ErrorBanner({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red),
      ),
      child: Text(
        "Database Error: $error",
        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _PaymentApprovalCard extends StatelessWidget {
  final Map<String, dynamic> doc;
  final NumberFormat currency;
  final Color textColor;
  final bool isProcessingPayment;
  final void Function(String id, double amount, Map<String, dynamic> data) onApprove;
  final void Function(String id) onReject;

  const _PaymentApprovalCard({
    required this.doc,
    required this.currency,
    required this.textColor,
    required this.isProcessingPayment,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc;
    final double amount = (data['amount'] as num).toDouble();
    final String agent = data['agentName'] ?? 'Associate';

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.5), width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text("Payment Approval Required",
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "$agent has collected a payment of ${currency.format(amount)}. Do you approve this transaction?",
            style: TextStyle(color: textColor, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isProcessingPayment ? null : () {
                    HapticFeedback.lightImpact();
                    onReject(doc['id'] ?? '');
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Reject", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: isProcessingPayment ? null : () {
                    HapticFeedback.lightImpact();
                    onApprove(doc['id'] ?? '', amount, data);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isProcessingPayment
                      ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : const Text("Approve", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void _showFullScreenImage(String imageUrl, String orderNo) {
  Get.to(
        () => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: Text("Order $orderNo", style: const TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            tooltip: 'Save to Gallery',
            onPressed: () => _downloadAndSaveImage(imageUrl, orderNo),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 1,
          maxScale: 4,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white),
            errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white, size: 50),
          ),
        ),
      ),
    ),
    transition: Transition.fadeIn,
  );
}

Future<void> _downloadAndSaveImage(String url, String orderNo) async {
  try {
    Get.snackbar("Downloading...", "Saving mockup to your gallery.",
        backgroundColor: Colors.black87, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);

    final response = await http.get(Uri.parse(url));
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/mockup_$orderNo.jpg');
    await file.writeAsBytes(response.bodyBytes);
    await Gal.putImage(file.path);

    Get.snackbar("Success!", "Image saved to your photo gallery.",
        backgroundColor: Colors.green.shade800, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);

  } catch (e) {
    Get.snackbar("Error", "Could not save image: $e",
        backgroundColor: Colors.red.shade800, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
  }
}