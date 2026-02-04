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
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email.text.trim(),
            password: password.text.trim(),
          );

      String uid = userCredential.user!.uid;

      // --- LOGIC UPDATE: Determine Pre-Approvals ---
      // ✅ CHANGED 'Sales Agent' to 'Sales Associate' here
      // Sales Associates, Managers, and Admins skip Unit/Shift approval.
      bool bypassLowerLevels =
          (role == 'Sales Associate' ||
          role == 'Sales Manager' ||
          role == 'Admin');

      // 2. Prepare User Data (For id_requests model)
      final newUser = UserModel(
        id: uid,
        name: fullName.text.trim(),
        email: email.text.trim(),
        employeeId: employeeId.text.trim(),
        role: role,
        status: "Pending",

        // Auto-approve lower levels so Admin is the only gatekeeper
        unitApproved: bypassLowerLevels ? true : false,
        shiftApproved: bypassLowerLevels ? true : false,
        adminApproved: false, // Always requires final Admin check

        createdAt: DateTime.now(),
      );

      // 3. BATCH WRITE: Save to BOTH 'id_requests' AND 'users'
      // This ensures the profile exists immediately so "New Order" works correctly.
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Ref 1: Request for Admin Approval
      DocumentReference requestRef = FirebaseFirestore.instance
          .collection('id_requests')
          .doc(uid);

      // Ref 2: Actual User Profile (Vital for fetching Name in App)
      DocumentReference userProfileRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid);

      // Data for 'users' collection
      Map<String, dynamic> userData = {
        "FullName": fullName.text.trim(), // ✅ Key field for "New Order" logic
        "Email": email.text.trim(),
        "Role": role,
        "EmployeeID": employeeId.text.trim(),
        "Status": "Pending",
        "CreatedAt": FieldValue.serverTimestamp(),
      };

      batch.set(requestRef, newUser.toJson());
      batch.set(userProfileRef, userData);

      await batch.commit();

      // 4. Force Sign Out (Critical)
      // Prevents auto-login to dashboard before approval
      await FirebaseAuth.instance.signOut();

      // 5. Success Feedback & Redirect
      Get.defaultDialog(
        title: "Request Submitted",
        middleText: bypassLowerLevels
            ? "Your request has been sent directly to the System Admin for approval."
            : "Your ID request has been sent to the $role hierarchy.",
        textConfirm: "OK",
        confirmTextColor: Colors.white,
        buttonColor: Colors.green,
        onConfirm: () {
          Get.back(); // Close dialog
          Get.offAllNamed(AppRouteNames.login); // Go to Login
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
    fullName.dispose();
    email.dispose();
    employeeId.dispose();
    password.dispose();
    super.onClose();
  }
}
