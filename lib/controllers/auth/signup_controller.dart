import 'package:cloud_firestore/cloud_firestore.dart'; // REQUIRED
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/route_names.dart';

class SignupController extends GetxController {
  final fullName = TextEditingController();
  final email = TextEditingController();
  final employeeId = TextEditingController();
  final password = TextEditingController();
  final signupFormKey = GlobalKey<FormState>();
  final isLoading = false.obs;

  // Added observables from previous login screens to match your UI needs
  final hidePassword = true.obs;
  final selectedRole = 'Worker'.obs;

  Future<void> submitIdRequest(String role) async {
    if (!signupFormKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      // 1. Save the request to Cloud Firestore 'id_requests' collection
      await FirebaseFirestore.instance.collection('id_requests').add({
        "name": fullName.text.trim(),
        "role": role,
        "email": email.text.trim(),
        "employeeId": employeeId.text.trim(),
        "password":
            password.text, // Store for later account creation after approval
        "unitApproved": false,
        "shiftApproved": false,
        "adminApproved": false,
        "status": "Pending", // Important for the AdminController filter
        "createdAt": FieldValue.serverTimestamp(),
      });

      // 2. Show success dialog
      Get.defaultDialog(
        title: "Request Sent",
        middleText: "Your request for $role has been submitted for approval.",
        onConfirm: () {
          _clearFields();
          Get.offAllNamed(AppRouteNames.login);
        },
        barrierDismissible: false,
      );
    } catch (e) {
      Get.snackbar("Error", "Could not submit request: $e");
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
    // Crucial for 8GB RAM: Dispose controllers to prevent memory leaks
    fullName.dispose();
    email.dispose();
    employeeId.dispose();
    password.dispose();
    super.onClose();
  }
}
