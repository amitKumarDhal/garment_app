import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../routes/route_names.dart';
import '../../controllers/navigation_controller.dart';

class ProfileController extends GetxController {
  static ProfileController get instance => Get.find();

  // Observable variables for UI
  final RxString name = "Loading...".obs;
  final RxString email = "".obs;
  final RxString role = "".obs;
  final RxString employeeId = "".obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserProfile();
  }

  /// Fetches REAL user details from Firestore
  Future<void> fetchUserProfile() async {
    try {
      isLoading.value = true;
      // 1. Get the current logged-in user's ID
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // 2. Fetch their document from the 'id_requests' collection
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('id_requests')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          // 3. Update UI with Real Data
          name.value = data['name'] ?? "User";
          email.value = data['email'] ?? "";
          role.value = data['role'] ?? "Worker";
          employeeId.value = data['employeeId'] ?? "N/A";
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Could not load profile data.");
    } finally {
      isLoading.value = false;
    }
  }

  /// Handles secure logout
  Future<void> logout() async {
    try {
      // 1. Sign out from Firebase (Invalidates the session)
      await FirebaseAuth.instance.signOut();

      // 2. Delete the NavigationController
      // (This ensures the next user doesn't see the previous user's tabs)
      Get.delete<NavigationController>();

      // 3. Redirect to Login Screen
      Get.offAllNamed(AppRouteNames.login);
    } catch (e) {
      Get.snackbar("Error", "Logout failed: $e");
    }
  }
}
