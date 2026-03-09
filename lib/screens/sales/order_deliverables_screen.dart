import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/sales/deliverables_controller.dart';
import '../../utils/constants/colors.dart';
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
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
        elevation: 0,
        centerTitle: false,
        titleSpacing: 24,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        title: Text(
          "Logistics Hub",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w900,
            fontSize: 22,
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
              // --- 1. PIPELINE OVERVIEW ---
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Text(
                        "FLOOR PIPELINE",
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    Obx(() {
                      final pipeline = controller.stageUnitBreakdown;
                      return SizedBox(
                        height: 95,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: pipeline.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final stage = pipeline[index];
                            final int count = stage['count'];
                            final bool isEmpty = count == 0;
                            final Color stageColor = stage['color'];

                            return Container(
                              width: 100,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isEmpty
                                    ? (isDark ? const Color(0xFF1E1E1E) : Colors.white)
                                    : stageColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isEmpty
                                      ? (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05))
                                      : stageColor.withValues(alpha: 0.3),
                                  width: isEmpty ? 1 : 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        stage['icon'],
                                        size: 18,
                                        color: isEmpty ? Colors.grey.shade400 : stageColor,
                                      ),
                                      Text(
                                        "$count",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: isEmpty ? Colors.grey.shade500 : (isDark ? Colors.white : Colors.black87),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    stage['name'].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: isEmpty ? Colors.grey.shade500 : stageColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // --- 2. ACTIONABLE SUMMARY CARDS ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    // Secondary Metric: Pre-Stitching
                    Expanded(
                      child: Obx(() {
                        int units = controller.totalNotStitchedUnits;
                        int orders = controller.notStitchedOrders.length;
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                            boxShadow: [if (!isDark) BoxShadow(color: Colors.blue.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.cut_rounded, size: 16, color: Colors.blue),
                              ),
                              const SizedBox(height: 12),
                              Text("$units", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, height: 1.1)),
                              const SizedBox(height: 4),
                              Text("Pre-Stitching", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                              Text("$orders Orders", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                            ],
                          ),
                        );
                      }),
                    ),
                    const SizedBox(width: 16),
                    // Primary Metric: Ready to Ship (High Emphasis)
                    Expanded(
                      child: Obx(() {
                        int units = controller.totalReadyUnits;
                        int orders = controller.readyForDispatchOrders.length;
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: const Color(0xFF0083B0).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                                child: const Icon(Icons.local_shipping_rounded, size: 16, color: Colors.white),
                              ),
                              const SizedBox(height: 12),
                              Text("$units", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
                              const SizedBox(height: 4),
                              const Text("Ready to Ship", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                              Text("$orders Orders", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white70)),
                            ],
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // --- 3. CRITICAL ALERTS ---
              Obx(() {
                if (controller.atRiskOrders.isEmpty) return const SizedBox.shrink();

                var sortedOrders = List.from(controller.atRiskOrders);
                DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.redAccent.shade400, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            "AT RISK (${sortedOrders.length})",
                            style: TextStyle(
                              color: Colors.redAccent.shade400,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: Scrollbar(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          physics: const BouncingScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: sortedOrders.length,
                          itemBuilder: (context, index) {
                            var order = sortedOrders[index];
                            DateTime deadline = DateTime(order.deliveryDate.year, order.deliveryDate.month, order.deliveryDate.day);
                            int daysLeft = deadline.difference(today).inDays;
                            bool isOverdue = daysLeft < 0;
                            bool isDueToday = daysLeft == 0;

                            return GestureDetector(
                              onTap: () => Get.to(() => SalesManagerOrderDetails(order: order)),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                                  boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border(left: BorderSide(color: Colors.redAccent.shade400, width: 4)),
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                order.clientName,
                                                style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87, fontSize: 14),
                                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "ID: ${order.manualOrderNo ?? order.id?.substring(0,5)} • Stuck in ${order.status.toUpperCase()}",
                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                  color: (isOverdue ? Colors.red : (isDueToday ? Colors.orange : Colors.amber)).withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(6)
                                              ),
                                              child: Text(
                                                isOverdue ? "${daysLeft.abs()} DAYS LATE" : (isDueToday ? "DUE TODAY" : "IN $daysLeft DAYS"),
                                                style: TextStyle(
                                                  color: isOverdue ? Colors.red : (isDueToday ? Colors.orange.shade700 : Colors.amber.shade700),
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }),

              // --- 4. DELIVERY SCHEDULE ---
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                  border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.transparent)),
                  boxShadow: [
                    if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, -4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Delivery Schedule",
                                style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Obx(() => Text(
                                DateFormat('EEEE, dd MMM').format(controller.selectedDate.value),
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: -0.5),
                              )),
                            ],
                          ),
                          Obx(() => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20)
                            ),
                            child: Text(
                              "${controller.ordersForSelectedDate.length} Targets",
                              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w800, fontSize: 11),
                            ),
                          ))
                        ],
                      ),
                    ),

                    // Modern Pill Date Selector
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: 30, // 30 days window
                        itemBuilder: (context, index) {
                          DateTime date = DateTime.now().subtract(const Duration(days: 3)).add(Duration(days: index));
                          bool isToday = date.day == DateTime.now().day && date.month == DateTime.now().month;

                          return Obx(() {
                            bool isSelected = controller.selectedDate.value.year == date.year &&
                                controller.selectedDate.value.month == date.month &&
                                controller.selectedDate.value.day == date.day;

                            return GestureDetector(
                              onTap: () => controller.selectDate(date),
                              child: Container(
                                width: 55,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.black87 : Colors.transparent,
                                  borderRadius: BorderRadius.circular(30), // Pill shape
                                  border: Border.all(
                                    color: isSelected ? Colors.black87 : (isDark ? Colors.white10 : Colors.grey.shade300),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      DateFormat('EEE').format(date).toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected ? Colors.white70 : (isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('dd').format(date),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                      ),
                                    ),
                                    if (isToday && !isSelected)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        width: 4, height: 4,
                                        decoration: BoxDecoration(color: TColors.primary, shape: BoxShape.circle),
                                      )
                                  ],
                                ),
                              ),
                            );
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Order List
                    Obx(() {
                      if (controller.ordersForSelectedDate.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 40, bottom: 80),
                          child: Center(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey.shade100, shape: BoxShape.circle),
                                  child: Icon(Icons.done_all_rounded, size: 32, color: Colors.grey.shade400),
                                ),
                                const SizedBox(height: 16),
                                Text("Schedule Clear", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w800, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text("No targets due for this date.", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500, fontSize: 12)),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24).copyWith(bottom: 120),
                        itemCount: controller.ordersForSelectedDate.length,
                        itemBuilder: (context, index) {
                          var order = controller.ordersForSelectedDate[index];
                          Color statusColor = _getStatusColor(order.status);

                          return GestureDetector(
                            onTap: () => Get.to(() => SalesManagerOrderDetails(order: order)),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF121212) : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                                boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(left: BorderSide(color: statusColor, width: 5)),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              order.clientName,
                                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: isDark ? Colors.white : Colors.black87),
                                              maxLines: 1, overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              order.status.toUpperCase(),
                                              style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                                            child: Icon(Icons.inventory_2_rounded, size: 14, color: Colors.grey.shade600),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "${order.quantity} Units",
                                                  style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 12, fontWeight: FontWeight.w800),
                                                ),
                                                Text(
                                                  order.productName,
                                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600),
                                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                "Value",
                                                style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w600),
                                              ),
                                              Text(
                                                currencyFormat.format(order.totalAmount),
                                                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14, fontWeight: FontWeight.w900),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ],
                ),
              ),
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