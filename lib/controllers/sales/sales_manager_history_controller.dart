import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/order_model.dart';

class SalesManagerHistoryController extends GetxController {
  final _db = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot>? _listener;

  var isLoading = true.obs;
  var allOrders = <OrderModel>[];
  var displayedOrders = <OrderModel>[].obs;

  var currentFilter = "All NDO".obs;
  Rx<DateTimeRange?> selectedDateRange = Rx<DateTimeRange?>(null);
  var searchQuery = "".obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is String) {
      currentFilter.value = Get.arguments;
    }
    fetchAllOrders();
  }

  @override
  void onClose() {
    _listener?.cancel();
    super.onClose();
  }

  void fetchAllOrders() {
    isLoading.value = true;

    _listener = _db.collection('orders')
        .orderBy('orderDate', descending: true)
        .limit(150) // ✅ Increased limit slightly for Master Ledger
        .snapshots()
        .listen((snapshot) {

      allOrders = snapshot.docs
          .map((doc) => OrderModel.fromSnapshot(doc))
          .toList();

      applyFilter();
      isLoading.value = false;
    }, onError: (e) {
      debugPrint("Stream error: $e");
      isLoading.value = false;
    });
  }

  Future<void> pickDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: isDark ? ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: Colors.purpleAccent),
          ) : ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.purple),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      selectedDateRange.value = picked;
      applyFilter();
    }
  }

  void clearDateFilter() {
    selectedDateRange.value = null;
    applyFilter();
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
    List<OrderModel> temp = allOrders;

    // --- 1. Filter by Status Tab ---
    if (currentFilter.value == "Trash") {
      temp = temp.where((o) => o.isDeleted == true).toList();
    }
    else if (currentFilter.value == "All") {
      temp = temp.where((o) => o.isDeleted != true).toList();
    }
    else if (currentFilter.value == "All NDO") {
      // ✅ "All NDO" shows everything EXCEPT Terminal States
      // Note: 'Shipped' and 'Shipping' are NOT terminal, so they stay visible here.
      List<String> terminalStatuses = ['delivered', 'completed', 'rejected', 'cancelled', 'deleted'];

      temp = temp.where((o) {
        String status = o.status.toLowerCase().trim();
        return !o.isDeleted && !terminalStatuses.contains(status);
      }).toList();
    }
    else {
      // ✅ Handles specific clicks on "Shipping", "Shipped", etc.
      temp = temp.where((o) =>
      o.status.toLowerCase().trim() == currentFilter.value.toLowerCase().trim() &&
          o.isDeleted != true
      ).toList();
    }

    // --- 2. Filter by Date Range ---
    if (selectedDateRange.value != null) {
      DateTime start = selectedDateRange.value!.start;
      DateTime end = selectedDateRange.value!.end.add(const Duration(days: 1));

      temp = temp.where((o) {
        return o.orderDate.isAfter(start) && o.orderDate.isBefore(end);
      }).toList();
    }

    // --- 3. Filter by Search Text ---
    if (searchQuery.value.isNotEmpty) {
      String lowerQuery = searchQuery.value.toLowerCase().trim();
      temp = temp.where((o) {
        bool matchBasic = o.clientName.toLowerCase().contains(lowerQuery) ||
            o.marketingPersonName.toLowerCase().contains(lowerQuery) ||
            (o.manualOrderNo?.toLowerCase().contains(lowerQuery) ?? false);

        bool matchProducts = o.products.any((prod) {
          String pName = (prod['productName'] ?? '').toString().toLowerCase();
          String pCode = (prod['productCode'] ?? '').toString().toLowerCase();
          return pName.contains(lowerQuery) || pCode.contains(lowerQuery);
        });

        return matchBasic || matchProducts;
      }).toList();
    }

    displayedOrders.assignAll(temp);
  }
}