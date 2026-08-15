import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/api_service.dart';
import '../../data/repositories/authentication_repository.dart';

class AdminProfileController extends GetxController {
  final name = "".obs;
  final email = "".obs;
  final role = "Admin".obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      isLoading.value = true;
      final user = ApiService.currentUser;
      if (user != null) {
        name.value = user['name'] ?? user['FullName'] ?? 'Super Admin';
        email.value = user['email'] ?? user['Email'] ?? '';
        role.value = (user['role'] ?? 'ADMIN').toString().replaceAll('_', ' ');
      }
    } catch (e) {
      debugPrint("Admin Profile Load Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  RxString get adminName => name;
  RxString get adminEmail => email;

  Future<void> confirmLogout() async {
    await AuthenticationRepository.instance.logout();
  }

  Future<void> logout() async {
    await AuthenticationRepository.instance.logout();
  }
}