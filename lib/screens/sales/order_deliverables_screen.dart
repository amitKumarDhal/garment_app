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
              // --- 2. ACTIONABLE SUMMARY CARDS ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch, // Makes both cards equal height
                    children: [
                      // --- Card 1: Pre-Stitching Breakdown ---
                      Expanded(
                        child: Obx(() {
                          int units = controller.totalNotStitchedUnits;
                          int orders = controller.notStitchedOrders.length;
                          final pipeline = controller.stageUnitBreakdown;

                          // ✅ Filter only the pre-stitching stages for the breakdown
                          final preStitchStages = pipeline.where((s) =>
                              ['Approved', 'Cutting', 'Printing', 'Printed'].contains(s['name'])
                          ).toList();

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
                                // Top Header & Icon
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
                                      child: const Icon(Icons.cut_rounded, size: 16, color: Colors.blue),
                                    ),
                                    Text("$orders Orders", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey.shade500)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Total Metric
                                Text("$units", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, height: 1.1)),
                                const SizedBox(height: 4),
                                Text("Pre-Stitching", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),

                                const SizedBox(height: 12),
                                Divider(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05), height: 1),
                                const SizedBox(height: 12),

                                // ✅ Line by Line Status Breakdown
                                ...preStitchStages.map((stage) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(width: 6, height: 6, decoration: BoxDecoration(color: stage['color'], shape: BoxShape.circle)),
                                            const SizedBox(width: 6),
                                            Text(stage['name'], style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                        Text("${stage['count']}", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isDark ? Colors.white70 : Colors.black87)),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        }),
                      ),

                      const SizedBox(width: 16),

                      // --- Card 2: Post-Stitching & Ready to Ship Breakdown ---
                      Expanded(
                        child: Obx(() {
                          int units = controller.totalReadyUnits;
                          int orders = controller.readyForDispatchOrders.length;
                          final pipeline = controller.stageUnitBreakdown;

                          // ✅ Filter the post-stitching stages to balance the UI and provide full tracking
                          final postStitchStages = pipeline.where((s) =>
                              ['Stitching', 'Stitched', 'Packing', 'Packed'].contains(s['name'])
                          ).toList();

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
                                // Top Header & Icon
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                                      child: const Icon(Icons.local_shipping_rounded, size: 16, color: Colors.white),
                                    ),
                                    Text("$orders Orders", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white70)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Total Metric
                                Text("$units", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
                                const SizedBox(height: 4),
                                const Text("Ready to Ship", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),

                                const SizedBox(height: 12),
                                Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
                                const SizedBox(height: 12),

                                // ✅ Line by Line Status Breakdown
                                ...postStitchStages.map((stage) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle)),
                                            const SizedBox(width: 6),
                                            Text(stage['name'], style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                        Text("${stage['count']}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // --- 3. CRITICAL ALERTS ---
              Obx(() {
                if (controller.atRiskOrders.isEmpty) return const SizedBox.shrink();

                var sortedOrders = List.from(controller.atRiskOrders);
                DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFF9F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- HEADER ---
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // ✅ FIX 1: Wrap Title in Expanded so it doesn't push the badge off-screen
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline_rounded, color: Colors.redAccent.shade400, size: 18),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        "CRITICAL DEADLINES",
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.redAccent.shade400,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8), // Gap
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.shade400,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "${sortedOrders.length} URGENT",
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(color: isDark ? Colors.white10 : Colors.red.withValues(alpha: 0.1), height: 1),

                        // --- SCROLLABLE LIST ---
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 280),
                          child: Scrollbar(
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              physics: const BouncingScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: sortedOrders.length,
                              separatorBuilder: (context, index) => Divider(
                                color: isDark ? Colors.white10 : Colors.red.withValues(alpha: 0.05),
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                              ),
                              itemBuilder: (context, index) {
                                var order = sortedOrders[index];
                                DateTime deadline = DateTime(order.deliveryDate.year, order.deliveryDate.month, order.deliveryDate.day);
                                int daysLeft = deadline.difference(today).inDays;

                                bool isOverdue = daysLeft < 0;
                                bool isDueToday = daysLeft == 0;
                                bool isPacked = order.status.toLowerCase() == 'packed';

                                Color alertColor = isPacked
                                    ? Colors.green
                                    : (isOverdue ? Colors.redAccent : (isDueToday ? Colors.orange : Colors.amber));

                                return GestureDetector(
                                  onTap: () => Get.to(() => SalesManagerOrderDetails(order: order)),
                                  behavior: HitTestBehavior.opaque,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 3,
                                          height: 32,
                                          decoration: BoxDecoration(color: alertColor, borderRadius: BorderRadius.circular(2)),
                                        ),
                                        const SizedBox(width: 12),

                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              RichText(
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                text: TextSpan(
                                                  style: const TextStyle(fontFamily: 'Urbanist'),
                                                  children: [
                                                    TextSpan(
                                                      text: "${order.manualOrderNo ?? order.id?.substring(0,5)} ",
                                                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                                                    ),
                                                    TextSpan(
                                                      text: "• ${order.clientName}",
                                                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              // ✅ FIX: Replaced Flexible with a standard Row,
                                              // and wrapped ONLY the text inside an Expanded.
                                              Row(
                                                children: [
                                                  Icon(Icons.inventory_2_outlined, size: 12, color: Colors.grey.shade500),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      "${order.quantity} Units stuck in ${order.status.toUpperCase()}",
                                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),                                        const SizedBox(width: 8),

                                        // ✅ RIGHT PILL
                                        Builder(
                                            builder: (context) {
                                              String text = isPacked
                                                  ? "READY: ${daysLeft < 0 ? '${daysLeft.abs()} LATE' : (daysLeft == 0 ? 'TODAY' : 'IN $daysLeft DAYS')}"
                                                  : (isOverdue ? "${daysLeft.abs()} DAYS LATE" : (isDueToday ? "DUE TODAY" : "In $daysLeft days"));

                                              if (isOverdue || isDueToday || isPacked) {
                                                return Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: alertColor.withValues(alpha: 0.05),
                                                    border: Border.all(color: alertColor.withValues(alpha: 0.5)),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    text.toUpperCase(),
                                                    style: TextStyle(color: alertColor, fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                                  ),
                                                );
                                              } else {
                                                return Text(text, style: TextStyle(color: alertColor, fontSize: 10, fontWeight: FontWeight.w800));
                                              }
                                            }
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(Icons.chevron_right_rounded, color: Colors.grey.shade600, size: 18),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Divider(color: isDark ? Colors.white10 : Colors.red.withValues(alpha: 0.1), height: 1),
                        // --- FOOTER ---
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Text(
                              "Tap any order to update production status",
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              /// --- 4. DELIVERY SCHEDULE (Compact Version) ---
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                  border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.transparent)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- SLIM HEADER ---
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Obx(() => Text(
                            DateFormat('EEEE, dd MMM').format(controller.selectedDate.value),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87),
                          )),
                          Obx(() => Text(
                            "${controller.ordersForSelectedDate.length} Targets",
                            style: TextStyle(color: TColors.primary, fontWeight: FontWeight.w800, fontSize: 11),
                          ))
                        ],
                      ),
                    ),

                    // --- COMPACT DATE SELECTOR ---
                    SizedBox(
                      height: 65, // Reduced from 80
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: 30,
                        itemBuilder: (context, index) {
                          DateTime date = DateTime.now().subtract(const Duration(days: 3)).add(Duration(days: index));
                          bool isToday = date.day == DateTime.now().day && date.month == DateTime.now().month;

                          return Obx(() {
                            bool isSelected = controller.selectedDate.value.year == date.year &&
                                controller.selectedDate.value.month == date.month &&
                                controller.selectedDate.value.day == date.day;

                            return GestureDetector(
                              onTap: () => controller.selectDate(date),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 45, // Narrower pills
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? TColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? TColors.primary : (isDark ? Colors.white10 : Colors.grey.shade200),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      DateFormat('EEE').format(date).toUpperCase(),
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: isSelected ? Colors.white70 : Colors.grey),
                                    ),
                                    Text(
                                      DateFormat('dd').format(date),
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87)),
                                    ),
                                    if (isToday && !isSelected)
                                      Container(margin: const EdgeInsets.only(top: 2), width: 3, height: 3, decoration: const BoxDecoration(color: TColors.primary, shape: BoxShape.circle))
                                  ],
                                ),
                              ),
                            );
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- HIGH-DENSITY ORDER LIST ---
                    Obx(() {
                      if (controller.ordersForSelectedDate.isEmpty) {
                        return const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text("No targets for today", style: TextStyle(color: Colors.grey, fontSize: 12))));
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24).copyWith(bottom: 100),
                        itemCount: controller.ordersForSelectedDate.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8), // Tighter spacing
                        itemBuilder: (context, index) {
                          var order = controller.ordersForSelectedDate[index];
                          Color statusColor = _getStatusColor(order.status);

                          return GestureDetector(
                            onTap: () => Get.to(() => SalesManagerOrderDetails(order: order)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  // Status Indicator Dot
                                  Container(width: 4, height: 30, decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2))),
                                  const SizedBox(width: 12),

                                  // Client & Product Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(order.clientName, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: isDark ? Colors.white : Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        Text("${order.quantity} Units • ${order.productName}", style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),

                                  // Price & Status Label
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(currencyFormat.format(order.totalAmount), style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13, fontWeight: FontWeight.w900)),
                                      const SizedBox(height: 2),
                                      Text(order.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 8, fontWeight: FontWeight.w900)),
                                    ],
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey.shade400),
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