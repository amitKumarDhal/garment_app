import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/services/api_service.dart';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

  @override
  void initState() {
    super.initState();
    currentOrder = widget.order;
    displayStatus = widget.order.status;
  }

  Future<void> _refreshOrder() async {
    try {
      final res = await ApiService.get('/orders/${widget.order.id}');
      if (res['success'] == true && res['order'] != null) {
        setState(() {
          currentOrder = OrderModel.fromJson(res['order']);
          displayStatus = currentOrder.status;
        });
      }
    } catch (e) {
      Get.snackbar("Error", "Could not refresh order details.");
    }
  }

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
                        errorWidget: (context, url, error) => const Icon(Icons.broken_image_rounded, size: 40),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // --- 1. KEY INFO CARD (NOW FULLY DETAILED) ---
              _buildSectionTitle("Client & Logistics Info", Icons.business_center_outlined, isDark),
              _buildCard(isDark, [
                _buildDetailRow(Icons.person_outline_rounded, "Sales Associate", currentOrder.marketingPersonName, isDark),
                _buildDivider(isDark),
                _buildDetailRow(Icons.domain_rounded, "Client", currentOrder.clientName, isDark, isBold: true),
                _buildDivider(isDark),
                _buildDetailRow(Icons.phone_outlined, "Phone", currentOrder.clientPhone ?? "N/A", isDark),
                _buildDivider(isDark),
                _buildDetailRow(Icons.location_on_outlined, "Address", currentOrder.clientAddress ?? "N/A", isDark),
                _buildDivider(isDark),
                _buildDetailRow(Icons.map_outlined, "State", currentOrder.state ?? "N/A", isDark),
                _buildDivider(isDark),
                _buildDetailRow(Icons.pin_drop_outlined, "PIN Code", currentOrder.pincode ?? "N/A", isDark, isBold: true, color: TColors.primary),
                _buildDivider(isDark),
                _buildDetailRow(Icons.calendar_month_rounded, "Deadline", DateFormat('MMM dd, yyyy').format(currentOrder.deliveryDate), isDark, color: Colors.redAccent),
              ]),
              const SizedBox(height: 28),

              // --- 2. DYNAMIC ITEM LIST (NOW DEEPLY DETAILED) ---
              _buildSectionTitle("Itemized Products (${currentOrder.products.length} Items)", Icons.inventory_2_outlined, isDark),
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
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(item['productName'] ?? "Unknown Item", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? Colors.white : Colors.black87))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text("${item['qty']} Units", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blue, fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildProductDetailRow("SKU / Code", item['productCode'] ?? 'N/A', isDark),
                        _buildProductDetailRow("Product Type", item['productType'] ?? 'N/A', isDark),
                        _buildProductDetailRow("Neck Type", item['neckType'] ?? 'N/A', isDark),

                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Unit Price", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                            Text(currency.format(iPrice), style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Item Total", style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold)),
                            Text(currency.format(iTotal), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 14)),
                          ],
                        ),

                        const SizedBox(height: 16),
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
                            style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // ✅ ADDED OVERALL ORDER NOTES
              if (currentOrder.productDetails?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Overall Notes", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(currentOrder.productDetails!, style: TextStyle(fontStyle: FontStyle.italic, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, height: 1.4)),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // --- 3. FINANCIAL BREAKDOWN ---
              _buildSectionTitle("Financial Ledger", Icons.receipt_long_rounded, isDark),
              _buildCard(isDark, [
                _buildFinanceRow("Items Subtotal", currency.format(calculatedSubtotal), isDark),
                const SizedBox(height: 8),
                _buildFinanceRow("Total Tax (GST)", "+ ${currency.format(calculatedTax)}", isDark),
                const SizedBox(height: 8),
                _buildFinanceRow("Shipping Charge", "+ ${currency.format(currentOrder.shippingCharge)}", isDark),
                const SizedBox(height: 16),
                _buildDashedDivider(isDark),
                const SizedBox(height: 16),
                _buildFinanceRow("Grand Total", currency.format(currentOrder.totalAmount), isDark, isBold: true, fontSize: 16),
                const SizedBox(height: 16),
                _buildFinanceRow("Advance Paid", "- ${currency.format(currentOrder.advanceAmount)}", isDark, color: Colors.redAccent),
                const SizedBox(height: 16),
                _buildDashedDivider(isDark),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("BALANCE DUE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.grey)),
                    Text(currency.format(currentOrder.balanceDue), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: currentOrder.balanceDue <= 0 ? Colors.green : Colors.redAccent)),
                  ],
                ),
              ]),
              const SizedBox(height: 32),

              // --- 4. SMART ACTION AREA (History Removed) ---
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
                          side: const BorderSide(color: Colors.redAccent, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text("REJECT", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800)),
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
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text("APPROVE ORDER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
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
                    border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                  ),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: controller.productionStages.contains(displayStatus) ? displayStatus : null,
                        decoration: InputDecoration(
                          labelText: "Move to Stage",
                          filled: true,
                          fillColor: isDark ? Colors.black26 : Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: controller.productionStages.map((stage) => DropdownMenuItem(value: stage, child: Text(stage))).toList(),
                        onChanged: (newValue) {
                          if (newValue != null && newValue != displayStatus) {
                            _confirmAction("Move to $newValue", Colors.blue, () async {
                              setState(() => displayStatus = newValue);
                              await controller.updateOrderStatus(currentOrder.id!, newValue);
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => _confirmAction("Reject", Colors.redAccent, () async {
                            await controller.rejectOrder(currentOrder.id!);
                            setState(() => displayStatus = "Rejected");
                          }),
                          child: const Text("CANCEL & REJECT ORDER", style: TextStyle(color: Colors.redAccent)),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                  child: Center(
                    child: Text("Order is ${displayStatus.toUpperCase()}.", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              EffectiveRevenueSection(order: currentOrder),

              if (displayStatus != 'Rejected')
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await PdfInvoiceService.generateAndPrintInvoice(currentOrder);
                    },
                    icon: const Icon(Icons.print_rounded),
                    label: const Text("PRINT INVOICE", style: TextStyle(fontWeight: FontWeight.w800)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
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

  // ✅ Helper for internal item attributes
  Widget _buildProductDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 13))),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: TColors.primary),
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
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha:0.03)),
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
          Expanded(
              flex: 2,
              child: Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 13))
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: isBold ? FontWeight.w800 : FontWeight.w600, color: color ?? (isDark ? Colors.white : Colors.black87)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceRow(String label, String value, bool isDark, {bool isBold = false, double fontSize = 13, Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
            child: Text(label, style: TextStyle(fontSize: fontSize, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600))
        ),
        const SizedBox(width: 8),
        Text(value, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.w900 : FontWeight.w600, color: color ?? (isDark ? Colors.white : Colors.black87))),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(color: isDark ? Colors.white10 : Colors.black.withValues(alpha:0.05));
  }

  Widget _buildDashedDivider(bool isDark) {
    return Row(children: List.generate(40, (index) => Expanded(child: Container(color: index % 2 == 0 ? Colors.transparent : (isDark ? Colors.grey.shade800 : Colors.grey.shade300), height: 1.5))));
  }

  void _confirmAction(String action, Color color, Future<void> Function() onConfirm) {
    Get.defaultDialog(
      title: "$action Order",
      titleStyle: TextStyle(fontWeight: FontWeight.w900, color: color),
      middleText: "Are you sure you want to $action this order?",
      barrierDismissible: false,
      confirm: ElevatedButton(
        onPressed: () async {
          Get.back(); // Close dialog

          // Show loader
          Get.dialog(
            const Center(child: CircularProgressIndicator(color: TColors.primary)),
            barrierDismissible: false,
          );

          await onConfirm();

          if (Get.isDialogOpen ?? false) Get.back(); // Close loader
        },
        style: ElevatedButton.styleFrom(backgroundColor: color),
        child: const Text("Confirm", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      cancel: OutlinedButton(
        onPressed: () => Get.back(),
        child: const Text("Cancel"),
      ),
    );
  }

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
      case 'out src': return Colors.indigoAccent;
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

      await ApiService.put('/orders/${order.id}', {
        'margin_number': marginX.value,
        'effective_revenue': effectiveRevenue.value,
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