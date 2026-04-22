import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/order_model.dart';

class SalesManagerHistoryController extends GetxController {
  final _db = FirebaseFirestore.instance;

  // ✅ UI State
  var isLoading = false.obs;
  var isRefreshing = false.obs;

  // ✅ Data Storage
  var allOrders = <OrderModel>[];
  var displayedOrders = <OrderModel>[].obs;

  // ✅ Filter State
  var currentFilter = "All NDO".obs;
  var searchQuery = "".obs;

  // =========================================================================
  // ✅ METRICS (Calculated locally to save server costs)
  // =========================================================================
  int get filteredOrdersCount => displayedOrders.length;

  double get filteredTotalRevenue =>
      displayedOrders.fold(0.0, (sum, o) => sum + o.totalAmount);

  double get filteredAov => (displayedOrders.isEmpty)
      ? 0.0
      : (filteredTotalRevenue / filteredOrdersCount);

  @override
  void onInit() {
    super.onInit();
    fetchHistoryData();
  }

  /// ✅ ONE-TIME FETCH: The most important optimization for quota issues
  Future<void> fetchHistoryData({bool quiet = false}) async {
    try {
      if (!quiet) isLoading.value = true;

      // Using a Get() call with a limit is the #1 way to prevent "Resource Exhausted"
      final snapshot = await _db
          .collection('orders')
          .orderBy('orderDate', descending: true)
          .limit(150) // Reduced slightly to keep initial load snappy
          .get(const GetOptions(source: Source.serverAndCache));

      allOrders = snapshot.docs
          .map((doc) => OrderModel.fromSnapshot(doc))
          .toList();

      applyFilter();
    } catch (e) {
      debugPrint("❌ Master Ledger Fetch error: $e");
      Get.snackbar(
        "Ledger Error",
        "Check your internet connection.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  /// ✅ PULL TO REFRESH
  Future<void> refreshData() async {
    isRefreshing.value = true;
    await fetchHistoryData(quiet: true);
  }

  void filterByStatus(String status) {
    currentFilter.value = status;
    applyFilter();
  }

  void searchOrders(String query) {
    searchQuery.value = query;
    applyFilter();
  }

  void applyFilter() {
    // Start with a clean copy of the master list
    List<OrderModel> temp = List.from(allOrders);

    // --- 1. STATUS FILTER ---
    if (currentFilter.value == "Trash") {
      temp = temp.where((o) => o.isDeleted == true).toList();
    } else if (currentFilter.value == "All") {
      temp = temp.where((o) => o.isDeleted != true).toList();
    } else if (currentFilter.value == "All NDO") {
      // Logic for active pipeline (Next Day Orders)
      const terminalStatuses = ['shipped', 'delivered', 'completed', 'rejected', 'cancelled'];
      temp = temp.where((o) {
        return !o.isDeleted && !terminalStatuses.contains(o.status.toLowerCase().trim());
      }).toList();
    } else {
      temp = temp.where((o) =>
      o.status.toLowerCase().trim() == currentFilter.value.toLowerCase().trim() && !o.isDeleted
      ).toList();
    }

    // --- 2. SEARCH LOGIC ---
    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase().trim();
      temp = temp.where((o) {
        final matchBasic = o.clientName.toLowerCase().contains(q) ||
            o.marketingPersonName.toLowerCase().contains(q) ||
            (o.manualOrderNo?.toLowerCase().contains(q) ?? false);

        final matchProducts = o.products.any((prod) {
          final pName = (prod['productName'] ?? '').toString().toLowerCase();
          final pCode = (prod['productCode'] ?? '').toString().toLowerCase();
          return pName.contains(q) || pCode.contains(q);
        });

        return matchBasic || matchProducts;
      }).toList();
    }

    displayedOrders.assignAll(temp);
  }
}