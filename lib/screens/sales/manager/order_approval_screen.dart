import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yoobbel/controllers/sales/sales_manager_controller.dart';
import '../../../data/models/order_model.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/widgets/order_status_timeline.dart';

class OrderApprovalScreen extends StatefulWidget {
  final OrderModel order;
  const OrderApprovalScreen({super.key, required this.order});

  @override
  State<OrderApprovalScreen> createState() => _OrderApprovalScreenState();
}

class _OrderApprovalScreenState extends State<OrderApprovalScreen> {
  final controller = Get.put(SalesManagerController());

  // ✅ NEW: Controller for Margin Input
  final TextEditingController _marginController = TextEditingController();

  // State Variables
  late String currentStatus;
  late double localAdvanceAmount;
  late double localBalanceDue;
  bool isProcessingPayment = false;

  final List<String> productionStages = [
    'Approved', 'Cutting', 'Stitching', 'Printing', 'Packing', 'Shipping', 'Delivered'
  ];

  @override
  void initState() {
    super.initState();
    currentStatus = widget.order.status;
    localAdvanceAmount = widget.order.advanceAmount;
    localBalanceDue = widget.order.balanceDue;

    // If a margin is already set, pre-fill the text field
    if (widget.order.effectiveRevenue > 0) {
      _marginController.text = widget.order.effectiveRevenue.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _marginController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text("Order Verification", style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
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
            _buildModernCard(
              title: "Live Production Status", icon: Icons.linear_scale, isDark: isDark, textColor: textColor,
              children: [
                OrderStatusTimeline(currentStatus: currentStatus),
                const SizedBox(height: 10),
                Center(child: Text("Current Stage: $currentStatus", style: TextStyle(color: TColors.primary, fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 20),
            _buildStatusHeader(order),
            const SizedBox(height: 24),
            _buildModernCard(
              title: "Identity Information", icon: Icons.badge_outlined, isDark: isDark, textColor: textColor,
              children: [
                _buildInfoRow(Icons.person_outline, "Client Name", order.clientName, subTextColor, textColor),
                _buildInfoRow(Icons.business, "Organization", order.organization ?? "N/A", subTextColor, textColor),
                _buildInfoRow(Icons.phone_outlined, "Phone", order.clientPhone ?? "N/A", subTextColor, textColor),
                _buildInfoRow(Icons.location_on_outlined, "Address", order.clientAddress ?? "N/A", subTextColor, textColor, isMultiLine: true),
                Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, thickness: 0.5, color: subTextColor.withValues(alpha: 0.3))),
                _buildInfoRow(Icons.support_agent, "Sales Associate", order.marketingPersonName, subTextColor, textColor, highlight: true),
                _buildInfoRow(Icons.event_note, "Order Date", _formatDate(order.orderDate), subTextColor, textColor),
                _buildInfoRow(Icons.calendar_month_outlined, "Delivery Deadline", _formatDate(order.deliveryDate), subTextColor, textColor, isBold: true, customValueColor: Colors.redAccent),
              ],
            ),
            const SizedBox(height: 20),

            // MULTI-ITEM PRODUCT SPECIFICATIONS
            _buildModernCard(
              title: "Product Specifications (${order.products.length} Items)",
              icon: Icons.inventory_2_outlined,
              isDark: isDark,
              textColor: textColor,
              children: [
                ...order.products.map((item) {
                  return Container(
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item['productName'] ?? "Unknown Item",
                                style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 15),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${item['qty']} Units",
                                style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blue, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text("SKU / Code: ${item['productCode'] ?? 'N/A'}", style: TextStyle(color: subTextColor, fontSize: 13)),
                        const SizedBox(height: 12),

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
                            item['sizeDescription'] != null && item['sizeDescription'].toString().isNotEmpty
                                ? item['sizeDescription']
                                : "No specific sizes requested.",
                            style: TextStyle(fontSize: 14, color: textColor, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                if (order.productDetails?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  const Text("Overall Notes", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(order.productDetails!, style: TextStyle(fontStyle: FontStyle.italic, color: subTextColor)),
                ],
              ],
            ),
            const SizedBox(height: 20),

            _buildModernCard(
              title: "Financial Breakdown", icon: Icons.receipt_long, isDark: isDark, textColor: textColor,
              children: [
                _buildFinanceRow("GST Percentage", "${order.gstPercentage}%", subTextColor, textColor),
                _buildFinanceRow("Shipping Charges", currency.format(order.shippingCharge), subTextColor, textColor),
                const Divider(height: 24),
                _buildFinanceRow("Grand Total", currency.format(order.totalAmount), subTextColor, textColor, isTotal: true),
                const SizedBox(height: 8),
                _buildFinanceRow("Less: Advance", "- ${currency.format(localAdvanceAmount)}", subTextColor, textColor, customValueColor: Colors.green),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: localBalanceDue <= 0 ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: localBalanceDue <= 0 ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.2))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(localBalanceDue <= 0 ? "FULLY PAID" : "BALANCE DUE", style: TextStyle(color: localBalanceDue <= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      Text(currency.format(localBalanceDue), style: TextStyle(color: localBalanceDue <= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.w900, fontSize: 20)),
                    ],
                  ),
                ),
              ],
            ),

            // PENDING PAYMENT REQUESTS STREAM
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('payment_requests')
                  .where('orderId', isEqualTo: order.id)
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {

                if (snapshot.hasError) {
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red)),
                    child: Text("Database Error: ${snapshot.error}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SizedBox(height: 20);
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final amount = (data['amount'] as num).toDouble();
                    final agent = data['agentName'] ?? 'Associate';

                    return Container(
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), border: Border.all(color: Colors.orange.withValues(alpha: 0.5), width: 1.5), borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                              const SizedBox(width: 8),
                              const Text("Payment Approval Required", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text("$agent has collected a payment of ${currency.format(amount)}. Do you approve this transaction?", style: TextStyle(color: textColor, fontSize: 14)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: isProcessingPayment ? null : () => _rejectPaymentRequest(doc.id),
                                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                  child: const Text("Reject"),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: isProcessingPayment ? null : () => _approvePaymentRequest(doc.id, amount, order.id!),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                  child: isProcessingPayment ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Approve"),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            if (currentStatus != 'Placed' && currentStatus != 'Pending') const SizedBox(height: 20),

            // --- 4. DYNAMIC ACTION AREA ---
            if (currentStatus == 'Placed' || currentStatus == 'Pending') ...[

              // ✅ NEW: MARGIN CONSOLE (Only visible when approving)
              _buildMarginInput(isDark),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _confirmAction(context, "Reject", Colors.red, () {
                        controller.rejectOrder(order.id!);
                        Get.back();
                      }),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), side: const BorderSide(color: Colors.redAccent, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: const Text("REJECT", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // ✅ Check for Margin before Approving
                        double erAmount = double.tryParse(_marginController.text) ?? 0.0;
                        if (erAmount <= 0) {
                          Get.snackbar("Missing Data", "Please enter the Effective Revenue (Margin) before approving.",
                              backgroundColor: Colors.orange.withValues(alpha: 0.8), colorText: Colors.white);
                          return;
                        }

                        _confirmAction(context, "Approve", Colors.green, () {
                          // Use the new method from the controller
                          controller.approveOrderWithMargin(order.id!, erAmount);
                          setState(() => currentStatus = 'Approved');
                        });
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), elevation: 4, shadowColor: Colors.green.withValues(alpha: 0.4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: const Text("APPROVE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // If already approved, just show the stage updater
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))], border: Border.all(color: TColors.primary.withValues(alpha: 0.3), width: 1.5)),
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
                    DropdownButtonFormField<String>(
                      initialValue: productionStages.contains(currentStatus) ? currentStatus : null,
                      decoration: InputDecoration(filled: true, fillColor: isDark ? Colors.grey[800] : Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                      items: productionStages.map((stage) {
                        return DropdownMenuItem(value: stage, child: Text(stage, style: TextStyle(color: textColor)));
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() => currentStatus = newValue);
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

  // ✅ NEW: MARGIN INPUT WIDGET
  Widget _buildMarginInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? Colors.amber.withValues(alpha: 0.05) : Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_outlined, color: Colors.amber, size: 18),
              SizedBox(width: 8),
              Text(
                "Management: Set Effective Revenue",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _marginController,
            keyboardType: TextInputType.number,
            style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: "Enter company margin (ER)",
              prefixText: "₹ ",
              filled: true,
              fillColor: isDark ? Colors.black26 : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "This value determines the Associate's target achievement and clears their pending status.",
            style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // FULLY UPGRADED PAYMENT APPROVAL
  Future<void> _approvePaymentRequest(String requestId, double amount, String orderId) async {
    setState(() => isProcessingPayment = true);
    try {
      final db = FirebaseFirestore.instance;

      await db.collection('payment_requests').doc(requestId).update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp()
      });

      final requestDoc = await db.collection('payment_requests').doc(requestId).get();
      final data = requestDoc.data();

      String? associateUid = data?['agentUid'];

      if (associateUid == null || associateUid.toString().isEmpty) {
        final associateName = data?['agentName'] ?? "Associate";
        final associateUserSnap = await db.collection('id_requests').where('name', isEqualTo: associateName).limit(1).get();
        if (associateUserSnap.docs.isNotEmpty) {
          associateUid = associateUserSnap.docs.first.id;
        }
      }

      if (associateUid != null && associateUid.isNotEmpty) {
        await db.collection('notifications').add({
          'targetUserId': associateUid,
          'title': 'Payment Approved! ✅',
          'message': 'Manager approved your collection of ₹$amount for Order #${widget.order.manualOrderNo}.',
          'orderId': orderId,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }

      final orderDoc = await db.collection('orders').doc(orderId).get();
      double currentTotal = (orderDoc.data()?['totalAmount'] ?? 0).toDouble();
      double currentAdvance = (orderDoc.data()?['advanceAmount'] ?? 0).toDouble();

      double newAdvance = currentAdvance + amount;
      double newBalance = currentTotal - newAdvance;
      if (newBalance < 0) newBalance = 0;

      final paymentRecord = {'amount': amount, 'date': Timestamp.now(), 'recordedBy': 'Manager Approved'};

      await db.collection('orders').doc(orderId).update({
        'advanceAmount': newAdvance,
        'balanceDue': newBalance,
        'paymentStatus': newBalance <= 0 ? 'Fully Paid' : 'Partially Paid',
        'paymentHistory': FieldValue.arrayUnion([paymentRecord]),
      });

      setState(() { localAdvanceAmount = newAdvance; localBalanceDue = newBalance; });
      Get.snackbar("Payment Approved", "The order balance has been successfully updated.", backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Could not approve payment: $e", backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() => isProcessingPayment = false);
    }
  }

  Future<void> _rejectPaymentRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance.collection('payment_requests').doc(requestId).update({'status': 'rejected', 'rejectedAt': FieldValue.serverTimestamp()});
      Get.snackbar("Payment Rejected", "The payment request has been dismissed.", backgroundColor: Colors.orange, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Could not reject payment: $e", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  // --- UI HELPERS ---
  Widget _buildStatusHeader(OrderModel order) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.orange.shade400, Colors.deepOrangeAccent], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Order #${order.manualOrderNo ?? '---'}", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)), child: Text(currentStatus.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
            ],
          ),
          const SizedBox(height: 4),
          Text("Created on ${_formatDate(order.orderDate)}", style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildModernCard({required String title, required IconData icon, required bool isDark, required Color textColor, required List<Widget> children}) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, size: 20, color: TColors.primary), const SizedBox(width: 8), Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor))]), const SizedBox(height: 16), ...children]),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value, Color labelColor, Color valueColor, {bool isBold = false, bool highlight = false, bool isMultiLine = false, Color? customValueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.grey[400]), const SizedBox(width: 12),
          Expanded(flex: 3, child: Text(label, style: TextStyle(color: labelColor, fontSize: 13))),
          Expanded(flex: 4, child: Text(value ?? "N/A", textAlign: TextAlign.end, style: TextStyle(fontWeight: isBold || highlight ? FontWeight.bold : FontWeight.w500, color: customValueColor ?? (highlight ? Colors.blue : valueColor), fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildFinanceRow(String label, String value, Color labelColor, Color valueColor, {bool isTotal = false, Color? customValueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: isTotal ? valueColor : labelColor, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: isTotal ? 18 : 14, fontWeight: FontWeight.bold, color: customValueColor ?? valueColor)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => "${date.day}/${date.month}/${date.year}";

  void _confirmAction(BuildContext context, String action, Color color, VoidCallback onConfirm) {
    Get.defaultDialog(
      title: "$action Order", titleStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
      middleText: "Are you sure you want to $action this transaction?",
      confirm: ElevatedButton(onPressed: () { onConfirm(); Get.back(); }, style: ElevatedButton.styleFrom(backgroundColor: color), child: const Text("Confirm", style: TextStyle(color: Colors.white))),
      cancel: OutlinedButton(onPressed: () => Get.back(), child: const Text("Cancel")),
      radius: 12,
    );
  }
}