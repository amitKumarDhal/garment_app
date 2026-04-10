// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../controllers/production/unit_supervisor_controller.dart';
import '../../utils/constants/colors.dart';
import '../../data/models/order_model.dart';
import '../profile/profile_screen.dart';

class UnitSupervisorHome extends StatelessWidget {
  const UnitSupervisorHome({super.key});

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  LinearGradient _buildSolidGradient(Color color) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [color.withValues(alpha: 0.8), color],
    );
  }


  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UnitSupervisorController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = TColors.getAdaptiveTextColor(context);

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : TColors.light,
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
                    style: const TextStyle(
                        color: TColors.textSecondary,
                        fontSize: 26,
                        fontWeight: FontWeight.w700
                    )
                ),
                Row(
                  children: [
                    Text(controller.supervisorName.value, style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: TColors.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: TColors.warning.withValues(alpha: 0.5))),
                      child: const Text("UNIT SUP", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: TColors.warning)),
                    ),
                  ],
                ),
              ],
            )),
            actions: [
              GestureDetector(
                onTap: () {},
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? Colors.white.withValues(alpha: 0.1) : TColors.primary.withValues(alpha: 0.1)
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
                          color: TColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? TColors.dark : TColors.light, width: 2),
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
                    decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? Colors.white.withValues(alpha: 0.1) : TColors.primary.withValues(alpha: 0.1)),
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
          return const Center(child: CircularProgressIndicator(color: TColors.primary));
        }

        List<String> excludedStages = ['shipping', 'shipped', 'delivered', 'completed', 'rejected'];

        List<OrderModel> floorOrders = controller.activeOrders
            .where((o) => !excludedStages.contains(o.status.toLowerCase()))
            .toList();

        floorOrders.sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));
        DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

        return RefreshIndicator(
          color: TColors.primary,
          backgroundColor: isDark ? TColors.darkCard : Colors.white,
          onRefresh: () async => controller.fetchActiveOrders(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // --- STAGE BREAKDOWN PIPELINE ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
                  child: Row(
                    children: [
                      const Icon(Icons.analytics_rounded, size: 16, color: TColors.primary),
                      const SizedBox(width: 6),
                      Text("Pipeline Analytics", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textColor)),
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
                          textColor,
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
                        color: isDark ? TColors.darkCard : const Color(0xFFFFF9F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: TColors.error.withValues(alpha: 0.4), width: 1),
                        boxShadow: [
                          if (!isDark) BoxShadow(color: TColors.error.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                        ]
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
                                    const Icon(Icons.error_outline_rounded, color: TColors.error, size: 18),
                                    const SizedBox(width: 8),
                                    const Flexible(
                                      child: Text(
                                        "ACTIVE FLOOR ORDERS",
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: TColors.error,
                                          fontWeight: FontWeight.w900,
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
                                decoration: BoxDecoration(color: TColors.error, borderRadius: BorderRadius.circular(6)),
                                child: Text("${floorOrders.length} IN QUEUE", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                              ),
                            ],
                          ),
                        ),
                        Divider(color: isDark ? Colors.white10 : TColors.error.withValues(alpha: 0.1), height: 1),

                        if (floorOrders.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(child: Text("Floor is clear!", style: TextStyle(color: TColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600))),
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
                                separatorBuilder: (context, index) => Divider(color: isDark ? Colors.white10 : TColors.error.withValues(alpha: 0.05), height: 1, indent: 16, endIndent: 16),
                                itemBuilder: (context, index) {
                                  var order = floorOrders[index];
                                  DateTime deadline = DateTime(order.deliveryDate.year, order.deliveryDate.month, order.deliveryDate.day);
                                  int daysLeft = deadline.difference(today).inDays;

                                  bool isOverdue = daysLeft < 0;
                                  bool isDueToday = daysLeft == 0;
                                  bool isPacked = order.status.toLowerCase() == 'packed';
                                  bool isOutSrc = order.status.toLowerCase() == 'out src';

                                  Color alertColor = isPacked ? TColors.success : (isOutSrc ? Colors.indigoAccent : (isOverdue ? TColors.error : (isDueToday ? TColors.warning : Colors.amber)));

                                  String fabricRequired = controller.getFabricRequiredText(order.quantity, order.productName);

                                  return GestureDetector(
                                    onTap: () => _showUpdateStageDialog(context, order, controller, isDark, textColor),
                                    behavior: HitTestBehavior.opaque,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      child: Row(
                                        children: [
                                          Container(width: 3, height: 32, decoration: BoxDecoration(color: alertColor, borderRadius: BorderRadius.circular(2))),
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
                                                      TextSpan(text: "${order.manualOrderNo ?? order.id?.substring(0,5)} ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: textColor)),
                                                      TextSpan(text: "• ${order.clientName}", style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: TColors.textSecondary)),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.inventory_2_outlined, size: 12, color: TColors.textSecondary),
                                                    const SizedBox(width: 4),
                                                    Expanded(child: Text("${order.quantity} Units stuck in ${order.status.toUpperCase()}", style: const TextStyle(fontSize: 11, color: TColors.textSecondary, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                                  ],
                                                ),
                                                if (fabricRequired != "Not Specified") ...[
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.calculate_rounded, size: 12, color: Colors.blueAccent),
                                                      const SizedBox(width: 4),
                                                      Expanded(child: Text("Needs $fabricRequired", style: const TextStyle(fontSize: 11, color: Colors.blueAccent, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                                    ],
                                                  ),
                                                ]
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
                                                    decoration: BoxDecoration(color: alertColor.withValues(alpha: 0.05), border: Border.all(color: alertColor.withValues(alpha: 0.5)), borderRadius: BorderRadius.circular(6)),
                                                    child: Text(text.toUpperCase(), style: TextStyle(color: alertColor, fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                                                  );
                                                } else {
                                                  return Text(text, style: TextStyle(color: alertColor, fontSize: 10, fontWeight: FontWeight.w800));
                                                }
                                              }
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.chevron_right_rounded, color: TColors.textSecondary, size: 18),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        Divider(color: isDark ? Colors.white10 : TColors.error.withValues(alpha: 0.1), height: 1),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: Text("Tap any order to update production status", style: TextStyle(color: TColors.textSecondary, fontSize: 10, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600))),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                _buildDatewiseDeliverables(floorOrders, isDark, textColor, controller, today, context),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDatewiseDeliverables(List<OrderModel> orders, bool isDark, Color textColor, UnitSupervisorController controller, DateTime today, BuildContext context) {
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
              Text("Deliverables Schedule", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textColor)),
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
                        color: isSelected ? TColors.primary : (isDark ? TColors.darkCard : Colors.white),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSelected ? TColors.primary : TColors.getBorderColor(context)),
                        boxShadow: isSelected ? [BoxShadow(color: TColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                      ),
                      child: Center(child: Text("All", style: TextStyle(color: isSelected ? Colors.white : textColor, fontWeight: FontWeight.w900, fontSize: 13))),
                    ),
                  );
                });
              }

              DateTime date = sortedDates[index - 1];
              int daysDiff = date.difference(today).inDays;
              String dayText = DateFormat('dd').format(date);
              String monthText = DateFormat('MMM').format(date).toUpperCase();

              Color badgeColor;
              if (daysDiff < 0) badgeColor = TColors.error;
              else if (daysDiff == 0) badgeColor = TColors.warning;
              else if (daysDiff == 1) badgeColor = TColors.electricBlue;
              else badgeColor = TColors.success;

              return Obx(() {
                bool isSelected = controller.selectedDeliverableDate.value == date;
                return GestureDetector(
                  onTap: () => controller.selectedDeliverableDate.value = date,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? badgeColor : (isDark ? TColors.darkCard : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? badgeColor : TColors.getBorderColor(context)),
                      boxShadow: isSelected ? [BoxShadow(color: badgeColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(monthText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isSelected ? Colors.white70 : TColors.textSecondary)),
                        Text(dayText, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : textColor, height: 1.1)),
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
                  badgeColor = TColors.error;
                } else if (daysDiff == 0) {
                  dateLabel = "TODAY";
                  badgeColor = TColors.warning;
                } else if (daysDiff == 1) {
                  dateLabel = "TOMORROW";
                  badgeColor = TColors.electricBlue;
                } else {
                  dateLabel = DateFormat('dd MMM yyyy').format(date).toUpperCase();
                  badgeColor = TColors.success;
                }

                List<OrderModel> dateOrders = groupedOrders[date]!;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? TColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: TColors.getBorderColor(context)),
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
                        separatorBuilder: (_, _) => Divider(height: 1, color: TColors.getBorderColor(context), indent: 16, endIndent: 16),
                        itemBuilder: (context, index) {
                          var o = dateOrders[index];
                          String fabricRequired = controller.getFabricRequiredText(o.quantity, o.productName);

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            onTap: () => _showUpdateStageDialog(context, o, controller, isDark, textColor),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(o.manualOrderNo ?? o.id?.substring(0,6) ?? "", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: textColor)),
                                Text(o.status.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: TColors.textSecondary)),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("${o.clientName} • ${o.productName} (${o.quantity} Units)", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: TColors.textSecondary)),
                                  if (fabricRequired != "Not Specified")
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text("Est. Fabric: $fabricRequired", style: const TextStyle(fontSize: 11, color: Colors.blueAccent, fontWeight: FontWeight.w700)),
                                    ),
                                ],
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded, size: 16, color: TColors.textSecondary),
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

  Widget _buildCompactStageCard(bool isDark, Color textColor, String title, int unitCount, int orderCount, Color color, IconData icon) {
    bool isEmpty = unitCount == 0 && orderCount == 0;
    Color activeColor = isEmpty ? TColors.textSecondary : color;
    Color bgColor = isDark ? TColors.darkCard : Colors.white;

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
                            color: isEmpty ? TColors.textSecondary : textColor,
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
                          color: isEmpty ? TColors.textSecondary : activeColor,
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
                        color: isEmpty ? TColors.textSecondary : (isDark ? Colors.white70 : Colors.grey.shade700)
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

  Widget _buildInfoRow(bool isDark, IconData icon, String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 14, color: TColors.textSecondary),
          ),
          const SizedBox(width: 8),
          Text("$label: ", style: const TextStyle(color: TColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w700),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialRequirementCard(OrderModel order, bool isDark, Color textColor, UnitSupervisorController controller) {
    Map<String, Map<String, dynamic>> materials = {};

    for (var prod in order.products) {
      String savedFabric = (prod['fabricType'] ?? 'Not Specified').toString();
      String color = (prod['color'] ?? order.color ?? 'Not Specified').toString();
      String lowerFab = savedFabric.toLowerCase();
      String neckType = (prod['neckType'] ?? '').toString().toLowerCase();

      if (savedFabric != 'Not Specified' && savedFabric.isNotEmpty) {
        String lookupKey = "${lowerFab}_${color.toLowerCase()}";
        if (!materials.containsKey(lookupKey)) {
          materials[lookupKey] = {
            'name': savedFabric,
            'color': color,
            'lookupKey': lookupKey,
            'unit': lowerFab.contains('collar') ? 'pcs' : 'kg',
          };
        }
      }

      if (neckType.contains('collar') && !lowerFab.contains('collar')) {
        String colLookupKey = "collar_${color.toLowerCase()}";
        if (!materials.containsKey(colLookupKey)) {
          materials[colLookupKey] = {
            'name': 'Collar',
            'color': color,
            'lookupKey': colLookupKey,
            'unit': 'pcs',
          };
        }
      }
    }

    String estimatedKg = controller.getFabricRequiredText(order.quantity, order.productName);

    if (materials.isEmpty && estimatedKg == "Not Specified") return const SizedBox.shrink();

    return Obx(() {
      return Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.inventory_2_rounded, color: Colors.blue, size: 18),
                const SizedBox(width: 8),
                Text("Material Requirements", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: isDark ? Colors.blue.shade200 : Colors.blue.shade800)),
              ],
            ),
            const SizedBox(height: 12),

            if (estimatedKg != "Not Specified") ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calculate_rounded, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text("Total Fabric Needed: ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                    const Spacer(),
                    Text(estimatedKg, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.blue)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            ...materials.values.map((mat) {
              double inStock = controller.inventoryStock[mat['lookupKey']] ?? 0.0;
              String displayStock = mat['unit'] == 'pcs' ? inStock.toInt().toString() : inStock.toStringAsFixed(1);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "${mat['name']} (${mat['color']})",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "In Stock: $displayStock ${mat['unit']}",
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    });
  }

  void _showUpdateStageDialog(BuildContext context, OrderModel order, UnitSupervisorController controller, bool isDark, Color textColor) {
    TextEditingController remarkController = TextEditingController();

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? TColors.darkCard : TColors.lightCard,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.only(left: 24, right: 24, top: 16),
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40, height: 4,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      Center(
                        child: Text(
                            "Order #${order.manualOrderNo ?? order.id?.substring(0,6)}",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5)
                        ),
                      ),
                      const SizedBox(height: 16),

                      Center(
                        child: GestureDetector(
                          onTap: () {
                            if (order.mockupUrl != null && order.mockupUrl!.isNotEmpty) {
                              _showFullScreenImage(context, order.mockupUrl!, order.manualOrderNo ?? "Unknown");
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            height: 280,
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black38 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: TColors.getBorderColor(context), width: 1.5),
                            ),
                            child: (order.mockupUrl != null && order.mockupUrl!.isNotEmpty)
                                ? CachedNetworkImage(
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
                            )
                                : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported_outlined, color: TColors.textSecondary.withValues(alpha: 0.5), size: 40),
                                const SizedBox(height: 8),
                                const Text("Waiting for Sales\nto upload mockup", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: TColors.textSecondary, fontWeight: FontWeight.bold, height: 1.2)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (order.mockupUrl != null && order.mockupUrl!.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Center(child: Text("Tap image to view full screen & download", style: TextStyle(fontSize: 10, color: TColors.textSecondary, fontStyle: FontStyle.italic))),
                        ),
                      const SizedBox(height: 24),

                      _buildMaterialRequirementCard(order, isDark, textColor, controller),

                      // ✅ THE FIX IS HERE: DETAILED PRODUCT LIST INSTEAD OF SUMMARY
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                            color: isDark ? Colors.black26 : TColors.light,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: TColors.getBorderColor(context))
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(isDark, Icons.business_rounded, "Client", order.clientName, textColor),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),

                            Row(
                              children: [
                                const Icon(Icons.inventory_2_rounded, size: 14, color: TColors.textSecondary),
                                const SizedBox(width: 8),
                                const Text("Products Details:", style: TextStyle(color: TColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                                const Spacer(),
                                Text("Total: ${order.quantity} pcs", style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w800)),
                              ],
                            ),
                            const SizedBox(height: 12),

                            ...order.products.map((prod) {
                              String name = prod['productName'] ?? prod['productDetails'] ?? 'Unknown Product';
                              String qty = (prod['qty'] ?? 0).toString();
                              String fabric = prod['fabricType'] ?? 'Not Specified';
                              String color = prod['color'] ?? 'Not Specified';
                              String sizes = prod['sizeDescription'] ?? 'Not Specified';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8, left: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(child: Text(name, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w800))),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: TColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                          child: Text("$qty pcs", style: const TextStyle(color: TColors.primary, fontSize: 10, fontWeight: FontWeight.w900)),
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text("Fabric: $fabric • Color: $color", style: const TextStyle(fontSize: 11, color: TColors.textSecondary)),
                                    if (sizes.isNotEmpty && sizes != 'Not Specified')
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text("Sizes: $sizes", style: const TextStyle(fontSize: 11, color: TColors.textSecondary)),
                                      )
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Stage Progression", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: textColor)),
                          GestureDetector(
                            onTap: () => _showHistoryDialog(context, order, isDark, textColor),
                            child: const Text("View All", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TColors.primary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildHorizontalTimeline(order, isDark, textColor),
                      const SizedBox(height: 24),

                      Text("Update Stage To:", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: textColor)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: controller.factoryStages.map((stage) {
                          bool isCurrent = stage.toLowerCase() == order.status.toLowerCase();

                          return GestureDetector(
                            onTap: isCurrent ? null : () {
                              Get.back();
                              _showConfirmationDialog(order, stage, controller, remarkController, isDark, textColor);
                            },
                            child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                    gradient: isCurrent ? _buildSolidGradient(TColors.primary) : null,
                                    color: isCurrent ? null : (isDark ? Colors.white10 : Colors.white),
                                    borderRadius: BorderRadius.circular(12),
                                    border: isCurrent ? null : Border.all(color: TColors.getBorderColor(context)),
                                    boxShadow: [
                                      if (!isCurrent && !isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))
                                    ]
                                ),
                                child: Text(
                                    stage,
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w700,
                                        color: isCurrent ? Colors.white : (isDark ? Colors.white70 : Colors.black87)
                                    )
                                )
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            },
          );
        }
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

  void _showConfirmationDialog(OrderModel order, String stage, UnitSupervisorController controller, TextEditingController remarkController, bool isDark, Color textColor) {
    remarkController.clear();

    Get.dialog(
      Dialog(
        backgroundColor: isDark ? TColors.darkCard : TColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: TColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.published_with_changes_rounded, color: TColors.primary, size: 24),
                ),
                const SizedBox(height: 12),

                Text("Confirm Update", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textColor)),
                const SizedBox(height: 4),

                RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                        style: const TextStyle(color: TColors.textSecondary, fontSize: 13, height: 1.3),
                        children: [
                          const TextSpan(text: "Change status to "),
                          TextSpan(text: '"$stage"', style: const TextStyle(color: TColors.primary, fontWeight: FontWeight.bold)),
                        ]
                    )
                ),
                const SizedBox(height: 16),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Remark (Optional)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: remarkController,
                  maxLines: 2,
                  style: TextStyle(color: textColor, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "E.g., Fabric received...",
                    hintStyle: const TextStyle(color: TColors.textSecondary, fontSize: 12),
                    filled: true,
                    fillColor: isDark ? Colors.black26 : TColors.light,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TColors.primary, width: 1.2)),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: TColors.textSecondary.withValues(alpha: 0.2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text("Cancel", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back();
                          controller.updateProductionStage(order.id!, order.status, stage, remark: remarkController.text.trim());
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: TColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Confirm", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildHorizontalTimeline(OrderModel order, bool isDark, Color textColor) {
    if (order.stageHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: isDark ? Colors.black26 : TColors.light, borderRadius: BorderRadius.circular(12)),
        child: const Text("No progression history available yet.", style: TextStyle(color: TColors.textSecondary, fontSize: 12)),
      );
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
                  Text(currentStage, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor.withValues(alpha: 0.8))),
                ],
              ),

              if (index < history.length - 1)
                Container(
                  width: 60,
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          timeTakenStr,
                          style: TextStyle(fontSize: 9, color: TColors.primary.withValues(alpha: 0.8), fontWeight: FontWeight.bold)
                      ),
                      Container(height: 2, color: isDark ? Colors.white24 : Colors.grey.shade300),
                    ],
                  ),
                )
            ],
          );
        },
      ),
    );
  }

  void _showHistoryDialog(BuildContext context, OrderModel order, bool isDark, Color textColor) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: isDark ? TColors.darkCard : TColors.lightCard,
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
                      Text("Stage History", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: TColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(order.manualOrderNo ?? "Unknown ID", style: const TextStyle(color: TColors.primary, fontWeight: FontWeight.w900, fontSize: 12)),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (history.isEmpty)
                    const Expanded(child: Center(child: Text("No updates have been made yet.", style: TextStyle(color: TColors.textSecondary))))
                  else
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          var event = history[index];
                          DateTime time = DateTime.now();
                          if (event['timestamp'] != null) time = (event['timestamp'] as Timestamp).toDate();

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
                                      Text(stage, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.person_rounded, size: 12, color: TColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Text("Updated by $updater", style: const TextStyle(fontSize: 12, color: TColors.textSecondary, fontWeight: FontWeight.w500)),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                                Text(
                                    DateFormat('dd MMM\nhh:mm a').format(time),
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: TColors.textSecondary, height: 1.3)
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
      case 'approved': return TColors.electricBlue;
      case 'fab purchased': return TColors.neonPink;
      case 'fab ready': return TColors.brightMint;
      case 'cutting': return TColors.cutting;
      case 'cutting done': return Colors.deepOrange;
      case 'printing': return TColors.printing;
      case 'printed': return Colors.cyan;
      case 'stitching': return TColors.stitching;
      case 'stitched': return Colors.brown;
      case 'packing': return TColors.packing;
      case 'packed': return Colors.deepPurple;
      case 'out src': return Colors.indigoAccent;
      case 'shipping':
      case 'shipped': return TColors.shipping;
      case 'delivered': return TColors.delivered;
      case 'completed': return TColors.success;
      case 'rejected': return TColors.error;
      case 'pending': return TColors.warning;
      default: return TColors.textSecondary;
    }
  }
}