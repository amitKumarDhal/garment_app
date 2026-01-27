import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/navigation_controller.dart';
import '../../utils/constants/colors.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  DateTime? currentBackPressTime;

  @override
  Widget build(BuildContext context) {
    // ✅ USE Get.find() here because AppRoutes already put it in memory.
    final controller = Get.find<NavigationController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      // 1. Loading State
      if (controller.isLoading.value) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      // 2. Error State
      if (controller.screens.isEmpty) {
        return const Scaffold(body: Center(child: Text("Error loading menu")));
      }

      // 3. Main UI
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;

          // Logic 1: If not on Home tab, go Home
          if (controller.selectedIndex.value != 0) {
            controller.selectedIndex.value = 0;
            return;
          }

          // Logic 2: Double press to exit
          final now = DateTime.now();
          if (currentBackPressTime == null ||
              now.difference(currentBackPressTime!) >
                  const Duration(seconds: 2)) {
            currentBackPressTime = now;
            Get.snackbar(
              "Exit App",
              "Press back again to exit",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.black.withValues(alpha: 0.8),
              colorText: Colors.white,
              duration: const Duration(seconds: 2),
              margin: const EdgeInsets.all(20),
              borderRadius: 20,
              isDismissible: false,
            );
          } else {
            SystemNavigator.pop();
          }
        },
        child: Scaffold(
          // IndexedStack keeps the state of pages alive (no reloading when switching tabs)
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
            items: controller.navItems,
          ),
        ),
      );
    });
  }
}
