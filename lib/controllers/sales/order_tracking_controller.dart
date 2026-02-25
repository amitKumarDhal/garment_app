import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../data/models/order_model.dart';

class OrderTrackingController extends GetxController {
  final searchController = TextEditingController();
  var isLoading = false.obs;
  var searchResults = <OrderModel>[].obs;
  var hasSearched = false.obs;

  // ✅ NEW: Filter state for Active vs Trash
  var currentFilter = "Active".obs;

  // ✅ NEW: Change filter and automatically re-run search
  void setFilter(String filter) {
    currentFilter.value = filter;
    if (searchController.text.trim().isNotEmpty) {
      searchOrder(searchController.text);
    } else {
      searchResults.clear();
    }
  }

  // Search Logic
  Future<void> searchOrder(String query) async {
    if (query.isEmpty) return;

    isLoading.value = true;
    hasSearched.value = true;
    searchResults.clear();

    try {
      List<OrderModel> tempResults = [];

      // 1. Try Searching by Manual Order ID (Exact Match)
      // Added .toUpperCase() assuming your IDs are like 'YB028'
      final idSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('manualOrderNo', isEqualTo: query.trim().toUpperCase())
          .get();

      if (idSnapshot.docs.isNotEmpty) {
        tempResults = idSnapshot.docs
            .map((doc) => OrderModel.fromSnapshot(doc))
            .toList();
      } else {
        // 2. If ID fails, Try Searching by Client Name
        final nameSnapshot = await FirebaseFirestore.instance
            .collection('orders')
            .where('clientName', isGreaterThanOrEqualTo: query)
            .where('clientName', isLessThan: '${query}z')
            .get();

        tempResults = nameSnapshot.docs
            .map((doc) => OrderModel.fromSnapshot(doc))
            .toList();
      }

      // ✅ 3. LOCAL FILTERING FOR SOFT DELETE
      // We filter locally because Firestore blocks multiple inequality filters in one query.
      bool isLookingForTrash = currentFilter.value == "Trash";

      searchResults.value = tempResults.where((order) {
        // Check if the order has the isDeleted flag
        bool isDeleted = order.toJson()['isDeleted'] == true;

        // If we want Trash, keep deleted ones. If we want Active, keep non-deleted ones.
        return isLookingForTrash ? isDeleted : !isDeleted;
      }).toList();

    } catch (e) {
      Get.snackbar("Error", "Could not track order: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void clearSearch() {
    searchController.clear();
    searchResults.clear();
    hasSearched.value = false;
  }
}