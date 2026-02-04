import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/order_model.dart';

class SalesManagerHistoryController extends GetxController {
  final _db = FirebaseFirestore.instance;

  var isLoading = true.obs;
  var allOrders = <OrderModel>[]; // Master list
  var displayedOrders = <OrderModel>[].obs; // Filtered list for UI
  var currentFilter = "All".obs; // Default filter

  // ✅ NEW: Store selected date range
  Rx<DateTimeRange?> selectedDateRange = Rx<DateTimeRange?>(null);

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is String) {
      currentFilter.value = Get.arguments;
    }
    fetchAllOrders();
  }

  // --- Fetch EVERYONE'S Orders ---
  void fetchAllOrders() async {
    try {
      isLoading.value = true;
      final snapshot = await _db
          .collection('orders')
          .orderBy('orderDate', descending: true)
          .limit(100)
          .get();

      allOrders = snapshot.docs
          .map((doc) => OrderModel.fromSnapshot(doc))
          .toList();

      applyFilter();
    } catch (e) {
      Get.snackbar(
        "Error",
        "Could not load history: $e",
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ NEW: Method to Pick Date Range
  Future<void> pickDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023), // Adjust based on when your app started
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.purple,
            colorScheme: const ColorScheme.light(primary: Colors.purple),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      selectedDateRange.value = picked;
      applyFilter(); // Filter immediately after selection
    }
  }

  // ✅ NEW: Clear Date Filter
  void clearDateFilter() {
    selectedDateRange.value = null;
    applyFilter();
  }

  // --- Filter Logic ---
  void filterByStatus(String status) {
    currentFilter.value = status;
    applyFilter();
  }

  void searchOrders(String query) {
    applyFilter(searchQuery: query);
  }

  // --- Main Filter Engine ---
  void applyFilter({String searchQuery = ''}) {
    List<OrderModel> temp = allOrders;

    // 1. Filter by Status Tab
    if (currentFilter.value != "All") {
      temp = temp
          .where(
            (o) => o.status.toLowerCase() == currentFilter.value.toLowerCase(),
          )
          .toList();
    }

    // 2. ✅ NEW: Filter by Date Range
    if (selectedDateRange.value != null) {
      DateTime start = selectedDateRange.value!.start;
      // Set end date to 23:59:59 of the last day to include the full day
      DateTime end = selectedDateRange.value!.end
          .add(const Duration(days: 1))
          .subtract(const Duration(seconds: 1));

      temp = temp.where((o) {
        return o.orderDate.isAfter(start) && o.orderDate.isBefore(end);
      }).toList();
    }

    // 3. Filter by Search Text
    if (searchQuery.isNotEmpty) {
      String lowerQuery = searchQuery.toLowerCase();
      temp = temp.where((o) {
        return o.clientName.toLowerCase().contains(lowerQuery) ||
            o.marketingPersonName.toLowerCase().contains(lowerQuery) ||
            (o.manualOrderNo?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    }

    displayedOrders.assignAll(temp);
  }
}
