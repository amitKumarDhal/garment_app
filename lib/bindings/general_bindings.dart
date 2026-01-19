import 'package:get/get.dart';

// Comment these out for now until the files are created and Firebase is ready
// import 'package:your_app_name/data/repositories/auth_repo.dart';
// import 'package:your_app_name/data/repositories/approval_repo.dart';

class GeneralBindings extends Bindings {
  @override
  void dependencies() {
    // We will initialize these once we build the actual classes.
    // For now, this is empty so the app doesn't crash on missing imports.
    
    // Get.put(AuthRepository()); 
  }
}