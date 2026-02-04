import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../routes/route_names.dart';

// ✅ IMPORTS FOR REDIRECTION
import '../../screens/sales/manager/sales_manager_dashboard.dart'; // Manager Screen
import '../../screens/auth/status_check_screen.dart'; // Status Check Screen

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

  /// ✅ REDIRECTION LOGIC
  Future<void> _setInitialScreen(User? user) async {
    // 1. If logged out, go to Login
    if (user == null) {
      Get.offAllNamed(AppRouteNames.login);
      return;
    }

    // 2. Wait for stack to clear
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // 3. Check Role & Status in Firestore
      DocumentSnapshot doc = await _db
          .collection('id_requests')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        String role = data['role'] ?? "Worker";
        String status = data['status'] ?? "Pending";

        // 🛑 SECURITY CHECK: Kick out if Pending or Rejected
        if (status == 'Pending' || status == 'Rejected') {
          await _auth.signOut();
          Get.offAll(() => const StatusCheckScreen());
          return;
        }

        // ✅ Save Role Locally
        await _storage.write('role', role);

        // ✅ ROUTING LOGIC
        if (role == 'Sales Manager') {
          // Managers get the special standalone dashboard
          Get.offAll(() => const SalesManagerDashboard());
        } else {
          // Agents, Workers, Admin go to MainWrapper (Tabs handled by NavigationController)
          Get.offAllNamed(AppRouteNames.mainWrapper);
        }
      } else {
        // Fallback if profile is missing
        await _auth.signOut();
        Get.offAllNamed(AppRouteNames.login);
      }
    } catch (e) {
      print("Auth Error: $e");
      await _auth.signOut();
      Get.offAllNamed(AppRouteNames.login);
    }
  }

  Future<void> logout() async {
    try {
      await _storage.erase();
      Get.offAllNamed(AppRouteNames.login);
      await Future.delayed(const Duration(milliseconds: 500));
      await _auth.signOut();
    } catch (e) {
      Get.snackbar("Error", "Logout failed: $e");
    }
  }
}
