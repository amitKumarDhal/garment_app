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
    // 1. Logged Out? -> Login Screen
    if (user == null) {
      Get.offAllNamed(AppRouteNames.login);
      return;
    }

    try {
      print("⏳ Auth Repo: Verifying user permissions from Database...");
      
      // 2. Always fetch fresh data from Firestore
      DocumentSnapshot doc = await _db.collection('id_requests').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        String role = data['role'] ?? "Worker";
        String status = data['status'] ?? "Pending";

        // 🛑 SECURITY CHECK: Kick out Pending/Rejected users instantly
        if (status == 'Pending' || status == 'Rejected') {
          print("⛔ Access Revoked: Status is $status");
          await _auth.signOut();
          Get.offAll(() => const StatusCheckScreen());
          return;
        }

        // ✅ VALID USER: Redirect based on DB Role
        print("✅ Access Granted: User is $role");
        _navigateToDashboard(role);

      } else {
        // User exists in Auth but has no Profile in Database
        print("❌ Error: No user profile found.");
        await _auth.signOut();
        Get.offAllNamed(AppRouteNames.login);
      }
    } catch (e) {
      print("🔥 Auth Error: $e");
      // Safety: Stay on Login if verification fails (e.g., no internet)
      Get.snackbar("Connection Error", "Could not verify account permissions.");
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