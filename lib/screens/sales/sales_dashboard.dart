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
    // ✅ Initialize/Find the controller
    final controller = Get.put(SalesAgentController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ Initial data fetch when the screen opens
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

              // ✅ REAL-TIME MY PERFORMANCE CARD
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
                    "February", // Dynamic month could be added via DateFormat
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

  // --- WIDGET: Personal Performance Card ---
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Total Achieved",
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

  // --- WIDGET: Team Leaderboard (Shows Exact Amount) ---
  Widget _buildTeamLeaderboard(bool isDark, SalesAgentController controller) {
    return Obx(() {
      // 1. Loading State
      if (controller.isLoading.value && controller.leaderboardData.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
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
          child: const Text("No sales data recorded this month."),
        );
      }

      // 3. List of Agents
      return Column(
        children: controller.leaderboardData.map((agent) {
          // ✅ STEP A: Get the Raw Amount safely
          double rawAmount = 0.0;
          if (agent['amount'] is num) {
            rawAmount = (agent['amount'] as num).toDouble();
          } else if (agent['amount'] is String) {
            rawAmount = double.tryParse(agent['amount']) ?? 0.0;
          }

          // ✅ STEP B: Format as Exact Currency (₹1,24,500)
          // decimalDigits: 0 removes the .00 cents for cleaner look
          String exactAmountDisplay = NumberFormat.currency(
            locale: 'en_IN',
            symbol: '₹',
            decimalDigits: 0,
          ).format(rawAmount);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                // Rank Badge
                CircleAvatar(
                  radius: 15,
                  backgroundColor: agent['rank'] == "1"
                      ? Colors.orange
                      : Colors.grey.shade200,
                  child: Text(
                    agent['rank'],
                    style: TextStyle(
                      fontSize: 12,
                      color: agent['rank'] == "1" ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            agent['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          // ✅ STEP C: Display the Exact Amount
                          Text(
                            exactAmountDisplay,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: TColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: agent['progress'],
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            agent['progress'] > 0.8
                                ? Colors.green
                                : (agent['progress'] > 0.5
                                      ? Colors.blue
                                      : Colors.orange),
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
          () => Get.to(
            () => const ClientListScreen(),
          ), // ✅ Link to the new screen
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
