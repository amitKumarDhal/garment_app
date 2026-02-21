import 'package:firebase_auth/firebase_auth.dart';
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

      // Firebase handles the heavy lifting here
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );

      // Success Feedback
      Get.back(); // Kick them back to the login screen
      Get.snackbar(
        "Link Dispatched",
        "A secure password reset link has been sent to your email.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha:0.15),
        colorText: Colors.green,
        duration: const Duration(seconds: 5),
        icon: const Icon(Icons.mark_email_read_rounded, color: Colors.green),
      );

    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        "Recovery Failed",
        e.message ?? "Could not send reset link. Verify your email.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withValues(alpha:0.15),
        colorText: Colors.redAccent,
        icon: const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
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