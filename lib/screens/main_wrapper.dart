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
  late final NavigationController controller; // Declare it here

  @override
  void initState() {
    super.initState();
    // Initialize it once when the screen loads
    controller = Get.put(NavigationController());
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Safe Injection
    final controller = Get.put(NavigationController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      if (controller.screens.isEmpty) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          if (controller.selectedIndex.value != 0) {
            controller.selectedIndex.value = 0;
            return;
          }
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
            );
          } else {
            SystemNavigator.pop();
          }
        },
        child: Scaffold(
          body: IndexedStack(
            index: controller.selectedIndex.value,
            children: controller.screens,
          ),
          bottomNavigationBar: NavigationBar(
            height: 70,
            elevation: 3,
            selectedIndex: controller.selectedIndex.value,
            onDestinationSelected: (index) =>
                controller.selectedIndex.value = index,
            backgroundColor: isDark ? TColors.dark : Colors.white,
            indicatorColor: TColors.primary.withValues(alpha: 0.1),
            destinations: controller.navItems,
          ),
        ),
      );
    });
  }
}
