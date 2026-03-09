import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/sales/deliverables_controller.dart';
import '../../utils/constants/colors.dart';
// ✅ FIXED IMPORT: Now routing to the Details screen instead of Approval screen
import 'manager/sales_manager_order_details.dart';

class OrderDeliverablesScreen extends StatelessWidget {
  const OrderDeliverablesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DeliverablesController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        title: Text(
          "Order Deliverables",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: TColors.primary,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        onRefresh: () async {
          await controller.smController.fetchMonthlyStats();
          await Future.delayed(const Duration(milliseconds: 800));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // --- 0. PRE-STITCHING QUEUE (NOT STITCHED) ---
              Obx(() {
                final notStitchedOrders = controller.notStitchedOrders;
                if (notStitchedOrders.isEmpty) return const SizedBox.shrink();

                int totalNotStitchedUnits = controller.totalNotStitchedUnits;

                return Container(
                  margin: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1565C0), const Color(0xFF0D47A1)]
                            : [Colors.blue.shade50, Colors.blue.shade100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.4), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))
                      ]
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                            Icons.precision_manufacturing_rounded,
                            color: isDark ? Colors.blue.shade200 : Colors.blue.shade700,
                            size: 24
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Pre-Stitching Queue",
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.blue.shade900,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Approved, Cutting, Printing & Printed",
                              style: TextStyle(
                                color: isDark ? Colors.blue.shade100 : Colors.blue.shade800,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "$totalNotStitchedUnits",
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.blue.shade900,
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                              height: 1,
                            ),
                          ),
                          Text(
                            "Units (${notStitchedOrders.length} Orders)",
                            style: TextStyle(
                              color: isDark ? Colors.blue.shade200 : Colors.blue.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              }),

              // --- 1. CRITICAL ALERTS CONSOLE ---
              Obx(() {
                if (controller.atRiskOrders.isEmpty) return const SizedBox.shrink();

                var sortedOrders = List.from(controller.atRiskOrders);
                DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

                return Container(
                  margin: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 24),
                  decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: Colors.redAccent.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))
                      ]
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- HEADER ---
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.1),
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
                            border: Border(bottom: BorderSide(color: Colors.redAccent.withValues(alpha: 0.2)))
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "CRITICAL DEADLINES",
                              style: TextStyle(
                                color: isDark ? Colors.red.shade400 : Colors.red.shade700,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                "${sortedOrders.length} URGENT",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10),
                              ),
                            )
                          ],
                        ),
                      ),

                      // --- LIST OF URGENT ORDERS ---
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: sortedOrders.length > 3 ? 240 : (sortedOrders.length * 80).toDouble()),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          physics: const BouncingScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: sortedOrders.length,
                          separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade200),
                          itemBuilder: (context, index) {
                            var order = sortedOrders[index];
                            DateTime deadline = DateTime(order.deliveryDate.year, order.deliveryDate.month, order.deliveryDate.day);
                            int daysLeft = deadline.difference(today).inDays;

                            bool isOverdue = daysLeft < 0;
                            bool isDueToday = daysLeft == 0;

                            return InkWell(
                              // ✅ FIXED ROUTING HERE
                              onTap: () => Get.to(() => SalesManagerOrderDetails(order: order)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    // Urgency Indicator Pill
                                    Container(
                                      width: 4,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isOverdue ? Colors.red : (isDueToday ? Colors.orange : Colors.amber),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Order Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                order.manualOrderNo?.isNotEmpty == true ? order.manualOrderNo! : "#${order.id?.substring(0,5)}",
                                                style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, fontSize: 14),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text("• ${order.clientName}", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.inventory_2_outlined, size: 12, color: Colors.grey.shade500),
                                              const SizedBox(width: 4),
                                              Text("${order.quantity} Units stuck in ", style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                              Text(order.status.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Time Remaining / Overdue Status
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        if (isOverdue)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), border: Border.all(color: Colors.red.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(4)),
                                            child: Text("${daysLeft.abs()} DAYS LATE", style: const TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.w900)),
                                          )
                                        else if (isDueToday)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), border: Border.all(color: Colors.orange.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(4)),
                                            child: const Text("DUE TODAY", style: TextStyle(color: Colors.orange, fontSize: 9, fontWeight: FontWeight.w900)),
                                          )
                                        else
                                          Text("In $daysLeft days", style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),

                                        const SizedBox(height: 4),
                                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // --- FOOTER NOTE ---
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14))),
                        child: Center(
                          child: Text("Tap any order to update production status", style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
                        ),
                      )
                    ],
                  ),
                );
              }),

              // --- 2. DATE SELECTOR TIMELINE ---
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: SizedBox(
                  height: 85,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: 30, // Show next 30 days
                    itemBuilder: (context, index) {
                      DateTime date = DateTime.now().subtract(const Duration(days: 3)).add(Duration(days: index));

                      return Obx(() {
                        bool isSelected = controller.selectedDate.value.year == date.year &&
                            controller.selectedDate.value.month == date.month &&
                            controller.selectedDate.value.day == date.day;

                        bool isToday = date.day == DateTime.now().day && date.month == DateTime.now().month;

                        return GestureDetector(
                          onTap: () => controller.selectDate(date),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 12),
                            width: 65,
                            decoration: BoxDecoration(
                              color: isSelected ? TColors.primary : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? TColors.primary : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected ? [BoxShadow(color: TColors.primary.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))] : [],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('MMM').format(date).toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected ? Colors.white70 : (isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('dd').format(date),
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                  ),
                                ),
                                if (isToday)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    width: 5, height: 5,
                                    decoration: BoxDecoration(
                                        color: isSelected ? Colors.white : TColors.primary,
                                        shape: BoxShape.circle
                                    ),
                                  )
                              ],
                            ),
                          ),
                        );
                      });
                    },
                  ),
                ),
              ),

              // --- 3. ORDERS FOR SELECTED DATE HEADER ---
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Target Deliveries",
                          style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Obx(() => Text(
                          DateFormat('EEEE, dd MMM').format(controller.selectedDate.value),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87),
                        )),
                      ],
                    ),
                    Obx(() => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: TColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10)
                      ),
                      child: Text(
                        "${controller.ordersForSelectedDate.length} Orders",
                        style: TextStyle(color: TColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ))
                  ],
                ),
              ),

              // --- 4. ORDERS LIST FOR SELECTED DATE ---
              Obx(() {
                if (controller.ordersForSelectedDate.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 40, bottom: 60),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03), shape: BoxShape.circle),
                            child: Icon(Icons.event_available_rounded, size: 40, color: Colors.grey.withValues(alpha: 0.5)),
                          ),
                          const SizedBox(height: 16),
                          Text("Clear schedule!", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w800, fontSize: 18)),
                          const SizedBox(height: 4),
                          Text("No deliverables set for this date.", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500, fontSize: 13)),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4).copyWith(bottom: 100),
                  itemCount: controller.ordersForSelectedDate.length,
                  itemBuilder: (context, index) {
                    var order = controller.ordersForSelectedDate[index];
                    Color statusColor = _getStatusColor(order.status);

                    return GestureDetector(
                      // ✅ FIXED ROUTING HERE TOO
                      onTap: () => Get.to(() => SalesManagerOrderDetails(order: order)),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04), width: 1.5),
                          boxShadow: [
                            if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 5))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Row: Client & Status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    order.clientName,
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : Colors.black87),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    order.status.toUpperCase(),
                                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Middle Row: Items & Agent
                            Row(
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(
                                  "${order.quantity} Items",
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text("•", style: TextStyle(color: Colors.grey.shade400)),
                                ),
                                Expanded(
                                  child: Text(
                                    order.productName,
                                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 12, fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                            ),

                            // Bottom Row: Amount & Action
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Total Value", style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold)),
                                    Text(
                                      currencyFormat.format(order.totalAmount),
                                      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15, fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text("Manage", style: TextStyle(color: TColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(color: TColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                                      child: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: TColors.primary),
                                    )
                                  ],
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Colors.blue;
      case 'cutting': return Colors.orange;
      case 'printing': return Colors.indigo;
      case 'printed': return Colors.cyan;
      case 'stitching': return Colors.amber;
      case 'stitched': return Colors.brown;
      case 'packing':
      case 'packed': return Colors.purple;
      case 'shipping':
      case 'shipped': return Colors.teal;
      case 'delivered': return Colors.green;
      case 'completed': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }
}