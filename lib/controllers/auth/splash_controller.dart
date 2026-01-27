import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../routes/route_names.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // FIX: Prevents "setState() called during build" crash
    await Future.delayed(Duration.zero);

    final deviceStorage = GetStorage();
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // --- SPEED CHECK: READ FROM LOCAL STORAGE FIRST ---
      String? cachedRole = deviceStorage.read('user_role');

      if (cachedRole != null) {
        // FOUND IT! NAVIGATE INSTANTLY
        _goToDashboard(cachedRole);
      } else {
        // CACHE MISS: FALLBACK TO INTERNET
        await _fetchRoleFromFirestore(user.uid);
      }
    } else {
      // No user logged in -> Go to Login
      Get.offAllNamed(AppRouteNames.login);
    }
  }

  // --- Helper 1: Navigate with Arguments ---
  void _goToDashboard(String role) {
    // CRITICAL FIX: We pass the 'role' as an argument.
    // This ensures the next screen knows which tab to open, even
    // if the controller is reset during navigation.
    Get.offAllNamed(AppRouteNames.mainWrapper, arguments: {'role': role});
  }

  // --- Helper 2: Fallback Fetcher (Internet) ---
  Future<void> _fetchRoleFromFirestore(String uid) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('id_requests')
          .doc(uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        String role = data['role'] ?? "Worker";

        // Save to local storage for next time
        GetStorage().write('user_role', role);

        _goToDashboard(role);
      } else {
        Get.offAllNamed(AppRouteNames.login);
      }
    } catch (e) {
      Get.offAllNamed(AppRouteNames.login);
    }
  }
}
