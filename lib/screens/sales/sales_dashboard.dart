// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:yoobbel/screens/sales/client_list_screen.dart';
import 'package:yoobbel/screens/sales/order_tracking_screen.dart';
import 'package:yoobbel/screens/sales/sales_catalog_screen.dart';
import '../../controllers/sales/sales_agent_controller.dart';
import '../../utils/constants/colors.dart';
import 'package:yoobbel/controllers/notifications/notification_controller.dart';
import 'package:yoobbel/screens/notifications/notification_screen.dart';

import '../profile/profile_screen.dart';

class SalesDashboard extends StatelessWidget {
  const SalesDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Initialize Controller
    final controller = Get.put(SalesAgentController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 2. Fetch Data Safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (FirebaseAuth.instance.currentUser != null) {
        if (controller.leaderboardData.isEmpty) {
          controller.fetchAgentStats();
          controller.fetchLeaderboard();
        }
      }
    });

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
      // ✅ SLEEK TRANSPARENT APP BAR
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
            // ✅ WRAPPED IN OBX TO LISTEN FOR AGENT NAME
            title: Obx(() {
              String name = "Agent";
              if (controller.agentName.value.isNotEmpty) {
                name = controller.agentName.value.trim().split(' ').first;
                // Capitalize first letter
                name = name[0].toUpperCase() + name.substring(1);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getGreeting(),
                    style: TextStyle(
                      color: isDark ? TColors.textWhite : TColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    name,
                    style: TextStyle(
                      color: isDark ? Colors.blue.shade200 : TColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );
            }),
            centerTitle: false,
            actions: [
              // ✅ LIVE NOTIFICATION BELL
              Obx(() {
                final notifController = Get.put(NotificationController());
                int unread = notifController.unreadCount.value;

                return _buildCircularAction(
                  Icons.notifications_none_rounded,
                  isDark,
                      () {
                    HapticFeedback.lightImpact();
                    Get.to(() => const NotificationScreen());
                  },
                  notificationCount: unread,
                );
              }),
              Padding(
                padding: const EdgeInsets.only(right: 20, left: 8),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Get.to(() => const ProfileScreen());
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? TColors.textWhite.withValues(alpha:0.1) : TColors.primary.withValues(alpha:0.1),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha:0.1) : TColors.primary.withValues(alpha:0.2),
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
        color: TColors.primary,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        onRefresh: () async {
          await controller.fetchAgentStats();
          await controller.fetchLeaderboard();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. MY MONTHLY TARGET SECTION ---
              _buildSectionHeader("My Progress", Icons.track_changes_rounded, isDark, trailing: DateFormat('MMM yyyy').format(DateTime.now())),
              _buildMyPerformanceCard(isDark, controller),

              const SizedBox(height: 32),

              // --- 2. TEAM LEADERBOARD SECTION ---
              _buildSectionHeader("Team Leaderboard", Icons.leaderboard_rounded, isDark, iconColor: Colors.orange),
              _buildTeamLeaderboard(isDark, controller),

              const SizedBox(height: 32),

              // --- 3. SHORTCUTS SECTION ---
              _buildSectionHeader("Quick Actions", Icons.bolt_rounded, isDark, iconColor: Colors.amber),
              _buildQuickLinksGrid(isDark),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- MODERN SECTION HEADER ---
  Widget _buildSectionHeader(String title, IconData icon, bool isDark, {Color? iconColor, String? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (iconColor ?? TColors.primary).withValues(alpha:0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor ?? TColors.primary),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            Text(
              trailing,
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ]
        ],
      ),
    );
  }

  // --- WIDGET: Personal Performance Card (✅ FIXED TOTAL ORDERS) ---
  Widget _buildMyPerformanceCard(bool isDark, SalesAgentController controller) {
    return Obx(() {
      final gross = controller.grossSales.value;
      final net = controller.netAchievement.value;

      // Achievement percentage follows Gross Sales
      final percentage = controller.achievementPercentage.clamp(0.0, 1.0);

      final target = controller.monthlyTarget.value;
      final formatCurrency = NumberFormat('#,##,##0', 'en_IN');

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5E35B1), Color(0xFF3949AB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3949AB).withValues(alpha:0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // --- TOP ROW: Progress Ring + Gross Sales ---
            Row(
              children: [
                // Progress Ring (Based on Gross)
                SizedBox(
                  height: 75,
                  width: 75,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 7,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha:0.1)),
                      ),
                      CircularProgressIndicator(
                        value: percentage,
                        strokeWidth: 7,
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeCap: StrokeCap.round,
                      ),
                      Center(
                        child: Text(
                          "${(percentage * 100).toStringAsFixed(0)}%",
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),

                // Gross Sales (The primary metric for the indicator)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha:0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "GROSS SALES (TR)",
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "₹${formatCurrency.format(gross)}",
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 28, color: Colors.white, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Target: ₹${formatCurrency.format(target)}",
                        style: TextStyle(color: Colors.white.withValues(alpha:0.8), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- BOTTOM ROW: Net Achievement vs Total Orders ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(16)
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Net Achievement (Moved here)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          "Net Achievement (ER)",
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w600)
                      ),
                      const SizedBox(height: 2),
                      Text(
                          "₹${formatCurrency.format(net)}",
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)
                      ),
                    ],
                  ),

                  Container(height: 30, width: 1, color: Colors.white.withValues(alpha: 0.2)),

                  // Total Orders
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                          "Total Orders",
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w600)
                      ),
                      const SizedBox(height: 2),
                      Text(
                          "${controller.totalOrders.value}",
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      );
    });
  }  Widget _buildTeamLeaderboard(bool isDark, SalesAgentController controller) {
    return Obx(() {
      if (controller.isLoading.value && controller.leaderboardData.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (controller.leaderboardData.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha:0.05) : Colors.black.withValues(alpha:0.03),
            ),
          ),
          child: Column(
            children: [
              Icon(Icons.bar_chart_rounded, size: 40, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                "No approved sales yet this month.",
                style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      }

      return Column(
        children: controller.leaderboardData.asMap().entries.map((entry) {
          int index = entry.key;
          var agent = entry.value;
          int rank = index + 1;

          double rawAmount = 0.0;
          if (agent['amount'] is num) {
            rawAmount = (agent['amount'] as num).toDouble();
          }

          int totalOrders = agent['count'] ?? 0;

          String exactAmountDisplay = NumberFormat.currency(
            locale: 'en_IN',
            symbol: '₹',
            decimalDigits: 0,
          ).format(rawAmount);

          double progress = agent['progress'] ?? 0.0;

          // ✅ FETCH THE SM FLAG
          bool isSM = agent['isSM'] == true;

          List<Color> rankGradient;
          Color rankBorder;
          Color textColor;

          if (rank == 1) {
            rankGradient = [const Color(0xFFFFD700), const Color(0xFFFFA000)];
            rankBorder = const Color(0xFFFFD700);
            textColor = Colors.white;
          } else if (rank == 2) {
            rankGradient = [const Color(0xFFB0BEC5), const Color(0xFF607D8B)];
            rankBorder = const Color(0xFFCFD8DC);
            textColor = Colors.white;
          } else if (rank == 3) {
            rankGradient = [const Color(0xFFCA8E5B), const Color(0xFF8D6E63)];
            rankBorder = const Color(0xFFBCAAA4);
            textColor = Colors.white;
          } else {
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: rank <= 3
                  ? Border.all(color: rankBorder.withValues(alpha:0.5), width: 1.5)
                  : Border.all(color: isDark ? Colors.white.withValues(alpha:0.05) : Colors.black.withValues(alpha:0.03)),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: rankGradient,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: rankGradient.last.withValues(alpha:0.3),
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
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha:0.25),
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
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
                        children: [
                          // ✅ UPDATED: Wrapped Name and SM Tag in a Row
                          Row(
                            children: [
                              Text(
                                agent['name'] ?? 'Unknown',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: nameColor,
                                ),
                              ),
                              if (isSM) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                                  ),
                                  child: const Text("SM", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.blueAccent)),
                                ),
                              ],
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: progressColor.withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: progressColor.withValues(alpha:0.2)),
                            ),
                            child: Text(
                              "${(progress * 100).toStringAsFixed(0)}%",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                color: progressColor,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            exactAmountDisplay,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: nameColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 1),
                            child: Text(
                              "•  $totalOrders Orders",
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
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
  // --- WIDGET: PREMIUM QUICK LINKS GRID ---
  Widget _buildQuickLinksGrid(bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _buildPremiumActionCard(
          "Clients",
          Icons.group_rounded,
          const Color(0xFF1E88E5),
          isDark,
              () => Get.to(() => const ClientListScreen()),
        ),
        _buildPremiumActionCard(
          "Catalogue",
          Icons.menu_book_rounded,
          const Color(0xFF00ACC1),
          isDark,
              () => Get.to(() => const SalesCatalogScreen()),
        ),
        _buildPremiumActionCard(
          "Track Order",
          Icons.local_shipping_rounded,
          const Color(0xFFF4511E),
          isDark,
              () => Get.to(() => const OrderTrackingScreen()),
        ),
        _buildPremiumActionCard(
          "Support",
          Icons.support_agent_rounded,
          const Color(0xFF43A047),
          isDark,
              () {},
        ),
      ],
    );
  }

  // Helper: Premium Action Card
  Widget _buildPremiumActionCard(
      String title,
      IconData icon,
      Color themeColor,
      bool isDark,
      VoidCallback onTap,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: themeColor.withValues(alpha:isDark ? 0.3 : 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha:isDark ? 0.1 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha:0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: themeColor, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER: App Bar Circular Action Button ---
  Widget _buildCircularAction(IconData icon, bool isDark, VoidCallback onTap, {int notificationCount = 0}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? TColors.textWhite.withValues(alpha:0.08) : TColors.textSecondary.withValues(alpha:0.12),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha:0.05) : Colors.black.withValues(alpha:0.03),
              width: 0.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: onTap,
              child: Icon(icon, size: 20, color: isDark ? TColors.textWhite : TColors.textPrimary),
            ),
          ),
        ),
        if (notificationCount > 0)
          Positioned(
            right: 8,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
                border: Border.all(color: isDark ? TColors.dark : Colors.white, width: 1.5),
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
      ],
    );
  }
  // --- HELPER: Time-based Greeting ---
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning,";
    if (hour < 17) return "Good Afternoon,";
    return "Good Evening,";
  }
}