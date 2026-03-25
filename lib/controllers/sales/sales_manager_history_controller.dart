import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/order_model.dart';

class SalesManagerHistoryController extends GetxController {
  final _db = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot>? _listener;

  var isLoading = true.obs;

  // ✅ Kept your excellent fix: Reactive list
  var allOrders = <OrderModel>[].obs;
  var displayedOrders = <OrderModel>[].obs;

  var currentFilter = "All NDO".obs;
  var searchQuery = "".obs;

  @override
  void onInit() {
    super.onInit();

    // ✅ STRICT OVERRIDE: Always reset to "All NDO" when entering the screen
    currentFilter.value = "All NDO";

    fetchAllOrders();
  }

  @override
  void onClose() {
    _listener?.cancel();
    super.onClose();
  }

  void fetchAllOrders() {
    isLoading.value = true;

    _listener = _db
        .collection('orders')
        .orderBy('orderDate', descending: true)
        .limit(150)
        .snapshots()
        .listen((snapshot) {
      // ✅ Kept your fix: using .value
      allOrders.value = snapshot.docs
          .map((doc) => OrderModel.fromSnapshot(doc))
          .toList();

      applyFilter();

      isLoading.value = false;
    }, onError: (e) {
      debugPrint("Stream error: $e");
      isLoading.value = false;
    });
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
    // ✅ IMPORTANT FIX: Pull from the reactive list
    List<OrderModel> temp = allOrders.toList();

    // --- STATUS FILTER ---
    if (currentFilter.value == "Trash") {
      temp = temp.where((o) => o.isDeleted == true).toList();
    } else if (currentFilter.value == "All") {
      temp = temp.where((o) => o.isDeleted != true).toList();
    } else if (currentFilter.value == "All NDO") {

      // ✅ Terminal statuses exactly matched to UI badge exclusions
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
      temp = temp.where((o) {
        return o.status.toLowerCase().trim() ==
            currentFilter.value.toLowerCase().trim() &&
            o.isDeleted != true;
      }).toList();
    }

    // --- SEARCH FILTER ---
    if (searchQuery.value.isNotEmpty) {
      String q = searchQuery.value.toLowerCase();

      temp = temp.where((o) {
        bool matchBasic = o.clientName.toLowerCase().contains(q) ||
            o.marketingPersonName.toLowerCase().contains(q) ||
            (o.manualOrderNo?.toLowerCase().contains(q) ?? false);

        // ✅ Deep search inside products array
        bool matchProducts = o.products.any((prod) {
          String pName = (prod['productName'] ?? '').toString().toLowerCase();
          String pCode = (prod['productCode'] ?? '').toString().toLowerCase();
          return pName.contains(q) || pCode.contains(q);
        });

        return matchBasic || matchProducts;
      }).toList();
    }

    displayedOrders.assignAll(temp);
  }
}