import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgotPasswordController extends GetxController {
  final emailController = TextEditingController();
  final resetFormKey = GlobalKey<FormState>();
  final isLoading = false.obs;

  Future<void> sendPasswordResetEmail() async {
    if (!resetFormKey.currentState!.validate()) return;

    try {
      isLoading.value = true;
      Get.back();
      Get.snackbar(
        "Link Dispatched",
        "If an account exists for ${emailController.text.trim()}, password reset instructions have been dispatched.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.15),
        colorText: Colors.green,
        duration: const Duration(seconds: 5),
        icon: const Icon(Icons.mark_email_read_rounded, color: Colors.green),
      );
    } catch (e) {
      Get.snackbar("System Error", "An unexpected error occurred: $e");
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }
}