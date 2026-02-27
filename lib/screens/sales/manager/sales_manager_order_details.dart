import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/sales/sales_manager_controller.dart';
import '../../../data/models/order_model.dart';
import '../../../utils/constants/colors.dart';
import '../../../services/pdf_invoice_service.dart';

class SalesManagerOrderDetails extends StatefulWidget {
  final OrderModel order;

  const SalesManagerOrderDetails({super.key, required this.order});

  @override
  State<SalesManagerOrderDetails> createState() => _SalesManagerOrderDetailsState();
}

class _SalesManagerOrderDetailsState extends State<SalesManagerOrderDetails> {
  final controller = Get.put(SalesManagerController());

  late OrderModel currentOrder;
  late String displayStatus;

  final List<String> productionStages = [
    'Approved', 'Cutting', 'Stitching', 'Printing', 'Packing', 'Shipping', 'Delivered'
  ];

  @override
  void initState() {
    super.initState();
    currentOrder = widget.order;
    displayStatus = widget.order.status;
  }

  Future<void> _refreshOrder() async {
    try {
      if (widget.order.id == null) return;
      final doc = await FirebaseFirestore.instance.collection('orders').doc(widget.order.id).get();
      if (doc.exists) {
        setState(() {
          currentOrder = OrderModel.fromSnapshot(doc);
          displayStatus = currentOrder.status;
        });
      }
    } catch (e) {
      Get.snackbar("Error", "Could not refresh order details.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    Color statusColor = _getStatusColor(displayStatus);

    // ✅ DYNAMIC CALCULATIONS FOR RECEIPT
    double calculatedSubtotal = 0;
    double calculatedTax = 0;

    for (var prod in currentOrder.products) {
      double price = double.tryParse(prod['price']?.toString() ?? '0') ?? 0.0;
      int qty = int.tryParse(prod['qty']?.toString() ?? '0') ?? 0;
      double gst = double.tryParse(prod['gstPercentage']?.toString() ?? '0') ?? 0.0;

      double base = price * qty;
      calculatedSubtotal += base;
      calculatedTax += base * (gst / 100);
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
        title: Row(
          children: [
            Text(
              "Order #${currentOrder.manualOrderNo ?? '---'}",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: -0.5),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3))
              ),
              child: Text(
                  displayStatus.toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: statusColor, letterSpacing: 1)
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshOrder,
        color: TColors.primary,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. KEY INFO CARD ---
              _buildSectionTitle("Client & Delivery Info", Icons.business_center_outlined, isDark),
              _buildCard(isDark, [
                _buildDetailRow(Icons.person_outline_rounded, "Sales Associate", currentOrder.marketingPersonName, isDark),
                _buildDivider(isDark),
                _buildDetailRow(Icons.domain_rounded, "Client", currentOrder.clientName, isDark, isBold: true),
                _buildDivider(isDark),
                _buildDetailRow(Icons.phone_outlined, "Phone", currentOrder.clientPhone ?? "N/A", isDark),
                _buildDivider(isDark),
                _buildDetailRow(Icons.location_on_outlined, "Address", currentOrder.clientAddress ?? "N/A", isDark),
                _buildDivider(isDark),
                _buildDetailRow(Icons.calendar_month_rounded, "Deadline", DateFormat('MMM dd, yyyy').format(currentOrder.deliveryDate), isDark, color: Colors.redAccent),
              ]),
              const SizedBox(height: 28),

              // --- 2. DYNAMIC ITEM LIST ---
              _buildSectionTitle("Itemized Products (${currentOrder.products.length})", Icons.inventory_2_outlined, isDark),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: currentOrder.products.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = currentOrder.products[index];
                  double iPrice = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
                  int iQty = int.tryParse(item['qty']?.toString() ?? '0') ?? 0;
                  double iTotal = double.tryParse(item['total']?.toString() ?? '0') ?? (iPrice * iQty);

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white.withValues(alpha:0.05) : Colors.black.withValues(alpha:0.03)),
                      boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withValues(alpha:0.02), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(item['productName'] ?? "Unknown Item", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: isDark ? Colors.white : Colors.black87))),
                            Text(currency.format(iTotal), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.green)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.grey.withValues(alpha:0.1), borderRadius: BorderRadius.circular(4)), child: Text(item['productCode'] ?? "NO SKU", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey.shade600))),
                            const SizedBox(width: 8),
                            Text("${item['qty']} Units × ${currency.format(iPrice)}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                          ],
                        ),
                        if (item['sizeDescription'] != null && item['sizeDescription'].toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text("Sizes: ${item['sizeDescription']}", style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)),
                        ]
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),

              // --- 3. FINANCIAL BREAKDOWN ---
              _buildSectionTitle("Financial Ledger", Icons.receipt_long_rounded, isDark),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.green.withValues(alpha:isDark ? 0.3 : 0.5), width: 1.5),
                  boxShadow: [if (!isDark) BoxShadow(color: Colors.green.withValues(alpha:0.05), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: Column(
                  children: [
                    _buildFinanceRow("Items Subtotal", currency.format(calculatedSubtotal), isDark),
                    const SizedBox(height: 8),
                    _buildFinanceRow("Total Tax (GST)", "+ ${currency.format(calculatedTax)}", isDark),
                    const SizedBox(height: 8),
                    _buildFinanceRow("Shipping Charge", "+ ${currency.format(currentOrder.shippingCharge)}", isDark),
                    const SizedBox(height: 16),
                    _buildDashedDivider(isDark),
                    const SizedBox(height: 16),
                    _buildFinanceRow("Grand Total", currency.format(currentOrder.totalAmount), isDark, isBold: true, fontSize: 16),
                    const SizedBox(height: 8),
                    _buildFinanceRow("Advance Paid", "- ${currency.format(currentOrder.advanceAmount)}", isDark, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    _buildDashedDivider(isDark),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("BALANCE DUE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.grey, letterSpacing: 0.5)),
                        Text(currency.format(currentOrder.balanceDue), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Colors.green)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- 4. SMART ACTION AREA (Production Status) ---
              if (displayStatus == 'Placed' || displayStatus == 'Pending') ...[
                Row(
                  children: [
                    // ✅ FIXED REJECT: Now updates state immediately instead of kicking you out
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _confirmAction("Reject", Colors.redAccent, () async {
                          await controller.rejectOrder(currentOrder.id!);
                          setState(() => displayStatus = "Rejected");
                        }),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.redAccent.withValues(alpha:0.5), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text("REJECT", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800, letterSpacing: 1)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _confirmAction("Approve", Colors.green, () async {
                          await controller.approveOrder(currentOrder.id!);
                          setState(() => displayStatus = "Approved");
                        }),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text("APPROVE ORDER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                    ),
                  ],
                ),
              ] else if (productionStages.contains(displayStatus)) ...[
                // ✅ REDESIGNED: Pipeline Management
                _buildSectionTitle("Pipeline Management", Icons.timeline_rounded, isDark),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? Colors.white.withValues(alpha:0.05) : Colors.black.withValues(alpha:0.05)),
                    boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withValues(alpha:0.02), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sleek Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: productionStages.contains(displayStatus) ? displayStatus : null,
                        icon: const Icon(Icons.swap_vert_rounded, color: Colors.grey),
                        decoration: InputDecoration(
                          labelText: "Current Stage",
                          labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600),
                          filled: true,
                          fillColor: isDark ? Colors.black.withValues(alpha:0.2) : Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black.withValues(alpha:0.05))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black.withValues(alpha:0.05))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TColors.primary, width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87, fontSize: 15),
                        items: productionStages.map((stage) => DropdownMenuItem(value: stage, child: Text(stage))).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            HapticFeedback.lightImpact();
                            setState(() => displayStatus = newValue);
                            controller.updateOrderStatus(currentOrder.id!, newValue);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Subtle Cancel Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmAction("Cancel & Reject", Colors.redAccent, () async {
                            await controller.rejectOrder(currentOrder.id!);
                            setState(() => displayStatus = "Rejected");
                          }),
                          icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 16),
                          label: const Text("CANCEL ORDER", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.redAccent.withValues(alpha:0.3)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Order is already Rejected or Cancelled
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                  child: Center(
                    child: Text("Order is ${displayStatus.toUpperCase()}.", style: TextStyle(color: isDark ? Colors.redAccent : Colors.red, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              EffectiveRevenueSection(order: currentOrder),

              /// Print Invoice Button
              if (displayStatus != 'Rejected')
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      await PdfInvoiceService.generateAndPrintInvoice(currentOrder);
                    },
                    icon: Icon(Icons.print_rounded, color: isDark ? Colors.white70 : Colors.black54, size: 20),
                    label: Text("PRINT INVOICE", style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w800, letterSpacing: 1)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: isDark ? Colors.white24 : Colors.black12, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: TColors.primary.withValues(alpha:0.15), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: TColors.primary)),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildCard(bool isDark, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha:0.05) : Colors.black.withValues(alpha:0.03)),
        boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withValues(alpha:0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, bool isDark, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500))),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(fontWeight: isBold ? FontWeight.w800 : FontWeight.w600, fontSize: 14, color: color ?? (isDark ? Colors.white : Colors.black87)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceRow(String label, String value, bool isDark, {bool isBold = false, double fontSize = 13, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: fontSize, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontWeight: isBold ? FontWeight.bold : FontWeight.w500)),
        Text(value, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.w900 : FontWeight.w600, color: color ?? (isDark ? Colors.white : Colors.black87))),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Divider(color: isDark ? Colors.white10 : Colors.black.withValues(alpha:0.05), thickness: 1));
  }

  Widget _buildDashedDivider(bool isDark) {
    return Row(children: List.generate(40, (index) => Expanded(child: Container(color: index % 2 == 0 ? Colors.transparent : (isDark ? Colors.grey.shade800 : Colors.grey.shade300), height: 1.5))));
  }

  void _confirmAction(String action, Color color, VoidCallback onConfirm) {
    Get.defaultDialog(
      title: "$action Order",
      titleStyle: TextStyle(fontWeight: FontWeight.w900, color: color),
      middleText: "Are you sure you want to $action this order?\n\nIf rejected, the revenue will be deducted automatically.",
      middleTextStyle: const TextStyle(fontSize: 14),
      confirm: ElevatedButton(
        onPressed: () {
          onConfirm();
          Get.back();
        },
        style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
        ),
        child: const Text("Confirm", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      cancel: OutlinedButton(
        onPressed: () => Get.back(),
        style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
        ),
        child: const Text("Cancel"),
      ),
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

// =========================================================================
// ✅ 1. THE DEDICATED CONTROLLER FOR LIVE MATH & SAVING
// =========================================================================
class EffectiveRevenueController extends GetxController {
  final OrderModel order;
  EffectiveRevenueController(this.order);

  final marginInput = TextEditingController();
  final RxInt marginX = 0.obs;
  final RxDouble effectiveRevenue = 0.0.obs;
  final RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();

    int existingMargin = order.marginNumber;

    if (existingMargin > 0) {
      marginInput.text = existingMargin.toString();
      calculateRevenue(marginInput.text);
    }
  }

  void calculateRevenue(String val) {
    if (val.isEmpty) {
      marginX.value = 0;
      effectiveRevenue.value = 0.0;
      return;
    }

    int input = int.tryParse(val) ?? 0;

    // ENFORCE RULE: x must be <= 30
    if (input > 30) {
      input = 30;
      marginInput.text = '30';
      marginInput.selection = TextSelection.fromPosition(TextPosition(offset: marginInput.text.length));
      HapticFeedback.heavyImpact();
    }

    marginX.value = input;
    // FORMULA: Effective Revenue = Total Amount * (x / 30)
    effectiveRevenue.value = order.totalAmount * (input / 30.0);
  }

  Future<void> saveEffectiveRevenue() async {
    if (marginX.value <= 0) {
      Get.snackbar("Invalid Margin", "Please enter a valid margin number (1-30).", backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    try {
      isSaving.value = true;
      HapticFeedback.mediumImpact();

      await FirebaseFirestore.instance.collection('orders').doc(order.id).update({
        'marginNumber': marginX.value,
        'effectiveRevenue': effectiveRevenue.value,
      });

      Get.snackbar(
        "Revenue Saved",
        "Effective Revenue locked at ₹${effectiveRevenue.value.toStringAsFixed(2)}",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar("Error", "Could not save revenue: $e", backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isSaving.value = false;
    }
  }
}

// =========================================================================
// ✅ 2. REDESIGNED MARGIN CALCULATOR (Simple & Relevant)
// =========================================================================
class EffectiveRevenueSection extends StatelessWidget {
  final OrderModel order;
  const EffectiveRevenueSection({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EffectiveRevenueController(order), tag: order.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: TColors.primary.withValues(alpha:0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.calculate_outlined, size: 16, color: TColors.primary)
              ),
              const SizedBox(width: 10),
              Text("Internal Margin", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
        ),

        // Main Card
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
            boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withValues(alpha:0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              // 1. Margin Input Field
              SizedBox(
                width: 75,
                child: TextField(
                  controller: controller.marginInput,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: controller.calculateRevenue,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: "Margin (x)",
                    labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: TColors.primary, width: 1.5)),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // 2. Live Calculation Result
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("EFFECTIVE REVENUE", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 0.5)),
                    Obx(
                          () => Text(
                        currency.format(controller.effectiveRevenue.value),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: TColors.primary),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Simple Checkmark Save Button
              Obx(() => IconButton(
                onPressed: controller.isSaving.value ? null : controller.saveEffectiveRevenue,
                style: IconButton.styleFrom(
                    backgroundColor: TColors.primary.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                icon: controller.isSaving.value
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: TColors.primary))
                    : const Icon(Icons.check_rounded, color: TColors.primary),
              )),
            ],
          ),
        ),
      ],
    );
  }
}