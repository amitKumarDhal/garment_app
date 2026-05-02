import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../data/models/order_model.dart';

class AdminAnalyticsController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  var isLoading = true.obs;
  var allOrders = <OrderModel>[].obs;

  var selectedTab = 'All'.obs;

  // ✅ NEW: Tracks the specific sub-category tapped (e.g., "Sports Jersey")
  var selectedSubFilter = 'All Categories'.obs;

  var selectedTimeframe = 'All Time'.obs;
  final List<String> timeframes = [
    'All Time', 'This Month', 'Last 3 Months', 'Last 6 Months', 'Last 12 Months', 'This FY'
  ];

  var totalOrders = 0.obs;
  var totalRevenue = 0.0.obs;
  var averageOrderValue = 0.0.obs;

  var regionalPerformance = <Map<String, dynamic>>[].obs;
  var topState = "N/A".obs;
  var topStateCount = 0.obs;

  var selectedRegionSort = 'Orders'.obs;

  final List<String> categoryOptions = ['Sports Jersey', 'Business Promotional', 'Team/Staff Wear', 'Specific Event Use', 'Others'];
  final List<String> fabricOptions = ['Dotknit 160GSM', 'Nokia 120GSM', 'SpunMatty 220GSM', 'PC Matty 240GSM', 'Others'];
  final List<String> neckOptions = ['Round Neck', 'Collared Neck', 'Others'];

  @override
  void onInit() {
    super.onInit();
    fetchAnalyticsData();
  }

  // ✅ NEW: Dynamically generates the list of chips based on the active tab
  List<String> get currentSubOptions {
    if (selectedTab.value == 'Category') return ['All Categories', ...categoryOptions];
    if (selectedTab.value == 'Fabric') return ['All Fabrics', ...fabricOptions];
    if (selectedTab.value == 'Neck Type') return ['All Neck Types', ...neckOptions];
    return [];
  }

  double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    return 0.0;
  }

  int _parseInt(dynamic val) {
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) return int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    return 0;
  }

  Future<void> fetchAnalyticsData({bool showSpinner = true}) async {
    try {
      if (showSpinner) isLoading.value = true;

      // =======================================================================
      // ✅ OPTIMIZED: Added serverAndCache.
      // Since this controller downloads the ENTIRE database to allow for instant
      // offline tab-switching, this single line saves thousands of reads by
      // utilizing local phone memory for historical orders.
      // =======================================================================
      final snapshot = await _db.collection('orders').get(const GetOptions(source: Source.serverAndCache));

      List<OrderModel> validOrders = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          if (data['isDeleted'] != true && data['isDeleteRequested'] != true && data['isDeleted'] != "true") {
            validOrders.add(OrderModel.fromSnapshot(doc));
          }
        } catch (e) {}
      }

      allOrders.value = validOrders;
      _calculateMetrics();
    } finally {
      if (showSpinner) isLoading.value = false;
    }
  }

  void switchTab(String tab) {
    selectedTab.value = tab;
    // Reset the sub-filter chip back to "All" whenever the main tab is changed
    if (tab != 'All') {
      selectedSubFilter.value = currentSubOptions.first;
    } else {
      selectedSubFilter.value = '';
    }
    _calculateMetrics();
  }

  // ✅ NEW: Triggered when a sub-filter chip is clicked
  void setSubFilter(String filter) {
    selectedSubFilter.value = filter;
    _calculateMetrics();
  }

  void setRegionSort(String sortType) {
    selectedRegionSort.value = sortType;
    _calculateMetrics();
  }

  void setTimeframe(String tf) {
    selectedTimeframe.value = tf;
    _calculateMetrics();
  }

  String _classifyProduct(Map<String, dynamic> product, String tab) {
    String pName = (product['productName'] ?? '').toString().toLowerCase();
    String pCode = (product['productCode'] ?? '').toString().toLowerCase();

    if (tab == 'Category') {
      String cat = (product['productType'] ?? '').toString().trim().toLowerCase();
      for (var opt in categoryOptions) {
        if (cat.contains('team') && opt.toLowerCase().contains('team')) return opt;
        if (cat == opt.toLowerCase()) return opt;
      }
      return 'Others';
    } else if (tab == 'Fabric') {
      String fab = (product['fabricType'] ?? '').toString().trim().toLowerCase();
      if (fab.contains('spun') || pName.contains('spun') || pCode.contains('spun')) return 'SpunMatty 220GSM';
      if (fab.contains('nokia') || pName.contains('nokia') || pCode.contains('nokia')) return 'Nokia 120GSM';
      if (fab.contains('dotknit') || pName.contains('dotknit') || pCode.contains('dryfit')) return 'Dotknit 160GSM';
      if (fab.contains('pc') || pName.contains('pc matty') || pCode.contains('pc')) return 'PC Matty 240GSM';
      return 'Others';
    } else if (tab == 'Neck Type') {
      String neck = (product['neckType'] ?? '').toString().trim().toLowerCase();
      if (neck.contains('collar') || pName.contains('polo')) return 'Collared Neck';
      if (neck.contains('round') || pName.contains('round')) return 'Round Neck';
      return 'Others';
    }
    return 'Unknown';
  }

  void _calculateMetrics() {
    DateTime now = DateTime.now();
    List<OrderModel> timeFilteredOrders = [];

    // 1. Time Filter
    if (selectedTimeframe.value == 'All Time') {
      timeFilteredOrders = List.from(allOrders);
    } else {
      for (var order in allOrders) {
        try {
          DateTime? d = order.createdAt ?? order.orderDate;
          bool inTime = false;
          if (selectedTimeframe.value == 'This Month') {
            inTime = (d.year == now.year && d.month == now.month);
          } else if (selectedTimeframe.value == 'Last 3 Months') inTime = d.isAfter(DateTime(now.year, now.month - 3, now.day));
          else if (selectedTimeframe.value == 'Last 6 Months') inTime = d.isAfter(DateTime(now.year, now.month - 6, now.day));
          else if (selectedTimeframe.value == 'Last 12 Months') inTime = d.isAfter(DateTime(now.year - 1, now.month, now.day));
          else if (selectedTimeframe.value == 'This FY') {
            int startYear = now.month >= 4 ? now.year : now.year - 1;
            inTime = d.isAfter(DateTime(startYear, 4, 1)) || d.isAtSameMomentAs(DateTime(startYear, 4, 1));
          }
          if (inTime) timeFilteredOrders.add(order);
        } catch (e) {}
      }
    }

    double globalRev = 0.0;
    int globalValidOrders = 0;
    Map<String, Map<String, dynamic>> stateStats = {};

    bool isSpecificFilter = selectedTab.value != 'All' && !selectedSubFilter.value.startsWith('All');

    for (var order in timeFilteredOrders) {
      String status = (order.status).toString().toLowerCase();
      if (status == 'pending' || status == 'placed' || status == 'rejected') continue;

      double effRev = _parseDouble(order.effectiveRevenue);
      double totalAmt = _parseDouble(order.totalAmount);

      // Accurately calculates margin proportion for orders with multiple items
      double revenueRatio = (effRev > 0 && totalAmt > 0) ? (effRev / totalAmt) : 1.0;

      String state = (order.state != null && order.state!.isNotEmpty) ? order.state! : "Unknown";

      double orderValidRev = 0.0;
      int orderValidUnits = 0;
      bool hasMatch = false;

      List<dynamic> safeProducts = [];
      try { safeProducts = order.products; } catch(e) {}

      Map<String, double> tempBreakdownRev = {};
      Map<String, int> tempBreakdownUnits = {};

      for (var rawProduct in safeProducts) {
        Map<String, dynamic> product = (rawProduct is Map) ? rawProduct as Map<String, dynamic> : rawProduct.toJson();
        int q = _parseInt(product['qty'] ?? product['quantity']);
        double pPrice = _parseDouble(product['price']);
        double pTotal = (pPrice * q) * revenueRatio;

        if (selectedTab.value != 'All') {
          String classification = _classifyProduct(product, selectedTab.value);

          // ✅ If a specific chip is selected (e.g. "Sports Jersey"), skip non-matching products!
          if (isSpecificFilter && classification != selectedSubFilter.value) {
            continue;
          }

          tempBreakdownRev[classification] = (tempBreakdownRev[classification] ?? 0.0) + pTotal;
          tempBreakdownUnits[classification] = (tempBreakdownUnits[classification] ?? 0) + q;
        }

        orderValidRev += pTotal;
        orderValidUnits += q;
        hasMatch = true;
      }

      if (hasMatch) {
        globalValidOrders++;
        globalRev += orderValidRev;

        if (!stateStats.containsKey(state)) {
          stateStats[state] = {'count': 0, 'revenue': 0.0, 'units': 0, 'breakdown': <String, Map<String, dynamic>>{}};
        }

        stateStats[state]!['count'] += 1;
        stateStats[state]!['revenue'] += orderValidRev;
        stateStats[state]!['units'] += orderValidUnits;

        if (selectedTab.value != 'All') {
          var bMap = stateStats[state]!['breakdown'] as Map<String, Map<String, dynamic>>;
          tempBreakdownRev.forEach((cat, rev) {
            if (!bMap.containsKey(cat)) bMap[cat] = {'count': 0, 'revenue': 0.0, 'units': 0};
            bMap[cat]!['count'] += 1;
            bMap[cat]!['revenue'] += rev;
            bMap[cat]!['units'] += tempBreakdownUnits[cat]!;
          });
        }
      }
    }

    totalOrders.value = globalValidOrders;
    totalRevenue.value = globalRev;
    averageOrderValue.value = globalValidOrders > 0 ? (globalRev / globalValidOrders) : 0.0;

    var sortedStates = stateStats.entries.toList();
    if (selectedRegionSort.value == 'Orders') sortedStates.sort((a, b) => b.value['count'].compareTo(a.value['count']));
    else if (selectedRegionSort.value == 'Units') sortedStates.sort((a, b) => b.value['units'].compareTo(a.value['units']));
    else sortedStates.sort((a, b) => b.value['revenue'].compareTo(a.value['revenue']));

    List<Map<String, dynamic>> regions = [];
    for (var entry in sortedStates) {
      double pct = globalRev > 0 ? (entry.value['revenue'] / globalRev) * 100 : 0.0;

      List<Map<String, dynamic>> finalBreakdown = [];

      // ✅ Only show breakdown list if viewing "All Categories" (otherwise it's redundant)
      if (selectedTab.value != 'All' && !isSpecificFilter) {
        var bMap = entry.value['breakdown'] as Map<String, Map<String, dynamic>>;
        var bSorted = bMap.entries.toList();
        bSorted.sort((a, b) => b.value['revenue'].compareTo(a.value['revenue']));
        for (var b in bSorted) {
          finalBreakdown.add({'name': b.key, 'count': b.value['count'], 'units': b.value['units'], 'revenue': b.value['revenue']});
        }
      }

      regions.add({
        'state': entry.key, 'count': entry.value['count'], 'revenue': entry.value['revenue'],
        'units': entry.value['units'], 'percentage': pct, 'breakdown': finalBreakdown
      });
    }
    regionalPerformance.value = regions;

    if (sortedStates.isNotEmpty) {
      var bestState = sortedStates.first;
      if (bestState.key == "Unknown" && sortedStates.length > 1) {
        bestState = sortedStates[1];
      }
      topState.value = bestState.key;
      topStateCount.value = bestState.value['count'];
    } else {
      topState.value = "N/A";
      topStateCount.value = 0;
    }
  }

}