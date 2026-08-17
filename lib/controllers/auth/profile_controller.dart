import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../data/services/api_service.dart';
import '../../data/repositories/authentication_repository.dart';

class ProfileController extends GetxController {
  static ProfileController get instance => Get.find();

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

  Future<void> fetchUserProfile() async {
    try {
      isLoading.value = true;
      final localUser = ApiService.currentUser;
      if (localUser != null) {
        name.value = localUser['name'] ?? localUser['FullName'] ?? "User";
        email.value = localUser['email'] ?? localUser['Email'] ?? "";
        role.value = (localUser['role'] ?? localUser['Role'] ?? "UNIT_SUPERVISOR").toString().replaceAll('_', ' ');
        employeeId.value = localUser['employee_id'] ?? localUser['employeeId'] ?? localUser['EmployeeID'] ?? "N/A";
      }

      final response = await ApiService.get('/auth/profile');
      if (response['success'] == true && response['user'] != null) {
        final data = response['user'] as Map<String, dynamic>;
        name.value = data['name'] ?? "User";
        email.value = data['email'] ?? "";
        role.value = (data['role'] ?? "UNIT_SUPERVISOR").toString().replaceAll('_', ' ');
        employeeId.value = data['employee_id'] ?? "N/A";
        ApiService.saveSession(ApiService.token ?? '', data);
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await AuthenticationRepository.instance.logout();
  }
}