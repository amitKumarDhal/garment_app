// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:yoobbel/screens/sales/client_list_screen.dart';
import 'package:yoobbel/screens/sales/sales_catalog_screen.dart';
import '../../controllers/sales/sales_agent_controller.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/sizes.dart';

class SalesDashboard extends StatelessWidget {
  const SalesDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SalesAgentController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    controller.fetchAgentStats();
    controller.fetchLeaderboard();

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : TColors.light,
      appBar: AppBar(
        title: const Text("Sales Performance"),
        centerTitle: true,
        backgroundColor: TColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              controller.fetchAgentStats();
              controller.fetchLeaderboard();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.fetchAgentStats();
          await controller.fetchLeaderboard();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(TSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. MY MONTHLY TARGET SECTION ---
              const Text(
                "My Progress (Current Month)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: TSizes.sm),

              // ✅ REAL-TIME MY PERFORMANCE CARD (UPDATED)
              _buildMyPerformanceCard(isDark, controller),

              const SizedBox(height: TSizes.xl),

              // --- 2. TEAM LEADERBOARD SECTION ---
              Row(
                children: [
                  const Icon(Icons.leaderboard, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    "Team Leaderboard",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat(
                      'MMMM',
                    ).format(DateTime.now()), // Auto-Current Month
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: TSizes.sm),

              // ✅ REAL-TIME LEADERBOARD WIDGET
              _buildTeamLeaderboard(isDark, controller),

              const SizedBox(height: TSizes.xl),

              // --- 3. SHORTCUTS SECTION ---
              const Text(
                "Shortcuts",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: TSizes.sm),
              _buildQuickLinksGrid(),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET: Personal Performance Card (Approved Only) ---
  Widget _buildMyPerformanceCard(bool isDark, SalesAgentController controller) {
    return Obx(() {
      final achievement = controller.monthlyAchievement.value;
      final percentage = controller.achievementPercentage;
      final target = controller.monthlyTarget;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [TColors.primary, TColors.primary.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: TColors.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // --- Progress Circle ---
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 70,
                  width: 70,
                  child: CircularProgressIndicator(
                    value: percentage,
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
                Text(
                  "${(percentage * 100).toStringAsFixed(0)}%",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),

            // --- Text Details ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Total Achieved", // ✅ Title reverted
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  "₹${achievement.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                // ❌ "Includes Pending" Label Removed
                Text(
                  "Target: ₹${target.toStringAsFixed(0)}",
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTeamLeaderboard(bool isDark, SalesAgentController controller) {
    return Obx(() {
      // 1. Loading State
      if (controller.isLoading.value && controller.leaderboardData.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        );
      }

      // 2. Empty State
      if (controller.leaderboardData.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Icon(Icons.bar_chart, size: 40, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                "No approved sales yet this month.",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      }

      // 3. List of Agents (Updated with Numbers)
      return Column(
        // ✅ 1. Use asMap().entries to get the index (0, 1, 2...)
        children: controller.leaderboardData.asMap().entries.map((entry) {
          int index = entry.key;
          var agent = entry.value;

          // ✅ 2. Calculate Rank (1, 2, 3...)
          int rank = index + 1;

          // A. Parse Data
          double rawAmount = 0.0;
          if (agent['amount'] is num) {
            rawAmount = (agent['amount'] as num).toDouble();
          }

          String exactAmountDisplay = NumberFormat.currency(
            locale: 'en_IN',
            symbol: '₹',
            decimalDigits: 0,
          ).format(rawAmount);

          double progress = agent['progress'] ?? 0.0;
          String greeting = agent['greeting'] ?? "";

          // B. Determine Colors based on Rank
          Color rankColor;
          if (rank == 1) {
            rankColor = const Color(0xFFFFD700); // Gold
          } else if (rank == 2) {
            rankColor = const Color(0xFFC0C0C0); // Silver
          } else if (rank == 3) {
            rankColor = const Color(0xFFCD7F32); // Bronze
          } else {
            rankColor = isDark
                ? Colors.grey.shade700
                : Colors.grey.shade400; // Normal
          }

          Color textColor = (rank <= 3)
              ? rankColor
              : (isDark ? Colors.white70 : Colors.black54);

          // C. Progress Bar Color
          Color progressColor;
          if (progress >= 1.0) {
            progressColor = Colors.purpleAccent;
          } else if (progress >= 0.9)
            progressColor = Colors.green;
          else if (progress >= 0.5)
            progressColor = Colors.amber;
          else
            progressColor = Colors.red;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: rankColor.withValues(alpha: rank == 1 ? 0.5 : 0.2),
                width: rank == 1 ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // ✅ 3. Rank Circle (Always Shows Number)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: rankColor.withValues(alpha: 0.1),
                    border: Border.all(
                      color: rankColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      "#$rank", // Shows #1, #2, #3...
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                agent['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              // ✅ 4. Add Trophy Icon next to name for Top 3
                              if (rank <= 3)
                                Padding(
                                  padding: const EdgeInsets.only(left: 6.0),
                                  child: Icon(
                                    Icons.emoji_events,
                                    size: 16,
                                    color: rankColor,
                                  ),
                                ),
                            ],
                          ),

                          // Percentage Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: progressColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${(progress * 100).toStringAsFixed(0)}%",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: progressColor,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Greeting / Subtitle
                      if (greeting.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2, bottom: 4),
                          child: Text(
                            greeting,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),

                      const SizedBox(height: 4),

                      // Amount & Bar
                      Row(
                        children: [
                          Text(
                            exactAmountDisplay,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progressColor,
                          ),
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

  // --- WIDGET: Quick Links Grid ---
  Widget _buildQuickLinksGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.5,
      children: [
        _buildSmallActionCard(
          "Clients",
          Icons.person_search,
          Colors.blue,
          () => Get.to(() => const ClientListScreen()),
        ),
        _buildSmallActionCard(
          "Catalogue",
          Icons.menu_book,
          Colors.indigo,
          () => Get.to(() => const SalesCatalogScreen()),
        ),
        _buildSmallActionCard(
          "Targets",
          Icons.track_changes,
          Colors.orange,
          () {},
        ),
        _buildSmallActionCard(
          "Support",
          Icons.help_center,
          Colors.blueGrey,
          () {},
        ),
      ],
    );
  }

  Widget _buildSmallActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
