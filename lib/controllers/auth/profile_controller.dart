import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../data/repositories/authentication_repository.dart';

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
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('id_requests')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          // Update UI with Real Data
          name.value = data['name'] ?? "User";
          email.value = data['email'] ?? "";
          role.value = data['role'] ?? "Worker";
          employeeId.value = data['employeeId'] ?? "N/A";
        }
      }
    } catch (e) {
      // Silent error or retry logic
      print("Error loading profile: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// ✅ CALL THE REPO FOR SAFE LOGOUT
  Future<void> logout() async {
    // This delegates the logic to AuthenticationRepository
    // which handles the correct "Navigation First, SignOut Second" order.
    await AuthenticationRepository.instance.logout();
  }
}
