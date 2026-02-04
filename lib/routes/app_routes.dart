import 'package:get/get.dart';
import 'package:yoobbel/controllers/auth/login_controller.dart';
import 'package:yoobbel/screens/sales/manager/sales_manager_dashboard.dart';
import 'route_names.dart';

// --- Screens ---
// Auth
import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/status_check_screen.dart';

// Admin
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/pending_approvals_screen.dart';
import '../screens/admin/production_reports_screen.dart';
import '../screens/admin/inventory_screen.dart';
import '../screens/admin/worker_list_screen.dart';

// Core
import '../screens/main_wrapper.dart';

// Floor / Factory
import '../screens/floor_management/supervisor_menu_screen.dart';
import '../screens/floor_management/cutting_entry_screen.dart';
import '../screens/floor_management/printing_entry_screen.dart';
import '../screens/floor_management/stitching_entry_screen.dart';
import '../screens/floor_management/packing_entry_screen.dart';
import '../screens/floor_management/factory_stock_summary_screen.dart';

// Marketing / Sales
import '../screens/floor_management/agent_list_screen.dart';
import '../screens/floor_management/marketing_upload_screen.dart';
import '../screens/sales/sales_dashboard.dart';
// Ensure this exists if you use it

// --- Controllers ---
import '../controllers/auth/splash_controller.dart';
import '../controllers/auth/signup_controller.dart';
import '../controllers/admin/admin_controller.dart';
import '../controllers/admin/inventory_controller.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/floor_management/marketing_controller.dart';

// ✅ CRITICAL FIX: Alias the controller import to avoid name conflict with the Screen
import '../controllers/floor_management/marketing_upload_controller.dart'
    as upload_ctrl;

import '../controllers/floor_management/cutting_controller.dart';
import '../controllers/floor_management/printing_controller.dart';
import '../controllers/floor_management/stitching_controller.dart';
import '../controllers/floor_management/packing_controller.dart';

class AppRoutes {
  static final pages = [
    // --- 1. SPLASH & AUTH ---
    GetPage(
      name: AppRouteNames.splash,
      page: () => const SplashScreen(),
      binding: BindingsBuilder(() {
        Get.put(SplashController());
      }),
    ),
    GetPage(
      name: AppRouteNames.login,
      page: () => const LoginScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => LoginController());
      }),
    ),
    GetPage(
      name: AppRouteNames.signup,
      page: () => const SignupScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => SignupController());
      }),
    ),
    GetPage(
      name: AppRouteNames.statusCheck,
      page: () => const StatusCheckScreen(),
    ),

    // --- 2. MAIN SHELL (Navigation Wrapper) ---
    GetPage(
      name: AppRouteNames.mainWrapper,
      page: () => const MainWrapper(),
      transition: Transition.fadeIn,
      binding: BindingsBuilder(() {
        Get.put(NavigationController());
        Get.lazyPut(() => AdminController());
      }),
    ),

    // --- 3. ADMIN SECTION ---
    GetPage(
      name: AppRouteNames.adminDashboard,
      page: () => const AdminDashboard(),
    ),
    GetPage(
      name: AppRouteNames.pendingApprovals,
      page: () => const PendingApprovalsScreen(),
    ),
    GetPage(
      name: AppRouteNames.inventory,
      page: () => const InventoryScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => InventoryController());
      }),
    ),
    GetPage(
      name: AppRouteNames.productionReports,
      page: () => const ProductionReportsScreen(),
    ),
    GetPage(
      name: AppRouteNames.workerList,
      page: () => const WorkerListScreen(),
    ),

    // --- 4. SALES & MARKETING SECTION ---
    GetPage(
      name: AppRouteNames.salesDashboard,
      page: () => const SalesDashboard(),
    ),
    GetPage(
      name: AppRouteNames.salesManagerDashboard,
      page: () => const SalesManagerDashboard(),
    ),
    GetPage(
      name: AppRouteNames.agentList,
      page: () => const AgentListScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => MarketingController());
      }),
    ),
    GetPage(
      name: AppRouteNames.marketingUpload,
      page: () => const MarketingUploadScreen(),
      binding: BindingsBuilder(() {
        // ✅ USE THE ALIAS HERE TO REFER TO THE CONTROLLER
        Get.lazyPut(() => upload_ctrl.MarketingUploadController());
      }),
    ),

    // --- 5. FACTORY FLOOR SECTION ---
    GetPage(
      name: AppRouteNames.supervisorMenu,
      page: () => const SupervisorMenuScreen(),
    ),
    GetPage(
      name: AppRouteNames.cuttingEntry,
      page: () => const CuttingEntryScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => CuttingController());
      }),
    ),
    GetPage(
      name: AppRouteNames.printingEntry,
      page: () => const PrintingEntryScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => PrintingController());
      }),
    ),
    GetPage(
      name: AppRouteNames.stitchingEntry,
      page: () => const StitchingEntryScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => StitchingController());
      }),
    ),
    GetPage(
      name: AppRouteNames.packingEntry,
      page: () => const PackingEntryScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => PackingController());
      }),
    ),
    GetPage(
      name: AppRouteNames.factoryStock,
      page: () => const FactoryStockSummaryScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => PackingController());
      }),
    ),
  ];
}
