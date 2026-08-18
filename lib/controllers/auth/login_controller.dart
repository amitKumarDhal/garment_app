import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/api_service.dart';
import '../../data/repositories/authentication_repository.dart';

class LoginController extends GetxController {
  static LoginController get instance => Get.find();

  final email = TextEditingController();
  final password = TextEditingController();
  final loginFormKey = GlobalKey<FormState>();

  final isLoading = false.obs;
  final hidePassword = true.obs;
  final selectedRole = 'Sales Associate'.obs;

  final List<String> roles = [
    'Admin',
    'Sales Manager',
    'Unit Supervisor',
    'Sales Associate',
  ];

  final Map<String, IconData> roleIcons = {
    'Admin': Icons.admin_panel_settings_outlined,
    'Sales Manager': Icons.domain_verification,
    'Unit Supervisor': Icons.engineering_outlined,
    'Sales Associate': Icons.support_agent,
  };

  Future<void> login() async {
    if (!loginFormKey.currentState!.validate()) return;

    try {
      isLoading.value = true;
      final response = await ApiService.post('/auth/login', {
        'email': email.text.trim(),
        'password': password.text.trim(),
      });

      final data = response['data'] is Map<String, dynamic> ? response['data'] as Map<String, dynamic> : response;
      final token = (data['accessToken'] ?? data['token'] ?? response['token']) as String?;
      final user = (data['user'] ?? response['user']) as Map<String, dynamic>?;

      if (response['success'] == true && token != null && user != null) {
        final String dbRole = (user['role'] ?? 'SALES_ASSOCIATE').toString().replaceAll('_', ' ').toLowerCase().trim();
        final String selectedDropdownRole = selectedRole.value.toLowerCase().trim();

        bool isRoleMismatch = dbRole != selectedDropdownRole;
        if (dbRole == 'sales associate' && selectedDropdownRole == 'sales associate') {
          isRoleMismatch = false;
        }

        if (isRoleMismatch && dbRole != 'admin') {
          _showError("Access Denied!\nYou are registered as '$dbRole', but selected '${selectedRole.value}'.");
          return;
        }

        final refreshToken = (data['refreshToken'] ?? response['refreshToken']) as String?;
        final expiresAt = (data['expiresAt'] ?? response['expiresAt']) is int
            ? (data['expiresAt'] ?? response['expiresAt']) as int
            : null;

        ApiService.saveSession(token, user, refreshToken: refreshToken, expiresAt: expiresAt);
        await AuthenticationRepository.instance.checkAuthSession();
      } else {
        _showError(response['message']?.toString() ?? "Login failed");
      }
    } catch (e) {
      final cleanMessage = e.toString().replaceFirst(RegExp(r'^(Exception|ApiException):\s*'), '');
      _showError(cleanMessage);
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