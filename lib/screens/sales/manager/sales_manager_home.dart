// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/sales/sales_manager_controller.dart';
import '../../../utils/constants/colors.dart';
import '../../../data/models/order_model.dart';
import '../order_deliverables_screen.dart';
import 'order_approval_screen.dart';
import 'sales_manager_history_screen.dart';
import 'sales_manager_approvals.dart';
import '../../notifications/notification_screen.dart';
import '../../../controllers/notifications/notification_controller.dart';
import '../../profile/profile_screen.dart';

class SalesManagerHome extends StatelessWidget {
  const SalesManagerHome({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SalesManagerController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchAllData();
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            titleSpacing: 20,
            systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
            title: Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    _getGreeting(),
                    style: TextStyle(
                        color: isDark ? TColors.textWhite : TColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold
                    )
                ),
                Row(
                  children: [
                    Text(
                        controller.managerName.value,
                        style: TextStyle(
                            color: isDark ? Colors.blue.shade200 : TColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800
                        )
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.deepPurpleAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.deepPurpleAccent.withValues(alpha: 0.5)),
                      ),
                      child: const Text(
                        "SM",
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.deepPurpleAccent),
                      ),
                    ),
                  ],
                ),
              ],
            )),
            centerTitle: false,
            actions: [
              Obx(() {
                final notifController = Get.put(NotificationController());
                int unread = notifController.unreadCount.value;
                return _buildCircularAction(
                  Icons.notifications_none_rounded,
                  isDark,
                      () => Get.to(() => const NotificationScreen()),
                  notificationCount: unread,
                );
              }),
              Padding(
                padding: const EdgeInsets.only(right: 20, left: 8),
                child: GestureDetector(
                  onTap: () => Get.to(() => const ProfileScreen()),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? TColors.textWhite.withValues(alpha: 0.1) : TColors.primary.withValues(alpha: 0.1),
                      border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.1) : TColors.primary.withValues(alpha: 0.2),
                          width: 1
                      ),
                    ),
                    child: Icon(Icons.person_rounded, size: 22, color: isDark ? Colors.white : TColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => controller.fetchAllData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. HEADER ROW (WITH TIMEFRAME SELECTOR) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      "Sales",
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black
                      )
                  ),
                  const SizedBox(width: 8),
                  // ✅ SAFE WRAPPER: Prevents overflow on small screens if date is too long
                  Expanded(
                    child: Obx(() => Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // Dropdown Trigger
                        GestureDetector(
                          onTap: () => _showTimeframeSelector(context, controller, isDark),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2C2C2E) : Colors.grey[200],
                                borderRadius: BorderRadius.circular(20)
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                    controller.selectedTimeframe.value,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : Colors.black
                                    )
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: isDark ? Colors.white : Colors.black),
                              ],
                            ),
                          ),
                        ),
                        // Show specific month picker ONLY if 'Monthly' is selected
                        if (controller.selectedTimeframe.value == 'Monthly')
                          GestureDetector(
                            onTap: () => _pickMonth(context, controller),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                  color: TColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: TColors.primary.withValues(alpha: 0.3))
                              ),
                              child: Text(
                                DateFormat('MMM yyyy').format(controller.selectedMonth.value),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: TColors.primary),
                              ),
                            ),
                          )
                      ],
                    )),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- 2. STAT CARDS ---
              Row(
                children: [
                  Expanded(
                    child: Obx(() => _buildStatCard(
                        context,
                        "Total Sales",
                        "₹${(controller.totalRevenue.value / 100000).toStringAsFixed(2)}L",
                        [const Color(0xFF81C784), const Color(0xFF388E3C)],
                        Icons.currency_rupee_rounded
                    )),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(() => _buildStatCard(
                        context,
                        "Total Orders",
                        controller.totalOrdersCount.value.toString(),
                        [const Color(0xFF64B5F6), const Color(0xFF1976D2)],
                        Icons.shopping_bag_outlined
                    )),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- 3. PRODUCTION PIPELINE ---
              GestureDetector(
                onTap: () => Get.to(() => const SalesManagerHistoryScreen(), arguments: "Approved"),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xFFFFB74D), Color(0xFFF57C00)]
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 6)
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        Positioned(
                            top: -11,
                            right: -11,
                            child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white.withValues(alpha: 0.05)
                            )
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                      "Production Pipeline",
                                      style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5
                                      )
                                  ),
                                  Obx(() => Text(
                                      "${controller.approvedOrders.length} Approved",
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900
                                      )
                                  )),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(height: 1, color: Colors.black12),
                              const SizedBox(height: 16),
                              Obx(() {
                                int cutting = controller.activeOrders.where((o) => o.status == 'Cutting').length;
                                int stitching = controller.activeOrders.where((o) => o.status == 'Stitching').length;
                                int packing = controller.activeOrders.where((o) => o.status == 'Packing').length;
                                return Row(
                                  children: [
                                    _buildCompactStage("Cut", cutting),
                                    _buildDivider(),
                                    _buildCompactStage("Stitch", stitching),
                                    _buildDivider(),
                                    _buildCompactStage("Pack", packing),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          shape: BoxShape.circle
                                      ),
                                      child: const Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.black,
                                          size: 16
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- 4. SHIPPING & GST ROW ---
              Row(
                children: [
                  Expanded(
                    child: Obx(() => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.teal.withValues(alpha: 0.3), width: 1.2),
                        boxShadow: [
                          if (!isDark) BoxShadow(color: Colors.teal.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.15), shape: BoxShape.circle),
                            child: const Icon(Icons.local_shipping_rounded, color: Colors.teal, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Shipping", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(
                                  NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹', decimalDigits: 1).format(controller.totalShippingCollected.value),
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3), width: 1.2),
                        boxShadow: [
                          if (!isDark) BoxShadow(color: Colors.pinkAccent.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.pinkAccent.withValues(alpha: 0.15), shape: BoxShape.circle),
                            child: const Icon(Icons.account_balance_rounded, color: Colors.pinkAccent, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Total GST", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(
                                  NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹', decimalDigits: 1).format(controller.totalGstCollected.value),
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- 5. UNITS & DELIVERABLES ROW ---
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2), width: 1.2),
                        boxShadow: [
                          if (!isDark)
                            BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.12), shape: BoxShape.circle),
                            child: const Icon(Icons.inventory_2_rounded, color: Colors.blueAccent, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Obx(() => Text(
                                  NumberFormat('#,##,###').format(controller.totalUnitsSold.value),
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )),
                                const SizedBox(height: 2),
                                // ✅ OVERFLOW FIX: Wrapped dynamic text in Expanded
                                Row(
                                  children: [
                                    Text("Units Sold ", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w600)),
                                    Expanded(
                                      child: Obx(() => Text(
                                        controller.selectedTimeframe.value == 'Monthly'
                                            ? "(${DateFormat('MMM').format(controller.selectedMonth.value)})"
                                            : "(${controller.selectedTimeframe.value})",
                                        style: TextStyle(color: Colors.blueAccent.withValues(alpha: 0.8), fontSize: 9, fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      )),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: GestureDetector(
                      onTap: () => Get.to(() => const OrderDeliverablesScreen()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark ? [const Color(0xFF2C1E3A), const Color(0xFF1F112B)] : [const Color(0xFFF3E5F5), const Color(0xFFE1BEE7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3), width: 1.2),
                          boxShadow: [
                            BoxShadow(color: Colors.purpleAccent.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 3))
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.purpleAccent.withValues(alpha: 0.2), shape: BoxShape.circle),
                              child: const Icon(Icons.calendar_month_rounded, color: Colors.purple, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Deliverables", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14, fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Obx(() {
                                    final count = controller.urgentDeliverablesCount;
                                    if (count == 0) {
                                      return Text("All on track", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 11, fontWeight: FontWeight.w600));
                                    }
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(6)),
                                      child: Text("$count URGENT", style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Obx(() {
                if (controller.deletionRequests.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 8),
                        const Text("Pending Deletions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.redAccent)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
                          child: Text(controller.deletionRequests.length.toString(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 110,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: controller.deletionRequests.length,
                        itemBuilder: (context, index) {
                          return _buildDeletionRequestCard(context, controller.deletionRequests[index], isDark, controller);
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              }),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Requires Action", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  TextButton(
                    onPressed: () => Get.to(() => const SalesManagerApprovals()),
                    style: TextButton.styleFrom(foregroundColor: isDark ? TColors.light : TColors.dark, padding: EdgeInsets.zero),
                    child: const Row(
                      children: [
                        Text("See All", style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Obx(() {
                if (controller.pendingOrders.isEmpty) {
                  return _buildEmptyState(isDark, "No pending orders", Icons.check_circle_outline);
                }
                return SizedBox(
                  height: 130,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: controller.pendingOrders.take(5).length,
                    itemBuilder: (context, index) {
                      return _buildHorizontalPendingOrderCard(context, controller.pendingOrders[index], isDark);
                    },
                  ),
                );
              }),
              const SizedBox(height: 32),

              _buildTopAssociatesLeaderboard(context, isDark, controller),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ HELPER: Timeframe Bottom Sheet
  void _showTimeframeSelector(BuildContext context, SalesManagerController controller, bool isDark) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Select Timeframe", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: controller.timeframes.map((tf) {
                return Obx(() {
                  bool isSelected = controller.selectedTimeframe.value == tf;
                  return GestureDetector(
                    onTap: () {
                      controller.setTimeframe(tf);
                      Get.back();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? TColors.primary : (isDark ? Colors.white10 : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? TColors.primary : Colors.transparent),
                      ),
                      child: Text(
                        tf,
                        style: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                });
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAssociatesLeaderboard(BuildContext context, bool isDark, SalesManagerController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bar_chart_rounded, color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                "Team Leaderboard",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Obx(() {
            if (controller.topAgents.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Text("No sales recorded for this period.", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: controller.topAgents.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final agent = controller.topAgents[index];
                int rankNum = index + 1;
                final String name = agent['name'];

                // ✅ FIX: Extract raw amount and format it to show the full exact total
                final double rawAmount = (agent['amount'] as num).toDouble();
                final String formattedAmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(rawAmount);

                final double progress = agent['progress'];
                final int ordersCount = agent['count'];

                final String rankBadge = agent['rank'] ?? 'JSA';
                final Color badgeColor = _getRankColor(rankBadge);

                final double displayProgress = progress.clamp(0.0, 1.0);
                String percentText = "${(progress * 100).toInt()}%";

                List<Color> rankGradient;
                Color rankBorderColor;
                Color rankTextColor;

                if (rankNum == 1) {
                  rankGradient = [const Color(0xFFFFD700), const Color(0xFFF57F17)];
                  rankBorderColor = const Color(0xFFFFD700).withValues(alpha: 0.5);
                  rankTextColor = Colors.white;
                } else if (rankNum == 2) {
                  rankGradient = [const Color(0xFFB0BEC5), const Color(0xFF78909C)];
                  rankBorderColor = const Color(0xFFB0BEC5).withValues(alpha: 0.5);
                  rankTextColor = Colors.white;
                } else if (rankNum == 3) {
                  rankGradient = [const Color(0xFFD4A373), const Color(0xFF8D6E63)];
                  rankBorderColor = const Color(0xFFD4A373).withValues(alpha: 0.5);
                  rankTextColor = Colors.white;
                } else {
                  rankGradient = isDark ? [const Color(0xFF3A3A3C), const Color(0xFF2C2C2E)] : [const Color(0xFFE5E5EA), const Color(0xFFD1D1D6)];
                  rankBorderColor = isDark ? Colors.white10 : Colors.black12;
                  rankTextColor = isDark ? Colors.white : Colors.black87;
                }

                Color progressColor = progress >= 0.8 ? Colors.green : progress >= 0.5 ? Colors.amber : Colors.redAccent;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: rankBorderColor, width: rankNum <= 3 ? 1.5 : 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 54, height: 54,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: rankGradient),
                              boxShadow: [
                                if (rankNum <= 3) BoxShadow(color: rankGradient.last.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4))
                              ],
                            ),
                            child: Center(
                              child: Text(
                                "#$rankNum",
                                style: TextStyle(color: rankTextColor, fontSize: 18, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        name,
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87),
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: badgeColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        rankBadge,
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: badgeColor),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      formattedAmt,
                                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: isDark ? Colors.white : Colors.black87),
                                    ),
                                    Text(
                                      "  •  $ordersCount Orders",
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: progressColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: progressColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              percentText,
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: progressColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Stack(
                        children: [
                          Container(
                            height: 6,
                            width: double.infinity,
                            decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
                          ),
                          LayoutBuilder(
                              builder: (context, constraints) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 1000),
                                  curve: Curves.easeOutCubic,
                                  height: 6,
                                  width: constraints.maxWidth * displayProgress,
                                  decoration: BoxDecoration(
                                      color: progressColor,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(color: progressColor.withValues(alpha: 0.4), blurRadius: 4)
                                      ]
                                  ),
                                );
                              }
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
  Color _getRankColor(String rank) {
    switch (rank.toUpperCase()) {
      case "SM": return Colors.blueAccent;
      case "SC": return Colors.teal;
      case "SSA": return Colors.blue;
      case "JSA":
      default: return Colors.indigoAccent;
    }
  }

  Widget _buildDeletionRequestCard(BuildContext context, OrderModel order, bool isDark, SalesManagerController controller) {
    return GestureDetector(
      onTap: () => _showDeletionDialog(context, order, controller),
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 12, bottom: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C1C1C) : const Color(0xFFFFF0F0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order.manualOrderNo ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.redAccent)),
                const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 18),
              ],
            ),
            Text(order.clientName, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text("By: ${order.marketingPersonName}", style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  void _showDeletionDialog(BuildContext context, OrderModel order, SalesManagerController controller) {
    Get.defaultDialog(
      title: "Deletion Request",
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            Text("${order.marketingPersonName} wants to delete order ${order.manualOrderNo} (${order.clientName}).", textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () { controller.denyDeletionRequest(order); Get.back(); },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: const Text("Deny", style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () { controller.approveDeletionRequest(order); Get.back(); },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: const Text("Approve", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStage(String label, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(count.toString(), style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900)),
        Text(label, style: TextStyle(color: Colors.black.withValues(alpha:0.6), fontSize: 11, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(margin: const EdgeInsets.symmetric(horizontal: 15), height: 20, width: 1.5, color: Colors.black12);
  }

  Widget _buildCircularAction(IconData icon, bool isDark, VoidCallback onTap, {int notificationCount = 0}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          width: 40, height: 40,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? TColors.textWhite.withValues(alpha:0.08) : TColors.textSecondary.withValues(alpha:0.12),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha:0.05) : Colors.black.withValues(alpha:0.03), width: 0.5)
          ),
          child: Material(
              color: Colors.transparent,
              child: InkWell(borderRadius: BorderRadius.circular(50), onTap: onTap, child: Icon(icon, size: 18, color: isDark ? TColors.textWhite : TColors.textPrimary))
          ),
        ),
        if (notificationCount > 0)
          Positioned(
            right: 2, top: 2,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (context, value, child) => Transform.scale(scale: value, child: child),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: isDark ? TColors.dark : Colors.white, width: 1.5), boxShadow: [BoxShadow(color: Colors.red.withValues(alpha:0.4), blurRadius: 6, spreadRadius: 1)]),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Center(child: Text(notificationCount > 9 ? '9+' : notificationCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark, String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
                message,
                style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w600)
            )
          ]
      ),
    );
  }

  Widget _buildHorizontalPendingOrderCard(BuildContext context, OrderModel order, bool isDark) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12, bottom: 4),
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 8, offset: const Offset(0, 4))],
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200, width: 1)
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.to(() => OrderApprovalScreen(order: order)),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.clientName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text("${order.quantity} Items • ${order.productName}", style: TextStyle(fontSize: 12, color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.orange.withValues(alpha:0.1), borderRadius: BorderRadius.circular(8)), child: const Text("NEW", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold))),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Amount", style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                        Text("₹${order.totalAmount.toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
                      ],
                    ),
                    Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black.withValues(alpha:0.04), shape: BoxShape.circle), child: Icon(Icons.arrow_forward_rounded, size: 16, color: isDark ? Colors.white : Colors.black)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, List<Color> gradientColors, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Icon Circle
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.black, size: 16),
          ),
          const SizedBox(height: 16),
          // Main Value
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _pickMonth(BuildContext context, SalesManagerController controller) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int selectedYear = controller.selectedMonth.value.year;
    final List<String> months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: isDark ? Colors.white : Colors.black), onPressed: () => setState(() => selectedYear--)),
                  Text(selectedYear.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: isDark ? Colors.white : Colors.black)),
                  IconButton(icon: Icon(Icons.arrow_forward_ios_rounded, size: 18, color: isDark ? Colors.white : Colors.black), onPressed: selectedYear < DateTime.now().year ? () => setState(() => selectedYear++) : null),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 12,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1.5, mainAxisSpacing: 12, crossAxisSpacing: 12),
                  itemBuilder: (context, index) {
                    final monthNum = index + 1;
                    final isSelected = monthNum == controller.selectedMonth.value.month && selectedYear == controller.selectedMonth.value.year;
                    final isFuture = selectedYear == DateTime.now().year && monthNum > DateTime.now().month;

                    return InkWell(
                      onTap: isFuture ? null : () {
                        controller.changeMonth(DateTime(selectedYear, monthNum));
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(color: isSelected ? TColors.primary : isDark ? Colors.white10 : Colors.grey[100], borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? TColors.primary : Colors.transparent)),
                        alignment: Alignment.center,
                        child: Text(months[index], style: TextStyle(color: isFuture ? Colors.grey.withValues(alpha:0.5) : isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87), fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning,";
    if (hour < 17) return "Good Afternoon,";
    return "Good Evening,";
  }
}