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
    final isDark = Get.isDarkMode;

    Get.defaultDialog(
      title: "Secure Logout",
      titleStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      radius: 16,
      contentPadding: const EdgeInsets.all(20),

      // ✅ We use 'content' to safely build the layout and prevent the Black Screen Crash!
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Are you sure you want to log out of the Admin Panel?",
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // Custom Row safely limits the Expanded widgets
          Row(
            children: [
              // ✅ CANCEL BUTTON
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: isDark ? Colors.white : Colors.black87,
                    side: BorderSide(color: isDark ? Colors.white24 : Colors.black12, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),

              // ✅ LOGOUT BUTTON
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    // Show a quick loading spinner so the user knows it's working
                    Get.dialog(
                        const Center(child: CircularProgressIndicator(color: Colors.redAccent)),
                        barrierDismissible: false
                    );

                    // 1. Sign out of Firebase
                    await _auth.signOut();

                    // 2. Clear all navigation history and go to Login Screen
                    // Get.offAll(() => const LoginScreen());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}