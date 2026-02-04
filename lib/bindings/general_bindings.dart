import 'package:get/get.dart';
import '../data/repositories/authentication_repository.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/admin/admin_controller.dart';

class GeneralBindings extends Bindings {
  @override
  void dependencies() {
    // 1. Authentication
    Get.put(AuthenticationRepository(), permanent: true);

    // 2. Navigation
    Get.put(NavigationController());

    // 3. ✅ THE PERMANENT FIX
    // DO NOT use lazyPut. Use 'put' with 'permanent: true'.
    // This forces the AdminController to stay alive forever.
    Get.put(AdminController(), permanent: true);
  }
}
