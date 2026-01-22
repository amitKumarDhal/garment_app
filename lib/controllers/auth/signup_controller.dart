import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yoobbel/data/models/newUser_model.dart';
import '../../routes/route_names.dart';

class SignupController extends GetxController {
  static SignupController get instance => Get.find();

  // --- Form Controllers ---
  final fullName = TextEditingController();
  final email = TextEditingController();
  final employeeId = TextEditingController();
  final password = TextEditingController();
  final signupFormKey = GlobalKey<FormState>();

  // --- Observables ---
  final isLoading = false.obs;
  final hidePassword = true.obs;

  /// Main function called by the Submit button
  Future<void> submitIdRequest(String role) async {
    if (!signupFormKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      // 1. Create User in Firebase Authentication
      // This creates the secure login credentials
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email.text.trim(),
            password: password.text.trim(),
          );

      // 2. Prepare User Data using UserModel
      final newUser = UserModel(
        id: userCredential.user!.uid,
        name: fullName.text.trim(),
        email: email.text.trim(),
        employeeId: employeeId.text.trim(),
        role: role,
        status: "Pending", // Crucial for Admin Approval Queue
        unitApproved: false,
        shiftApproved: false,
        adminApproved: false,
        createdAt: DateTime.now(),
      );

      // 3. Save to Firestore 'id_requests' collection
      await FirebaseFirestore.instance
          .collection('id_requests')
          .doc(newUser.id)
          .set(newUser.toJson());

      // 4. Success Feedback & Redirect
      Get.defaultDialog(
        title: "Request Submitted",
        middleText:
            "Your ID request has been sent to the $role hierarchy for approval.",
        textConfirm: "OK",
        confirmTextColor: Colors.white,
        onConfirm: () {
          // Close dialog and go to Login
          Get.back();
          Get.offAllNamed(AppRouteNames.login);
        },
        barrierDismissible: false,
      );
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        "Registration Failed",
        _handleAuthError(e.code),
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
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

  // Helper to make error messages user-friendly
  String _handleAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return "This email is already registered.";
      case 'invalid-email':
        return "Please enter a valid email address.";
      case 'weak-password':
        return "Password is too weak. Try a stronger one.";
      default:
        return "An unknown error occurred.";
    }
  }

  @override
  void onClose() {
    // Memory cleanup for 8GB RAM optimization
    fullName.dispose();
    email.dispose();
    employeeId.dispose();
    password.dispose();
    super.onClose();
  }
}
