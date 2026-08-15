import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/api_service.dart';
import '../../routes/route_names.dart';

class SignupController extends GetxController {
  static SignupController get instance => Get.find();

  final fullName = TextEditingController();
  final email = TextEditingController();
  final employeeId = TextEditingController();
  final password = TextEditingController();
  final signupFormKey = GlobalKey<FormState>();

  final isLoading = false.obs;
  final hidePassword = true.obs;

  Future<void> submitIdRequest(String role) async {
    if (!signupFormKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      String backendRole = 'SALES_ASSOCIATE';
      final cleanRole = role.toLowerCase().trim();
      if (cleanRole == 'sales manager') {
        backendRole = 'SALES_MANAGER';
      } else if (cleanRole == 'unit supervisor' || cleanRole == 'supervisor') {
        backendRole = 'UNIT_SUPERVISOR';
      } else if (cleanRole == 'sales associate' || cleanRole == 'sales agent') {
        backendRole = 'SALES_ASSOCIATE';
      }

      final response = await ApiService.post('/auth/register', {
        'name': fullName.text.trim(),
        'email': email.text.trim(),
        'password': password.text.trim(),
        'employee_id': employeeId.text.trim(),
        'role': backendRole,
      });

      if (response['success'] == true) {
        Get.defaultDialog(
          title: "Request Submitted",
          middleText: "Your registration request has been sent to the System Administrator for approval.",
          textConfirm: "OK",
          confirmTextColor: Colors.white,
          buttonColor: Colors.green,
          onConfirm: () {
            Get.back();
            Get.offAllNamed(AppRouteNames.login);
          },
          barrierDismissible: false,
        );
      } else {
        Get.snackbar(
          "Registration Failed",
          response['message'] ?? "Registration failed",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Something went wrong: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
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
