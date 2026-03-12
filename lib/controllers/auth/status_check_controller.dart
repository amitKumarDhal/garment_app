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
      // Force lowercase to match the database standard
      String searchEmail = emailController.text.trim().toLowerCase();

      // =================================================================
      // 1. FIRST CHECK: Look in the 'users' collection (Approved Users)
      // =================================================================
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: searchEmail)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        // User found in 'users'! They are approved.
        Map<String, dynamic> data = userQuery.docs.first.data();

        // We force the status to 'Approved' just in case the DB has weird formatting
        data['status'] = 'Approved';
        requestData.value = data;
      }
      else {
        // =================================================================
        // 2. SECOND CHECK: Look in 'id_requests' (Pending/Rejected Users)
        // =================================================================
        final requestQuery = await FirebaseFirestore.instance
            .collection('id_requests')
            .where('email', isEqualTo: searchEmail)
            .limit(1)
            .get();

        if (requestQuery.docs.isNotEmpty) {
          // Found their pending/rejected request
          requestData.value = requestQuery.docs.first.data();
        }
        else {
          // Not found in either collection
          Get.snackbar(
            "Not Found",
            "No profile or pending request found for this email.",
            backgroundColor: Colors.orange.withValues(alpha: 0.1),
            colorText: Colors.orange,
          );
        }
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