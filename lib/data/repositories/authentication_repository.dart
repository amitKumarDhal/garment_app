import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../routes/route_names.dart';

// ✅ 1. ADD ALL THESE IMPORTS (Required to find the controllers)
import '../../controllers/navigation_controller.dart';
import '../../controllers/admin/inventory_controller.dart';
import '../../controllers/admin/admin_controller.dart';
import '../../controllers/admin/worker_report_controller.dart'; // Adjust name if your file is named differently

// ✅ IMPORTS FOR SCREENS
import '../../screens/sales/manager/sales_manager_dashboard.dart';
import '../../screens/auth/status_check_screen.dart';

class AuthenticationRepository extends GetxController {
  static AuthenticationRepository get instance => Get.find();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _storage = GetStorage();
  late final Rx<User?> firebaseUser;

  @override
  void onReady() {
    firebaseUser = Rx<User?>(_auth.currentUser);
    firebaseUser.bindStream(_auth.userChanges());
    ever(firebaseUser, _setInitialScreen);
  }

  Future<void> _setInitialScreen(User? user) async {
    // 1. Logged Out
    if (user == null) {
      Get.offAllNamed(AppRouteNames.login);
      return;
    }

    // 2. Clear Stack
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // 3. Fetch Role
      DocumentSnapshot doc = await _db
          .collection('id_requests')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        String role = data['role'] ?? "Worker";
        String status = data['status'] ?? "Pending";

        // 🛑 Security Check
        if (status == 'Pending' || status == 'Rejected') {
          await _auth.signOut();
          Get.offAll(() => const StatusCheckScreen());
          return;
        }

        // ✅ Save Role Correctly
        await _storage.write('user_role', role);

        // ✅ Routing Logic
        if (role == 'Sales Manager') {
          Get.offAll(() => const SalesManagerDashboard());
        } else {
          Get.offAllNamed(AppRouteNames.mainWrapper);
        }
      } else {
        await _auth.signOut();
        Get.offAllNamed(AppRouteNames.login);
      }
    } catch (e) {
      print("Auth Error: $e");
      await _auth.signOut();
      Get.offAllNamed(AppRouteNames.login);
    }
  }

  // ✅ UPDATED LOGOUT FUNCTION (The "Terminator")
  Future<void> logout() async {
    try {
      // 1. Clear local storage
      await _storage.erase();

      // 2. Kill the UI immediately
      Get.offAllNamed(AppRouteNames.login);

      // 3. FORCE DELETE ALL ADMIN CONTROLLERS
      // This stops the Streams before we lose permission.

      if (Get.isRegistered<NavigationController>()) {
        Get.delete<NavigationController>(force: true);
      }

      // Fixes 'inventory' permission error
      if (Get.isRegistered<InventoryController>()) {
        Get.delete<InventoryController>(force: true);
      }

      // Fixes 'orders' permission error
      if (Get.isRegistered<AdminController>()) {
        Get.delete<AdminController>(force: true);
      }

      // Fixes 'packing_entries', 'stitching_entries' errors
      // (Assuming your report controller is named WorkerReportController based on your folder structure)
      if (Get.isRegistered<WorkerReportController>()) {
        Get.delete<WorkerReportController>(force: true);
      }

      // 4. Wait for cleanup (Critical Step)
      await Future.delayed(const Duration(milliseconds: 1000));

      // 5. NOW sign out
      await _auth.signOut();
    } catch (e) {
      Get.snackbar("Error", "Logout failed: $e");
    }
  }
}
