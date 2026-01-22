import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../routes/route_names.dart';

class AuthenticationRepository extends GetxController {
  static AuthenticationRepository get instance => Get.find();

  // Firebase Variables
  final _auth = FirebaseAuth.instance;
  late final Rx<User?> firebaseUser;

  @override
  void onReady() {
    // Bind the firebase user to a reactive variable
    firebaseUser = Rx<User?>(_auth.currentUser);
    firebaseUser.bindStream(_auth.userChanges());

    // Ever is a GetX worker that listens to changes and triggers a function
    ever(firebaseUser, _setInitialScreen);
  }

  // Choose where the app goes based on Auth Status
  _setInitialScreen(User? user) {
    if (user == null) {
      Get.offAllNamed(AppRouteNames.login);
    } else {
      Get.offAllNamed(AppRouteNames.supervisorMenu);
    }
  }

  // --- Auth Methods ---
  Future<void> logout() async => await _auth.signOut();
}
