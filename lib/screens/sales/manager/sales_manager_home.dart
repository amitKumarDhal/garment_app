import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/sales/sales_manager_controller.dart';
import '../../../utils/constants/colors.dart';
import '../../../data/models/order_model.dart';
import 'order_approval_screen.dart';
import 'sales_manager_history_screen.dart';
import 'sales_manager_approvals.dart';

// ✅ IMPORT THE PROFILE SCREEN
import '../../profile/profile_screen.dart';

class SalesManagerHome extends StatelessWidget {
  const SalesManagerHome({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Initialize Controller
    final controller = Get.put(SalesManagerController());

    // 2. AUTOMATIC FETCH: Loads data immediately when screen opens
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
            systemOverlayStyle: isDark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            title: Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    color: isDark ? TColors.textWhite : TColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  controller.managerName.value,
                  style: TextStyle(
                    color: TColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )),
            centerTitle: false,
            actions: [
              _buildCircularAction(
                Icons.notifications_none_rounded,
                isDark,
                    () {},
                notificationCount: 5,
              ),
              Padding(
                padding: const EdgeInsets.only(right: 20, left: 8),
                child: GestureDetector(
                  onTap: () => Get.to(() => const ProfileScreen()),
                  // ✅ REPLACED: Using a stylized Profile Icon instead of text or network image
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? TColors.textWhite.withOpacity(0.1)
                          : TColors.primary.withOpacity(0.1),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : TColors.primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      size: 22,
                      color: isDark ? Colors.white : TColors.primary,
                    ),
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
              // --- 1. HEADER ROW ("Sales" & "Monthly" Button) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Sales",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _pickMonth(context, controller),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2C2E) : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Monthly",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // --- 2. THE STAT CARDS ---
              Row(
                children: [
                  Expanded(
                    child: Obx(
                          () => _buildStatCard(
                        context,
                        "Total Sales",
                        "₹${(controller.totalRevenue.value / 100000).toStringAsFixed(2)}L",
                        [const Color(0xFF81C784), const Color(0xFF388E3C)],
                        Icons.currency_rupee_rounded,
                        onTap: () {},
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(
                          () => _buildStatCard(
                        context,
                        "Total Orders",
                        controller.totalOrdersCount.value.toString(),
                        [const Color(0xFF64B5F6), const Color(0xFF1976D2)],
                        Icons.shopping_bag_outlined,
                        onTap: () {},
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // --- 3. PRODUCTION PIPELINE ---
              GestureDetector(
                onTap: () => Get.to(
                      () => const SalesManagerHistoryScreen(),
                  arguments: "Approved",
                ),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color(0xFFFFB74D),
                        Color(0xFFF57C00),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -15, right: -15,
                          child: CircleAvatar(radius: 50, backgroundColor: Colors.white.withOpacity(0.05)),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.01)],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Production Pipeline",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Obx(() => Text(
                                    "${controller.approvedOrders.length} Approved",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  )),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(height: 1, color: Colors.white12),
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
                                      decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                                      child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
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

              const SizedBox(height: 32),

              // --- 4. REQUIRES ACTION ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Requires Action",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  TextButton(
                    onPressed: () => Get.to(() => const SalesManagerApprovals()),
                    style: TextButton.styleFrom(
                      foregroundColor: TColors.primary,
                      padding: EdgeInsets.zero,
                    ),
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

                var previewList = controller.pendingOrders.take(5).toList();

                return SizedBox(
                  height: 130,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: previewList.length,
                    itemBuilder: (context, index) {
                      final order = previewList[index];
                      return _buildHorizontalPendingOrderCard(context, order, isDark);
                    },
                  ),
                );
              }),

              const SizedBox(height: 32),

              // --- 5. TOP ASSOCIATES ---
              Obx(() => Text(
                "Top Associates (${DateFormat('MMMM').format(controller.selectedMonth.value)})",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              )),
              const SizedBox(height: 16),

              _buildTeamLeaderboard(isDark, controller),

            ],
          ),
        ),
      ),
    );
  }

  // --- COMPACT STAGES ---
  Widget _buildCompactStage(String label, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          count.toString(),
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(margin: const EdgeInsets.symmetric(horizontal: 15), height: 20, width: 1, color: Colors.white10);
  }

  // --- APP BAR ICON ---
  Widget _buildCircularAction(IconData icon, bool isDark, VoidCallback onTap, {int notificationCount = 0}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          width: 40, height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? TColors.textWhite.withOpacity(0.08) : TColors.textSecondary.withOpacity(0.12),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), width: 0.5),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: onTap,
              child: Icon(icon, size: 18, color: isDark ? TColors.textWhite : TColors.textPrimary),
            ),
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
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? TColors.dark : Colors.white, width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 6, spreadRadius: 1)],
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Center(
                  child: Text(
                    notificationCount > 9 ? '9+' : notificationCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // --- HORIZONTAL PENDING ORDER CARD ---
  Widget _buildHorizontalPendingOrderCard(BuildContext context, OrderModel order, bool isDark) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12, bottom: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDark)
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200, width: 1),
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
                          Text(
                            order.clientName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${order.quantity} Items • ${order.productName}",
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text("NEW", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
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
                        Text(
                          "₹${order.totalAmount.toStringAsFixed(0)}",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_forward_rounded, size: 16, color: isDark ? Colors.white : Colors.black),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- LEADERBOARD ---
  Widget _buildTeamLeaderboard(bool isDark, SalesManagerController controller) {
    return Obx(() {
      if (controller.isLoading.value && controller.topAgents.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.topAgents.isEmpty) {
        return _buildEmptyState(isDark, "No approved sales yet this month.", Icons.bar_chart);
      }

      return Column(
        children: controller.topAgents.asMap().entries.map((entry) {
          int index = entry.key;
          var agent = entry.value;
          int rank = index + 1;

          // ... (Keep existing data parsing logic)
          double rawAmount = (agent['amount'] is num) ? (agent['amount'] as num).toDouble() : 0.0;
          int orderCount = agent['count'] ?? 0;
          String exactAmountDisplay = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(rawAmount);
          double progress = agent['progress'] ?? 0.0;
          String percentText = "${(progress * 100).toStringAsFixed(0)}%";

          List<Color> rankGradient;
          Color rankBorder;
          Color textColor; // ✅ Added explicit text color control

          if (rank == 1) {
            rankGradient = [const Color(0xFFFFD700), const Color(0xFFFFA000)]; // Deeper gold
            rankBorder = const Color(0xFFFFD700);
            textColor = Colors.white;
          } else if (rank == 2) {
            rankGradient = [const Color(0xFFB0BEC5), const Color(0xFF607D8B)]; // High-contrast Silver
            rankBorder = const Color(0xFFCFD8DC);
            textColor = Colors.white;
          } else if (rank == 3) {
            rankGradient = [const Color(0xFFCA8E5B), const Color(0xFF8D6E63)]; // Bronze
            rankBorder = const Color(0xFFBCAAA4);
            textColor = Colors.white;
          } else {
            // ✅ Standard Ranks: Uses a high-contrast background for clear visibility
            rankGradient = isDark
                ? [const Color(0xFF3A3A3C), const Color(0xFF2C2C2E)]
                : [const Color(0xFFE5E5EA), const Color(0xFFD1D1D6)];
            rankBorder = Colors.transparent;
            textColor = isDark ? Colors.white : Colors.black87;
          }

          Color nameColor = isDark ? Colors.white : Colors.black87;
          Color progressColor = progress >= 1.0 ? Colors.purpleAccent : progress >= 0.8 ? Colors.green : progress >= 0.5 ? Colors.amber : Colors.redAccent;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
              ],
              border: rank <= 3 ? Border.all(color: rankBorder.withOpacity(0.5), width: 1.5) : null,
            ),
            child: Row(
              children: [
                // ✅ RANK CIRCLE REFINED
                Container(
                  width: 48, // Slightly larger for clarity
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: rankGradient),
                    boxShadow: [
                      BoxShadow(
                        color: rankGradient.last.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      "#$rank",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900, // Extra bold
                        color: textColor,
                        // ✅ Shadow ensures text stands out from the gradient background
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.25),
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // ... (Keep the rest of your Expanded Column for Agent info)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(agent['name'] ?? "Unknown", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: nameColor)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: progressColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: progressColor.withOpacity(0.2))),
                            child: Text(percentText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: progressColor)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(exactAmountDisplay, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: nameColor)),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 1),
                            child: Text("•  $orderCount Orders", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildStatCard(
      BuildContext context,
      String title,
      String value,
      List<Color> gradientColors,
      IconData icon, {
        VoidCallback? onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.black, size: 16),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: -0.5),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black45, width: 1.0)),
                  child: const Icon(Icons.arrow_outward_rounded, color: Colors.black, size: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // --- GRID MONTH PICKER ---
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
                  IconButton(
                    icon: Icon(Icons.arrow_forward_ios_rounded, size: 18, color: isDark ? Colors.white : Colors.black),
                    onPressed: selectedYear < DateTime.now().year ? () => setState(() => selectedYear++) : null,
                  ),
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
                        decoration: BoxDecoration(
                          color: isSelected ? TColors.primary : isDark ? Colors.white10 : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? TColors.primary : Colors.transparent),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          months[index],
                          style: TextStyle(
                            color: isFuture ? Colors.grey.withOpacity(0.5) : isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
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