import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // --- GRADIENT HELPER ---
  LinearGradient _buildSolidGradient(Color color) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [color.withValues(alpha: 0.6), color],
    );
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
                Text(
                    _getGreeting(),
                    style: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontSize: 26,
                        fontWeight: FontWeight.w700
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

        List<String> excludedStages = ['shipping', 'shipped', 'delivered', 'completed', 'rejected'];

        List<OrderModel> floorOrders = controller.activeOrders
            .where((o) => !excludedStages.contains(o.status.toLowerCase()))
            .toList();

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

                // --- STAGE BREAKDOWN PIPELINE (COMPACT) ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
                  child: Row(
                    children: [
                      const Icon(Icons.analytics_rounded, size: 16, color: TColors.primary),
                      const SizedBox(width: 6),
                      Text("Pipeline Analytics", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
                    ],
                  ),
                ),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: controller.stageUnitBreakdown.length,
                    itemBuilder: (context, index) {
                      var stage = controller.stageUnitBreakdown[index];
                      return _buildCompactStageCard(
                          isDark,
                          stage['name'],
                          stage['count'],
                          stage['orderCount'] ?? 0,
                          stage['color'],
                          stage['icon']
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // --- ACTIVE FLOOR ORDERS (AT RISK LIST) ---
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
                                    // ✅ CALLING THE NEW UPGRADED DIALOG HERE
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

                const SizedBox(height: 24),

                // DATE WISE DELIVERABLES SCHEDULE WITH SCROLLABLE STRIP
                _buildDatewiseDeliverables(floorOrders, isDark, controller, today),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDatewiseDeliverables(List<OrderModel> orders, bool isDark, UnitSupervisorController controller, DateTime today) {
    if (orders.isEmpty) return const SizedBox.shrink();

    Map<DateTime, List<OrderModel>> groupedOrders = {};
    for (var o in orders) {
      DateTime d = DateTime(o.deliveryDate.year, o.deliveryDate.month, o.deliveryDate.day);
      groupedOrders.putIfAbsent(d, () => []).add(o);
    }

    List<DateTime> sortedDates = groupedOrders.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
          child: Row(
            children: [
              const Icon(Icons.calendar_month_rounded, size: 18, color: TColors.primary),
              const SizedBox(width: 8),
              Text("Deliverables Schedule", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
        ),

        SizedBox(
          height: 65,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: sortedDates.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Obx(() {
                  bool isSelected = controller.selectedDeliverableDate.value == null;
                  return GestureDetector(
                    onTap: () => controller.selectedDeliverableDate.value = null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isSelected ? TColors.primary : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSelected ? TColors.primary : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05))),
                        boxShadow: isSelected ? [BoxShadow(color: TColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                      ),
                      child: Center(
                        child: Text("All", style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87), fontWeight: FontWeight.w900, fontSize: 13)),
                      ),
                    ),
                  );
                });
              }

              DateTime date = sortedDates[index - 1];
              int daysDiff = date.difference(today).inDays;
              String dayText = DateFormat('dd').format(date);
              String monthText = DateFormat('MMM').format(date).toUpperCase();

              Color badgeColor;
              if (daysDiff < 0) badgeColor = Colors.redAccent;
              else if (daysDiff == 0) badgeColor = Colors.orange;
              else if (daysDiff == 1) badgeColor = Colors.blue;
              else badgeColor = Colors.green;

              return Obx(() {
                bool isSelected = controller.selectedDeliverableDate.value == date;
                return GestureDetector(
                  onTap: () => controller.selectedDeliverableDate.value = date,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? badgeColor : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? badgeColor : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05))),
                      boxShadow: isSelected ? [BoxShadow(color: badgeColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(monthText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isSelected ? Colors.white70 : (isDark ? Colors.white54 : Colors.black54))),
                        Text(dayText, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87), height: 1.1)),
                      ],
                    ),
                  ),
                );
              });
            },
          ),
        ),
        const SizedBox(height: 16),

        Obx(() {
          DateTime? selectedDate = controller.selectedDeliverableDate.value;
          List<DateTime> datesToShow = selectedDate == null ? sortedDates : [selectedDate];

          if (selectedDate != null && !groupedOrders.containsKey(selectedDate)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              controller.selectedDeliverableDate.value = null;
            });
            return const SizedBox.shrink();
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: datesToShow.map((date) {
                int daysDiff = date.difference(today).inDays;
                String dateLabel;
                Color badgeColor;

                if (daysDiff < 0) {
                  dateLabel = "OVERDUE (${daysDiff.abs()} Days)";
                  badgeColor = Colors.redAccent;
                } else if (daysDiff == 0) {
                  dateLabel = "TODAY";
                  badgeColor = Colors.orange;
                } else if (daysDiff == 1) {
                  dateLabel = "TOMORROW";
                  badgeColor = Colors.blue;
                } else {
                  dateLabel = DateFormat('dd MMM yyyy').format(date).toUpperCase();
                  badgeColor = Colors.green;
                }

                List<OrderModel> dateOrders = groupedOrders[date]!;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                    boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.1),
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(dateLabel, style: TextStyle(color: badgeColor, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.0)),
                            Text("${dateOrders.length} Orders", style: TextStyle(color: badgeColor, fontWeight: FontWeight.w800, fontSize: 11)),
                          ],
                        ),
                      ),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: dateOrders.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade100, indent: 16, endIndent: 16),
                        itemBuilder: (context, index) {
                          var o = dateOrders[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            // ✅ CALLING THE NEW UPGRADED DIALOG HERE
                            onTap: () => _showUpdateStageDialog(context, o, controller, isDark),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(o.manualOrderNo ?? o.id?.substring(0,6) ?? "", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
                                Text(o.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade500)),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text("${o.clientName} • ${o.productName} (${o.quantity} Units)", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                            ),
                            trailing: Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey.shade400),
                          );
                        },
                      )
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        }),
      ],
    );
  }

  // --- HELPER FOR POPUP UI ---
  Widget _buildInfoRow(bool isDark, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Text("$label: ", style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
        Expanded(child: Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 12, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  // --- NEW RICH POPUP LOGIC ---
  void _showUpdateStageDialog(BuildContext context, OrderModel order, UnitSupervisorController controller, bool isDark) {
    TextEditingController remarkController = TextEditingController();

    showModalBottomSheet(
        context: context,
        isScrollControlled: true, // Required for keyboard avoidance
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom, // Pushes UI up when keyboard opens
              left: 24, right: 24, top: 24,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // --- 1. HEADER: MOCKUP & DETAILS ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported_outlined, color: Colors.grey.shade400, size: 24),
                            const SizedBox(height: 4),
                            Text("Mockup\n(Soon)", textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Order: ${order.manualOrderNo ?? order.id?.substring(0,6)}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
                            const SizedBox(height: 8),
                            _buildInfoRow(isDark, Icons.business_rounded, "Client", order.clientName),
                            const SizedBox(height: 4),
                            _buildInfoRow(isDark, Icons.category_rounded, "Product", "${order.productName} (${order.quantity} pcs)"),
                            const SizedBox(height: 4),
                            _buildInfoRow(isDark, Icons.straighten_rounded, "Sizes", "Mixed/Standard"),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // --- 2. HORIZONTAL TIME TRACKER ---
                  Text("Stage Progression Time", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 12),
                  _buildHorizontalTimeline(order, isDark),
                  const SizedBox(height: 24),

                  // --- 3. REMARK TEXT FIELD ---
                  Text("Add Remark (Optional)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: remarkController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "E.g., Waiting for thread delivery...",
                      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      filled: true,
                      fillColor: isDark ? Colors.black26 : Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TColors.primary, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- 4. UPDATE STAGE SELECTION ---
                  Text("Update Stage To:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: controller.factoryStages.map((stage) {
                      bool isCurrent = stage.toLowerCase() == order.status.toLowerCase();

                      return GestureDetector(
                        onTap: isCurrent ? null : () {
                          Get.back(); // Close bottom sheet
                          Get.defaultDialog(
                            title: "Confirm Update",
                            titleStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isDark ? Colors.white : Colors.black87),
                            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            content: Column(
                              children: [
                                Text('Changing status to', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                                const SizedBox(height: 8),
                                Text('"$stage"', style: TextStyle(color: TColors.primary, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            cancel: OutlinedButton(
                              onPressed: () => Get.back(),
                              style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5))),
                              child: const Text("No", style: TextStyle(color: Colors.redAccent)),
                            ),
                            confirm: ElevatedButton(
                              onPressed: () {
                                Get.back(); // Close dialog
                                controller.updateProductionStage(order.id!, order.status, stage, remark: remarkController.text.trim());
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: TColors.primary),
                              child: const Text("Confirm", style: TextStyle(color: Colors.white)),
                            ),
                          );
                        },
                        child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                                gradient: isCurrent ? _buildSolidGradient(TColors.primary) : null,
                                color: isCurrent ? null : (isDark ? Colors.white10 : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(8),
                                border: isCurrent ? null : Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300)
                            ),
                            child: Text(
                                stage,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isCurrent ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.black87)
                                )
                            )
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        }
    );
  }

  // --- HORIZONTAL TIMELINE HELPER ---
  Widget _buildHorizontalTimeline(OrderModel order, bool isDark) {
    if (order.stageHistory.isEmpty) {
      return Text("No progression history available yet.", style: TextStyle(color: Colors.grey.shade500, fontSize: 12));
    }

    List<dynamic> history = List.from(order.stageHistory);
    history.sort((a, b) {
      DateTime timeA = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
      DateTime timeB = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
      return timeA.compareTo(timeB);
    });

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: history.length,
        itemBuilder: (context, index) {
          var current = history[index];
          DateTime currentTime = (current['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
          String currentStage = current['stage'] ?? 'Unknown';
          Color stageColor = _getStatusColor(currentStage);

          String timeTakenStr = '';
          if (index < history.length - 1) {
            var next = history[index + 1];
            DateTime nextTime = (next['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
            Duration diff = nextTime.difference(currentTime);

            if (diff.inDays > 0) {
              timeTakenStr = "${diff.inDays}d ${diff.inHours.remainder(24)}h";
            } else if (diff.inHours > 0) {
              timeTakenStr = "${diff.inHours}h ${diff.inMinutes.remainder(60)}m";
            } else {
              timeTakenStr = "${diff.inMinutes}m";
            }
          }

          return Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: stageColor.withValues(alpha: 0.15), shape: BoxShape.circle),
                    child: Icon(Icons.check_circle_rounded, color: stageColor, size: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(currentStage, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
                ],
              ),

              if (index < history.length - 1)
                Container(
                  width: 60,
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(timeTakenStr, style: const TextStyle(fontSize: 9, color: TColors.primary, fontWeight: FontWeight.bold)),
                      Container(height: 2, color: TColors.primary.withValues(alpha: 0.3)),
                    ],
                  ),
                )
            ],
          );
        },
      ),
    );
  }

  // --- COLOR HELPER ---
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
      default: return Colors.grey;
    }
  }

  // --- COMPACT & INFORMATIVE STAGE MICRO-CARD ---
  Widget _buildCompactStageCard(bool isDark, String title, int unitCount, int orderCount, Color color, IconData icon) {
    bool isEmpty = unitCount == 0 && orderCount == 0;
    Color activeColor = isEmpty ? Colors.grey.shade400 : color;
    Color bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      width: 155,
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isEmpty ? Colors.grey.withValues(alpha: 0.1) : activeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: activeColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                        unitCount.toString(),
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: isEmpty ? Colors.grey.shade500 : (isDark ? Colors.white : Colors.black87),
                            height: 1.0
                        )
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: isEmpty ? Colors.transparent : activeColor.withValues(alpha: 0.1),
                        border: Border.all(color: isEmpty ? Colors.grey.withValues(alpha: 0.3) : activeColor.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "$orderCount ord",
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: isEmpty ? Colors.grey.shade500 : activeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
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
}