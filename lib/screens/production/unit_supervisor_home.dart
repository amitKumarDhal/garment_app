import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/production/unit_supervisor_controller.dart';
import '../../utils/constants/colors.dart';
import '../../data/models/order_model.dart';
import '../profile/profile_screen.dart';

class UnitSupervisorHome extends StatelessWidget {
  const UnitSupervisorHome({super.key});

  // Helper method for dynamic greeting
  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning,';
    } else if (hour < 17) {
      return 'Good Afternoon,';
    } else {
      return 'Good Evening,';
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UnitSupervisorController());
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
            titleSpacing: 24,
            title: Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ ENLARGED DYNAMIC GREETING
                Text(
                    _getGreeting(),
                    style: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontSize: 26, // Increased font size
                        fontWeight: FontWeight.w700 // Made it slightly bolder
                    )
                ),
                Row(
                  children: [
                    Text(controller.supervisorName.value, style: TextStyle(color: isDark ? Colors.white : TColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.orange.withValues(alpha: 0.5))),
                      child: const Text("UNIT SUP", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.orange)),
                    ),
                  ],
                ),
              ],
            )),
            actions: [
              // ✅ NEW: NOTIFICATION BELL WITH BADGE
              GestureDetector(
                onTap: () {
                  // TODO: Add navigation to notifications screen
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? TColors.textWhite.withValues(alpha: 0.1) : TColors.primary.withValues(alpha: 0.1)
                      ),
                      child: Icon(Icons.notifications_outlined, size: 22, color: isDark ? Colors.white : TColors.primary),
                    ),
                    // Red dot indicator
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9), width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // PROFILE ICON
              Padding(
                padding: const EdgeInsets.only(right: 24),
                child: GestureDetector(
                  onTap: () => Get.to(() => const ProfileScreen()),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? TColors.textWhite.withValues(alpha: 0.1) : TColors.primary.withValues(alpha: 0.1)),
                    child: Icon(Icons.person_rounded, size: 22, color: isDark ? Colors.white : TColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.activeOrders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // ✅ FILTER & SORT FOR ACTIVE FLOOR
        // Exclude Shipped/Delivered. Show only things currently on the floor.
        List<String> excludedStages = ['shipping', 'shipped', 'delivered', 'completed', 'rejected'];

        List<OrderModel> floorOrders = controller.activeOrders
            .where((o) => !excludedStages.contains(o.status.toLowerCase()))
            .toList();

        // Sort by deadline (most urgent first)
        floorOrders.sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));

        DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

        return RefreshIndicator(
          onRefresh: () async => controller.fetchActiveFactoryOrders(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// --- STAGE BREAKDOWN PIPELINE (SCROLLABLE) ---
                // --- STAGE BREAKDOWN PIPELINE (COMPACT) ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
                  child: Row(
                    children: [
                      Icon(Icons.analytics_rounded, size: 16, color: TColors.primary),
                      const SizedBox(width: 6),
                      Text("Pipeline Analytics", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
                    ],
                  ),
                ),
                SizedBox(
                  height: 60, // 🔥 Drastically reduced height for a compact UI
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: controller.stageUnitBreakdown.length,
                    itemBuilder: (context, index) {
                      var stage = controller.stageUnitBreakdown[index];
                      return _buildCompactStageCard(isDark, stage['name'], stage['count'], stage['color'], stage['icon']);
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // --- EXACT MATCH TO SALES MANAGER "AT RISK" SECTION ---
                Padding(
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
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline_rounded, color: Colors.redAccent.shade400, size: 18),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        "ACTIVE FLOOR ORDERS",
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
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.shade400,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "${floorOrders.length} IN QUEUE",
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(color: isDark ? Colors.white10 : Colors.red.withValues(alpha: 0.1), height: 1),

                        // --- SCROLLABLE LIST ---
                        if (floorOrders.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(40),
                            child: Center(
                              child: Text(
                                "Floor is clear!",
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                          )
                        else
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 350),
                            child: Scrollbar(
                              child: ListView.separated(
                                padding: EdgeInsets.zero,
                                physics: const BouncingScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: floorOrders.length,
                                separatorBuilder: (context, index) => Divider(
                                  color: isDark ? Colors.white10 : Colors.red.withValues(alpha: 0.05),
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                ),
                                itemBuilder: (context, index) {
                                  var order = floorOrders[index];
                                  DateTime deadline = DateTime(order.deliveryDate.year, order.deliveryDate.month, order.deliveryDate.day);
                                  int daysLeft = deadline.difference(today).inDays;

                                  bool isOverdue = daysLeft < 0;
                                  bool isDueToday = daysLeft == 0;
                                  bool isPacked = order.status.toLowerCase() == 'packed';

                                  Color alertColor = isPacked
                                      ? Colors.green
                                      : (isOverdue ? Colors.redAccent : (isDueToday ? Colors.orange : Colors.amber));

                                  return GestureDetector(
                                    onTap: () => _showUpdateStageDialog(context, order, controller, isDark),
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
                                          ),
                                          const SizedBox(width: 8),

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
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
// --- COMPACT & INFORMATIVE STAGE MICRO-CARD ---
  Widget _buildCompactStageCard(bool isDark, String title, int count, Color color, IconData icon) {
    bool isEmpty = count == 0;
    Color activeColor = isEmpty ? Colors.grey.shade400 : color;
    Color bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      width: 135, // Wide enough to read, short enough to save space
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEmpty
              ? (isDark ? Colors.white10 : Colors.grey.shade200)
              : activeColor.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          if (!isDark && !isEmpty)
            BoxShadow(color: activeColor.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          // Left: Status Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isEmpty ? Colors.grey.withValues(alpha: 0.1) : activeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: activeColor, size: 16),
          ),
          const SizedBox(width: 10),

          // Right: Count & Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                    count.toString(),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isEmpty ? Colors.grey.shade500 : (isDark ? Colors.white : Colors.black87),
                        height: 1.0
                    )
                ),
                const SizedBox(height: 2),
                Text(
                    title,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isEmpty ? Colors.grey.shade500 : (isDark ? Colors.white70 : Colors.grey.shade700)
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  void _showUpdateStageDialog(BuildContext context, OrderModel order, UnitSupervisorController controller, bool isDark) {
    showModalBottomSheet(
        context: context,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Update Order: ${order.manualOrderNo}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 4),
                Text("Current Stage: ${order.status}", style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                const SizedBox(height: 24),

                // The Wrap will nicely layout all the available stages as chips
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: controller.factoryStages.map((stage) {
                    bool isCurrent = stage.toLowerCase() == order.status.toLowerCase();
                    return ActionChip(
                      label: Text(stage, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isCurrent ? Colors.white : (isDark ? Colors.white : Colors.black87))),
                      backgroundColor: isCurrent ? TColors.primary : (isDark ? Colors.white10 : Colors.grey.shade100),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      onPressed: isCurrent ? null : () {
                        Get.back();
                        controller.updateProductionStage(order.id!, order.status, stage);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }
    );
  }
}