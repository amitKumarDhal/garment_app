class TTexts {
  TTexts._();

  // --- 🌍 Global Generic ---
  static const String appName = "Zobbra";
  static const String submit = "Submit";
  static const String save = "Save Entry";
  static const String cancel = "Cancel";
  static const String confirm = "Confirm"; // Added
  static const String delete = "Delete";   // Added
  static const String edit = "Edit";       // Added
  static const String search = "Search..."; // Added
  static const String logout = "Logout";   // Added

  // --- 🔐 Auth / Login ---
  static const String loginTitle = "Factory Manager";
  static const String loginSubTitle = "Select your role to access your dashboard";
  static const String requestAccount = "Need an account? Create ID Request";
  static const String pendingApproval = "Account Pending Approval"; // Added
  static const String loginButton = "Login"; // Added

  // --- 🏭 Department Titles ---
  static const String cuttingTitle = "Cutting Section";
  static const String printingTitle = "Printing Section";
  static const String stitchingTitle = "Stitching Section";
  static const String packingTitle = "Packing & Export";

  // --- 📦 Order & Sales Specific (NEW) ---
  static const String orderNo = "Order No.";
  static const String clientName = "Client Name";
  static const String productName = "Product Name";
  static const String quantity = "Quantity";
  static const String totalAmount = "Total Amount";
  static const String status = "Status";
  static const String requiresAction = "Requires Action";
  static const String approve = "Approve";
  static const String reject = "Reject";

  // --- 📋 Production Specific ---
  static const String styleNo = "Style Number";
  static const String workerName = "Worker Name";
  static const String dailyProduction = "Daily Production Log";
  static const String netGoodPieces = "Net Good Pieces";
  static const String defectivePieces = "Defective Pieces"; // Added

  // --- ⚠️ Validation & Alerts ---
  static const String emailRequired = "Official email/ID is required";
  static const String passwordRequired = "Password must be at least 6 characters";
  static const String fieldRequired = "This field is required";
  static const String success = "Success!"; // Added
  static const String error = "Error!";     // Added
  static const String confirmDelete = "Are you sure you want to delete this?"; // Added

  // --- 📭 Empty States (NEW) ---
  static const String noData = "No data available";
  static const String noOrders = "No orders found";
  static const String allCaughtUp = "You're all caught up!";
}