// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../data/models/order_model.dart';

class SalesManagerHistoryController extends GetxController {
  final _db = FirebaseFirestore.instance;

  // ✅ UI State
  var isLoading = false.obs;
  var isRefreshing = false.obs;

  // ✅ UI Pagination State (Prevents app from crashing when rendering thousands of cards)
  var visibleLimit = 25.obs;

  // ✅ Data Storage (Holds ALL orders in the background)
  var allOrders = <OrderModel>[];
  var displayedOrders = <OrderModel>[].obs;

  // ✅ Filter State
  var currentFilter = "All NDO".obs;
  var searchQuery = "".obs;

  // =========================================================================
  // ✅ METRICS (Calculates instantly on the FULL filtered list)
  // =========================================================================
  int get filteredOrdersCount => displayedOrders.length;

  double get filteredTotalRevenue =>
      displayedOrders.fold(0.0, (sum, o) => sum + o.totalAmount);

  double get filteredAov => (displayedOrders.isEmpty)
      ? 0.0
      : (filteredTotalRevenue / filteredOrdersCount);

  // =========================================================================
  // ✅ SAFE RENDERING LIST
  // =========================================================================
  // This passes only a chunk of the data to the UI so the phone doesn't freeze
  List<OrderModel> get renderableOrders {
    if (visibleLimit.value >= displayedOrders.length) {
      return displayedOrders;
    }
    return displayedOrders.sublist(0, visibleLimit.value);
  }

  bool get canLoadMoreUI => visibleLimit.value < displayedOrders.length;

  void loadMoreUI() {
    HapticFeedback.lightImpact();
    visibleLimit.value += 25;
  }

  @override
  void onInit() {
    super.onInit();
    fetchAllData();
  }

  // =========================================================================
  // ✅ DATA FETCHING (UNLIMITED BUT CACHED)
  // =========================================================================
  Future<void> fetchAllData({bool quiet = false}) async {
    try {
      if (!quiet) isLoading.value = true;

      // Fetches everything, but prioritizes cache to save your Firebase quota
      final snapshot = await _db
          .collection('orders')
          .orderBy('orderDate', descending: true)
          .get(const GetOptions(source: Source.serverAndCache));

      if (snapshot.docs.isNotEmpty) {
        allOrders = snapshot.docs.map((doc) => OrderModel.fromSnapshot(doc)).toList();
      } else {
        allOrders = [];
      }

      applyFilter();
    } catch (e) {
      debugPrint("❌ Master Ledger Fetch error: $e");
      Get.snackbar("Ledger Error", "Check your internet connection.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
          colorText: Colors.red);
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> refreshData() async {
    isRefreshing.value = true;
    visibleLimit.value = 25; // Reset UI limit on pull-to-refresh
    await fetchAllData(quiet: true);
  }

  // =========================================================================
  // ✅ LOCAL FILTERING
  // =========================================================================
  void filterByStatus(String status) {
    currentFilter.value = status;
    visibleLimit.value = 25; // Reset UI limit when changing tabs
    applyFilter();
  }

  void searchOrders(String query) {
    searchQuery.value = query;
    visibleLimit.value = 25; // Reset UI limit when searching
    applyFilter();
  }

  void applyFilter() {
    List<OrderModel> temp = List.from(allOrders);

    // --- 1. STATUS FILTER ---
    if (currentFilter.value == "Trash") {
      temp = temp.where((o) => o.isDeleted == true).toList();
    } else if (currentFilter.value == "All") {
      temp = temp.where((o) => o.isDeleted != true).toList();
    } else if (currentFilter.value == "All NDO") {
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