import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/route_names.dart';

import '../../controllers/navigation_controller.dart';
import '../../controllers/admin/inventory_controller.dart';
import '../../controllers/admin/admin_controller.dart';
import '../../controllers/admin/worker_report_controller.dart';

import '../../screens/sales/manager/sales_manager_dashboard.dart';
import '../../screens/auth/status_check_screen.dart';

import '../../controllers/production/unit_supervisor_controller.dart';
import '../../controllers/production/stock_summary_controller.dart';
import '../../controllers/production/stock_in_out_controller.dart';

class AuthenticationRepository extends GetxController {
  static AuthenticationRepository get instance => Get.find();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  late final Rx<User?> firebaseUser;

  // 🛡️ MEMORY VAULT: Securely hold the role
  String currentLoggedInRole = 'worker';

  @override
  void onReady() {
    firebaseUser = Rx<User?>(_auth.currentUser);
    firebaseUser.bindStream(_auth.userChanges());
    ever(firebaseUser, _setInitialScreen);
  }

  Future<void> _setInitialScreen(User? user) async {
    if (user == null) {
      Get.offAllNamed(AppRouteNames.login);
      return;
    }

    try {
      Map<String, dynamic>? userData;

      DocumentSnapshot userDoc = await _db.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        userData = userDoc.data() as Map<String, dynamic>;
      } else {
        DocumentSnapshot requestDoc = await _db.collection('id_requests').doc(user.uid).get();
        if (requestDoc.exists) {
          userData = requestDoc.data() as Map<String, dynamic>;
        }
      }

      if (userData != null) {
        String rawRole = (userData['role'] ?? userData['Role'] ?? 'worker').toString();
        String rawStatus = (userData['status'] ?? userData['Status'] ?? 'pending').toString();

        String cleanRole = rawRole.toLowerCase().trim();
        String cleanStatus = rawStatus.toLowerCase().trim();

        // 🛡️ LOCK ROLE INTO MEMORY
        currentLoggedInRole = cleanRole;

        debugPrint("🔐 AUTH CHECK -> Role: $cleanRole | Status: $cleanStatus");

        if (cleanStatus == 'pending' || cleanStatus == 'rejected') {
          Get.offAll(() => const StatusCheckScreen());
          return;
        }

        _navigateToDashboard(cleanRole);
      } else {
        await _auth.signOut();
        Get.offAllNamed(AppRouteNames.login);
      }
    } catch (e) {
      debugPrint("🚨 Auth Check Crash: $e");
      await _auth.signOut();
      Get.offAllNamed(AppRouteNames.login);
    }
  }

  void _navigateToDashboard(String role) {
    String exactRole = role.replaceAll(' ', '');

    if (exactRole == 'salesmanager') {
      Get.offAll(() => const SalesManagerDashboard());
    } else {
      // 🛡️ TRIPLE-THREAT FIX:
      // 1. Force the controller to update if it's already awake
      if (Get.isRegistered<NavigationController>()) {
        Get.find<NavigationController>().updateRole(role);
      }

      // 2. Pass the argument in the route just in case
      Get.offAllNamed(AppRouteNames.mainWrapper, arguments: {'role': role});
    }
  }

  Future<void> logout() async {
    try {
      // Clears the memory vault on logout
      currentLoggedInRole = 'worker';
      await _auth.signOut();
    } catch (e) {
      debugPrint("Logout Error: $e");
      Get.snackbar("Error", "Logout failed: $e", backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }
}