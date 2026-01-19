import 'package:get/get.dart';
import 'login_controller.dart';

class ProfileController extends GetxController {
  var userName = "User Name".obs;
  var userEmail = "user@factory.com".obs;
  var supervisorId = "ID-Pending".obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  void _loadUserData() {
    if (Get.isRegistered<LoginController>()) {
      final loginCtrl = Get.find<LoginController>();
      if (loginCtrl.selectedRole.value == 'Admin') {
        userName.value = "Chief Admin";
        userEmail.value = "admin@factory.com";
        supervisorId.value = "ADM-2026-X";
      } else {
        userName.value = "Factory Worker";
        userEmail.value = loginCtrl.email.text.isNotEmpty
            ? loginCtrl.email.text
            : "worker@factory.com";
        supervisorId.value = "EMP-8829-B";
      }
    }
  }

  void logout() {
    userName.value = "";
    userEmail.value = "";
  }
}
