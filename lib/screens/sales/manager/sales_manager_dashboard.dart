import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yoobbel/screens/profile/profile_screen.dart';
import '../../../../utils/constants/colors.dart';

// ✅ IMPORT THE REAL PROFILE SCREEN

import 'sales_manager_home.dart';
import 'sales_manager_approvals.dart';

class SalesManagerDashboard extends StatelessWidget {
  const SalesManagerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // Create a local controller for tab management
    final controller = Get.put(SalesManagerNavController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : TColors.light,

      // ✅ 1. DYNAMIC BODY (Switches based on index)
      body: Obx(() => controller.screens[controller.selectedIndex.value]),

      // ✅ 2. BOTTOM NAVIGATION BAR
      bottomNavigationBar: Obx(
        () => NavigationBar(
          height: 80,
          elevation: 0,
          selectedIndex: controller.selectedIndex.value,
          onDestinationSelected: (index) =>
              controller.selectedIndex.value = index,
          backgroundColor: isDark ? TColors.dark : Colors.white,
          indicatorColor: Colors.purple.withOpacity(0.1),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Overview',
            ),
            NavigationDestination(
              icon: Icon(Icons.verified_outlined),
              selectedIcon: Icon(Icons.verified),
              label: 'Approvals',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ LOCAL CONTROLLER TO MANAGE TABS
class SalesManagerNavController extends GetxController {
  final RxInt selectedIndex = 0.obs;

  final screens = [
    const SalesManagerHome(), // Tab 0
    const SalesManagerApprovals(), // Tab 1
    const ProfileScreen(), // Tab 2: Now points to the Main Profile Screen
  ];
}
