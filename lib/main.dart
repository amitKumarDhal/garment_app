import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:yoobbel/utils/theme/theme.dart';
import 'bindings/general_bindings.dart';
import 'routes/route_names.dart';
import 'routes/app_routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set System UI Overlay (Status Bar & Navigation Bar colors)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Lock Orientation to Portrait for industrial consistency
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
      title: 'Yoobbel',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system, // Switches based on phone settings
      theme: TAppTheme.lightTheme,
      darkTheme: TAppTheme.darkTheme,

      // Global Dependency Injection
      initialBinding: GeneralBindings(),

      // Navigation Logic
      initialRoute: AppRouteNames.splash,
      getPages: AppRoutes.pages,

      // Default transition for a premium feel
      defaultTransition: Transition.cupertino,
    );
  }
}
