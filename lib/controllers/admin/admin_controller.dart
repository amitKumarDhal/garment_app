import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yoobbel/data/models/order_model.dart';

class AdminController extends GetxController {
  static AdminController get instance => Get.find();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Observables for Dashboard Stat Cards ---
  var totalDailyProduction = 0.0.obs;
  var averageEfficiency = 0.0.obs;
  var activeWorkers = 0.obs;
  var totalDamages = 0.obs;

  // --- Reactive Firestore Lists ---
  RxList<Map<String, dynamic>> pendingRequests = <Map<String, dynamic>>[].obs;
  RxList<OrderModel> recentOrders = <OrderModel>[].obs;
  RxList<Map<String, dynamic>> recentCuttingEntries =
      <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> recentPrintingEntries =
      <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> recentStitchingEntries =
      <Map<String, dynamic>>[].obs;

  var pendingApprovalsCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _bindPendingRequests();
    _bindOrdersStream();
    _bindCuttingStream();
    _bindPrintingStream();
    _bindStitchingStream();
  }

  // 1. --- ID APPROVAL QUEUE ---
  void _bindPendingRequests() {
    _db
        .collection('id_requests')
        .where('status', isEqualTo: 'Pending')
        .snapshots()
        .listen((snapshot) {
          pendingRequests.assignAll(
            snapshot.docs.map((doc) {
              var data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList(),
          );
          pendingApprovalsCount.value = pendingRequests.length;
        });
  }

  // 2. --- MARKETING ORDERS ---
  void _bindOrdersStream() {
    _db
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .listen((snapshot) {
          recentOrders.assignAll(
            snapshot.docs.map((doc) => OrderModel.fromSnapshot(doc)).toList(),
          );
          _calculateProductionTotal();
        });
  }

  // 3. --- CUTTING FLOOR ---
  void _bindCuttingStream() {
    _db
        .collection('cutting_entries')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .listen((snapshot) {
          recentCuttingEntries.assignAll(
            snapshot.docs.map((doc) {
              var data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList(),
          );
        });
  }

  // 4. --- PRINTING FLOOR ---
  void _bindPrintingStream() {
    _db
        .collection('printing_entries')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .listen((snapshot) {
          recentPrintingEntries.assignAll(
            snapshot.docs.map((doc) {
              var data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList(),
          );
          _calculateGlobalStats();
        });
  }

  // 5. --- STITCHING FLOOR ---
  void _bindStitchingStream() {
    _db
        .collection('stitching_entries')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .listen((snapshot) {
          recentStitchingEntries.assignAll(
            snapshot.docs.map((doc) {
              var data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList(),
          );
          _calculateGlobalStats();
        });
  }

  // --- KPI CALCULATIONS ---

  /// Calculates Efficiency, Active Workers, and Combined Damages
  void _calculateGlobalStats() {
    // A. Efficiency & Workers from Stitching
    if (recentStitchingEntries.isNotEmpty) {
      double totalEff = 0.0;
      Set<String> workers = {};
      for (var entry in recentStitchingEntries) {
        totalEff += (entry['efficiency'] as num? ?? 0.0).toDouble();
        workers.add(entry['workerName'] ?? 'Unknown');
      }
      averageEfficiency.value = totalEff / recentStitchingEntries.length;
      activeWorkers.value = workers.length;
    }

    // B. Total Damages (Printing + Stitching)
    int pDamages = recentPrintingEntries.fold(
      0,
      (totalsum, item) => totalsum + (item['totalDamaged'] as int? ?? 0),
    );
    int sDamages = recentStitchingEntries.fold(
      0,
      (totalsum, item) => totalsum + (item['rejectedQty'] as int? ?? 0),
    );
    totalDamages.value = pDamages + sDamages;
  }

  /// Sums up the totalAmount from orders
  void _calculateProductionTotal() {
    double total = recentOrders.fold(
      0,
      (totalsum, item) => totalsum + item.totalAmount,
    );
    totalDailyProduction.value = total;
  }

  // --- ACTIONS ---

  Future<void> approveNextStage(String docId, Map<String, dynamic> user) async {
    try {
      final docRef = _db.collection('id_requests').doc(docId);
      if (!user['unitApproved']) {
        await docRef.update({'unitApproved': true});
      } else if (!user['shiftApproved']) {
        await docRef.update({'shiftApproved': true});
      } else if (!user['adminApproved']) {
        await docRef.update({'adminApproved': true, 'status': 'Approved'});
        Get.snackbar(
          "Approved",
          "${user['name']} access granted",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  Future<void> rejectRequest(String docId) async {
    try {
      await _db.collection('id_requests').doc(docId).delete();
      Get.snackbar(
        "Deleted",
        "Request removed",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  Future<void> refreshStats() async {
    _calculateProductionTotal();
    _calculateGlobalStats();
    await Future.delayed(const Duration(seconds: 1));
  }
}
