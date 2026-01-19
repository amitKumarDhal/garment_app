import 'package:get/get.dart';
import 'route_names.dart';

// Screens
import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/pending_approvals_screen.dart';
import '../screens/main_wrapper.dart';
import '../screens/floor_management/supervisor_menu_screen.dart';
import '../screens/floor_management/agent_list_screen.dart';
import '../screens/floor_management/marketing_upload_screen.dart'; // NEW
import '../screens/floor_management/cutting_entry_screen.dart';
import '../screens/floor_management/printing_entry_screen.dart';
import '../screens/floor_management/stitching_entry_screen.dart';
import '../screens/floor_management/packing_entry_screen.dart';

// Controllers
import '../controllers/auth/splash_controller.dart';
import '../controllers/auth/signup_controller.dart';
import '../controllers/admin/admin_controller.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/floor_management/marketing_controller.dart'; // NEW
import '../controllers/floor_management/marketing_upload_controller.dart'; // NEW
import '../controllers/floor_management/cutting_controller.dart';
import '../controllers/floor_management/printing_controller.dart';
import '../controllers/floor_management/stitching_controller.dart';
import '../controllers/floor_management/packing_controller.dart';

class AppRoutes {
  static final pages = [
    // Splash
    GetPage(
      name: AppRouteNames.splash,
      page: () => const SplashScreen(),
      binding: BindingsBuilder(() => Get.put(SplashController())),
    ),

    // Auth
    GetPage(
      name: AppRouteNames.login,
      page: () => const LoginScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRouteNames.signup,
      page: () => const SignupScreen(),
      binding: BindingsBuilder(() => Get.lazyPut(() => SignupController())),
    ),

    // Main Shell
    GetPage(
      name: AppRouteNames.mainWrapper,
      page: () => const MainWrapper(),
      binding: BindingsBuilder(() {
        Get.put(NavigationController());
        Get.put(AdminController());
      }),
    ),

    // Admin
    GetPage(
      name: AppRouteNames.adminDashboard,
      page: () => const AdminDashboard(),
    ),
    GetPage(
      name: AppRouteNames.pendingApprovals,
      page: () => const PendingApprovalsScreen(),
    ),

    // Supervisor Floor
    GetPage(
      name: AppRouteNames.supervisorMenu,
      page: () => const SupervisorMenuScreen(),
    ),

    // Floor Management Sections
    GetPage(
      name: AppRouteNames.cuttingEntry,
      page: () => const CuttingEntryScreen(),
      binding: BindingsBuilder(() => Get.lazyPut(() => CuttingController())),
    ),
    GetPage(
      name: AppRouteNames.printingEntry,
      page: () => const PrintingEntryScreen(),
      binding: BindingsBuilder(() => Get.lazyPut(() => PrintingController())),
    ),
    GetPage(
      name: AppRouteNames.stitchingEntry,
      page: () => const StitchingEntryScreen(),
      binding: BindingsBuilder(() => Get.lazyPut(() => StitchingController())),
    ),
    GetPage(
      name: AppRouteNames.packingEntry,
      page: () => const PackingEntryScreen(),
      binding: BindingsBuilder(() => Get.lazyPut(() => PackingController())),
    ),

    // Marketing Section
    GetPage(
      name: AppRouteNames.agentList,
      page: () => const AgentListScreen(),
      binding: BindingsBuilder(() => Get.lazyPut(() => MarketingController())),
    ),
    GetPage(
      name: AppRouteNames
          .marketingUpload, // Ensure this exists in your route_names.dart
      page: () => const MarketingUploadScreen(),
      binding: BindingsBuilder(
        () => Get.lazyPut(() => MarketingUploadController()),
      ),
    ),
  ];
}
