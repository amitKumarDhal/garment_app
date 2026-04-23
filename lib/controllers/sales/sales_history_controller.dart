import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../data/models/order_model.dart';

class SalesHistoryController extends GetxController {
  static SalesHistoryController get instance => Get.find();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // --- UI State ---
  var isLoading = true.obs;
  String currentAgentName = "";

  // --- Pagination State ---
  var isLoadingMore = false.obs;
  var hasMoreData = true.obs;
  DocumentSnapshot? lastDocument; // 👈 The cursor
  final int documentLimit = 25;   // 👈 How many orders to fetch per swipe

  // Master list of all history (used for local filtering to save quota)
  var allHistoryOrders = <OrderModel>[];

  // The list actually shown on the screen
  var displayedOrders = <OrderModel>[].obs;

  // Filter state
  var currentFilter = "All".obs;
  var currentSearchQuery = "".obs;

  @override
  void onInit() {
    super.onInit();
    fetchHistory();
  }

  // --- Helper: Cache the Agent Name ---
  Future<void> _ensureAgentName() async {
    if (currentAgentName.isNotEmpty) return;

    final user = _auth.currentUser;
    if (user != null) {
      currentAgentName = user.displayName ?? "Unknown";
      try {
        final userDoc = await _db.collection('id_requests').doc(user.uid).get(const GetOptions(source: Source.serverAndCache));
        if (userDoc.exists) {
          currentAgentName = userDoc.data()?['name'] ?? currentAgentName;
        }
      } catch (e) {
        debugPrint("Error fetching agent name: $e");
      }
    }
  }

  // =========================================================================
  // ✅ DATA FETCHING (PAGINATED)
  // =========================================================================

  /// 1️⃣ INITIAL FETCH: Grabs the first batch of orders
  Future<void> fetchHistory({bool quiet = false}) async {
    try {
      if (!quiet) isLoading.value = true;
      hasMoreData.value = true; // Reset flag

      await _ensureAgentName();
      if (currentAgentName.isEmpty) return;

      final snapshot = await _db
          .collection('orders')
          .where('marketingPersonName', isEqualTo: currentAgentName)
          .orderBy('orderDate', descending: true)
          .limit(documentLimit)
          .get(const GetOptions(source: Source.serverAndCache));

      if (snapshot.docs.isNotEmpty) {
        allHistoryOrders = snapshot.docs.map((doc) => OrderModel.fromSnapshot(doc)).toList();
        lastDocument = snapshot.docs.last; // Save cursor

        if (snapshot.docs.length < documentLimit) {
          hasMoreData.value = false; // Database is empty beyond this point
        }
      } else {
        allHistoryOrders = [];
        hasMoreData.value = false;
      }

      applyFilter();

    } catch (e) {
      Get.snackbar("Error", "Could not load history: $e",
          backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  /// 2️⃣ FETCH NEXT PAGE: Triggered when user scrolls to the bottom
  Future<void> fetchNextPage() async {
    if (isLoadingMore.value || !hasMoreData.value || lastDocument == null) return;

    try {
      isLoadingMore.value = true;
      HapticFeedback.selectionClick();

      await _ensureAgentName();

      final snapshot = await _db
          .collection('orders')
          .where('marketingPersonName', isEqualTo: currentAgentName)
          .orderBy('orderDate', descending: true)
          .startAfterDocument(lastDocument!) // 👈 Start where we left off
          .limit(documentLimit)
          .get(const GetOptions(source: Source.serverAndCache));

      if (snapshot.docs.isNotEmpty) {
        final newOrders = snapshot.docs.map((doc) => OrderModel.fromSnapshot(doc)).toList();

        allHistoryOrders.addAll(newOrders);
        lastDocument = snapshot.docs.last; // Update cursor

        if (snapshot.docs.length < documentLimit) {
          hasMoreData.value = false; // Reached the end
        }

        applyFilter();
      } else {
        hasMoreData.value = false;
      }
    } catch (e) {
      debugPrint("❌ Pagination Error: $e");
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// ✅ PULL TO REFRESH: Resets cursor and list
  Future<void> refreshData() async {
    lastDocument = null; // Clear the cursor
    await fetchHistory(quiet: true);
  }

  // =========================================================================
  // ✅ DELETION REQUESTS
  // =========================================================================

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
      if (order.id == null) return;

      await _db.collection('orders').doc(order.id).update({
        'isDeleteRequested': true,
        'deleteRequestedAt': FieldValue.serverTimestamp(),
      });

      await refreshData(); // Update UI

      final managerSnapshot = await _db.collection('users').where('Role', isEqualTo: 'Sales Manager').get();

      for (var managerDoc in managerSnapshot.docs) {
        await _db.collection('notifications').add({
          'targetUserId': managerDoc.id,
          'title': 'Deletion Request ⚠️',
          'message': 'Associate requested to delete Order ${order.manualOrderNo}. Approval required.',
          'orderId': order.id,
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
      Get.snackbar("Error", "Could not send delete request: $e",
          backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> cancelDeleteRequest(String? orderId) async {
    if (orderId == null) return;

    try {
      isLoading.value = true;

      await _db.collection('orders').doc(orderId).update({
        'isDeleteRequested': false,
        'deleteRequestedAt': FieldValue.delete(),
      });

      await refreshData(); // Update UI

      Get.snackbar(
        "Request Cancelled",
        "Your deletion request has been successfully withdrawn.",
        backgroundColor: Colors.green.withValues(alpha: 0.1),
        colorText: Colors.green,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar("Error", "Could not cancel request: $e",
          backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  // =========================================================================
  // ✅ FILTERING & SEARCHING (Local to save reads)
  // =========================================================================

  void filterByStatus(String status) {
    currentFilter.value = status;
    applyFilter();
  }

  void searchOrders(String query) {
    currentSearchQuery.value = query;
    applyFilter();
  }

  void applyFilter() {
    List<OrderModel> temp = allHistoryOrders;

    // 1. Status Filter
    if (currentFilter.value == "Trash") {
      temp = temp.where((o) => o.toJson()['isDeleted'] == true).toList();
    } else if (currentFilter.value == "All") {
      temp = temp.where((o) => o.toJson()['isDeleted'] != true).toList();
    } else {
      temp = temp
          .where((o) =>
      o.status.toLowerCase() == currentFilter.value.toLowerCase() &&
          o.toJson()['isDeleted'] != true
      )
          .toList();
    }

    // 2. Search Query Filter
    if (currentSearchQuery.value.isNotEmpty) {
      String lowerQuery = currentSearchQuery.value.toLowerCase();
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

  // =========================================================================
  // ✅ PAYMENTS
  // =========================================================================

  Future<void> recordPayment(OrderModel order, double amount) async {
    if (amount > order.balanceDue) {
      Get.snackbar(
        "Invalid Payment Amount",
        "You cannot collect ₹$amount because the remaining balance is only ₹${order.balanceDue}.",
        backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
        colorText: Colors.red,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading.value = true;
      await _ensureAgentName();
      String agentUid = _auth.currentUser?.uid ?? '';

      await _db.collection('payment_requests').add({
        'orderId': order.id,
        'manualOrderNo': order.manualOrderNo ?? 'Unknown',
        'clientName': order.clientName,
        'agentName': currentAgentName,
        'agentUid': agentUid,
        'amount': amount,
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
      });

      final managerSnapshot = await _db.collection('users')
          .where('Role', isEqualTo: 'Sales Manager')
          .get();

      for (var managerDoc in managerSnapshot.docs) {
        await _db.collection('notifications').add({
          'targetUserId': managerDoc.id,
          'title': 'Payment Approval Required 💰',
          'message': '$currentAgentName collected ₹$amount for Order ${order.manualOrderNo}.',
          'orderId': order.id,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }

      Get.snackbar(
        "Approval Requested",
        "Payment of ₹$amount sent to Manager. The due balance will update once approved.",
        backgroundColor: Colors.orange.withValues(alpha: 0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );

    } catch (e) {
      Get.snackbar("Error", "Failed to submit payment request: $e",
          backgroundColor: Colors.redAccent.withValues(alpha: 0.1), colorText: Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  Stream<bool> hasPendingPayment(String? orderId) {
    if (orderId == null) return Stream.value(false);

    return _db.collection('payment_requests')
        .where('orderId', isEqualTo: orderId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }
}