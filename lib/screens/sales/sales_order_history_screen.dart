// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../controllers/floor_management/marketing_upload_controller.dart';
import '../../utils/constants/colors.dart';
import '../../controllers/sales/sales_history_controller.dart';
import '../../data/models/order_model.dart';
import '../floor_management/marketing_upload_screen.dart';

class SalesOrderHistoryScreen extends StatefulWidget {
  const SalesOrderHistoryScreen({super.key});

  @override
  State<SalesOrderHistoryScreen> createState() => _SalesOrderHistoryScreenState();
}

class _SalesOrderHistoryScreenState extends State<SalesOrderHistoryScreen> {
  late final SalesHistoryController controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller = Get.put(SalesHistoryController());

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        controller.fetchNextPage();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        title: Text(
          "My Ledger",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
      ),

      body: Column(
        children: [
          // --- 1. CLEAN SEARCH & FILTER HEADER ---
          Container(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            decoration: BoxDecoration(color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9)),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => controller.searchOrders(val),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: "Search ID or Client...",
                    hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black38, fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white70 : TColors.primary, size: 20),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: isDark ? BorderSide.none : BorderSide(color: Colors.black.withValues(alpha:0.05))
                    ),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: TColors.primary, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildFilterChip(controller, "All", isDark),
                      _buildFilterChip(controller, "Pending", isDark),
                      _buildFilterChip(controller, "Approved", isDark),
                      _buildFilterChip(controller, "Fab Purchased", isDark),
                      _buildFilterChip(controller, "Fab Ready", isDark),
                      _buildFilterChip(controller, "Cutting", isDark),
                      _buildFilterChip(controller, "Cutting Done", isDark),
                      _buildFilterChip(controller, "Printing", isDark),
                      _buildFilterChip(controller, "Printed", isDark),
                      _buildFilterChip(controller, "Stitching", isDark),
                      _buildFilterChip(controller, "Stitched", isDark),
                      _buildFilterChip(controller, "Packing", isDark),
                      _buildFilterChip(controller, "Packed", isDark),
                      _buildFilterChip(controller, "Shipping", isDark),
                      _buildFilterChip(controller, "Shipped", isDark),
                      _buildFilterChip(controller, "Delivered", isDark),
                      _buildFilterChip(controller, "Rejected", isDark),
                      _buildFilterChip(controller, "Trash", isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- 2. ORDERS LIST WITH PAGINATION ---
          Expanded(
            child: RefreshIndicator(
              color: TColors.primary,
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              onRefresh: () async {
                HapticFeedback.lightImpact();
                await controller.refreshData();
              },
              child: Obx(() {
                if (controller.isLoading.value && controller.displayedOrders.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.displayedOrders.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black.withValues(alpha:0.05), shape: BoxShape.circle),
                              child: Icon(Icons.receipt_long_rounded, size: 48, color: isDark ? Colors.white54 : Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            Text("No orders found.", style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                return ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 120),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: controller.displayedOrders.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {

                    if (index == controller.displayedOrders.length) {
                      return Obx(() {
                        if (controller.isLoadingMore.value) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (!controller.hasMoreData.value && controller.displayedOrders.isNotEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                  "End of Results",
                                  style: TextStyle(color: isDark ? Colors.white30 : Colors.black26, fontWeight: FontWeight.bold)
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      });
                    }

                    final order = controller.displayedOrders[index];
                    return _buildHistoryCard(context, order, isDark);
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(SalesHistoryController controller, String label, bool isDark) {
    return Obx(() {
      bool isSelected = controller.currentFilter.value == label;
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          controller.filterByStatus(label);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? TColors.primary : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? TColors.primary : (isDark ? Colors.white10 : Colors.black.withValues(alpha:0.05))),
            boxShadow: isSelected ? [BoxShadow(color: TColors.primary.withValues(alpha:0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildHistoryCard(BuildContext context, OrderModel order, bool isDark) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    Color statusColor = _getStatusColor(order.status);
    bool isDeleted = order.toJson()['isDeleted'] == true;

    int totalUnits = order.quantity;
    if (order.products.isNotEmpty) {
      totalUnits = order.products.fold(0, (sum, item) => sum + (int.tryParse(item['qty']?.toString() ?? '0') ?? 0));
    }
    double unitPrice = totalUnits > 0 ? (order.totalAmount / totalUnits) : 0.0;

    String productSummary = "No Items";
    if (order.products.isNotEmpty) {
      String firstItem = order.products.first['productName'] ?? "Unknown Item";
      int extraCount = order.products.length - 1;
      productSummary = extraCount > 0 ? "$firstItem + $extraCount more" : firstItem;
    } else {
      productSummary = order.productName;
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showOrderDetails(context, order, isDark);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDeleted
                  ? Colors.redAccent.withValues(alpha: 0.3)
                  : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
              width: 1.5
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isDeleted) ...[
              Row(
                children: [
                  const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 14),
                  const SizedBox(width: 4),
                  const Text(
                    "SOFT DELETED",
                    style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: isDeleted ? Colors.grey : Colors.orange, width: 1.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    order.manualOrderNo ?? "---",
                    style: TextStyle(color: isDeleted ? Colors.grey : Colors.orange, fontWeight: FontWeight.w900, fontSize: 11),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: isDeleted ? Colors.grey.withValues(alpha: 0.1) : statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6)
                  ),
                  child: Text(
                    isDeleted ? "DELETED" : order.status.toUpperCase(),
                    style: TextStyle(color: isDeleted ? Colors.grey : statusColor, fontWeight: FontWeight.w900, fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              order.clientName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: isDeleted ? Colors.grey : (isDark ? Colors.white : Colors.black87)),
            ),
            Text(
              productSummary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.marketingPersonName,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd • hh:mm a').format(order.orderDate),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),

            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "$totalUnits Units × ${currency.format(unitPrice)}",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54),
                ),
                Text(
                  currency.format(order.totalAmount),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isDeleted ? Colors.grey : (isDark ? Colors.white : Colors.black87)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, OrderModel order, SalesHistoryController controller) {
    final TextEditingController amountController = TextEditingController(text: order.balanceDue.toStringAsFixed(0));

    Get.defaultDialog(
      title: "Update Due Amount",
      titleStyle: const TextStyle(fontWeight: FontWeight.w900),
      content: Column(
        children: [
          Text("Remaining Balance: ₹${order.balanceDue}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 15),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              prefixText: "₹ ",
              prefixStyle: const TextStyle(color: TColors.primary, fontWeight: FontWeight.w900),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TColors.primary, width: 2)),
            ),
          ),
        ],
      ),
      confirm: ElevatedButton(
        onPressed: () {
          double amount = double.tryParse(amountController.text) ?? 0.0;
          if (amount > 0) {
            Get.back();
            HapticFeedback.mediumImpact();
            controller.recordPayment(order, amount);
          }
        },
        style: ElevatedButton.styleFrom(backgroundColor: TColors.primary, minimumSize: const Size(120, 45)),
        child: const Text("Save Payment", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      cancel: OutlinedButton(onPressed: () => Get.back(), child: const Text("Cancel")),
    );
  }

  // ✅ NEW: Full Payment Confirmation Dialog
  void _confirmFullPayment(BuildContext context, OrderModel order) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    Get.defaultDialog(
      title: "Confirm Payment",
      titleStyle: const TextStyle(fontWeight: FontWeight.w900),
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
        child: Text(
          "Request approval for a full payment of ${currency.format(order.balanceDue)}?",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14),
        ),
      ),
      confirm: ElevatedButton(
        onPressed: () {
          Get.back(); // Close the dialog
          Navigator.pop(context); // Close the bottom sheet to show the snackbar properly
          HapticFeedback.heavyImpact();
          Get.find<SalesHistoryController>().recordPayment(order, order.balanceDue);
        },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(120, 45)),
        child: const Text("Confirm", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      cancel: OutlinedButton(onPressed: () => Get.back(), child: const Text("Cancel")),
    );
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

  void _showOrderDetails(BuildContext context, OrderModel order, bool isDark) {
    bool isDeleted = order.toJson()['isDeleted'] == true;

    final lockedStatuses = [
      'cutting', 'cutting done',
      'printing', 'printed', 'stitching', 'stitched',
      'packing', 'packed', 'shipping', 'shipped', 'delivered', 'rejected'
    ];

    final bool isLocked = lockedStatuses.contains(order.status.toLowerCase()) || isDeleted;
    final bool canRequestDelete = !isLocked && !isDeleted;

    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Ledger Details", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: -0.5)),

                  if (isDeleted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Text("Deleted", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                    )
                  else if (order.isDeleteRequested)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Text("Pending Deletion", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                        IconButton(
                          onPressed: () {
                            HapticFeedback.heavyImpact();
                            _confirmCancelDelete(context, order);
                          },
                          icon: const Icon(Icons.undo_rounded, color: Colors.blueAccent, size: 20),
                          padding: const EdgeInsets.only(left: 8),
                          constraints: const BoxConstraints(),
                        )
                      ],
                    )
                  else if (canRequestDelete)
                      IconButton(
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          _confirmDelete(context, order);
                        },
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      )
                    else
                      Icon(Icons.lock_outline_rounded, color: Colors.grey.shade400, size: 20),
                ],
              ),
              const SizedBox(height: 16),

              if (order.mockupUrl != null && order.mockupUrl!.isNotEmpty) ...[
                Center(
                  child: GestureDetector(
                    onTap: () => _showFullScreenImage(context, order.mockupUrl!, order.manualOrderNo ?? "Unknown"),
                    child: Container(
                      width: double.infinity,
                      height: 250,
                      margin: const EdgeInsets.only(bottom: 8),
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black38 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: TColors.getBorderColor(context), width: 1.5),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: order.mockupUrl!,
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
                const Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 24.0),
                      child: Text("Tap image to view full screen & download", style: TextStyle(fontSize: 10, color: TColors.textSecondary, fontStyle: FontStyle.italic)),
                    )
                ),
              ],

              _modalRow("Order Number", order.manualOrderNo ?? "N/A", isDark, isBold: true, valueColor: TColors.primary),
              _modalRow("Client Name", order.clientName, isDark, isBold: true),
              _modalRow("Organization", order.organization ?? "N/A", isDark),
              _modalRow("Phone", order.clientPhone ?? "N/A", isDark),
              _modalRow("Deadline", DateFormat('MMM dd, yyyy').format(order.deliveryDate), isDark),
              _modalRow("Status", isDeleted ? "DELETED" : order.status.toUpperCase(), isDark, isStatus: true, overrideColor: isDeleted ? Colors.grey : null),

              if ((order.state != null && order.state!.isNotEmpty) || (order.pincode != null && order.pincode!.isNotEmpty))
                _modalRow("State / PIN", "${order.state ?? 'N/A'} - ${order.pincode ?? 'N/A'}", isDark),

              const SizedBox(height: 24),
              Text("ITEMIZED PRODUCTS", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey.shade500, fontSize: 11, letterSpacing: 1)),
              const SizedBox(height: 12),

              ...order.products.map((item) {
                double iPrice = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
                int iQty = int.tryParse(item['qty']?.toString() ?? '0') ?? 0;
                double iTotal = double.tryParse(item['total']?.toString() ?? '0') ?? (iPrice * iQty);

                String neck = item['neckType'] ?? 'Not Specified';
                String type = item['productType'] ?? 'Not Specified';
                String sizes = item['sizeDescription']?.toString() ?? 'Not Specified';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black.withValues(alpha:0.03), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 16, color: isDark ? Colors.white70 : Colors.black54),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['productName'] ?? "Unknown", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: isDark ? Colors.white : Colors.black87)),
                            const SizedBox(height: 4),

                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(color: TColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                              child: Text(
                                  "Type: $type | Neck: $neck",
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: TColors.primary)
                              ),
                            ),

                            if (sizes.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text("Sizes: $sizes", style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                              ),

                            Text("${item['qty']} Units × ${currency.format(iPrice)}", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                      Text(currency.format(iTotal), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: isDark ? Colors.white : Colors.black87)),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),
              Text("FINANCIAL SUMMARY", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey.shade500, fontSize: 11, letterSpacing: 1)),
              const SizedBox(height: 12),

              _modalRow("Shipping Charge", currency.format(order.shippingCharge), isDark),
              _modalRow("Advance Paid", "- ${currency.format(order.advanceAmount)}", isDark, valueColor: Colors.orange),
              _modalRow("Grand Total", currency.format(order.totalAmount), isDark, isBold: true),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Balance Due", style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600)),
                  order.balanceDue <= 0
                      ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(6)),
                    child: const Text("FULLY PAID", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
                  )
                      : Text(currency.format(order.balanceDue), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.redAccent)),
                ],
              ),
              const SizedBox(height: 24),

              // ✅ PAYMENT BUTTONS
              if (order.balanceDue > 0 && !isDeleted) ...[
                Builder(
                  builder: (context) {
                    bool isPending = Get.find<SalesHistoryController>().hasPendingPayment(order);

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: OutlinedButton.icon(
                                onPressed: isPending ? null : () {
                                  Navigator.pop(context);
                                  _showPaymentDialog(context, order, Get.find<SalesHistoryController>());
                                },
                                icon: const Icon(Icons.edit_note_rounded, size: 18),
                                label: const Text("Update Due"),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  foregroundColor: isPending ? Colors.grey : TColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: ElevatedButton.icon(
                                onPressed: isPending ? null : () {
                                  HapticFeedback.mediumImpact();
                                  _confirmFullPayment(context, order);
                                },
                                icon: Icon(
                                    isPending ? Icons.hourglass_empty_rounded : Icons.done_all_rounded,
                                    size: 18,
                                    color: Colors.white
                                ),
                                label: Text(
                                    isPending ? "PENDING" : "FULLY PAID",
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  disabledBackgroundColor: Colors.grey.shade400,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Informational Text if Pending
                        if (isPending)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Text(
                              "A payment request is waiting for Manager approval.",
                              style: TextStyle(color: Colors.orange.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],

              if (order.paymentHistory.isNotEmpty) ...[
                Text("PAYMENT HISTORY", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey.shade500, fontSize: 11, letterSpacing: 1)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: order.paymentHistory.length,
                    separatorBuilder: (_, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Divider(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05), height: 1),
                    ),
                    itemBuilder: (context, index) {
                      final record = order.paymentHistory[index];
                      DateTime date = record['date'] is String
                          ? (DateTime.tryParse(record['date'].toString()) ?? DateTime.now())
                          : (record['date'] is DateTime ? record['date'] as DateTime : DateTime.now());
                      double amount = double.tryParse(record['amount'].toString()) ?? 0.0;

                      return Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Payment Recorded", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: isDark ? Colors.white : Colors.black87)),
                                Text(DateFormat('MMM dd • hh:mm a').format(date), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                              ],
                            ),
                          ),
                          Text("+ ${currency.format(amount)}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.green)),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
              ],

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isLocked
                          ? null
                          : () async {
                        Navigator.pop(context);
                        Get.delete<MarketingUploadController>();
                        await Get.to(() => MarketingUploadScreen(existingOrder: order));
                        Get.find<SalesHistoryController>().fetchHistory();
                      },
                      icon: Icon(isLocked ? Icons.lock_outline_rounded : Icons.edit_rounded, size: 18),
                      label: Text(isLocked ? "Locked" : "Edit Order", style: const TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isLocked ? Colors.grey : TColors.primary,
                        side: BorderSide(color: isLocked ? Colors.grey.shade300 : TColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white24 : Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text("Close", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, OrderModel order) {
    Get.defaultDialog(
      title: "Request Deletion?",
      titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      middleText: "This order is active. You must request approval from the Sales Manager to delete it.",
      textConfirm: "Send Request",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.orange,
      cancelTextColor: Colors.black87,
      onConfirm: () {
        Get.find<SalesHistoryController>().requestDeleteOrder(order);
        Get.back(); // Close the DefaultDialog
        Navigator.pop(context); // Close the bottom sheet that was open behind it
      },
    );
  }

  void _confirmCancelDelete(BuildContext context, OrderModel order) {
    Get.defaultDialog(
      title: "Cancel Deletion?",
      titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      middleText: "Do you want to withdraw the deletion request and keep this order active?",
      textConfirm: "Yes, Keep Order",
      textCancel: "No",
      confirmTextColor: Colors.white,
      buttonColor: Colors.blueAccent,
      cancelTextColor: Colors.black87,
      onConfirm: () {
        Get.find<SalesHistoryController>().cancelDeleteRequest(order.id);
        Get.back(); // Close the DefaultDialog
        Navigator.pop(context); // Close the bottom sheet that was open behind it
      },
    );
  }

  Widget _modalRow(String label, String value, bool isDark, {bool isStatus = false, bool isBold = false, Color? valueColor, Color? overrideColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: (isBold || isStatus) ? FontWeight.w900 : FontWeight.w700,
                fontSize: 14,
                color: overrideColor ?? (isStatus ? _getStatusColor(value) : (valueColor ?? (isDark ? Colors.white : Colors.black87))),
              ),
            ),
          ),
        ],
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
      case 'shipping':
      case 'shipped': return Colors.teal;
      case 'delivered': return Colors.green;
      case 'completed': return Colors.green;
      case 'rejected': return Colors.red;
      case 'pending': return const Color(0xFFFFC107);
      case 'placed': return const Color(0xFFFFC107);
      default: return Colors.grey;
    }
  }
}