import 'dart:async'; // ✅ Required for StreamSubscription
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/order_model.dart';

class SalesManagerHistoryController extends GetxController {
  final _db = FirebaseFirestore.instance;

  // ✅ Stream Subscription to manage the listener
  StreamSubscription<QuerySnapshot>? _listener;

  var isLoading = true.obs;
  var allOrders = <OrderModel>[]; // Master list
  var displayedOrders = <OrderModel>[].obs; // Filtered list for UI
  var currentFilter = "All".obs; // Default filter

  // ✅ Store selected date range
  Rx<DateTimeRange?> selectedDateRange = Rx<DateTimeRange?>(null);
  
  // ✅ Store search query for real-time persistence
  var searchQuery = "".obs; 

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is String) {
      currentFilter.value = Get.arguments;
    }
    fetchAllOrders();
  }

  // ✅ NEW: Cancel stream when controller is closed (Logout)
  @override
  void onClose() {
    _listener?.cancel(); // Stops listening to Firebase
    super.onClose();
  }

  // --- Fetch EVERYONE'S Orders (REAL-TIME + SAFE CLEANUP) ---
  void fetchAllOrders() {
    isLoading.value = true;
    
    // ✅ Assign to _listener so we can cancel it later
    _listener = _db.collection('orders')
        .orderBy('orderDate', descending: true)
        .limit(100)
        .snapshots() // Listen for changes
        .listen((snapshot) {
      
      allOrders = snapshot.docs
          .map((doc) => OrderModel.fromSnapshot(doc))
          .toList();

      // Re-apply filters automatically whenever data changes
      applyFilter();
      
      isLoading.value = false;
    }, onError: (e) {
      // ✅ Handle permission errors gracefully (e.g. on logout)
      print("Stream error or stopped: $e");
      isLoading.value = false;
    });
  }

  // ✅ Method to Pick Date Range
  Future<void> pickDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023), 
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
      applyFilter(); 
    }
  }

  // ✅ Clear Date Filter
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
    searchQuery.value = query; // Update the class variable
    applyFilter();
  }

  // --- Main Filter Engine ---
  void applyFilter() {
    List<OrderModel> temp = allOrders;

    // 1. Filter by Status Tab
    if (currentFilter.value != "All") {
      temp = temp
          .where(
            (o) => o.status.toLowerCase() == currentFilter.value.toLowerCase(),
          )
          .toList();
    }

    // 2. Filter by Date Range
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
    if (searchQuery.value.isNotEmpty) {
      String lowerQuery = searchQuery.value.toLowerCase();
      temp = temp.where((o) {
        return o.clientName.toLowerCase().contains(lowerQuery) ||
            o.marketingPersonName.toLowerCase().contains(lowerQuery) ||
            (o.manualOrderNo?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    }

    displayedOrders.assignAll(temp);
  }
}