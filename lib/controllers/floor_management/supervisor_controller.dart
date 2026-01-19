import 'package:get/get.dart';

class SupervisorController extends GetxController {
  final supervisorName = "Justin Mason".obs;
  final supervisorRole = "Floor Supervisor".obs;
  final currentShift = "Morning Shift (A)".obs;

  void goToSection(String route) => Get.toNamed(route);
}
