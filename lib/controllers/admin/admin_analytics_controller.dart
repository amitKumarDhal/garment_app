import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/order_model.dart';

class AdminAnalyticsController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Observables
  var isLoading = true.obs;
  var allOrders = <OrderModel>[].obs;

  var selectedTab = 'All'.obs;

  // Timeframe Observables
  var selectedTimeframe = 'All Time'.obs;
  final List<String> timeframes = [
    'All Time',
    'This Month',
    'Last 3 Months',
    'Last 6 Months',
    'Last 12 Months',
    'This FY'
  ];

  // Metrics Observables
  var totalOrders = 0.obs;
  var totalRevenue = 0.0.obs;
  var averageOrderValue = 0.0.obs;

  var regionalPerformance = <Map<String, dynamic>>[].obs;
  var topState = "N/A".obs;
  var topStateCount = 0.obs;

  var selectedRegionSort = 'Orders'.obs;

  final List<String> categoryOptions = [
    'Sports Jersey', 'Business Promotional', 'Team/Staff Wear', 'Specific Event Use', 'Others'
  ];
  final List<String> fabricOptions = [
    'Dotknit 160GSM', 'Nokia 120GSM', 'SpunMatty 220GSM', 'PC Matty 240GSM', 'Others'
  ];
  final List<String> neckOptions = [
    'Round Neck', 'Collared Neck', 'Others'
  ];

  @override
  void onInit() {
    super.onInit();
    fetchAnalyticsData();
  }

  double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    return 0.0;
  }

  Future<void> fetchAnalyticsData({bool showSpinner = true}) async {
    try {
      if (showSpinner) isLoading.value = true;

      final snapshot = await _db.collection('orders').get();

      List<OrderModel> validOrders = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          bool isDeleted = data['isDeleted'] == true || data['isDeleted'] == "true";
          bool isDeleteReq = data['isDeleteRequested'] == true || data['isDeleteRequested'] == "true";

          if (!isDeleted && !isDeleteReq) {
            validOrders.add(OrderModel.fromSnapshot(doc));
          }
        } catch (e) {
          debugPrint("Skipped corrupt order doc: ${doc.id}");
        }
      }

      allOrders.value = validOrders;
      _calculateMetrics();

    } catch (e) {
      debugPrint("Analytics Error: $e");
    } finally {
      if (showSpinner) isLoading.value = false;
    }
  }

  void switchTab(String tab) {
    selectedTab.value = tab;
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

  // ✅ NEW: Powerful classification engine for products
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
    }
    else if (tab == 'Fabric') {
      String fab = (product['fabricType'] ?? '').toString().trim().toLowerCase();
      if (fab.contains('spun') || pName.contains('spun') || pCode.contains('spun')) return 'SpunMatty 220GSM';
      if (fab.contains('nokia') || pName.contains('nokia') || pCode.contains('nokia')) return 'Nokia 120GSM';
      if (fab.contains('dotknit') || pName.contains('dotknit') || pCode.contains('dotknit') || pName.contains('dryfit') || pCode.contains('dryfit')) return 'Dotknit 160GSM';
      if (fab.contains('pc') || pName.contains('pc matty') || pCode.contains('pc')) return 'PC Matty 240GSM';
      return 'Others';
    }
    else if (tab == 'Neck Type') {
      String neck = (product['neckType'] ?? '').toString().trim().toLowerCase();
      if (neck.contains('collar') || pName.contains('collar') || pName.contains('polo')) return 'Collared Neck';
      if (neck.contains('round') || pName.contains('round')) return 'Round Neck';
      return 'Others';
    }
    return 'Unknown';
  }

  void _calculateMetrics() {
    DateTime now = DateTime.now();
    List<OrderModel> timeFilteredOrders = [];

    // 1. Apply Time Filter
    if (selectedTimeframe.value == 'All Time') {
      timeFilteredOrders = List.from(allOrders);
    } else {
      for (var order in allOrders) {
        try {
          DateTime? d = order.createdAt ?? order.orderDate;
          if (d == null) continue;

          bool inTime = false;
          if (selectedTimeframe.value == 'This Month') {
            inTime = (d.year == now.year && d.month == now.month);
          } else if (selectedTimeframe.value == 'Last 3 Months') {
            inTime = d.isAfter(DateTime(now.year, now.month - 3, now.day));
          } else if (selectedTimeframe.value == 'Last 6 Months') {
            inTime = d.isAfter(DateTime(now.year, now.month - 6, now.day));
          } else if (selectedTimeframe.value == 'Last 12 Months') {
            inTime = d.isAfter(DateTime(now.year - 1, now.month, now.day));
          } else if (selectedTimeframe.value == 'This FY') {
            int startYear = now.month >= 4 ? now.year : now.year - 1;
            DateTime fyStart = DateTime(startYear, 4, 1);
            inTime = d.isAfter(fyStart) || d.isAtSameMomentAs(fyStart);
          }

          if (inTime) timeFilteredOrders.add(order);
        } catch (e) {}
      }
    }

    // 2. Global Metrics Calculation
    double globalRev = 0.0;
    for (var order in timeFilteredOrders) {
      double effRev = _parseDouble(order.effectiveRevenue);
      double totalAmt = _parseDouble(order.totalAmount);
      String status = (order.status).toString().toLowerCase();

      if (status != 'pending' && status != 'placed' && status != 'rejected') {
        globalRev += (effRev > 0) ? effRev : totalAmt;
      }
    }

    totalOrders.value = timeFilteredOrders.length;
    totalRevenue.value = globalRev;
    averageOrderValue.value = timeFilteredOrders.isNotEmpty ? (globalRev / timeFilteredOrders.length) : 0.0;

    // 3. State & Breakdown Calculation
    Map<String, Map<String, dynamic>> stateStats = {};

    for (var order in timeFilteredOrders) {
      try {
        String state = (order.state != null && order.state!.isNotEmpty) ? order.state! : "Unknown";
        double effRev = _parseDouble(order.effectiveRevenue);
        double totalAmt = _parseDouble(order.totalAmount);
        String status = (order.status).toString().toLowerCase();

        bool isRevenueValid = (status != 'pending' && status != 'placed' && status != 'rejected');
        double orderRev = isRevenueValid ? ((effRev > 0) ? effRev : totalAmt) : 0.0;

        int orderUnits = 0;
        List<dynamic> safeProducts = [];
        try { safeProducts = order.products; } catch(e) {}

        // Initialize State Map if it doesn't exist
        if (!stateStats.containsKey(state)) {
          stateStats[state] = {
            'count': 0,
            'revenue': 0.0,
            'units': 0,
            'breakdown': <String, Map<String, dynamic>>{}
          };
        }

        stateStats[state]!['count'] += 1;
        stateStats[state]!['revenue'] += orderRev;

        Set<String> categoriesInThisOrder = {}; // To count unique orders per category

        // Process individual products for breakdown
        for (var rawProduct in safeProducts) {
          Map<String, dynamic> product = {};
          if (rawProduct is Map) product = rawProduct as Map<String, dynamic>;
          else try { product = rawProduct.toJson(); } catch(e) {}

          int q = 0;
          var rawQ = product['qty'] ?? product['quantity'];
          if (rawQ is int) q = rawQ;
          else if (rawQ is String) q = int.tryParse(rawQ.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          else if (rawQ is double) q = rawQ.toInt();

          double pPrice = _parseDouble(product['price']);
          double pTotal = isRevenueValid ? (pPrice * q) : 0.0; // Basic estimate for breakdown revenue

          orderUnits += q;

          // If a specific tab is selected, build the breakdown
          if (selectedTab.value != 'All') {
            String classification = _classifyProduct(product, selectedTab.value);
            categoriesInThisOrder.add(classification);

            var breakdownMap = stateStats[state]!['breakdown'] as Map<String, Map<String, dynamic>>;
            if (!breakdownMap.containsKey(classification)) {
              breakdownMap[classification] = {'count': 0, 'revenue': 0.0, 'units': 0};
            }
            breakdownMap[classification]!['units'] += q;
            breakdownMap[classification]!['revenue'] += pTotal;
          }
        }

        // Add to order count for the specific categories found in this order
        if (selectedTab.value != 'All') {
          var breakdownMap = stateStats[state]!['breakdown'] as Map<String, Map<String, dynamic>>;
          for (String cat in categoriesInThisOrder) {
            breakdownMap[cat]!['count'] += 1;
          }
        }

        stateStats[state]!['units'] += orderUnits;

      } catch(e) {}
    }

    if (stateStats.isNotEmpty) {
      var sortedStates = stateStats.entries.toList();

      // Sort States
      if (selectedRegionSort.value == 'Orders') {
        sortedStates.sort((a, b) => b.value['count'].compareTo(a.value['count']));
      } else if (selectedRegionSort.value == 'Units') {
        sortedStates.sort((a, b) => b.value['units'].compareTo(a.value['units']));
      } else {
        sortedStates.sort((a, b) => b.value['revenue'].compareTo(a.value['revenue']));
      }

      List<Map<String, dynamic>> regions = [];
      for (var entry in sortedStates) {
        double percentage = 0.0;
        if (selectedRegionSort.value == 'Orders' && timeFilteredOrders.isNotEmpty) {
          percentage = (entry.value['count'] / timeFilteredOrders.length) * 100;
        } else if (selectedRegionSort.value == 'Revenue' && globalRev > 0) {
          percentage = (entry.value['revenue'] / globalRev) * 100;
        } else if (selectedRegionSort.value == 'Units') {
          percentage = 100.0;
        }

        // Format breakdown for UI
        List<Map<String, dynamic>> finalBreakdown = [];
        if (selectedTab.value != 'All') {
          var bMap = entry.value['breakdown'] as Map<String, Map<String, dynamic>>;
          var bSorted = bMap.entries.toList();

          // Sort the sub-categories inside the state
          if (selectedRegionSort.value == 'Orders') {
            bSorted.sort((a, b) => b.value['count'].compareTo(a.value['count']));
          } else if (selectedRegionSort.value == 'Units') {
            bSorted.sort((a, b) => b.value['units'].compareTo(a.value['units']));
          } else {
            bSorted.sort((a, b) => b.value['revenue'].compareTo(a.value['revenue']));
          }

          for (var b in bSorted) {
            finalBreakdown.add({
              'name': b.key,
              'count': b.value['count'],
              'units': b.value['units'],
              'revenue': b.value['revenue']
            });
          }
        }

        regions.add({
          'state': entry.key,
          'count': entry.value['count'],
          'revenue': entry.value['revenue'],
          'units': entry.value['units'],
          'percentage': percentage,
          'breakdown': finalBreakdown // Pass to UI
        });
      }
      regionalPerformance.value = regions;

      var bestState = sortedStates.first;
      if (bestState.key == "Unknown" && sortedStates.length > 1) {
        bestState = sortedStates[1];
      }
      topState.value = bestState.key;
      topStateCount.value = bestState.value['count'];

    } else {
      regionalPerformance.clear();
      topState.value = "N/A";
      topStateCount.value = 0;
    }
  }

  void _resetMetrics() {
    totalOrders.value = 0;
    totalRevenue.value = 0.0;
    averageOrderValue.value = 0.0;
    topState.value = "N/A";
    topStateCount.value = 0;
    regionalPerformance.clear();
  }
}