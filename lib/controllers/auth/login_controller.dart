import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

  // --- Roles List (Must match database strings) ---
  final List<String> roles = [
    'Admin',
    'Sales Manager',
    'Shift Supervisor',
    'Unit Supervisor',
    'Worker',
    'Sales Associate', // ✅ Updated Name
  ];

  final Map<String, IconData> roleIcons = {
    'Admin': Icons.admin_panel_settings_outlined,
    'Sales Manager': Icons.domain_verification,
    'Shift Supervisor': Icons.domain_outlined,
    'Unit Supervisor': Icons.engineering_outlined,
    'Worker': Icons.assignment_ind_outlined,
    'Sales Associate': Icons.support_agent,
  };

  // --- Login Logic ---
  Future<void> login() async {
    if (!loginFormKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      // 1. Authenticate with Firebase
      // ⚡ This triggers the AuthenticationRepository stream listener!
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: email.text.trim(),
            password: password.text.trim(),
          );

      // 2. Fetch Data for "Dropdown vs Database" Validation
      // We do this check to prevent users from logging in as the wrong role type
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('id_requests')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        
        // Normalize Data
        final String dbRole = (userData['role'] ?? 'Worker').toString().trim();
        final String selectedDropdownRole = selectedRole.value.trim();

        // --- 🛑 SECURITY CHECK: BLOCK MISMATCHED ROLES ---
        bool isRoleMismatch = dbRole != selectedDropdownRole;

        // ✅ EXCEPTION: Allow "Sales Agent" (DB) -> "Sales Associate" (App)
        if (dbRole == 'Sales Agent' && selectedDropdownRole == 'Sales Associate') {
          isRoleMismatch = false; 
        }

        if (isRoleMismatch) {
          // ⛔ Mismatch detected: Kick them out immediately
          await FirebaseAuth.instance.signOut(); 
          _showError("Access Denied!\nYou are registered as a '$dbRole', but selected '$selectedDropdownRole'.");
          return;
        }
      }
      
      // 3. SUCCESS!
      // We do NOT redirect here. 
      // The AuthenticationRepository has detected the login and is currently fetching the role
      // to redirect the user securely. We just stop the loading spinner.
      
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