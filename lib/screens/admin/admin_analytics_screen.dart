// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/admin/admin_analytics_controller.dart';
import '../../utils/constants/colors.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminAnalyticsController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = NumberFormat.compactCurrency(symbol: '₹', locale: 'en_IN', decimalDigits: 1);
    final numberFormat = NumberFormat.decimalPattern('en_IN');

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
          "Product Insights",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: TColors.primary));
        }

        return Column(
          children: [
            // --- 0. MASTER TIME FILTER ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Time Filter",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                      boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: controller.selectedTimeframe.value,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: TColors.primary, size: 18),
                        dropdownColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        items: controller.timeframes.map((String tf) {
                          return DropdownMenuItem<String>(
                            value: tf,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(tf),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) controller.setTimeframe(val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- 1. THE 4 TABS ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Expanded(child: _buildTabButton("All", controller, isDark)),
                  Expanded(child: _buildTabButton("Category", controller, isDark)),
                  Expanded(child: _buildTabButton("Fabric", controller, isDark)),
                  Expanded(child: _buildTabButton("Neck Type", controller, isDark)),
                ],
              ),
            ),

            // ✅ 2. NEW: THE HORIZONTAL SUB-FILTER CHIPS (Only shows if not "All")
            if (controller.selectedTab.value != 'All')
              Container(
                height: 38,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: controller.currentSubOptions.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    String option = controller.currentSubOptions[index];
                    bool isSelected = controller.selectedSubFilter.value == option;

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        controller.setSubFilter(option);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? TColors.primary : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? TColors.primary : (isDark ? Colors.white10 : Colors.black12)),
                        ),
                        child: Text(
                          option,
                          style: TextStyle(
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // --- 3. REFRESHABLE CONTENT AREA ---
            Expanded(
              child: RefreshIndicator(
                color: TColors.primary,
                backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                onRefresh: () => controller.fetchAnalyticsData(showSpinner: false),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // 📈 THE DYNAMIC PERFORMANCE CARD
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                          boxShadow: [
                            if (!isDark)
                              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 8))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.insights_rounded, color: isDark ? Colors.white54 : Colors.black54, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    controller.selectedTab.value == 'All'
                                        ? "OVERALL PERFORMANCE (${controller.selectedTimeframe.value.toUpperCase()})"
                                        : "${controller.selectedSubFilter.value.toUpperCase()} PERFORMANCE",
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: isDark ? Colors.white54 : Colors.black54, letterSpacing: 1.0),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            IntrinsicHeight(
                              child: Row(
                                children: [
                                  Expanded(child: _buildCompactMetric("ORDERS", controller.totalOrders.value.toString(), Colors.blueAccent, isDark)),
                                  VerticalDivider(color: isDark ? Colors.white10 : Colors.grey.shade200, width: 24, thickness: 1.5),
                                  Expanded(child: _buildCompactMetric("REVENUE", currency.format(controller.totalRevenue.value), Colors.green, isDark)),
                                  VerticalDivider(color: isDark ? Colors.white10 : Colors.grey.shade200, width: 24, thickness: 1.5),
                                  Expanded(child: _buildCompactMetric("A.O.V.", currency.format(controller.averageOrderValue.value), Colors.purpleAccent, isDark)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // 🌍 GEOGRAPHICAL DEMAND
                      const Text(
                        "Geographical Demand",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),

                      // ✅ 3-Way Toggles
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: _buildSortToggle("Orders", controller, isDark)),
                            Expanded(child: _buildSortToggle("Units", controller, isDark)),
                            Expanded(child: _buildSortToggle("Revenue", controller, isDark)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Obx(() {
                        final regions = controller.regionalPerformance;
                        final isSortingByOrders = controller.selectedRegionSort.value == 'Orders';
                        final isSortingByUnits = controller.selectedRegionSort.value == 'Units';

                        if (regions.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Text("No regional data available.", style: TextStyle(color: Colors.grey.shade500)),
                            ),
                          );
                        }

                        return Column(
                          children: List.generate(regions.length, (index) {
                            final region = regions[index];
                            final String stateName = region['state'];
                            final int count = region['count'];
                            final double percentage = region['percentage'];
                            final double revenue = region['revenue'] ?? 0.0;
                            final int units = region['units'] ?? 0;
                            final bool isTop = index == 0;
                            final List<dynamic> breakdown = region['breakdown'] ?? [];

                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.teal.withValues(alpha: isTop ? 0.5 : 0.2), width: isTop ? 2.0 : 1.0),
                                boxShadow: [if (!isDark) BoxShadow(color: Colors.teal.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 6))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: isTop ? Colors.teal : (isDark ? Colors.white10 : Colors.grey.shade100),
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          "#${index + 1}",
                                          style: TextStyle(
                                            color: isTop ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    stateName,
                                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      isSortingByOrders ? "$count Orders" :
                                                      isSortingByUnits ? "${numberFormat.format(units)} Units" :
                                                      currency.format(revenue),
                                                      style: TextStyle(
                                                          fontWeight: FontWeight.w900,
                                                          color: isTop ? Colors.teal : (isDark ? Colors.white : Colors.black87),
                                                          fontSize: 14
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      isSortingByOrders ? currency.format(revenue) :
                                                      isSortingByUnits ? "$count Orders" :
                                                      "$count Orders",
                                                      style: TextStyle(
                                                          fontWeight: FontWeight.w700,
                                                          color: isTop ? Colors.teal.withValues(alpha: 0.8) : Colors.grey.shade500,
                                                          fontSize: 11
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
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
                                                        width: constraints.maxWidth * (percentage / 100),
                                                        decoration: BoxDecoration(
                                                          color: isTop ? Colors.teal : Colors.teal.withValues(alpha: 0.4),
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                      );
                                                    }
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  // ✅ DYNAMIC BREAKDOWN (Only shows if "All Categories" is selected)
                                  if (breakdown.isNotEmpty) ...[
                                    const SizedBox(height: 20),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.black26 : Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${controller.selectedTab.value.toUpperCase()} BREAKDOWN",
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade500, letterSpacing: 0.5),
                                          ),
                                          const SizedBox(height: 10),
                                          ...breakdown.map((b) {
                                            String name = b['name'];
                                            int bUnits = b['units'];
                                            double bRev = b['revenue'];
                                            int bCount = b['count'];

                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 8.0),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      name,
                                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : Colors.black87),
                                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Text(
                                                    isSortingByOrders ? "$bCount Ord" :
                                                    isSortingByUnits ? "${numberFormat.format(bUnits)} Pcs" :
                                                    currency.format(bRev),
                                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: TColors.primary),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                        );
                      }),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  // --- HELPER WIDGETS ---
  Widget _buildSortToggle(String title, AdminAnalyticsController controller, bool isDark) {
    return Obx(() {
      bool isSelected = controller.selectedRegionSort.value == title;
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          controller.setRegionSort(title);
        },
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? TColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            title,
            style: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                fontSize: 11,
                letterSpacing: 0.5
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTabButton(String title, AdminAnalyticsController controller, bool isDark) {
    bool isSelected = controller.selectedTab.value == title;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        controller.switchTab(title);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? const Color(0xFF3A3A3C) : Colors.black87) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade500,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactMetric(String title, String value, Color color, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
            title,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: color, letterSpacing: -0.5)
          ),
        ),
      ],
    );
  }
}