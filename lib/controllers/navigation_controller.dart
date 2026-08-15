import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/services/api_service.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/floor_management/supervisor_menu_screen.dart';
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

    if (foundRole.isEmpty && Get.arguments != null && Get.arguments['role'] != null) {
      foundRole = Get.arguments['role'].toString();
    }

    if (foundRole.isNotEmpty) {
      _configureMenuForRole(foundRole);
      isLoading.value = false;
    } else {
      _loadMenuFromSession();
    }
  }

  void updateRole(String role) {
    _configureMenuForRole(role);
    isLoading.value = false;
  }

  Future<void> _loadMenuFromSession() async {
    isLoading.value = true;
    final user = ApiService.currentUser;
    if (user != null) {
      final role = (user['role'] ?? 'UNIT_SUPERVISOR').toString();
      _configureMenuForRole(role);
    } else {
      _configureMenuForRole('UNIT_SUPERVISOR');
    }
    isLoading.value = false;
  }

  void _configureMenuForRole(String role) {
    final List<Widget> newScreens = [];
    final List<NavigationDestination> newNavItems = [];

    String cleanRole = role.trim().toLowerCase().replaceAll('_', ' ');
    debugPrint("📱 NAV CONTROLLER BUILDING TABS FOR: $cleanRole");

    if (cleanRole == 'admin') {
      newScreens.addAll([
        const AdminDashboard(),
        const StockSummaryScreen(),
        const OrderDeliverablesScreen(),
        const EligibleAgentsScreen(),
      ]);
      newNavItems.addAll([
        const NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded, color: TColors.primary), label: 'Home'),
        const NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2_rounded, color: TColors.primary), label: 'Stock'),
        const NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics_rounded, color: TColors.primary), label: 'Reports'),
        const NavigationDestination(icon: Icon(Icons.workspace_premium_outlined), selectedIcon: Icon(Icons.workspace_premium, color: TColors.primary), label: 'Bonus'),
      ]);
    } else if (cleanRole == 'sales manager') {
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
    } else if (cleanRole == 'sales associate' || cleanRole == 'sales agent') {
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
    } else {
      // Unit Supervisor
      newScreens.addAll([
        const UnitSupervisorHome(),
        const MockupListScreen(),
        const UnitSupervisorOrdersScreen(),
        const StockInOutScreen(),
        const StockSummaryScreen(),
      ]);
      newNavItems.addAll([
        const NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded, color: TColors.primary), label: 'Home'),
        const NavigationDestination(icon: Icon(Icons.palette_outlined), selectedIcon: Icon(Icons.palette_rounded, color: TColors.primary), label: 'Design'),
        const NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore_rounded, color: TColors.primary), label: 'Explorer'),
        const NavigationDestination(icon: Icon(Icons.swap_horizontal_circle_outlined), selectedIcon: Icon(Icons.swap_horizontal_circle, color: TColors.primary), label: 'Stock I/O'),
        const NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart_rounded, color: TColors.primary), label: 'Summary'),
      ]);
    }

    screens.assignAll(newScreens);
    navItems.assignAll(newNavItems);
    selectedIndex.value = 0;
  }
}