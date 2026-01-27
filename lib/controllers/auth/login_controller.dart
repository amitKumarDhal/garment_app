import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../routes/route_names.dart';
import '../navigation_controller.dart';

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

  // --- Role Config (THIS WAS MISSING) ---
  final List<String> roles = [
    'Worker',
    'Unit Supervisor',
    'Shift Supervisor',
    'Admin',
  ];

  // FIX: Added the missing map here
  final Map<String, IconData> roleIcons = {
    'Worker': Icons.engineering_outlined,
    'Unit Supervisor': Icons.manage_accounts_outlined,
    'Shift Supervisor': Icons.supervisor_account_outlined,
    'Admin': Icons.admin_panel_settings_outlined,
  };

  /// --- Real Login Logic ---
  Future<void> login() async {
    if (!loginFormKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      // 1. Authenticate
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: email.text.trim(),
            password: password.text.trim(),
          );

      // 2. Fetch User Profile
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

      // 3. Security Checks
      if (dbStatus == 'Pending') {
        await FirebaseAuth.instance.signOut();
        _showError("Account awaiting approval.");
        return;
      } else if (dbStatus == 'Rejected') {
        await FirebaseAuth.instance.signOut();
        _showError("Account rejected.");
        return;
      }

      if (dbRole != selectedRole.value) {
        await FirebaseAuth.instance.signOut();
        _showError("You are not registered as a ${selectedRole.value}.");
        return;
      }

      // 4. Success - Save Data & Navigate
      GetStorage().write('user_role', dbRole);

      // Prepare Navigation Controller
      if (Get.isRegistered<NavigationController>()) {
        Get.delete<NavigationController>();
      }
      final navController = Get.put(NavigationController());

      if (dbRole == 'Admin') {
        navController.selectedIndex.value = 0;
      } else {
        navController.selectedIndex.value = 1;
      }

      Get.snackbar(
        "Welcome",
        "Logged in as ${userData['name']}",
        backgroundColor: Colors.green.withValues(alpha: 0.1),
        colorText: Colors.green,
      );

      Get.offAllNamed(AppRouteNames.mainWrapper);
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Login failed");
    } catch (e) {
      _showError("System Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _showError(String message) {
    Get.snackbar(
      "Access Denied",
      message,
      backgroundColor: Colors.red.withValues(alpha: 0.1),
      colorText: Colors.red,
    );
  }
}
