import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/admin/admin_notification_controller.dart';
import '../../utils/constants/colors.dart';
import '../../controllers/admin/admin_controller.dart';
import '../../routes/route_names.dart';

import 'admin_notification_screen.dart';
import 'admin_profile_screen.dart';
import 'worker_list_screen.dart';
import 'inventory_screen.dart';
import '../floor_management/agent_list_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (FirebaseAuth.instance.currentUser != null) {
        controller.startAdminListeners();
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatCurrency = NumberFormat('#,##,##0', 'en_IN');

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),

      // ✅ SLEEK TRANSPARENT APP BAR (Executive Style)
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            titleSpacing: 24,
            systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
            title: Obx(() {
              String name = controller.adminName.value.isNotEmpty
                  ? controller.adminName.value.trim().split(' ').first
                  : "Super Admin";

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getGreeting(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: TColors.primary,
                    ),
                  ),
                ],
              );
            }),
            actions: [
              // ✅ DYNAMIC Notification Bell
              Obx(() {
                final notifController = Get.put(AdminNotificationController());
                return _buildAppBarAction(
                  Icons.notifications_none_rounded,
                  isDark,
                      () {
                    HapticFeedback.lightImpact();
                    Get.to(() => const AdminNotificationScreen());
                  },
                  badgeCount: notifController.unreadCount.value,
                );
              }),
              const SizedBox(width: 12),

              // ✅ FUNCTIONAL Premium Profile Avatar
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Get.to(() => const AdminProfileScreen());
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 20),
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: TColors.primary.withValues(alpha:0.4), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: TColors.primary.withValues(alpha:0.1),
                    child: const Icon(Icons.person_rounded, size: 18, color: TColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        color: TColors.primary,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        onRefresh: () async => controller.refreshStats(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. PRIMARY METRICS (DAILY & MONTHLY) ---
              Row(
                children: [
                  Expanded(
                    child: Obx(() => _buildPrimaryHighlightCard(
                      title: "Daily Production",
                      value: "₹${formatCurrency.format(controller.totalDailyProduction.value)}",
                      icon: Icons.today_rounded,
                      gradientColors: [const Color(0xFF6A1B9A), const Color(0xFF9C27B0)],
                      isDark: isDark,
                    )),
                  ),
                  const SizedBox(width: 16),

                  // ✅ NEW: Tappable Monthly Revenue Card triggers Month Picker
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.selectMonthYear(context),
                      child: Obx(() => _buildPrimaryHighlightCard(
                        title: "${DateFormat('MMM yyyy').format(controller.selectedMonth.value)} Revenue",
                        value: "₹${formatCurrency.format(controller.totalMonthlyRevenue.value)}",
                        icon: Icons.calendar_month_rounded,
                        gradientColors: [const Color(0xFF00796B), const Color(0xFF009688)],
                        isDark: isDark,
                      )),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // --- FACTORY HEALTH CARD ---
              Obx(() {
                double eff = controller.averageEfficiency.value;
                Color effColor = eff >= 80 ? const Color(0xFF43A047) : (eff >= 50 ? Colors.orange : Colors.redAccent);
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: effColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.speed_rounded, color: effColor),
                      const SizedBox(width: 12),
                      Text("Factory Efficiency", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54)),
                      const Spacer(),
                      Text("${eff.toStringAsFixed(1)}%", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: effColor)),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),

              // --- 2. SECONDARY KPI GRID ---
              // ✅ UPDATED: Section Header with Calendar Action
              Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader("Operational KPIs", Icons.analytics_outlined, isDark),
                  ],
                ),
              ),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  Obx(() => _buildKPICard("Active Workforce", "${controller.activeWorkers.value}", Icons.groups_rounded, Colors.teal, isDark, onTap: () => Get.to(() => const WorkerListScreen()))),
                  Obx(() => _buildKPICard("Total Damages", "${controller.totalDamages.value}", Icons.warning_rounded, Colors.deepOrange, isDark)),
                  _buildKPICard("Sales Force", "View Agents", Icons.support_agent_rounded, Colors.indigo, isDark, onTap: () => Get.to(() => const AgentListScreen())),
                  _buildKPICard("Inventory", "Check Stock", Icons.inventory_2_rounded, Colors.blueGrey, isDark, onTap: () => Get.to(() => const InventoryScreen())),
                ],
              ),
              const SizedBox(height: 32),

              // --- 3. QUICK ACTIONS ---
              _buildSectionHeader("Quick Actions", Icons.bolt_rounded, isDark, iconColor: Colors.orange),
              Obx(() => _buildActionCard(
                context: context,
                title: "Pending Approvals",
                subtitle: "${controller.pendingApprovalsCount.value} requests waiting for verification",
                icon: Icons.verified_user_rounded,
                color: Colors.orange,
                isDark: isDark,
                onTap: () => Get.toNamed(AppRouteNames.pendingApprovals),
              )),
              const SizedBox(height: 32),

              // --- 4. LIVE ACTIVITY FEED ---
              _buildSectionHeader("Live Factory Feed", Icons.history_rounded, isDark),
              _buildActivityFeed(isDark, controller),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== WIDGETS =====================

  Widget _buildAppBarAction(IconData icon, bool isDark, VoidCallback onTap, {int badgeCount = 0}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? Colors.white.withValues(alpha:0.08) : Colors.black.withValues(alpha:0.04),
          ),
          child: IconButton(
            icon: Icon(icon, size: 20, color: isDark ? Colors.white : Colors.black87),
            onPressed: onTap,
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle, border: Border.all(color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9), width: 2)),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Center(child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark, {Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: (iconColor ?? TColors.primary).withValues(alpha:0.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: iconColor ?? TColors.primary),
          ),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildPrimaryHighlightCard({required String title, required String value, required IconData icon, required List<Color> gradientColors, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: gradientColors.last.withValues(alpha:0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Colors.white, letterSpacing: -0.5)),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.white.withValues(alpha:0.8), fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color, bool isDark, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha:0.05) : Colors.black.withValues(alpha:0.03)),
          boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withValues(alpha:0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: color.withValues(alpha:0.15), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 16),
                ),
                if (onTap != null) Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey.shade400),
              ],
            ),
            const Spacer(),

            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
            ),

            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({required BuildContext context, required String title, required String subtitle, required IconData icon, required Color color, required bool isDark, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha:0.3), width: 1.5),
          boxShadow: [if (!isDark) BoxShadow(color: color.withValues(alpha:0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha:0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

// --- 5. PREMIUM VERTICAL TIMELINE FEED (WITH DATE) ---
  Widget _buildActivityFeed(bool isDark, AdminController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (controller.recentActivities.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha:0.03)),
          ),
          child: Center(
            child: Text(
              "No recent factory activity.",
              style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600),
            ),
          ),
        );
      }

      final activities = controller.recentActivities.take(5).toList();

      return Container(
        padding: const EdgeInsets.only(top: 24, bottom: 8, left: 12, right: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha:0.05) : Colors.black.withValues(alpha:0.03)),
          boxShadow: [
            if (!isDark)
              BoxShadow(color: Colors.black.withValues(alpha:0.02), blurRadius: 15, offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          children: List.generate(activities.length, (index) {
            final activity = activities[index];
            final isLast = index == activities.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- LEFT: DATE & TIMESTAMP ---
                  SizedBox(
                    width: 65,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        children: [
                          Text(
                            DateFormat('MMM d').format(activity.time),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('hh:mm a').format(activity.time),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // --- CENTER: TIMELINE TRACK & ICON ---
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: activity.color.withValues(alpha:0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: activity.color.withValues(alpha:0.3), width: 1.5),
                        ),
                        child: Icon(activity.icon, color: activity.color, size: 14),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.black.withValues(alpha:0.05),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // --- RIGHT: ACTIVITY BUBBLE ---
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha:0.03) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha:0.03)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              activity.subtitle,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      );
    });
  }
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning,";
    if (hour < 17) return "Good Afternoon,";
    return "Good Evening,";
  }
}