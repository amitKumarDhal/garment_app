import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/route_names.dart';

class LoginController extends GetxController {
  static LoginController get instance => Get.find();

  final email = TextEditingController();
  final password = TextEditingController();
  final loginFormKey = GlobalKey<FormState>();

  final isLoading = false.obs;
  final hidePassword = true.obs;
  final selectedRole = 'Worker'.obs;

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

  Future<void> login() async {
    if (!loginFormKey.currentState!.validate()) return;

    try {
      isLoading.value = true;
      await Future.delayed(const Duration(seconds: 2));

      // Simulated Logic: admin@factory.com or worker@factory.com with pass '123456'
      final userEmail = email.text.trim().toLowerCase();
      if ((userEmail == "admin@factory.com" ||
              userEmail == "worker@factory.com") &&
          password.text == "123456") {
        Get.offAllNamed(AppRouteNames.mainWrapper);
      } else {
        Get.snackbar(
          "Error",
          "Invalid credentials for ${selectedRole.value}",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    email.dispose();
    password.dispose();
    super.onClose();
  }
}
