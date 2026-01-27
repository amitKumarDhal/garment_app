import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart'; // CRITICAL FOR SPEED
import 'package:yoobbel/utils/theme/theme.dart';
import 'bindings/general_bindings.dart';
import 'routes/route_names.dart';
import 'routes/app_routes.dart';
import 'firebase_options.dart';

void main() async {
  // 1. Ensure Flutter Engine is ready (MUST BE FIRST)
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Local Storage (Critical for Instant Speed)
  await GetStorage.init();

  // 3. Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 4. UI Styling (Transparent Status Bar)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // 5. Lock Orientation
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((
    _,
  ) {
    runApp(const App());
  });
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Yoobbel Production',
      debugShowCheckedModeBanner: false,

      // Theme Settings
      themeMode: ThemeMode.system,
      theme: TAppTheme.lightTheme,
      darkTheme: TAppTheme.darkTheme,

      // Global Bindings (Auth Repository, etc.)
      initialBinding: GeneralBindings(),

      // Navigation Setup
      initialRoute: AppRouteNames.splash,
      getPages: AppRoutes.pages,

      // Smoother Transitions
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
