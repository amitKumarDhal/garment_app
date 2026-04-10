// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/admin/admin_controller.dart';
import '../../utils/constants/colors.dart';
import '../../data/models/activity_item_model.dart';

class ProductionReportsScreen extends StatelessWidget {
  const ProductionReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Trigger fetch on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchReportData();
    });

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),

      // ✅ SLEEK TRANSPARENT APP BAR
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
        elevation: 0,
        centerTitle: false,
        titleSpacing: 24,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        title: Text(
          "Floor Reports",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 1. PREMIUM DATE SELECTOR ---
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: GestureDetector(
              onTap: () async {
                HapticFeedback.lightImpact();
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: controller.reportDate.value,
                  firstDate: DateTime(2023),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: TColors.primary,
                          onPrimary: Colors.white,
                          onSurface: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  controller.setReportDate(picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                  boxShadow: [
                    if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: TColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.calendar_month_rounded, color: TColors.primary, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Select Date",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 4),
                          Obx(
                                () => Text(
                              DateFormat('EEEE, dd MMM yyyy').format(controller.reportDate.value),
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : Colors.black87,
                                  letterSpacing: -0.3
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ),
          ),

          // --- 2. ANIMATED HORIZONTAL FILTERS ---
          Container(
            height: 46,
            margin: const EdgeInsets.only(bottom: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Obx(
                    () => Row(
                  children: [
                    _buildFilterChip(controller, "All", isDark),
                    _buildFilterChip(controller, "Orders", isDark),
                    _buildFilterChip(controller, "Cutting", isDark),
                    _buildFilterChip(controller, "Printing", isDark),
                    _buildFilterChip(controller, "Stitching", isDark),
                    _buildFilterChip(controller, "Packing", isDark),
                  ],
                ),
              ),
            ),
          ),

          // Meta Text
          Obx(() => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              "ACTIVITY LOG (${controller.reportList.length})",
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          )),

          // --- 3. REPORT LIST ---
          Expanded(
            child: Obx(() {
              if (controller.isReportLoading.value) {
                return const Center(child: CircularProgressIndicator(color: TColors.primary));
              }

              if (controller.reportList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.assignment_late_rounded, size: 48, color: Colors.grey.shade400),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No records found for\n${DateFormat('dd MMM yyyy').format(controller.reportDate.value)}",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 15, fontWeight: FontWeight.w600, height: 1.4),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 40),
                itemCount: controller.reportList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildReportTile(context, controller.reportList[index], isDark);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---

  // ✅ UPGRADED ANIMATED FILTER PILLS
  Widget _buildFilterChip(AdminController controller, String label, bool isDark) {
    bool isSelected = controller.reportSection.value == label;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        controller.setReportSection(label);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: isSelected ? const LinearGradient(colors: [TColors.primary, Color(0xFF5E35B1)]) : null,
          color: isSelected ? null : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: isSelected ? Colors.transparent : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08)),
              width: 1.5
          ),
          boxShadow: isSelected ? [BoxShadow(color: TColors.primary.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))] : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            fontSize: 13,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  // ✅ UPGRADED ACTIVITY CARD
  Widget _buildReportTile(BuildContext context, ActivityItem item, bool isDark) {
    String time = DateFormat('hh:mm a').format(item.time);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03)),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(width: 16),

          // Data 
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: -0.3
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                      fontSize: 13,
                      fontWeight: FontWeight.w500
                  ),
                ),
              ],
            ),
          ),

          // Timestamp
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade400,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}