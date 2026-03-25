import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../controllers/sales/sales_manager_controller.dart';
import '../../../controllers/sales/sales_manager_history_controller.dart';
import '../../../data/models/order_model.dart';
import '../../../utils/constants/colors.dart';
import 'sales_manager_order_details.dart';

class SalesManagerHistoryScreen extends StatelessWidget {
  const SalesManagerHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SalesManagerHistoryController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ NOTE: Initial filter state is handled by controller.onInit()

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
        elevation: 0,
        centerTitle: false,
        titleSpacing: 24,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: () => Get.back(),
        ),
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        title: Text(
          "Master Ledger",
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
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  onChanged: (val) => controller.searchOrders(val),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: "Search ID, Agent, or Client...",
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

                // Scrollable Status Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip(controller, "All", isDark),
                      _buildFilterChip(controller, "All NDO", isDark),
                      _buildFilterChip(controller, "Delivered", isDark),
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
                      // ✅ ADDED: Out SRC chip before Shipping
                      _buildFilterChip(controller, "Out SRC", isDark),
                      _buildFilterChip(controller, "Shipping", isDark),
                      _buildFilterChip(controller, "Shipped", isDark),
                      _buildFilterChip(controller, "Rejected", isDark),
                      _buildFilterChip(controller, "Trash", isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- 2. ORDERS LIST WITH REFRESH INDICATOR ---
          Expanded(
            child: RefreshIndicator(
              color: TColors.primary,
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              onRefresh: () async {
                HapticFeedback.lightImpact();
                try {
                  final mainController = Get.find<SalesManagerController>();
                  mainController.fetchOrderHistory();
                  mainController.fetchPendingOrders();
                  await Future.delayed(const Duration(milliseconds: 800));
                } catch (e) {
                  await Future.delayed(const Duration(milliseconds: 500));
                }
              },
              child: Obx(() {
                if (controller.isLoading.value) {
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
                              child: Icon(Icons.search_off_rounded, size: 48, color: isDark ? Colors.white54 : Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            Text("No orders match your criteria.", style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 40, top: 0),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: controller.displayedOrders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final order = controller.displayedOrders[index];
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Get.to(() => SalesManagerOrderDetails(order: order));
                      },
                      child: _buildRedesignedOrderCard(context, order, isDark),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildFilterChip(SalesManagerHistoryController controller, String label, bool isDark) {
    return Obx(() {
      bool isSelected = controller.currentFilter.value == label;

      Color baseColor = TColors.primary;
      if (label == 'All NDO') baseColor = Colors.deepOrange;
      else if (label == 'Out SRC') baseColor = Colors.indigoAccent; // ✅ Brand Color
      else if (label != 'All' && label != 'Trash') baseColor = _getStatusColor(label);
      else if (label == 'Trash') baseColor = Colors.red;

      int count = 0;
      List<OrderModel> baseList = controller.allOrders;

      if (label == 'All') {
        count = baseList.length;
      } else if (label == 'All NDO') {
        count = baseList.where((o) {
          String s = o.status.toLowerCase();
          return s != 'shipped' && s != 'delivered' && s != 'completed';
        }).length;
      } else if (label == 'Trash') {
        count = baseList.where((o) => o.isDeleted || o.status.toLowerCase() == 'deleted').length;
      } else {
        count = baseList.where((o) => o.status.toLowerCase() == label.toLowerCase()).length;
      }

      return Padding(
        padding: const EdgeInsets.only(right: 8, top: 8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                controller.filterByStatus(label);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? baseColor : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSelected ? baseColor : (isDark ? Colors.white10 : Colors.black.withValues(alpha:0.05))),
                  boxShadow: isSelected ? [BoxShadow(color: baseColor.withValues(alpha:0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                ),
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

            Positioned(
              top: -6,
              right: -6,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                    color: isSelected ? Colors.white : baseColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
                        width: 2
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))
                    ]
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? baseColor : Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildRedesignedOrderCard(BuildContext context, OrderModel order, bool isDark) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final Color statusColor = _getStatusColor(order.status);

    final int qty = order.quantity;
    final double unitPrice = qty > 0 ? (order.totalAmount / qty) : 0.0;

    String displayLocation = "";
    if (order.state != null && order.state!.isNotEmpty) {
      displayLocation = order.state!;
    } else if (order.clientAddress != null && order.clientAddress!.isNotEmpty) {
      displayLocation = order.clientAddress!;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
            width: 1.2
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orange, width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  order.manualOrderNo ?? "---",
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showHistoryDialog(context, order, isDark);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.history_rounded, size: 14, color: isDark ? Colors.white70 : Colors.black54),
                    ),
                  ),
                  Text(
                    order.status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.5),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            order.clientName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87),
          ),

          if (displayLocation.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 2),
              child: Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 12, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      displayLocation,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          Text(
            order.productName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.person, size: 12, color: Colors.grey.shade500),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  order.marketingPersonName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ),
              Icon(Icons.access_time_rounded, size: 10, color: Colors.grey.shade500),
              const SizedBox(width: 3),
              Text(
                DateFormat('MMM dd • hh:mm a').format(order.orderDate),
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, thickness: 0.5)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$qty × ${currency.format(unitPrice)}",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54),
              ),
              Text(
                currency.format(order.totalAmount),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87),
              ),
            ],
          ),
        ],
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
      case 'packing':
      case 'packed': return Colors.purple;
      case 'out src': return Colors.indigoAccent; // ✅ ADDED
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