import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../controllers/sales/sales_manager_controller.dart';
import '../../../data/models/order_model.dart';
import '../../../utils/constants/colors.dart';
import '../../../services/pdf_invoice_service.dart';
import '../../floor_management/marketing_upload_screen.dart';
import '../../../controllers/floor_management/marketing_upload_controller.dart';
import '../../../controllers/sales/sales_history_controller.dart';

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

  // ✅ FULL SCREEN IMAGE VIEWER
  void _showFullScreenImage(BuildContext context, String imageUrl, String orderNo) {
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

  // ✅ DOWNLOAD AND SAVE TO GALLERY LOGIC
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    Color statusColor = _getStatusColor(displayStatus);

    // DYNAMIC CALCULATIONS FOR RECEIPT
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

              // --- 0. DESIGN MOCKUP SECTION ---
              if (currentOrder.mockupUrl != null && currentOrder.mockupUrl!.isNotEmpty) ...[
                _buildSectionTitle("Design Mockup", Icons.palette_outlined, isDark),
                Center(
                  child: GestureDetector(
                    onTap: () => _showFullScreenImage(context, currentOrder.mockupUrl!, currentOrder.manualOrderNo ?? "Unknown"),
                    child: Container(
                      width: double.infinity,
                      height: 250,
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black38 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: isDark ? Colors.white24 : Colors.black12, width: 1.5),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: currentOrder.mockupUrl!,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: TColors.primary)),
                        errorWidget: (context, url, error) => Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image_rounded, color: TColors.error.withValues(alpha: 0.5), size: 40),
                            const SizedBox(height: 8),
                            const Text("Image Error", style: TextStyle(color: TColors.error, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 8.0, bottom: 28.0),
                  child: Center(child: Text("Tap image to view full screen & download", style: TextStyle(fontSize: 10, color: TColors.textSecondary, fontStyle: FontStyle.italic))),
                ),
              ],

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

                if ((currentOrder.state != null && currentOrder.state!.isNotEmpty) || (currentOrder.pincode != null && currentOrder.pincode!.isNotEmpty)) ...[
                  _buildDivider(isDark),
                  _buildDetailRow(Icons.map_outlined, "State & PIN", "${currentOrder.state ?? 'N/A'} - ${currentOrder.pincode ?? 'N/A'}", isDark),
                ],

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

                  String neck = item['neckType'] ?? 'Not Specified';
                  String type = item['productType'] ?? 'Not Specified';

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

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(color: TColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text(
                              "Type: $type  |  Neck: $neck",
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: TColors.primary)
                          ),
                        ),

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

              // --- 3. FINANCIAL BREAKDOWN WITH PAYMENT HISTORY ---
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 12),

                    if (currentOrder.paymentHistory.isNotEmpty) ...[
                      const Text("Payment Record:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      ...currentOrder.paymentHistory.map((payment) {

                        double amount = 0.0;
                        if (payment['amount'] != null) {
                          amount = double.tryParse(payment['amount'].toString()) ?? 0.0;
                        }

                        String dateStr = "Unknown Date";
                        if (payment['date'] != null) {
                          DateTime dt = (payment['date'] as Timestamp).toDate();
                          dateStr = DateFormat('dd MMM, hh:mm a').format(dt);
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  "Paid on $dateStr",
                                  style: TextStyle(fontSize: 12, color: Colors.redAccent.withValues(alpha: 0.8), fontStyle: FontStyle.italic)
                              ),
                              Text(
                                  "- ${currency.format(amount)}",
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.redAccent)
                              ),
                            ],
                          ),
                        );
                      }),
                    ] else if (currentOrder.advanceAmount > 0) ...[
                      _buildFinanceRow("Advance Paid", "- ${currency.format(currentOrder.advanceAmount)}", isDark, color: Colors.redAccent),
                    ],

                    const SizedBox(height: 16),
                    _buildDashedDivider(isDark),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("REMAINING AMOUNT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.grey, letterSpacing: 0.5)),
                        Text(currency.format(currentOrder.balanceDue), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: currentOrder.balanceDue <= 0 ? Colors.green : Colors.redAccent)),
                      ],
                    ),

                    if (currentOrder.balanceDue <= 0) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3), width: 1.5),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_rounded, color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "FULL PAYMENT SUCCESSFUL",
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      )
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- 4. SMART ACTION AREA (Production Status) ---
              if (displayStatus == 'Placed' || displayStatus == 'Pending') ...[
                Row(
                  children: [
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
                    const SizedBox(width: 12),
                    Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade300)
                      ),
                      child: IconButton(
                        icon: Icon(Icons.history_rounded, color: isDark ? Colors.white : Colors.black87, size: 22),
                        onPressed: () => _showHistoryDialog(context, currentOrder, isDark),
                      ),
                    ),
                    const SizedBox(width: 12),
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
              ] else if (controller.productionStages.contains(displayStatus)) ...[
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
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: controller.productionStages.contains(displayStatus) ? displayStatus : null,
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
                              items: controller.productionStages.map((stage) => DropdownMenuItem(value: stage, child: Text(stage))).toList(),

                              onChanged: (newValue) {
                                if (newValue != null && newValue.toLowerCase() != displayStatus.toLowerCase()) {
                                  HapticFeedback.lightImpact();
                                  _confirmAction("Move to $newValue", Colors.blue, () async {
                                    setState(() => displayStatus = newValue);
                                    await controller.updateOrderStatus(currentOrder.id!, newValue);
                                  });
                                } else if (newValue != null && newValue.toLowerCase() == displayStatus.toLowerCase()) {
                                  Get.snackbar(
                                    "Notice",
                                    "The order is already marked as $newValue.",
                                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                                    colorText: Colors.blue,
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            height: 52,
                            width: 52,
                            decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade300)
                            ),
                            child: IconButton(
                              icon: Icon(Icons.history_rounded, color: isDark ? Colors.white : Colors.black87, size: 22),
                              onPressed: () => _showHistoryDialog(context, currentOrder, isDark),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ✅ ADDED OUT SRC AND OTHER LOCKED STATUSES HERE TO PREVENT SALES MANAGER FROM EDITING IT IF THEY SHOULDN'T.
                      // Wait, Sales Manager SHOULD be able to edit. The prompt instructions were to add Out SRC to the "locked from sales agent" list.
                      // Let's make sure the Sales Manager "Edit Order" button (if they have one) or Cancel button handles it correctly.
                      // Actually, Sales Manager CAN cancel orders.

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmAction("Cancel & Reject", Colors.redAccent, () async {
                            if (displayStatus != "Rejected") {
                              await controller.rejectOrder(currentOrder.id!);
                              setState(() => displayStatus = "Rejected");
                            }
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
                Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                      child: Center(
                        child: Text("Order is ${displayStatus.toUpperCase()}.", style: TextStyle(color: isDark ? Colors.redAccent : Colors.red, fontWeight: FontWeight.w800, letterSpacing: 1)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showHistoryDialog(context, currentOrder, isDark),
                        icon: const Icon(Icons.history_rounded, size: 18),
                        label: const Text("VIEW ORDER HISTORY", style: TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                      ),
                    )
                  ],
                ),
              ],

              const SizedBox(height: 24),

              EffectiveRevenueSection(order: currentOrder),

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

  void _showHistoryDialog(BuildContext context, OrderModel order, bool isDark) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) {
          List<dynamic> history = List.from(order.stageHistory.reversed);

          return FractionallySizedBox(
            heightFactor: 0.6,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Stage History", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: TColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(order.manualOrderNo ?? "Unknown ID", style: const TextStyle(color: TColors.primary, fontWeight: FontWeight.w900, fontSize: 12)),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (history.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text("No updates have been made yet.", style: TextStyle(color: Colors.grey.shade500)),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          var event = history[index];
                          DateTime time = DateTime.now();
                          if (event['timestamp'] != null) {
                            time = (event['timestamp'] as Timestamp).toDate();
                          }
                          String stage = event['stage'] ?? 'Unknown Stage';
                          String updater = event['updatedBy'] ?? 'System';
                          Color color = _getStatusColor(stage);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    Container(
                                      width: 14, height: 14,
                                      decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.3), width: 3)),
                                    ),
                                    if (index != history.length - 1)
                                      Container(width: 2, height: 40, color: isDark ? Colors.white10 : Colors.grey.shade200)
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(stage, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.person_rounded, size: 12, color: Colors.grey.shade500),
                                          const SizedBox(width: 4),
                                          Text("Updated by $updater", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                                Text(
                                    DateFormat('dd MMM\nhh:mm a').format(time),
                                    textAlign: TextAlign.right,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, height: 1.3)
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    )
                ],
              ),
            ),
          );
        }
    );
  }

  // ✅ ADDED OUT SRC COLOR MAP TO MANAGER APP
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Colors.blue;
      case 'fab purchased': return Colors.pink;
      case 'fab ready': return Colors.lightGreen;
      case 'cutting': return Colors.orange;
      case 'cutting done': return Colors.deepOrange;
      case 'printing': return Colors.indigo;
      case 'printed': return Colors.cyan;
      case 'stitching': return Colors.amber;
      case 'stitched': return Colors.brown;
      case 'packing': return Colors.purple;
      case 'packed': return Colors.deepPurple;
      case 'out src': return Colors.indigoAccent; // ✅ NEW
      case 'shipping':
      case 'shipped': return Colors.teal;
      case 'delivered': return Colors.green;
      case 'completed': return Colors.green;
      case 'rejected': return Colors.red;
      case 'pending': return const Color(0xFFFFC107);
      default: return Colors.grey;
    }
  }
}

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

    if (input > 30) {
      input = 30;
      marginInput.text = '30';
      marginInput.selection = TextSelection.fromPosition(TextPosition(offset: marginInput.text.length));
      HapticFeedback.heavyImpact();
    }

    marginX.value = input;
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