import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// --- IMPORTS: Admin & Worker ---
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/inventory_screen.dart';
import '../screens/admin/production_reports_screen.dart';
import '../screens/admin/daily_work_log_screen.dart';

// --- IMPORTS: Floor Management ---
import '../screens/floor_management/supervisor_menu_screen.dart';
import '../screens/floor_management/factory_stock_summary_screen.dart';

// --- IMPORTS: Production (Unit Supervisor) ---
import '../screens/production/unit_supervisor_home.dart';

// --- IMPORTS: Sales & Sales Manager ---
import '../screens/production/unit_supervisor_orders_screen.dart';
import '../screens/sales/sales_dashboard.dart';
import '../screens/sales/sales_order_history_screen.dart';
import '../screens/floor_management/marketing_upload_screen.dart';
import '../screens/sales/manager/sales_manager_home.dart';
import '../screens/sales/manager/sales_manager_approvals.dart';

// --- IMPORTS: Common ---
import '../screens/profile/profile_screen.dart';
import '../utils/constants/colors.dart';

class NavigationController extends GetxController {
  static NavigationController get instance => Get.find();

  final Rx<int> selectedIndex = 0.obs;

  final RxList<Widget> screens = <Widget>[].obs;
  final RxList<NavigationDestination> navItems = <NavigationDestination>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadMenuFromDatabase();
  }

  Future<void> _loadMenuFromDatabase() async {
    isLoading.value = true;
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // ✅ BUG FIX: Check users collection first, then id_requests!
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (!doc.exists) {
          doc = await FirebaseFirestore.instance.collection('id_requests').doc(user.uid).get();
        }

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          // ✅ MAGIC FIX: Safe Lowercase Map
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
    screens.clear();
    navItems.clear();

    // Make role lowercase so 'Unit Supervisor', 'UNIT SUPERVISOR', and 'unit supervisor' all match
    String cleanRole = role.trim().toLowerCase();

    if (cleanRole == 'admin') {
      screens.addAll([
        const AdminDashboard(),
        const InventoryScreen(),
        const ProductionReportsScreen(),
      ]);
      navItems.addAll([
        const NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded, color: TColors.primary), label: 'Home'),
        const NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2_rounded, color: TColors.primary), label: 'Stock'),
        const NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics_rounded, color: TColors.primary), label: 'Reports'),
      ]);
    }
    else if (cleanRole == 'sales manager') {
      screens.addAll([
        const SalesManagerHome(),
        const SalesManagerApprovals(),
        const ProfileScreen(),
      ]);
      navItems.addAll([
        const NavigationDestination(icon: Icon(Icons.insights), label: 'Home'),
        const NavigationDestination(icon: Icon(Icons.rule), label: 'Approve'),
        const NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ]);
    }
    else if (cleanRole == 'sales associate' || cleanRole == 'sales agent') {
      screens.addAll([
        const SalesDashboard(),
        const SalesOrderHistoryScreen(),
        const MarketingUploadScreen(),
        const ProfileScreen(),
      ]);
      navItems.addAll([
        const NavigationDestination(icon: Icon(Icons.store_outlined), label: 'Home'),
        const NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
        const NavigationDestination(icon: Icon(Icons.add_circle_outline), label: 'New'),
        const NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ]);
    }
    else if (cleanRole == 'shift supervisor') {
      screens.addAll([
        const SupervisorMenuScreen(),
        const FactoryStockSummaryScreen(),
        const ProfileScreen(),
      ]);
      navItems.addAll([
        const NavigationDestination(icon: Icon(Icons.domain_outlined), label: 'Floor'),
        const NavigationDestination(icon: Icon(Icons.warehouse_outlined), label: 'Stock'),
        const NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ]);
    }
    // ✅ SAFE UNIT SUPERVISOR CHECK
    else if (cleanRole == 'unit supervisor') {
      screens.addAll([
        const UnitSupervisorHome(),
        const UnitSupervisorOrdersScreen(),
        // const InventoryScreen(),
        const ProfileScreen(),
      ]);
      navItems.addAll([
        const NavigationDestination(icon: Icon(Icons.engineering_outlined), label: 'Floor'),
        const NavigationDestination(icon: Icon(Icons.view_list_rounded), label: 'Orders'), // ✅ Added Bottom Nav Item
        // const NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Materials'),
        const NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ]);
    }
    else {
      screens.addAll([
        const DailyWorkLogScreen(),
        const ProfileScreen()
      ]);
      navItems.addAll([
        const NavigationDestination(icon: Icon(Icons.assignment_outlined), label: 'My Work'),
        const NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ]);
    }
  }
}