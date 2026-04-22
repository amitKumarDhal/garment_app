import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/daily_work_log_screen.dart';
import '../screens/floor_management/supervisor_menu_screen.dart';
import '../screens/floor_management/factory_stock_summary_screen.dart';
import '../screens/production/mockup_list_screen.dart';
import '../screens/production/stock_summary_screen.dart';
import '../screens/production/unit_supervisor_home.dart';
import '../screens/production/unit_supervisor_orders_screen.dart';
import '../screens/production/stock_in_out_screen.dart';
import '../screens/sales/order_deliverables_screen.dart';
import '../screens/sales/sales_dashboard.dart';
import '../screens/sales/sales_order_history_screen.dart';
import '../screens/floor_management/marketing_upload_screen.dart';
import '../screens/sales/manager/sales_manager_home.dart';
import '../screens/sales/manager/sales_manager_approvals.dart';
import '../screens/profile/profile_screen.dart';
import '../utils/constants/colors.dart';
import '../../data/repositories/authentication_repository.dart';

// ✅ IMPORT THE NEW SCREEN HERE (Make sure the path matches where you save it!)
import '../screens/admin/eligible_agents_screen.dart';

class NavigationController extends GetxController {
  static NavigationController get instance => Get.find();

  final Rx<int> selectedIndex = 0.obs;
  final RxList<Widget> screens = <Widget>[].obs;
  final RxList<NavigationDestination> navItems = <NavigationDestination>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();

    String foundRole = '';

    if (Get.isRegistered<AuthenticationRepository>()) {
      foundRole = AuthenticationRepository.instance.currentLoggedInRole;
    }

    if (foundRole.isEmpty || foundRole == 'worker') {
      if (Get.arguments != null && Get.arguments['role'] != null) {
        foundRole = Get.arguments['role'].toString();
      }
    }

    if (foundRole.isNotEmpty && foundRole != 'worker') {
      _configureMenuForRole(foundRole);
      isLoading.value = false;
    } else {
      _loadMenuFromDatabase();
    }
  }

  void updateRole(String role) {
    _configureMenuForRole(role);
    isLoading.value = false;
  }

  Future<void> _loadMenuFromDatabase() async {
    isLoading.value = true;
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (!doc.exists) {
          doc = await FirebaseFirestore.instance.collection('id_requests').doc(user.uid).get();
        }

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final safeData = data.map((key, value) => MapEntry(key.toLowerCase(), value));

          String role = (safeData['role'] ?? 'Worker').toString().trim();
          _configureMenuForRole(role);
        } else {
          _configureMenuForRole('Worker');
        }
      } catch (e) {
        debugPrint("Nav Error: $e");
        _configureMenuForRole('Worker');
      }
    } else {
      _configureMenuForRole('Worker');
    }

    isLoading.value = false;
  }

  void _configureMenuForRole(String role) {
    final List<Widget> newScreens = [];
    final List<NavigationDestination> newNavItems = [];

    String cleanRole = role.trim().toLowerCase();
    debugPrint("📱 NAV CONTROLLER BUILDING TABS FOR: $cleanRole");

    if (cleanRole == 'admin') {
      newScreens.addAll([
        const AdminDashboard(),
        const StockSummaryScreen(),
        const OrderDeliverablesScreen(),
        const EligibleAgentsScreen(), // ✅ NEW SCREEN ADDED HERE
      ]);
      newNavItems.addAll([
        const NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded, color: TColors.primary), label: 'Home'),
        const NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2_rounded, color: TColors.primary), label: 'Stock'),
        const NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics_rounded, color: TColors.primary), label: 'Reports'),
        const NavigationDestination(icon: Icon(Icons.workspace_premium_outlined), selectedIcon: Icon(Icons.workspace_premium, color: TColors.primary), label: 'Bonus'), // ✅ NEW TAB ADDED HERE
      ]);
    }
    else if (cleanRole == 'sales manager') {
      newScreens.addAll([
        const SalesManagerHome(),
        const SalesManagerApprovals(),
        const ProfileScreen(),
      ]);
      newNavItems.addAll([
        const NavigationDestination(icon: Icon(Icons.insights), label: 'Home'),
        const NavigationDestination(icon: Icon(Icons.rule), label: 'Approve'),
        const NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ]);
    }
    else if (cleanRole == 'sales associate' || cleanRole == 'sales agent') {
      newScreens.addAll([
        const SalesDashboard(),
        const SalesOrderHistoryScreen(),
        const MarketingUploadScreen(),
        const ProfileScreen(),
      ]);
      newNavItems.addAll([
        const NavigationDestination(icon: Icon(Icons.store_outlined), label: 'Home'),
        const NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
        const NavigationDestination(icon: Icon(Icons.add_circle_outline), label: 'New'),
        const NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ]);
    }
    else if (cleanRole == 'shift supervisor') {
      newScreens.addAll([
        const SupervisorMenuScreen(),
        const FactoryStockSummaryScreen(),
        const ProfileScreen(),
      ]);
      newNavItems.addAll([
        const NavigationDestination(icon: Icon(Icons.domain_outlined), label: 'Floor'),
        const NavigationDestination(icon: Icon(Icons.warehouse_outlined), label: 'Stock'),
        const NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ]);
    }
    else if (cleanRole == 'unit supervisor') {
      newScreens.addAll([
        const UnitSupervisorHome(),
        const MockupListScreen(),           // ✅ 1. Added the Mockup Screen
        const UnitSupervisorOrdersScreen(),
        const StockInOutScreen(),
        const StockSummaryScreen(),
      ]);
      newNavItems.addAll([
        const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded, color: TColors.primary),
            label: 'Home'
        ),
        // ✅ 2. Added the Mockup Tab Icon
        const NavigationDestination(
            icon: Icon(Icons.palette_outlined),
            selectedIcon: Icon(Icons.palette_rounded, color: TColors.primary),
            label: 'Mockup'
        ),
        const NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded, color: TColors.primary),
            label: 'Explorer'
        ),
        const NavigationDestination(
            icon: Icon(Icons.swap_horizontal_circle_outlined),
            selectedIcon: Icon(Icons.swap_horizontal_circle, color: TColors.primary),
            label: 'Stock I/O'
        ),
        const NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded, color: TColors.primary),
            label: 'Summary'
        ),
      ]);
    }    else {
      newScreens.addAll([
        const DailyWorkLogScreen(),
        const ProfileScreen()
      ]);
      newNavItems.addAll([
        const NavigationDestination(icon: Icon(Icons.assignment_outlined), label: 'My Work'),
        const NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ]);
    }

    screens.assignAll(newScreens);
    navItems.assignAll(newNavItems);
    selectedIndex.value = 0;
  }
}