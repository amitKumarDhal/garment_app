import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../admin/admin_controller.dart';
import '../../routes/route_names.dart';

class SignupController extends GetxController {
  final fullName = TextEditingController();
  final email = TextEditingController();
  final employeeId = TextEditingController();
  final password = TextEditingController();
  final signupFormKey = GlobalKey<FormState>();
  final isLoading = false.obs;

  Future<void> submitIdRequest(String role) async {
    if (!signupFormKey.currentState!.validate()) return;

    try {
      isLoading.value = true;
      await Future.delayed(const Duration(seconds: 1));

      final adminController = Get.find<AdminController>();
      adminController.pendingRequests.add({
        "id": "USR${DateTime.now().millisecondsSinceEpoch}",
        "name": fullName.text.trim(),
        "role": role,
        "email": email.text.trim(),
        "employeeId": employeeId.text.trim(),
        "unitApproved": false,
        "shiftApproved": false,
        "adminApproved": false,
      });
      adminController.updateBadgeCount();

      Get.defaultDialog(
        title: "Request Sent",
        middleText: "Your request for $role has been submitted for approval.",
        onConfirm: () {
          _clearFields();
          Get.offAllNamed(AppRouteNames.login);
        },
        barrierDismissible: false,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _clearFields() {
    fullName.clear();
    email.clear();
    employeeId.clear();
    password.clear();
  }

  @override
  void onClose() {
    fullName.dispose();
    email.dispose();
    employeeId.dispose();
    password.dispose();
    super.onClose();
  }
}
