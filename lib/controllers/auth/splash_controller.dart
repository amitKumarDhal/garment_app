import 'package:get/get.dart';
import '../../routes/route_names.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _startAnimation();
  }

  Future<void> _startAnimation() async {
    // Wait for 3 seconds
    await Future.delayed(const Duration(seconds: 3));

    // Safety check: Only redirect if still on splash
    if (Get.currentRoute == AppRouteNames.splash) {
      Get.offAllNamed(AppRouteNames.login);
    }
  }
}
