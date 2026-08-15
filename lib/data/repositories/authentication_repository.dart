import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../../routes/route_names.dart';
import '../../controllers/navigation_controller.dart';
import '../../screens/sales/manager/sales_manager_dashboard.dart';
import '../../screens/auth/status_check_screen.dart';

class AuthenticationRepository extends GetxController {
  static AuthenticationRepository get instance => Get.find();

  String currentLoggedInRole = 'unit supervisor';

  @override
  void onReady() {
    super.onReady();
    checkAuthSession();
  }

  Future<void> checkAuthSession() async {
    final token = ApiService.token;
    final user = ApiService.currentUser;

    if (token == null || user == null) {
      Get.offAllNamed(AppRouteNames.login);
      return;
    }

    try {
      final String rawRole = (user['role'] ?? 'UNIT_SUPERVISOR').toString();
      final String rawStatus = (user['status'] ?? 'APPROVED').toString();

      final String cleanRole = rawRole.toLowerCase().trim();
      final String cleanStatus = rawStatus.toLowerCase().trim();

      currentLoggedInRole = cleanRole;

      debugPrint("🔐 AUTH CHECK -> Role: $cleanRole | Status: $cleanStatus");

      if (cleanStatus == 'pending' || cleanStatus == 'rejected') {
        Get.offAll(() => const StatusCheckScreen());
        return;
      }

      _navigateToDashboard(cleanRole);
    } catch (e) {
      debugPrint("🚨 Auth Check Crash: $e");
      logout();
    }
  }

  void _navigateToDashboard(String role) {
    String exactRole = role.replaceAll(' ', '');

    if (exactRole == 'salesmanager') {
      Get.offAll(() => const SalesManagerDashboard());
    } else {
      if (Get.isRegistered<NavigationController>()) {
        Get.find<NavigationController>().updateRole(role);
      }
      Get.offAllNamed(AppRouteNames.mainWrapper, arguments: {'role': role});
    }
  }

  Future<void> logout() async {
    try {
      currentLoggedInRole = 'unit supervisor';
      ApiService.clearSession();
      Get.offAllNamed(AppRouteNames.login);
    } catch (e) {
      debugPrint("Logout Error: $e");
      Get.snackbar("Error", "Logout failed: $e", backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }
}