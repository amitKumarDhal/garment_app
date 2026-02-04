import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ Added for User ID
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/order_model.dart';

class SalesHistoryController extends GetxController {
  static SalesHistoryController get instance =>
      Get.find(); // ✅ Helper to find controller

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance; // ✅ Auth Instance

  var isLoading = true.obs;

  // Master list of all history (used for resetting search)
  var allHistoryOrders = <OrderModel>[];

  // The list actually shown on the screen
  var displayedOrders = <OrderModel>[].obs;

  // Filter state: "All", "Pending", "Approved", or "Rejected"
  var currentFilter = "All".obs;

  @override
  void onInit() {
    super.onInit();
    fetchHistory();
  }

  // --- 1. Fetch ONLY Logged-in Agent's Orders ---
  void fetchHistory() async {
    try {
      isLoading.value = true;
      final user = _auth.currentUser;

      if (user != null) {
        // Step A: Get the exact name stored in your profile
        String myName = user.displayName ?? "Unknown";
        final userDoc = await _db.collection('id_requests').doc(user.uid).get();
        if (userDoc.exists) {
          myName = userDoc.data()?['name'] ?? myName;
        }

        // Step B: Query Firestore - STRICTLY FILTER BY AGENT NAME
        final snapshot = await _db
            .collection('orders')
            .where(
              'marketingPersonName',
              isEqualTo: myName,
            ) // 🔒 LOCKS DATA TO USER
            // ✅ Removed 'status' filter from DB query to simplify index.
            // We filter status locally in applyFilter() anyway.
            .orderBy(
              'orderDate',
              descending: true,
            ) // ✅ Changed 'createdAt' to 'orderDate'
            .limit(50)
            .get();

        final orders = snapshot.docs
            .map((doc) => OrderModel.fromSnapshot(doc))
            .toList();

        allHistoryOrders = orders;
        applyFilter(); // Apply the "All/Pending" filter locally
      }
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

  // --- 2. Delete Order Method ---
  Future<void> deleteOrder(OrderModel order) async {
    try {
      if (order.status.toLowerCase() == 'approved') {
        Get.snackbar(
          "Action Denied",
          "Approved orders are locked and cannot be deleted.",
          backgroundColor: Colors.orange.withOpacity(0.1),
          colorText: Colors.orange,
        );
        return;
      }

      isLoading.value = true;

      // Delete from Firestore
      await _db.collection('orders').doc(order.id).delete();

      // Update local lists
      allHistoryOrders.removeWhere((o) => o.id == order.id);
      displayedOrders.removeWhere((o) => o.id == order.id);

      Get.snackbar(
        "Deleted",
        "Order has been removed successfully",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } catch (e) {
      Get.snackbar("Error", "Failed to delete: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // --- 3. Filter by Chip ---
  void filterByStatus(String status) {
    currentFilter.value = status;
    applyFilter();
  }

  // --- 4. Search Bar Logic ---
  void searchOrders(String query) {
    applyFilter(searchQuery: query);
  }

  // --- 5. Main Filter Engine ---
  void applyFilter({String searchQuery = ''}) {
    List<OrderModel> temp = allHistoryOrders;

    // A. Apply Status Filter
    if (currentFilter.value != "All") {
      temp = temp
          .where(
            (o) => o.status.toLowerCase() == currentFilter.value.toLowerCase(),
          )
          .toList();
    }

    // B. Apply Search Filter
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
