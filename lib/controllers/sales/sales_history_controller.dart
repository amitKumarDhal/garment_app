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
        final snapshot = await _db
            .collection('orders')
            .where('marketingPersonName', isEqualTo: myName)
            .orderBy('orderDate', descending: true)
            .limit(100)
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

  // ✅ 6. ASSOCIATE PAYMENT LOGIC (Allows Associate to collect/mark full payment)
  Future<void> recordPayment(OrderModel order, double amount) async {
    try {
      double newAdvance = order.advanceAmount + amount;
      double newBalance = order.totalAmount - newAdvance;

      if (newBalance < 0) newBalance = 0;

      // 1. Create the timestamped payment record
      final user = _auth.currentUser;
      String agentName = user?.displayName ?? 'Sales Associate';

      final paymentRecord = {
        'amount': amount,
        'date': Timestamp.now(),
        'recordedBy': agentName,
      };

      // 2. Update Firebase safely
      await _db.collection('orders').doc(order.id).update({
        'advanceAmount': newAdvance,
        'balanceDue': newBalance,
        'paymentStatus': newBalance <= 0 ? 'Fully Paid' : 'Partially Paid',
        'paymentHistory': FieldValue.arrayUnion([paymentRecord]),
      });

      // 3. Show Success Message
      Get.snackbar(
        "Payment Successful",
        newBalance <= 0 ? "Order marked as FULLY PAID." : "₹$amount recorded successfully.",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      fetchHistory(); // Refresh the associate's list
    } catch (e) {
      Get.snackbar("Error", "Failed to update payment: $e", backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }
}