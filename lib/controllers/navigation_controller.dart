import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:yoobbel/screens/admin/admin_dashboard.dart';
import 'package:yoobbel/screens/floor_management/supervisor_menu_screen.dart';
import 'package:yoobbel/screens/profile/profile_screen.dart';

class NavigationController extends GetxController {
  static NavigationController get instance => Get.find();

  final Rx<int> selectedIndex = 0.obs;
  final RxBool isLoading = true.obs;

  // Dynamic Lists
  final RxList<Widget> screens = <Widget>[].obs;
  final RxList<BottomNavigationBarItem> navItems =
      <BottomNavigationBarItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initializeMenu();
  }

  void changeIndex(int index) => selectedIndex.value = index;

  void _initializeMenu() async {
    // 1. Check Arguments (FASTEST)
    if (Get.arguments != null && Get.arguments is Map) {
      String? argRole = Get.arguments['role'];
      if (argRole != null) {
        _setupRoleBasedUI(argRole);
        return;
      }
    }

    // 2. Check Local Storage (FAST)
    final deviceStorage = GetStorage();
    String? cachedRole = deviceStorage.read('user_role');
    if (cachedRole != null) {
      _setupRoleBasedUI(cachedRole);
      return;
    }

    // 3. Fallback: Fetch from Internet (SLOW)
    await _fetchRoleFromNetwork();
  }

  // Helper to set up the lists without duplicating logic
  void _setupRoleBasedUI(String role) {
    List<Widget> newScreens = [];
    List<BottomNavigationBarItem> newItems = [];

    if (role == 'Admin') {
      // --- ADMIN VIEW ---
      newScreens = [
        const AdminDashboard(),
        const SupervisorMenuScreen(),
        const ProfileScreen(),
      ];
      newItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Admin"),
        BottomNavigationBarItem(icon: Icon(Icons.layers), label: "Floor"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ];
    } else {
      // --- SUPERVISOR / WORKER VIEW ---
      newScreens = [
        const SupervisorMenuScreen(),
        const Center(child: Text("My Tasks")),
        const ProfileScreen(),
      ];
      newItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.list), label: "Tasks"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ];
    }

    // --- CRITICAL FIX: Use assignAll() to force UI update ---
    screens.assignAll(newScreens);
    navItems.assignAll(newItems);

    // Stop loading AFTER data is set
    isLoading.value = false;
  }

  Future<void> _fetchRoleFromNetwork() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('id_requests')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          String role = userDoc['role'] ?? 'Worker';
          GetStorage().write('user_role', role);
          _setupRoleBasedUI(role);
        }
      } catch (e) {
        // Handle error
      }
    }
    isLoading.value = false;
  }
}
