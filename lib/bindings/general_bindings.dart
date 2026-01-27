import 'package:get/get.dart';
import '../data/repositories/authentication_repository.dart';

class GeneralBindings extends Bindings {
  @override
  void dependencies() {
    // Inject Authentication Repository
    // 'permanent: true' ensures it is never deleted from memory
    Get.put(AuthenticationRepository(), permanent: true);
  }
}
