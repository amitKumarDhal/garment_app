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
        // ✅ FIX 1: Query the permanent 'users' collection, not 'id_requests'
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;

          // ✅ FIX 2: Dual-case safety (handles both old and new data structures)
          name.value = data['name'] ?? data['FullName'] ?? "Unknown User";
          email.value = data['email'] ?? data['Email'] ?? "";
          role.value = data['role'] ?? data['Role'] ?? "Worker";
          employeeId.value = data['employeeId'] ?? data['EmployeeID'] ?? "N/A";
        }
      }
    } catch (e) {
      print("Error loading profile: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// ✅ CALL THE REPO FOR SAFE LOGOUT
  Future<void> logout() async {
    await AuthenticationRepository.instance.logout();
  }
}