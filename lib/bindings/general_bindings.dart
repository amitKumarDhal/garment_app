import 'package:get/get.dart';
import '../data/repositories/authentication_repository.dart';

class GeneralBindings extends Bindings {
  @override
  void dependencies() {
    // Inject the Authentication Repository at the Root Level
    // It remains in memory as long as the app is open
    Get.put(AuthenticationRepository());
  }
}
