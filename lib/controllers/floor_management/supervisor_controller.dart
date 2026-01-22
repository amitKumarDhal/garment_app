import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class SupervisorController extends GetxController {
  static SupervisorController get instance => Get.find();

  // Observable variables
  final supervisorName = "Loading...".obs;
  final supervisorRole = "".obs;
  final currentShift =
      "Morning Shift (A)".obs; // You can make this dynamic later

  @override
  void onInit() {
    super.onInit();
    _loadSupervisorProfile();
  }

  /// Fetches the real name of the logged-in user
  void _loadSupervisorProfile() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('id_requests') // Same collection used in Signup
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          supervisorName.value = data['name'] ?? "Supervisor";
          supervisorRole.value = data['role'] ?? "Worker";
        }
      } catch (e) {
        print("Error loading supervisor profile: $e");
        supervisorName.value = "Unknown User";
      }
    }
  }

  void goToSection(String route) {
    Get.toNamed(route);
  }
}
