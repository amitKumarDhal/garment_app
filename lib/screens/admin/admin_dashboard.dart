// ignore_for_file: curly_braces_in_flow_control_structures

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
import '../floor_management/agent_list_screen.dart';
import 'admin_analytics_screen.dart';

// ✅ IMPORT THE SALES MANAGER HISTORY SCREEN
import '../sales/manager/sales_manager_history_screen.dart';

// ✅ IMPORT THE UNIT SUPERVISOR ORDERS SCREEN
import '../production/unit_supervisor_orders_screen.dart';

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

              // =========================================================
              // ✅ SECTION 1: THE FINANCIAL PULSE
              // =========================================================
              _buildSectionHeader(
                "The Financial Pulse",
                Icons.account_balance_wallet_rounded,
                isDark,
                iconColor: Colors.purple,
                trailingWidget: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showTimeframeBottomSheet(context, controller, isDark);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300),
                      boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 12, color: TColors.primary),
                        const SizedBox(width: 6),
                        Obx(() => Text(
                          controller.timeframeLabel.value,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? Colors.white : Colors.black87),
                        )),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: isDark ? Colors.white70 : Colors.black54),
                      ],
                    ),
                  ),
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: Obx(() => _buildDualMetricCard(
                      mainTitle: "Total Revenue",
                      mainValue: "₹${formatCurrency.format(controller.periodRevenue.value)}",
                      subTitle: "Today",
                      subValue: "₹${formatCurrency.format(controller.totalDailyProduction.value)}",
                      icon: Icons.show_chart_rounded,
                      gradientColors: [const Color(0xFF6A1B9A), const Color(0xFF9C27B0)],
                      isDark: isDark,
                    )),
                  ),
                  const SizedBox(width: 16),

                  Expanded(
                    child: Obx(() => _buildDualMetricCard(
                      mainTitle: "Total Orders",
                      mainValue: "${controller.periodOrders.value}",
                      subTitle: "Today",
                      subValue: "+${controller.todayOrders.value}",
                      icon: Icons.shopping_cart_rounded,
                      gradientColors: [const Color(0xFF00796B), const Color(0xFF009688)],
                      isDark: isDark,
                    )),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Obx(() => _buildHorizontalMetricCard(
                title: "Total Units (Garments)",
                mainValue: formatCurrency.format(controller.periodUnits.value),
                subTitle: "Today",
                subValue: "+${formatCurrency.format(controller.todayUnits.value)}",
                icon: Icons.checkroom_rounded,
                gradientColors: [const Color(0xFF283593), const Color(0xFF1976D2)],
                isDark: isDark,
              )),

              const SizedBox(height: 32),

              // =========================================================
              // ✅ SECTION 2: STRATEGIC ANALYTICS
              // =========================================================
              _buildSectionHeader("Strategic Analytics", Icons.insights_rounded, isDark, iconColor: Colors.blue),

              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Get.to(() => const AdminAnalyticsScreen());
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                        child: const Icon(Icons.troubleshoot_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Deep Product Analytics", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                            SizedBox(height: 2),
                            Text("Revenue & Regional Trends", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 11)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // =========================================================
              // ✅ SECTION 3: FACTORY & TEAM OPERATIONS
              // =========================================================
              _buildSectionHeader("Factory & Team Operations", Icons.precision_manufacturing_rounded, isDark, iconColor: Colors.teal),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  Obx(() => _buildKPICard("Active Workforce", "${controller.activeWorkers.value}", Icons.groups_rounded, Colors.teal, isDark, onTap: () => Get.to(() => const WorkerListScreen()))),

                  _buildKPICard("Production Pipeline", "Track Orders", Icons.route_rounded, Colors.deepOrange, isDark, onTap: () => Get.to(() => const SalesManagerHistoryScreen())),

                  _buildKPICard("Sales Force", "View Agents", Icons.support_agent_rounded, Colors.indigo, isDark, onTap: () => Get.to(() => const AgentListScreen())),

                  _buildKPICard("Factory Orders", "View Floor", Icons.factory_rounded, Colors.blueGrey, isDark, onTap: () => Get.to(() => const UnitSupervisorOrdersScreen())),
                ],
              ),

              const SizedBox(height: 32),

              // =========================================================
              // ✅ SECTION 4: THE ACTION HUB
              // =========================================================
              _buildSectionHeader("The Action Hub", Icons.notifications_active_rounded, isDark, iconColor: Colors.orange),

              Obx(() => _buildActionCard(
                title: "Pending Approvals",
                subtitle: "${controller.pendingApprovalsCount.value} requests waiting for verification",
                icon: Icons.verified_user_rounded,
                color: Colors.orange,
                isDark: isDark,
                onTap: () => Get.toNamed(AppRouteNames.pendingApprovals),
              )),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== WIDGETS =====================

  Widget _buildHorizontalMetricCard({
    required String title,
    required String mainValue,
    required String subTitle,
    required String subValue,
    required IconData icon,
    required List<Color> gradientColors,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors, begin: Alignment.centerLeft, end: Alignment.centerRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: gradientColors.last.withValues(alpha:0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Colors.white.withValues(alpha:0.9), fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(mainValue, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 26, color: Colors.white, letterSpacing: -0.5)),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(subTitle, style: TextStyle(color: Colors.white.withValues(alpha:0.8), fontSize: 10, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subValue, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTimeframeBottomSheet(BuildContext context, AdminController controller, bool isDark) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 20),
                    Text("Select Metric Timeframe", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 16),
                    _buildBottomSheetOption("Specific Month...", Icons.calendar_month_rounded, () => controller.selectSpecificMonth(context), isDark),
                    _buildBottomSheetOption("Last 3 Months", Icons.date_range_rounded, () => controller.setTimeframe("Last 3 Months", 3), isDark),
                    _buildBottomSheetOption("Last 6 Months", Icons.date_range_rounded, () => controller.setTimeframe("Last 6 Months", 6), isDark),
                    _buildBottomSheetOption("Last 9 Months", Icons.date_range_rounded, () => controller.setTimeframe("Last 9 Months", 9), isDark),
                    _buildBottomSheetOption("Last 12 Months", Icons.date_range_rounded, () => controller.setTimeframe("Last 12 Months", 12), isDark),
                    _buildBottomSheetOption("This Financial Year", Icons.account_balance_rounded, () => controller.setFinancialYear(), isDark),
                  ],
                ),
              ),
            ),
          );
        }
    );
  }

  Widget _buildBottomSheetOption(String title, IconData icon, VoidCallback onTap, bool isDark) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: TColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, color: TColors.primary, size: 20),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildDualMetricCard({
    required String mainTitle,
    required String mainValue,
    required String subTitle,
    required String subValue,
    required IconData icon,
    required List<Color> gradientColors,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: gradientColors.last.withValues(alpha:0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              Expanded(
                child: Text(
                  mainTitle,
                  textAlign: TextAlign.right,
                  style: TextStyle(color: Colors.white.withValues(alpha:0.9), fontSize: 11, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(mainValue, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 26, color: Colors.white, letterSpacing: -0.5)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("$subTitle: ", style: TextStyle(color: Colors.white.withValues(alpha:0.8), fontSize: 11, fontWeight: FontWeight.w600)),
                Text(subValue, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

  // ✅ UPDATED: Supports putting a widget (like the Timeframe button) at the end of the row
  Widget _buildSectionHeader(String title, IconData icon, bool isDark, {Color? iconColor, Widget? trailingWidget}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: (iconColor ?? TColors.primary).withValues(alpha:0.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: iconColor ?? TColors.primary),
          ),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
          if (trailingWidget != null) ...[
            const Spacer(),
            trailingWidget,
          ]
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

  Widget _buildActionCard({required String title, required String subtitle, required IconData icon, required Color color, required bool isDark, required VoidCallback onTap}) {
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning,";
    if (hour < 17) return "Good Afternoon,";
    return "Good Evening,";
  }
}