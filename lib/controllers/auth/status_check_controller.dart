import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/api_service.dart';

class StatusCheckController extends GetxController {
  final emailController = TextEditingController();
  final isLoading = false.obs;

  var requestData = Rxn<Map<String, dynamic>>();
  var hasSearched = false.obs;

  Future<void> checkStatus() async {
    if (emailController.text.isEmpty) {
      Get.snackbar("Error", "Please enter your email");
      return;
    }

    isLoading.value = true;
    hasSearched.value = true;
    requestData.value = null;

    try {
      final response = await ApiService.get('/auth/profile');
      if (response['success'] == true && response['user'] != null) {
        requestData.value = response['user'] as Map<String, dynamic>;
      } else {
        Get.snackbar(
          "Not Found",
          "No profile found for this email.",
          backgroundColor: Colors.orange.withValues(alpha: 0.1),
          colorText: Colors.orange,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to check status: $e",
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }
}