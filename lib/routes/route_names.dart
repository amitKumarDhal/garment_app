class AppRouteNames {
  // --- Auth ---
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String statusCheck = '/status-check';

  // --- Navigation Shell ---
  static const String mainWrapper = '/main-wrapper';

  // --- Sales & Marketing ---
  static const String salesDashboard = '/sales-dashboard';
  static const String salesManagerDashboard =
      '/sales-manager-dashboard'; // ✅ NEW
  static const String agentList = '/agent-list';
  static const String agentDetail = '/agent-detail';
  static const String clientDetail = '/client-detail';
  static const String marketingUpload = '/marketing-upload';
  static const String inventory = '/inventory'; // ✅ Verified

  // --- Supervisor / Production ---
  static const String supervisorMenu = '/supervisor-menu';
  static const String cuttingEntry = '/cutting-entry';
  static const String printingEntry = '/printing-entry';
  static const String stitchingEntry = '/stitching-entry';
  static const String packingEntry = '/packing-entry';
  static const String factoryStock = '/factory-stock';

  // --- Admin ---
  static const String adminDashboard = '/admin-dashboard';
  static const String pendingApprovals = '/pending-approvals';
  static const String productionReports = '/production-reports'; // ✅ ADDED
  static const String workerList = '/worker-list'; // ✅ ADDED
}
