import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/route_names.dart';

class LoginController extends GetxController {
  static LoginController get instance => Get.find();

  // --- Controllers & Keys ---
  final email = TextEditingController();
  final password = TextEditingController();
  final loginFormKey = GlobalKey<FormState>();

  // --- Observables ---
  final isLoading = false.obs;
  final hidePassword = true.obs;
  final selectedRole = 'Worker'.obs; // Default selection

  // --- Role Config ---
  final List<String> roles = [
    'Worker',
    'Unit Supervisor',
    'Shift Supervisor',
    'Admin',
  ];

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

      // 1. Authenticate with Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: email.text.trim(),
            password: password.text.trim(),
          );

      // 2. Fetch User Profile from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('id_requests')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        await FirebaseAuth.instance.signOut();
        _showError("User record not found. Please sign up first.");
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final dbStatus = userData['status'] ?? 'Pending';
      final dbRole = userData['role'] ?? 'Worker';

      // 3. Security Check: Is Account Approved?
      if (dbStatus == 'Pending') {
        await FirebaseAuth.instance.signOut();
        _showError("Account awaiting Admin approval.");
        return;
      } else if (dbStatus == 'Rejected') {
        await FirebaseAuth.instance.signOut();
        _showError("Account request was rejected.");
        return;
      }

      // 4. Security Check: Does Role Match?
      // Prevent a Worker from logging in as Admin by selecting it in the UI
      if (dbRole != selectedRole.value) {
        await FirebaseAuth.instance.signOut();
        _showError("You are not registered as a ${selectedRole.value}.");
        return;
      }

      // 5. Success - Navigate to Dashboard
      Get.snackbar(
        "Welcome Back",
        "Logged in as ${userData['name']}",
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );

      Get.offAllNamed(AppRouteNames.mainWrapper);
    } on FirebaseAuthException catch (e) {
      // Handle standard Firebase errors
      String message = "Login Failed";
      if (e.code == 'user-not-found') message = "No user found for this email.";
      if (e.code == 'wrong-password') message = "Incorrect password.";
      if (e.code == 'invalid-credential')
        message = "Invalid email or password.";
      _showError(message);
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
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withOpacity(0.1),
      colorText: Colors.red,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void onClose() {
    // Memory cleanup for 8GB RAM optimization
    email.dispose();
    password.dispose();
    super.onClose();
  }
}
