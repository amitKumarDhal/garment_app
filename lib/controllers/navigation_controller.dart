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

// --- IMPORTS: Sales & Sales Manager ---
import '../screens/sales/sales_dashboard.dart';
import '../screens/sales/sales_order_history_screen.dart'; // Fixed import
import '../screens/floor_management/marketing_upload_screen.dart'; // Fixed import
import '../screens/sales/manager/sales_manager_home.dart';
import '../screens/sales/manager/sales_manager_approvals.dart';

// --- IMPORTS: Common ---
import '../screens/profile/profile_screen.dart';

class NavigationController extends GetxController {
  static NavigationController get instance => Get.find();

  final Rx<int> selectedIndex = 0.obs;
  
  // ❌ Removed GetStorage (Security Requirement)
  
  // Observables for UI
  final RxList<Widget> screens = <Widget>[].obs;
  final RxList<NavigationDestination> navItems = <NavigationDestination>[].obs;
  final RxBool isLoading = true.obs; // ✅ Add loading state

  @override
  void onInit() {
    super.onInit();
    _loadMenuFromDatabase(); // ✅ Fetch from DB instead of Storage
  }

  /// 🔄 FETCH ROLE FROM FIRESTORE
  Future<void> _loadMenuFromDatabase() async {
    isLoading.value = true;
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('id_requests')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          String role = (data['role'] ?? 'Worker').toString().trim();
          
          // Configure menu based on verified DB role
          _configureMenuForRole(role);
        } else {
          // Fallback if doc missing
          _configureMenuForRole('Worker'); 
        }
      } catch (e) {
        print("Nav Error: $e");
        _configureMenuForRole('Worker'); // Fallback on error
      }
    } else {
      _configureMenuForRole('Worker'); // Fallback if not logged in
    }
    
    isLoading.value = false;
  }

  void _configureMenuForRole(String role) {
    screens.clear();
    navItems.clear();

    // Normalize role string to be safe
    String cleanRole = role.trim(); 

    // ============================================================
    // 👑 ADMIN
    // ============================================================
    if (cleanRole == 'Admin') {
        screens.addAll([
          const AdminDashboard(),
          const InventoryScreen(),
          const ProductionReportsScreen(),
          const ProfileScreen(),
        ]);
        navItems.addAll([
          const NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Admin'),
          const NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Stock'),
          const NavigationDestination(icon: Icon(Icons.analytics_outlined), label: 'Reports'),
          const NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ]);
    }

    // ============================================================
    // 📊 SALES MANAGER
    // ============================================================
    else if (cleanRole == 'Sales Manager') {
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

    // ============================================================
    // 🛍️ SALES ASSOCIATE
    // ============================================================
    else if (cleanRole == 'Sales Associate' || cleanRole == 'Sales Agent') {
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

    // ============================================================
    // 🏭 SHIFT SUPERVISOR
    // ============================================================
    else if (cleanRole == 'Shift Supervisor') {
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

    // ============================================================
    // 🔧 UNIT SUPERVISOR
    // ============================================================
    else if (cleanRole == 'Unit Supervisor') {
        screens.addAll([
          const SupervisorMenuScreen(),
          const InventoryScreen(),
          const ProfileScreen(),
        ]);
        navItems.addAll([
          const NavigationDestination(icon: Icon(Icons.engineering_outlined), label: 'Unit'),
          const NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Materials'),
          const NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ]);
    }

    // ============================================================
    // 👷 WORKER (Default)
    // ============================================================
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