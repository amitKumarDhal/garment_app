import 'package:get/get.dart';
import '../../data/services/api_service.dart';

class SupervisorController extends GetxController {
  static SupervisorController get instance => Get.find();

  final supervisorName = "Unit Supervisor".obs;
  final supervisorRole = "UNIT_SUPERVISOR".obs;
  final currentShift = "Morning Shift (A)".obs;

  @override
  void onInit() {
    super.onInit();
    _loadSupervisorProfile();
  }

  void _loadSupervisorProfile() {
    final user = ApiService.currentUser;
    if (user != null) {
      supervisorName.value = user['name'] ?? user['FullName'] ?? "Unit Supervisor";
      supervisorRole.value = (user['role'] ?? "UNIT_SUPERVISOR").toString();
    }
  }

  void goToSection(String route) {
    Get.toNamed(route);
  }
}
