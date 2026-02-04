import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:yoobbel/screens/floor_management/marketing_upload_screen.dart';
import 'package:yoobbel/screens/sales/sales_order_history_screen.dart';

// --- IMPORTS: Admin & Worker ---
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/inventory_screen.dart';
import '../screens/admin/production_reports_screen.dart';
import '../screens/admin/daily_work_log_screen.dart';

// --- IMPORTS: Floor Management ---
import '../screens/floor_management/supervisor_menu_screen.dart';
import '../screens/floor_management/factory_stock_summary_screen.dart';

// --- IMPORTS: Sales & Sales Manager ---
import '../screens/sales/sales_dashboard.dart';
import '../screens/sales/manager/sales_manager_home.dart';
import '../screens/sales/manager/sales_manager_approvals.dart';

// --- IMPORTS: Common ---
import '../screens/profile/profile_screen.dart';

class NavigationController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;
  final _storage = GetStorage();

  final RxList<Widget> screens = <Widget>[].obs;
  final RxList<NavigationDestination> navItems = <NavigationDestination>[].obs;

  @override
  void onInit() {
    super.onInit();
    _configureMenuForRole();
  }

  void _configureMenuForRole() {
    // ✅ READ CORRECT KEY: Matches what LoginController saves ('user_role')
    String role = _storage.read('user_role') ?? 'Worker';

    screens.clear();
    navItems.clear();

    switch (role) {
      // ============================================================
      // 👑 ADMIN
      // ============================================================
      case 'Admin':
        screens.addAll([
          const AdminDashboard(),
          const InventoryScreen(),
          const ProductionReportsScreen(),
          const ProfileScreen(),
        ]);
        navItems.addAll([
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Admin',
          ),
          const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Stock',
          ),
          const NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            label: 'Reports',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ]);
        break;

      // ============================================================
      // 📊 SALES MANAGER
      // ============================================================
      case 'Sales Manager':
        screens.addAll([
          const SalesManagerHome(), // Index 0: Overview
          const SalesManagerApprovals(), // Index 1: Approve/Reject
          const ProfileScreen(), // Index 2: Profile
        ]);
        navItems.addAll([
          const NavigationDestination(
            icon: Icon(Icons.insights),
            label: 'Home',
          ),
          const NavigationDestination(icon: Icon(Icons.rule), label: 'Approve'),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ]);
        break;

      // ============================================================
      // 🛍️ SALES ASSOCIATE (Previously Sales Agent)
      // ============================================================
      case 'Sales Associate': // ✅ New Name
      case 'Sales Agent': // ✅ Legacy Support (Old users won't crash)
        screens.addAll([
          const SalesDashboard(), // Home
          const SalesOrderHistoryScreen(), // Orders List
          const MarketingUploadScreen(), // New Order Form
          const ProfileScreen(), // Profile
        ]);
        navItems.addAll([
          const NavigationDestination(
            icon: Icon(Icons.store_outlined),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Orders',
          ),
          const NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            label: 'New',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ]);
        break;

      // ============================================================
      // 🏭 SHIFT SUPERVISOR
      // ============================================================
      case 'Shift Supervisor':
        screens.addAll([
          const SupervisorMenuScreen(),
          const FactoryStockSummaryScreen(),
          const ProfileScreen(),
        ]);
        navItems.addAll([
          const NavigationDestination(
            icon: Icon(Icons.domain_outlined),
            label: 'Floor',
          ),
          const NavigationDestination(
            icon: Icon(Icons.warehouse_outlined),
            label: 'Stock',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ]);
        break;

      // ============================================================
      // 🔧 UNIT SUPERVISOR
      // ============================================================
      case 'Unit Supervisor':
        screens.addAll([
          const SupervisorMenuScreen(),
          const InventoryScreen(),
          const ProfileScreen(),
        ]);
        navItems.addAll([
          const NavigationDestination(
            icon: Icon(Icons.engineering_outlined),
            label: 'Unit',
          ),
          const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Materials',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ]);
        break;

      // ============================================================
      // 👷 WORKER
      // ============================================================
      case 'Worker':
        screens.addAll([const DailyWorkLogScreen(), const ProfileScreen()]);
        navItems.addAll([
          const NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            label: 'My Work',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ]);
        break;

      // ============================================================
      // ❌ DEFAULT / FALLBACK (Prevents Crash)
      // ============================================================
      default:
        // Must provide at least 2 items to prevent NavigationBar crash
        screens.addAll([
          const Scaffold(body: Center(child: Text("Loading Dashboard..."))),
          const ProfileScreen(),
        ]);
        navItems.addAll([
          const NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          const NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ]);
    }
  }
}
