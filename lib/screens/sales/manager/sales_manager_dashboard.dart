import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../utils/constants/colors.dart';

// ✅ SCREENS
import 'sales_manager_home.dart'; // 1. Overview
import '../../floor_management/marketing_upload_screen.dart'; // 2. New Order
import '../sales_order_history_screen.dart'; // 3. My Orders
import '../sales_dashboard.dart'; // 4. The Full Associate Dashboard

class SalesManagerDashboard extends StatelessWidget {
  const SalesManagerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SalesManagerNavController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        controller.handleBackPress();
      },
      child: Scaffold(
        backgroundColor: isDark ? TColors.dark : TColors.light,

        // ✅ CRITICAL: extendBody allows the screen content to scroll BEHIND the floating nav bar
        extendBody: true,

        // Body changes based on selectedIndex
        body: Obx(() => controller.screens[controller.selectedIndex.value]),

        // ✅ NEW FLOATING GLASS DOCK (4 Items)
        bottomNavigationBar: _buildFloatingNavBar(isDark, controller),
      ),
    );
  }

  // --- PREMIUM FLOATING DOCK NAV BAR (GRADIENT BORDER) ---
  Widget _buildFloatingNavBar(bool isDark, SalesManagerNavController controller) {
    return Padding(
      // Margin to make it float above the bottom of the screen
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),

      // OUTER CONTAINER: Acts as the Gradient Border & Drop Shadow
      child: Container(
        height: 64, // Sleek, compact height
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          // The Gradient for the border
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purpleAccent,
              Colors.green,
              Colors.amber,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),

        // The padding here determines the WIDTH of your gradient border (e.g., 1.5 pixels)
        child: Padding(
          padding: const EdgeInsets.all(1.5),

          // INNER CONTAINER: Your solid app background color
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? TColors.dark : Colors.white,
              borderRadius: BorderRadius.circular(30.5), // Inner radius (32 - 1.5 padding)
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30.5),
              child: Obx(
                    () => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(0, Icons.dashboard_rounded, "Overview", isDark, controller),
                    _buildNavItem(1, Icons.add_circle_rounded, "New", isDark, controller),
                    _buildNavItem(2, Icons.receipt_long_rounded, "Orders", isDark, controller),
                    // Index 3 acts purely as a redirect button
                    _buildNavItem(3, Icons.swap_horiz_rounded, "Sales View", isDark, controller),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- ANIMATED NAV ITEM ---
  Widget _buildNavItem(int index, IconData icon, String label, bool isDark, SalesManagerNavController controller) {
    // Note: Index 3 will never actually be 'selected' because it redirects
    final isSelected = controller.selectedIndex.value == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact(); // Premium tactile feel on tap

        // ✅ CUSTOM NAVIGATION LOGIC MAINTAINED
        if (index == 3) {
          Get.to(() => const SalesDashboard());
          return;
        }
        controller.selectedIndex.value = index;
      },
      // Container animates its width/padding when selected
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint,
        padding: EdgeInsets.symmetric(
          // ✅ INCREASED PADDING: More horizontal breathing room since there are only 4 items now
          horizontal: isSelected ? 16 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white10 : TColors.primary.withOpacity(0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Floating dot indicator + Icon
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isSelected ? 1.0 : 0.0,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    height: 4,
                    width: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : TColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Icon(
                  icon,
                  size: 22,
                  color: isSelected
                      ? (isDark ? Colors.white : TColors.primary)
                      : Colors.grey.shade500,
                ),
              ],
            ),

            // Text expands smoothly when selected
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutQuint,
              child: SizedBox(
                width: isSelected ? null : 0, // Collapses text to 0 width when not selected
                child: Padding(
                  padding: const EdgeInsets.only(left: 6, top: 4),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12, // Slightly larger font since we have 4 items
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : TColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ UPDATED CONTROLLER
class SalesManagerNavController extends GetxController {
  final RxInt selectedIndex = 0.obs;
  DateTime? lastBackPressTime;

  // ✅ REMOVED PROFILE SCREEN FROM CONTROLLER ARRAY
  final screens = [
    const SalesManagerHome(), // Index 0
    const MarketingUploadScreen(), // Index 1
    const SalesOrderHistoryScreen(), // Index 2
    const SizedBox(), // Index 3 (Placeholder for Agent View)
  ];

  void handleBackPress() {
    if (selectedIndex.value != 0) {
      selectedIndex.value = 0;
      return;
    }
    DateTime now = DateTime.now();
    if (lastBackPressTime == null ||
        now.difference(lastBackPressTime!) > const Duration(seconds: 2)) {
      lastBackPressTime = now;
      Get.rawSnackbar(
        messageText: const Center(
          child: Text(
            "Press back again to exit",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.black87,
        borderRadius: 30,
        margin: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } else {
      SystemNavigator.pop();
    }
  }
}