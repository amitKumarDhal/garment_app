import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../data/models/order_model.dart';

class OrderTrackingController extends GetxController {
  final searchController = TextEditingController();
  var isLoading = false.obs;
  var searchResults = <OrderModel>[].obs;
  var hasSearched = false.obs;

  // Search Logic
  Future<void> searchOrder(String query) async {
    if (query.isEmpty) return;
    
    isLoading.value = true;
    hasSearched.value = true;
    searchResults.clear();

    try {
      // 1. Try Searching by Manual Order ID (Exact Match)
      final idSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('manualOrderNo', isEqualTo: query.trim())
          .get();

      if (idSnapshot.docs.isNotEmpty) {
        searchResults.value = idSnapshot.docs
            .map((doc) => OrderModel.fromSnapshot(doc))
            .toList();
      } else {
        // 2. If ID fails, Try Searching by Client Name
        // Note: This matches names starting with the query (Case sensitive in basic Firestore)
        final nameSnapshot = await FirebaseFirestore.instance
            .collection('orders')
            .where('clientName', isGreaterThanOrEqualTo: query)
            .where('clientName', isLessThan: '${query}z')
            .get();
            
        searchResults.value = nameSnapshot.docs
            .map((doc) => OrderModel.fromSnapshot(doc))
            .toList();
      }
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