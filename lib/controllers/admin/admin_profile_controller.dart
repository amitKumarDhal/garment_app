import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminProfileController extends GetxController {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // Observables for the UI
  var adminName = "Loading...".obs;
  var adminEmail = "Loading...".obs;

  @override
  void onInit() {
    super.onInit();
    fetchAdminDetails();
  }

  // --- Fetch Admin Details ---
  Future<void> fetchAdminDetails() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        adminEmail.value = user.email ?? "No Email";

        // Fetch name from the Firestore 'users' collection
        final userDoc = await _db.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          adminName.value = userDoc.data()?['FullName'] ?? userDoc.data()?['Name'] ?? "Master Admin";
        } else {
          // Fallback to Firebase Auth Display Name
          adminName.value = user.displayName ?? "Master Admin";
        }
      }
    } catch (e) {
      debugPrint("Error fetching admin details: $e");
    }
  }

  // --- Secure Logout ---
  void confirmLogout() {
    Get.defaultDialog(
      title: "Secure Logout",
      titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      middleText: "Are you sure you want to log out of the Admin Panel?",
      textConfirm: "Logout",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      cancelTextColor: Colors.black87,
      onConfirm: () async {
        // 1. Sign out of Firebase
        await _auth.signOut();

        // 2. Clear all navigation history and go to Login Screen
        // Get.offAll(() => const LoginScreen());
      },
    );
  }
}