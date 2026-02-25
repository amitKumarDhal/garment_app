import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/order_model.dart';

class SalesHistoryController extends GetxController {
  static SalesHistoryController get instance => Get.find();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  var isLoading = true.obs;

  // Master list of all history (used for resetting search)
  var allHistoryOrders = <OrderModel>[];

  // The list actually shown on the screen
  var displayedOrders = <OrderModel>[].obs;

  // Filter state: "All", "Pending", "Approved", "Trash", etc.
  var currentFilter = "All".obs;

  // ✅ NEW: Store search query so it persists when switching tabs
  var currentSearchQuery = "".obs;

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
        // Note: We pull EVERYTHING here, including deleted items, so the local filter can sort them.
        final snapshot = await _db
            .collection('orders')
            .where('marketingPersonName', isEqualTo: myName)
            .orderBy('orderDate', descending: true)
            .limit(100) // ✅ Bumped limit to ensure trash items are caught
            .get();

        final orders = snapshot.docs
            .map((doc) => OrderModel.fromSnapshot(doc))
            .toList();

        allHistoryOrders = orders;
        applyFilter();
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Could not load history: $e",
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // --- 2. REQUEST Deletion Method ---
  Future<void> requestDeleteOrder(OrderModel order) async {
    final lockedStatuses = ['shipping', 'shipped', 'delivered'];
    if (lockedStatuses.contains(order.status.toLowerCase())) {
      Get.snackbar(
        "Action Denied",
        "Orders in '${order.status}' phase cannot be deleted.",
        backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
        colorText: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading.value = true;

      await _db.collection('orders').doc(order.id).update({
        'isDeleteRequested': true,
        'deleteRequestedAt': FieldValue.serverTimestamp(),
      });

      fetchHistory();

      final managerSnapshot = await _db.collection('users').where('Role', isEqualTo: 'Sales Manager').get();

      for (var managerDoc in managerSnapshot.docs) {
        await _db.collection('notifications').add({
          'targetUserId': managerDoc.id,
          'title': 'Deletion Request ⚠️',
          'message': 'Associate requested to delete Order ${order.manualOrderNo}. Approval required.',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }

      Get.snackbar(
        "Request Sent",
        "Deletion request sent to the Sales Manager for approval.",
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Could not send delete request: $e",
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
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
    currentSearchQuery.value = query; // ✅ Save search text
    applyFilter();
  }

  // --- 5. Main Filter Engine (✅ UPGRADED FOR SOFT DELETE) ---
  void applyFilter() {
    List<OrderModel> temp = allHistoryOrders;

    // A. Apply Status & Trash Filter (The Gatekeeper)
    if (currentFilter.value == "Trash") {
      // Show ONLY items marked as deleted
      temp = temp.where((o) => o.toJson()['isDeleted'] == true).toList();
    } else if (currentFilter.value == "All") {
      // Show everything EXCEPT deleted items
      temp = temp.where((o) => o.toJson()['isDeleted'] != true).toList();
    } else {
      // Show specific status but EXCLUDE deleted items
      temp = temp
          .where((o) =>
      o.status.toLowerCase() == currentFilter.value.toLowerCase() &&
          o.toJson()['isDeleted'] != true
      )
          .toList();
    }

    // B. Apply Search Filter (✅ Upgraded to include product names)
    if (currentSearchQuery.value.isNotEmpty) {
      String lowerQuery = currentSearchQuery.value.toLowerCase();
      temp = temp.where((o) {
        // Basic match
        bool matchBasic = o.clientName.toLowerCase().contains(lowerQuery) ||
            o.marketingPersonName.toLowerCase().contains(lowerQuery) ||
            (o.manualOrderNo?.toLowerCase().contains(lowerQuery) ?? false);

        // Product match
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