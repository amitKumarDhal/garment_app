import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../utils/constants/colors.dart';

// ✅ SCREENS
import 'sales_manager_home.dart'; // 1. Overview
import '../../floor_management/marketing_upload_screen.dart'; // 2. New Order
import '../sales_order_history_screen.dart'; // 3. My Orders
import '../../profile/profile_screen.dart'; // 4. Profile
import '../sales_dashboard.dart'; // 5. The Full Associate Dashboard

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

        // Body changes based on selectedIndex
        body: Obx(() => controller.screens[controller.selectedIndex.value]),

        bottomNavigationBar: Obx(
          () => NavigationBar(
            height: 80,
            elevation: 0,
            selectedIndex: controller.selectedIndex.value,

            // ✅ CUSTOM NAVIGATION LOGIC
            onDestinationSelected: (index) {
              // If User clicks "Agent View" (Index 3), Redirect instead of switching tab
              if (index == 3) {
                Get.to(() => const SalesDashboard());
                return;
              }
              // Otherwise, switch tab normally
              controller.selectedIndex.value = index;
            },

            backgroundColor: isDark ? TColors.dark : Colors.white,
            indicatorColor: Colors.purple.withOpacity(0.5),
            destinations: const [
              // Index 0: Overview
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard, color: TColors.primary),
                label: 'Overview',
              ),

              // Index 1: New Order
              NavigationDestination(
                icon: Icon(Icons.add_circle_outline),
                selectedIcon: Icon(Icons.add_circle, color: TColors.primary),
                label: 'NewOrder',
              ),

              // Index 2: My Orders
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long, color: TColors.primary),
                label: 'MyOrders',
              ),

              // ✅ Index 3: Agent View (Redirects)
              NavigationDestination(
                icon: Icon(Icons.swap_horiz_outlined),
                selectedIcon: Icon(Icons.swap_horiz, color: TColors.primary),
                label: 'SalesView',
              ),

              // Index 4: Profile
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person, color: TColors.primary),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SalesManagerNavController extends GetxController {
  final RxInt selectedIndex = 0.obs;
  DateTime? lastBackPressTime;

  // ✅ Note: We don't need SalesDashboard in this list
  // because we redirect to it separately!
  final screens = [
    const SalesManagerHome(), // Index 0
    const MarketingUploadScreen(), // Index 1
    const SalesOrderHistoryScreen(), // Index 2
    const SizedBox(), // Index 3 (Placeholder for Agent View)
    const ProfileScreen(), // Index 4
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
