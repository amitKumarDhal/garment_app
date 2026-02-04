import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../../routes/route_names.dart';
import '../../../../controllers/navigation_controller.dart';
import '../../screens/sales/sales_dashboard.dart';
import '../../screens/sales/manager/sales_manager_dashboard.dart';

class LoginController extends GetxController {
  static LoginController get instance => Get.find();

  // --- Controllers & Keys ---
  final email = TextEditingController();
  final password = TextEditingController();
  final loginFormKey = GlobalKey<FormState>();

  // --- Observables ---
  final isLoading = false.obs;
  final hidePassword = true.obs;
  final selectedRole = 'Worker'.obs;

  // --- ✅ UPDATED HIERARCHY ---
  final List<String> roles = [
    'Admin',
    'Sales Manager',
    'Shift Supervisor',
    'Unit Supervisor',
    'Worker',
    'Sales Associate', // ✅ Changed from 'Sales Agent'
  ];

  final Map<String, IconData> roleIcons = {
    'Admin': Icons.admin_panel_settings_outlined,
    'Sales Manager': Icons.domain_verification,
    'Shift Supervisor': Icons.domain_outlined,
    'Unit Supervisor': Icons.engineering_outlined,
    'Worker': Icons.assignment_ind_outlined,
    'Sales Associate': Icons.support_agent, // ✅ Updated Key
  };

  /// --- Login Logic ---
  Future<void> login() async {
    if (!loginFormKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      // 1. Authenticate with Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: email.text.trim(),
            password: password.text.trim(),
          );

      // 2. Fetch User Profile from Firestore
      // We look in 'id_requests' because that's where the specific role/status lives
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('id_requests')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        await FirebaseAuth.instance.signOut();
        _showError("User record not found.");
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final dbStatus = userData['status'] ?? 'Pending';
      final dbRole = userData['role'] ?? 'Worker';

      // 3. Security Checks (Status & Role Match)
      if (dbStatus == 'Pending') {
        await FirebaseAuth.instance.signOut();
        _showError("Account awaiting approval.");
        return;
      } else if (dbStatus == 'Rejected') {
        await FirebaseAuth.instance.signOut();
        _showError("Account rejected.");
        return;
      }

      // 4. Success - Save Data
      GetStorage().write('user_role', dbRole);

      // --- RESET NAVIGATION CONTROLLER ---
      if (Get.isRegistered<NavigationController>()) {
        Get.delete<NavigationController>();
      }
      Get.put(NavigationController());

      Get.snackbar(
        "Welcome",
        "Logged in as ${userData['name']}",
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );

      // 5. ✅ REDIRECT BASED ON ROLE
      _redirectUser(dbRole);
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Login failed");
    } catch (e) {
      _showError("System Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ NEW: Smart Redirection updated for 'Sales Associate'
  void _redirectUser(String role) {
    if (role == 'Sales Manager' || role == 'manager') {
      Get.offAll(() => const SalesManagerDashboard());
    }
    // ✅ Updated to check for 'Sales Associate' (Keep 'Agent' for old users)
    else if (role == 'Sales Associate' ||
        role == 'Sales Agent' ||
        role == 'sales_agent') {
      Get.offAll(() => const SalesDashboard());
    } else {
      // Default for Admin, Workers, Supervisors
      Get.offAllNamed(AppRouteNames.mainWrapper);
    }
  }

  void _showError(String message) {
    Get.snackbar(
      "Access Denied",
      message,
      backgroundColor: Colors.red.withOpacity(0.1),
      colorText: Colors.red,
    );
  }
}
