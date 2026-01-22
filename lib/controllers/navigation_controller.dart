import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yoobbel/screens/admin/admin_dashboard.dart';
import 'package:yoobbel/screens/floor_management/supervisor_menu_screen.dart';
import 'package:yoobbel/screens/profile/profile_screen.dart';

class NavigationController extends GetxController {
  static NavigationController get instance => Get.find();

  final Rx<int> selectedIndex = 0.obs;
  final RxBool isLoading = true.obs;

  // Dynamic Lists that change based on Role
  final RxList<Widget> screens = <Widget>[].obs;
  final RxList<BottomNavigationBarItem> navItems =
      <BottomNavigationBarItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    _restoreSession();
  }

  void changeIndex(int index) => selectedIndex.value = index;

  void _restoreSession() async {
    isLoading.value = true;
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('id_requests')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          String role = userDoc['role'] ?? 'Worker';

          if (role == 'Admin') {
            // --- ADMIN VIEW ---
            screens.value = [
              const AdminDashboard(),
              const SupervisorMenuScreen(), // Admin can also see floor menu
              const ProfileScreen(),
            ];
            navItems.value = const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: "Admin",
              ),
              BottomNavigationBarItem(icon: Icon(Icons.layers), label: "Floor"),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: "Profile",
              ),
            ];
          } else {
            // --- SUPERVISOR / WORKER VIEW ---
            screens.value = [
              const SupervisorMenuScreen(),
              const Center(child: Text("My Tasks")), // Placeholder
              const ProfileScreen(),
            ];
            navItems.value = const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
              BottomNavigationBarItem(icon: Icon(Icons.list), label: "Tasks"),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: "Profile",
              ),
            ];
          }
        }
      } catch (e) {
        print("Error restoring session: $e");
      }
    }
    isLoading.value = false;
  }
}
