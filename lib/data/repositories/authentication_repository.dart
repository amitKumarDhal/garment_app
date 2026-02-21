import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../routes/route_names.dart';

// ✅ CONTROLLER IMPORTS (For Cleanup)
import '../../controllers/navigation_controller.dart';
import '../../controllers/admin/inventory_controller.dart';
import '../../controllers/admin/admin_controller.dart';
import '../../controllers/admin/worker_report_controller.dart';

// ✅ SCREEN IMPORTS (For Redirection)
import '../../screens/sales/manager/sales_manager_dashboard.dart';
import '../../screens/auth/status_check_screen.dart';

class AuthenticationRepository extends GetxController {
  static AuthenticationRepository get instance => Get.find();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  late final Rx<User?> firebaseUser;

  @override
  void onReady() {
    firebaseUser = Rx<User?>(_auth.currentUser);
    firebaseUser.bindStream(_auth.userChanges());
    ever(firebaseUser, _setInitialScreen);
  }

  /// 🔄 CENTRAL NAVIGATION LOGIC
  /// ❌ No GetStorage: Always fetches from Database for maximum security.
  Future<void> _setInitialScreen(User? user) async {
    if (user == null) {
      Get.offAllNamed(AppRouteNames.login);
      return;
    }

    try {
      // 1. Check 'users' collection first (Approved users)
      DocumentSnapshot userDoc = await _db.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        String role = (data['role'] ?? data['Role'] ?? "Worker").toString();
        String status = (data['status'] ?? data['Status'] ?? "Pending").toString();

        if (status.toLowerCase() == 'pending' || status.toLowerCase() == 'rejected') {
          await _auth.signOut();
          Get.offAll(() => const StatusCheckScreen());
          return;
        }
        _navigateToDashboard(role);
        return;
      }

      // 2. Fallback check in 'id_requests'
      DocumentSnapshot requestDoc = await _db.collection('id_requests').doc(user.uid).get();

      if (requestDoc.exists) {
        final data = requestDoc.data() as Map<String, dynamic>;
        String role = (data['role'] ?? data['Role'] ?? "Worker").toString();
        String status = (data['status'] ?? data['Status'] ?? "Pending").toString();

        if (status.toLowerCase() == 'pending' || status.toLowerCase() == 'rejected') {
          await _auth.signOut();
          Get.offAll(() => const StatusCheckScreen());
          return;
        }
        _navigateToDashboard(role);
      } else {
        await _auth.signOut();
        Get.offAllNamed(AppRouteNames.login);
      }
    } catch (e) {
      await _auth.signOut();
      Get.offAllNamed(AppRouteNames.login);
    }
  }
  // ... imports ...

  // Helper to handle routing
  void _navigateToDashboard(String role) {
    String cleanRole = role.toLowerCase().replaceAll(' ', '');

    // 1. Sales Managers still get their own dedicated dashboard
    if (cleanRole == 'salesmanager') {
      Get.offAll(() => const SalesManagerDashboard());
    } 
    // 2. ✅ FIX: Sales Associates now go to MainWrapper (to get the Navbar)
    else {
      // Admin, Worker, Supervisor, AND Sales Associate
      Get.offAllNamed(AppRouteNames.mainWrapper);
    }
  }

  // ✅ CLEAN LOGOUT (The Terminator)
  Future<void> logout() async {
    try {
      // 1. Kill UI immediately
      Get.offAllNamed(AppRouteNames.login);

      // 2. Kill Admin/Worker Controllers to stop Streams
      if (Get.isRegistered<NavigationController>()) Get.delete<NavigationController>(force: true);
      if (Get.isRegistered<InventoryController>()) Get.delete<InventoryController>(force: true);
      if (Get.isRegistered<AdminController>()) Get.delete<AdminController>(force: true);
      if (Get.isRegistered<WorkerReportController>()) Get.delete<WorkerReportController>(force: true);

      // 3. Small delay to ensure UI is gone before auth cuts connection
      await Future.delayed(const Duration(milliseconds: 500));
      await _auth.signOut();
    } catch (e) {
      Get.snackbar("Error", "Logout failed: $e");
    }
  }
}