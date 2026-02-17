import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:yoobbel/controllers/sales/sales_manager_controller.dart';
import '../../../data/models/order_model.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/widgets/order_status_timeline.dart';

// ✅ 1. Converted to StatefulWidget to handle updates
class OrderApprovalScreen extends StatefulWidget {
  final OrderModel order;
  const OrderApprovalScreen({super.key, required this.order});

  @override
  State<OrderApprovalScreen> createState() => _OrderApprovalScreenState();
}

class _OrderApprovalScreenState extends State<OrderApprovalScreen> {
  final controller = Get.put(SalesManagerController());
  
  // ✅ 2. State Variable for the current status
  late String currentStatus;

  // ✅ 3. List of stages for the dropdown
  final List<String> productionStages = [
    'Approved',
    'Cutting',
    'Stitching',
    'Printing',
    'Packing',
    'Shipping',
    'Delivered'
  ];

  @override
  void initState() {
    super.initState();
    currentStatus = widget.order.status;
  }

  @override
  Widget build(BuildContext context) {
    // Convenience variable
    final order = widget.order;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );

    // Define text colors based on theme
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- LIVE TIMELINE ---
            _buildModernCard(
              title: "Live Production Status",
              icon: Icons.linear_scale,
              isDark: isDark,
              textColor: textColor,
              children: [
                OrderStatusTimeline(currentStatus: currentStatus),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    "Current Stage: $currentStatus",
                    style: TextStyle(
                        color: TColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- TOP STATUS HEADER ---
            _buildStatusHeader(order),
            const SizedBox(height: 24),

            // --- 1. CLIENT & AGENT SECTION ---
            _buildModernCard(
              title: "Identity Information",
              icon: Icons.badge_outlined,
              isDark: isDark,
              textColor: textColor,
              children: [
                _buildInfoRow(Icons.person_outline, "Client Name", order.clientName, subTextColor, textColor),
                _buildInfoRow(Icons.business, "Organization", order.organization ?? "N/A", subTextColor, textColor),
                _buildInfoRow(Icons.phone_outlined, "Phone", order.clientPhone ?? "N/A", subTextColor, textColor),
                _buildInfoRow(Icons.location_on_outlined, "Address", order.clientAddress ?? "N/A", subTextColor, textColor, isMultiLine: true),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, thickness: 0.5, color: subTextColor.withValues(alpha: 0.3)),
                ),
                _buildInfoRow(Icons.support_agent, "Sales Associate", order.marketingPersonName, subTextColor, textColor, highlight: true),
                _buildInfoRow(Icons.event_note, "Order Date", _formatDate(order.orderDate), subTextColor, textColor),
                _buildInfoRow(Icons.calendar_month_outlined, "Delivery Deadline", _formatDate(order.deliveryDate), subTextColor, textColor, isBold: true, customValueColor: Colors.redAccent),
              ],
            ),

            const SizedBox(height: 20),

            // --- 2. PRODUCT & SIZES SECTION ---
            _buildModernCard(
              title: "Product Specifications",
              icon: Icons.inventory_2_outlined,
              isDark: isDark,
              textColor: textColor,
              children: [
                _buildInfoRow(Icons.shopping_bag_outlined, "Product", order.productName, subTextColor, textColor, isBold: true),
                _buildInfoRow(Icons.qr_code, "SKU / Code", order.productCode ?? "N/A", subTextColor, textColor),
                _buildInfoRow(Icons.layers_outlined, "Quantity", "${order.quantity} Units", subTextColor, textColor),

                // UNIT PRICE
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Calculated Unit Price", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
                      Text(_calculateUnitPrice(order), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),

                const Text("Size Breakdown", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    order.sizeDescription?.isNotEmpty == true ? order.sizeDescription! : "No specific sizes.",
                    style: TextStyle(fontSize: 14, color: textColor, height: 1.4),
                  ),
                ),

                if (order.productDetails?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  const Text("Notes", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(order.productDetails!, style: TextStyle(fontStyle: FontStyle.italic, color: subTextColor)),
                ],
              ],
            ),

            const SizedBox(height: 20),

            // --- 3. FINANCIAL SUMMARY ---
            _buildModernCard(
              title: "Financial Breakdown",
              icon: Icons.receipt_long,
              isDark: isDark,
              textColor: textColor,
              children: [
                _buildFinanceRow("GST Percentage", "${order.gstPercentage}%", subTextColor, textColor),
                _buildFinanceRow("Shipping Charges", currency.format(order.shippingCharge), subTextColor, textColor),
                const Divider(height: 24),
                _buildFinanceRow("Grand Total", currency.format(order.totalAmount), subTextColor, textColor, isTotal: true),
                const SizedBox(height: 8),
                _buildFinanceRow("Less: Advance", "- ${currency.format(order.advanceAmount)}", subTextColor, textColor, customValueColor: Colors.green),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("BALANCE DUE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      Text(currency.format(order.balanceDue), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 20)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // --- ✅ 4. DYNAMIC ACTION AREA ---
            
            // CONDITION A: If Order is "Placed" or "Pending" -> Show Approve/Reject Buttons
            if (currentStatus == 'Placed' || currentStatus == 'Pending') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _confirmAction(context, "Reject", Colors.red, () {
                        controller.rejectOrder(order.id!); // Added ! for safety
                        Get.back();
                      }),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        side: const BorderSide(color: Colors.redAccent, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text("REJECT", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _confirmAction(context, "Approve", Colors.green, () {
                        controller.approveOrder(order.id!); // Added ! for safety
                        setState(() {
                          currentStatus = 'Approved'; // Update UI instantly to show dropdown
                        });
                      }),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        elevation: 4,
                        shadowColor: Colors.green.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text("APPROVE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ),
                ],
              ),
            ] 
            
            // CONDITION B: If Order is Approved/Cutting/Stitching... -> Show Dropdown Input
            else ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                  border: Border.all(color: TColors.primary.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.update, color: TColors.primary),
                        const SizedBox(width: 8),
                        Text("Update Production Stage", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // ✅ DROPDOWN FOR MANAGER INPUT
                    DropdownButtonFormField<String>(
                      initialValue: productionStages.contains(currentStatus) ? currentStatus : null,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: productionStages.map((stage) {
                        return DropdownMenuItem(
                          value: stage,
                          child: Text(stage, style: TextStyle(color: textColor)),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          // 1. Update Visuals
                          setState(() => currentStatus = newValue); 
                          // 2. Save to Database
                          controller.updateOrderStatus(order.id!, newValue); 
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- EXISTING WIDGET HELPERS (Unchanged) ---

  Widget _buildStatusHeader(OrderModel order) {
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
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
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
                  currentStatus.toUpperCase(), // ✅ Uses live state variable
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Created on ${_formatDate(order.orderDate)}",
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCard({
    required String title,
    required IconData icon,
    required bool isDark,
    required Color textColor,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: TColors.primary),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String? value,
    Color labelColor,
    Color valueColor, {
    bool isBold = false,
    bool highlight = false,
    bool isMultiLine = false,
    Color? customValueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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

  Widget _buildFinanceRow(
    String label,
    String value,
    Color labelColor,
    Color valueColor, {
    bool isTotal = false,
    Color? customValueColor,
  }) {
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

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  String _calculateUnitPrice(OrderModel order) {
    if (order.quantity == 0) return "₹0.00";
    double amountWithoutShipping = order.totalAmount - order.shippingCharge;
    double gstMultiplier = 1 + (order.gstPercentage / 100);
    double baseTotal = amountWithoutShipping / gstMultiplier;
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
      title: "$action Order",
      titleStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
      middleText: "Are you sure you want to $action this transaction?",
      confirm: ElevatedButton(
        onPressed: () {
          onConfirm();
          Get.back();
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