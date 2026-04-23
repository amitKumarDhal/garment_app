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

  // ✅ Pagination State
  var isLoadingMore = false.obs;
  var hasMoreData = true.obs;
  DocumentSnapshot? lastDocument; // 👈 The cursor
  final int documentLimit = 25; // 👈 How many orders to fetch per swipe

  // ✅ Data Storage
  var allOrders = <OrderModel>[];
  var displayedOrders = <OrderModel>[].obs;

  // ✅ Filter State
  var currentFilter = "All NDO".obs;
  var searchQuery = "".obs;

  // =========================================================================
  // ✅ METRICS
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
    fetchInitialData();
  }

  // =========================================================================
  // ✅ DATA FETCHING (PAGINATED)
  // =========================================================================

  /// 1️⃣ INITIAL FETCH: Grabs the first batch of orders
  Future<void> fetchInitialData({bool quiet = false}) async {
    try {
      if (!quiet) isLoading.value = true;
      hasMoreData.value = true; // Reset the flag

      final snapshot = await _db
          .collection('orders')
          .orderBy('orderDate', descending: true)
          .limit(documentLimit)
          .get(const GetOptions(source: Source.serverAndCache));

      if (snapshot.docs.isNotEmpty) {
        allOrders = snapshot.docs.map((doc) => OrderModel.fromSnapshot(doc)).toList();
        lastDocument = snapshot.docs.last; // Save cursor

        if (snapshot.docs.length < documentLimit) {
          hasMoreData.value = false; // We got less than the limit, database is empty
        }
      } else {
        allOrders = [];
        hasMoreData.value = false;
      }

      applyFilter();
    } catch (e) {
      debugPrint("❌ Master Ledger Initial Fetch error: $e");
      Get.snackbar("Ledger Error", "Check your internet connection.",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent.withOpacity(0.1), colorText: Colors.red);
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  /// 2️⃣ FETCH NEXT PAGE: Grabs the next batch when the user scrolls to the bottom
  Future<void> fetchNextPage() async {
    // Stop if we are already loading, or if we hit the end of the database
    if (isLoadingMore.value || !hasMoreData.value || lastDocument == null) return;

    try {
      isLoadingMore.value = true;
      HapticFeedback.selectionClick();

      final snapshot = await _db
          .collection('orders')
          .orderBy('orderDate', descending: true)
          .startAfterDocument(lastDocument!) // 👈 Start exactly where we left off
          .limit(documentLimit)
          .get(const GetOptions(source: Source.serverAndCache));

      if (snapshot.docs.isNotEmpty) {
        final newOrders = snapshot.docs.map((doc) => OrderModel.fromSnapshot(doc)).toList();

        allOrders.addAll(newOrders); // Add to master list
        lastDocument = snapshot.docs.last; // Update cursor

        if (snapshot.docs.length < documentLimit) {
          hasMoreData.value = false; // Reached the end
        }

        applyFilter(); // Re-apply the current filter/search to the expanded list
      } else {
        hasMoreData.value = false;
      }
    } catch (e) {
      debugPrint("❌ Master Ledger Pagination error: $e");
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// ✅ PULL TO REFRESH: Resets everything and starts from the top
  Future<void> refreshData() async {
    isRefreshing.value = true;
    lastDocument = null; // Clear cursor
    await fetchInitialData(quiet: true);
  }

  // =========================================================================
  // ✅ LOCAL FILTERING (Saves Quota)
  // =========================================================================

  void filterByStatus(String status) {
    currentFilter.value = status;
    applyFilter();
  }

  void searchOrders(String query) {
    searchQuery.value = query;
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