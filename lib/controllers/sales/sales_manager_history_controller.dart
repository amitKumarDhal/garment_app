import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/order_model.dart';

class SalesManagerHistoryController extends GetxController {
  final _db = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot>? _listener;

  var isLoading = true.obs;

  // ✅ All orders from DB (Source of Truth)
  var allOrders = <OrderModel>[].obs;
  // ✅ Filtered orders shown in the list
  var displayedOrders = <OrderModel>[].obs;

  var currentFilter = "All NDO".obs;
  var searchQuery = "".obs;

  // =========================================================================
  // ✅ DYNAMIC SUMMARY GETTERS (Updates automatically based on selection)
  // =========================================================================

  /// 1. Get total number of orders currently visible in the list
  int get filteredOrdersCount => displayedOrders.length;

  /// 2. Get total revenue sum for currently visible orders
  double get filteredTotalRevenue =>
      displayedOrders.fold(0.0, (sum, o) => sum + o.totalAmount);

  /// 3. Get Average Order Value (AOV) for visible orders
  double get filteredAov {
    if (displayedOrders.isEmpty) return 0.0;
    return filteredTotalRevenue / filteredOrdersCount;
  }

  // =========================================================================

  @override
  void onInit() {
    super.onInit();
    // ✅ Always start with "All NDO" (Next Day Orders / Active floor items)
    currentFilter.value = "All NDO";
    fetchAllOrders();
  }

  @override
  void onClose() {
    _listener?.cancel();
    super.onClose();
  }

  /// Listens to real-time changes in Firestore
  void fetchAllOrders() {
    isLoading.value = true;

    _listener = _db
        .collection('orders')
        .orderBy('orderDate', descending: true)
        .limit(200) // Adjusted limit for larger catalogs
        .snapshots()
        .listen((snapshot) {

      allOrders.value = snapshot.docs
          .map((doc) => OrderModel.fromSnapshot(doc))
          .toList();

      applyFilter();
      isLoading.value = false;
    }, onError: (e) {
      debugPrint("❌ Master Ledger Stream error: $e");
      isLoading.value = false;
    });
  }

  /// Sets the status filter (e.g., 'Approved', 'Out SRC')
  void filterByStatus(String status) {
    currentFilter.value = status;
    applyFilter();
  }

  /// Updates search query and recalculates the list
  void searchOrders(String query) {
    searchQuery.value = query;
    applyFilter();
  }

  /// Core logic to filter data and calculate metrics
  void applyFilter() {
    List<OrderModel> temp = allOrders.toList();

    // --- 1. STATUS FILTER LOGIC ---
    if (currentFilter.value == "Trash") {
      temp = temp.where((o) => o.isDeleted == true).toList();
    } else if (currentFilter.value == "All") {
      temp = temp.where((o) => o.isDeleted != true).toList();
    } else if (currentFilter.value == "All NDO") {
      // Terminal statuses to exclude from "Active Pipeline"
      List<String> terminalStatuses = [
        'shipped',
        'delivered',
        'completed',
        'rejected',
        'cancelled',
        'deleted'
      ];

      temp = temp.where((o) {
        String status = o.status.toLowerCase().trim();
        return !o.isDeleted && !terminalStatuses.contains(status);
      }).toList();
    } else {
      // Specific status logic (e.g., 'Out SRC', 'Packing')
      temp = temp.where((o) {
        return o.status.toLowerCase().trim() ==
            currentFilter.value.toLowerCase().trim() &&
            o.isDeleted != true;
      }).toList();
    }

    // --- 2. SEARCH FILTER LOGIC ---
    if (searchQuery.value.isNotEmpty) {
      String q = searchQuery.value.toLowerCase().trim();

      temp = temp.where((o) {
        // Search in ID, Agent Name, and Client Name
        bool matchBasic = o.clientName.toLowerCase().contains(q) ||
            o.marketingPersonName.toLowerCase().contains(q) ||
            (o.manualOrderNo?.toLowerCase().contains(q) ?? false);

        // Search inside the products nested map
        bool matchProducts = o.products.any((prod) {
          String pName = (prod['productName'] ?? '').toString().toLowerCase();
          String pCode = (prod['productCode'] ?? '').toString().toLowerCase();
          return pName.contains(q) || pCode.contains(q);
        });

        return matchBasic || matchProducts;
      }).toList();
    }

    // Updating this observable triggers the Obx in the UI
    displayedOrders.assignAll(temp);
  }
}