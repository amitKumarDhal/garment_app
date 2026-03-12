import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  static LoginController get instance => Get.find();

  final email = TextEditingController();
  final password = TextEditingController();
  final loginFormKey = GlobalKey<FormState>();

  final isLoading = false.obs;
  final hidePassword = true.obs;
  final selectedRole = 'Worker'.obs;

  final List<String> roles = [
    'Admin',
    'Sales Manager',
    'Shift Supervisor',
    'Unit Supervisor',
    'Worker',
    'Sales Associate',
  ];

  final Map<String, IconData> roleIcons = {
    'Admin': Icons.admin_panel_settings_outlined,
    'Sales Manager': Icons.domain_verification,
    'Shift Supervisor': Icons.domain_outlined,
    'Unit Supervisor': Icons.engineering_outlined,
    'Worker': Icons.assignment_ind_outlined,
    'Sales Associate': Icons.support_agent,
  };

  Future<void> login() async {
    if (!loginFormKey.currentState!.validate()) return;

    try {
      isLoading.value = true;
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email.text.trim(), password: password.text.trim());

      Map<String, dynamic>? userData;

      // Check 'users' first
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();
      if (userDoc.exists) {
        userData = userDoc.data() as Map<String, dynamic>;
      } else {
        // Fallback to 'id_requests'
        DocumentSnapshot requestDoc = await FirebaseFirestore.instance.collection('id_requests').doc(userCredential.user!.uid).get();
        if (requestDoc.exists) userData = requestDoc.data() as Map<String, dynamic>;
      }

      if (userData != null) {
        // ✅ MAGIC FIX: Convert all database keys to lowercase in memory
        final safeData = userData.map((key, value) => MapEntry(key.toLowerCase(), value));

        final String dbRole = (safeData['role'] ?? 'Worker').toString().trim();
        final String selectedDropdownRole = selectedRole.value.trim();

        bool isRoleMismatch = dbRole.toLowerCase() != selectedDropdownRole.toLowerCase();

        if (dbRole.toLowerCase() == 'sales agent' && selectedDropdownRole.toLowerCase() == 'sales associate') {
          isRoleMismatch = false;
        }

        if (isRoleMismatch) {
          await FirebaseAuth.instance.signOut();
          _showError("Access Denied!\nYou are registered as a '$dbRole', but selected '$selectedDropdownRole'.");
          return;
        }
      } else {
        await FirebaseAuth.instance.signOut();
        _showError("Access Denied!\nNo profile found in the system.");
        return;
      }
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
      duration: const Duration(seconds: 4),
    );
  }
}