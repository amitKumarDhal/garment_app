import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/order_model.dart';

class ManagerController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Observables
  var pendingOrders = <OrderModel>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPendingOrders();
  }

  // --- 1. Fetch only Pending Orders ---
  void fetchPendingOrders() {
    isLoading.value = true;

    // Using a listener so the manager sees new orders the second they are uploaded
    _db
        .collection('orders')
        .where('status', isEqualTo: 'Pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          pendingOrders.value = snapshot.docs
              .map((doc) => OrderModel.fromSnapshot(doc))
              .toList();
          isLoading.value = false;
        });
  }

  // --- 2. Action: Approve Order ---
  Future<void> approveOrder(String orderId) async {
    await _updateStatus(orderId, 'Approved', Colors.green);
  }

  // --- 3. Action: Reject Order ---
  Future<void> rejectOrder(String orderId) async {
    await _updateStatus(orderId, 'Rejected', Colors.red);
  }

  // --- Private Helper for Firestore Update ---
  Future<void> _updateStatus(
    String orderId,
    String status,
    Color snackColor,
  ) async {
    try {
      await _db.collection('orders').doc(orderId).update({
        'status': status,
        'approvedAt': FieldValue.serverTimestamp(), // Track when it was decided
      });

      Get.snackbar(
        "Order $status",
        "The record has been updated successfully.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: snackColor.withOpacity(0.1),
        colorText: snackColor,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar("Error", "Failed to update status: $e");
    }
  }
}
