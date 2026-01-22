import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/navigation_controller.dart';
import '../../utils/constants/colors.dart';

class MainWrapper extends StatelessWidget {
  const MainWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure the controller is loaded
    final controller = Get.put(NavigationController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      // 1. LOADING STATE (Fixes the "Flash" or "Empty" screen)
      if (controller.isLoading.value) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      // 2. ERROR STATE (If something went wrong with Firebase)
      if (controller.screens.isEmpty) {
        return const Scaffold(body: Center(child: Text("Error loading menu")));
      }

      // 3. MAIN APP STRUCTURE
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (controller.selectedIndex.value != 0) {
            controller.selectedIndex.value = 0;
          }
        },
        child: Scaffold(
          // Use the DYNAMIC list from the controller
          body: IndexedStack(
            index: controller.selectedIndex.value,
            children: controller.screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: controller.selectedIndex.value,
            onTap: controller.changeIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: isDark ? TColors.dark : Colors.white,
            selectedItemColor: TColors.primary,
            unselectedItemColor: Colors.grey,
            // Use the DYNAMIC items from the controller
            items: controller.navItems,
          ),
        ),
      );
    });
  }
}
