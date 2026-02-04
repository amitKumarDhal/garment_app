import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StatusCheckController extends GetxController {
  final emailController = TextEditingController();
  final isLoading = false.obs;

  // Stores the fetched data
  var requestData = Rxn<Map<String, dynamic>>();
  var hasSearched = false.obs;

  Future<void> checkStatus() async {
    if (emailController.text.isEmpty) {
      Get.snackbar("Error", "Please enter your email");
      return;
    }

    isLoading.value = true;
    hasSearched.value = true;
    requestData.value = null; // Reset previous result

    try {
      // Find the user document by email
      final querySnapshot = await FirebaseFirestore.instance
          .collection('id_requests')
          .where('email', isEqualTo: emailController.text.trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        requestData.value = querySnapshot.docs.first.data();
      } else {
        Get.snackbar(
          "Not Found",
          "No ID request found for this email.",
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
