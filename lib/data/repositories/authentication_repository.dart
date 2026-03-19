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

      // 1. Try to get user from 'users' collection
      DocumentSnapshot userDoc = await _db.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        userData = userDoc.data() as Map<String, dynamic>;
      } else {
        // 2. Try to get user from 'id_requests' collection
        DocumentSnapshot requestDoc = await _db.collection('id_requests').doc(user.uid).get();
        if (requestDoc.exists) {
          userData = requestDoc.data() as Map<String, dynamic>;
        }
      }

      if (userData != null) {
        // 🚨 BULLETPROOF DATA EXTRACTION 🚨
        // Get the role, checking both 'role' and 'Role' keys, default to 'worker'
        String rawRole = (userData['role'] ?? userData['Role'] ?? 'worker').toString();
        // Get the status, checking both 'status' and 'Status' keys, default to 'pending'
        String rawStatus = (userData['status'] ?? userData['Status'] ?? 'pending').toString();

        // Convert everything to lowercase and trim spaces to ensure perfect matching
        String cleanRole = rawRole.toLowerCase().trim();
        String cleanStatus = rawStatus.toLowerCase().trim();

        debugPrint("🔐 AUTH CHECK -> Role: $cleanRole | Status: $cleanStatus");

        // Check if the user is allowed in
        if (cleanStatus == 'pending' || cleanStatus == 'rejected') {
          // Send to Status screen, but DO NOT sign them out here!
          // The Status Screen needs them logged in to check their status stream.
          Get.offAll(() => const StatusCheckScreen());
          return;
        }

        // If they are approved, send them to the correct dashboard
        _navigateToDashboard(cleanRole);
      } else {
        // No document found at all
        debugPrint("🚨 Auth Check: No profile found in DB for ${user.uid}");
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
    // Remove all spaces for exact matching (e.g., 'sales manager' -> 'salesmanager')
    String exactRole = role.replaceAll(' ', '');

    if (exactRole == 'salesmanager') {
      Get.offAll(() => const SalesManagerDashboard());
    } else {
      Get.offAllNamed(AppRouteNames.mainWrapper);
    }
  }

  Future<void> logout() async {
    try {
      Get.offAllNamed(AppRouteNames.login);

      if (Get.isRegistered<NavigationController>()) Get.delete<NavigationController>(force: true);
      if (Get.isRegistered<InventoryController>()) Get.delete<InventoryController>(force: true);
      if (Get.isRegistered<AdminController>()) Get.delete<AdminController>(force: true);
      if (Get.isRegistered<WorkerReportController>()) Get.delete<WorkerReportController>(force: true);

      if (Get.isRegistered<UnitSupervisorController>()) Get.delete<UnitSupervisorController>(force: true);
      if (Get.isRegistered<StockSummaryController>()) Get.delete<StockSummaryController>(force: true);
      if (Get.isRegistered<StockInOutController>()) Get.delete<StockInOutController>(force: true);

      await Future.delayed(const Duration(milliseconds: 500));
      await _auth.signOut();
    } catch (e) {
      Get.snackbar("Error", "Logout failed: $e");
    }
  }
}