import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yoobbel/data/models/order_model.dart';
import '../../utils/constants/colors.dart';
import '../../data/models/activity_item_model.dart';

class AdminController extends GetxController {
  static AdminController get instance => Get.find();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Observables ---
  var totalDailyProduction = 0.0.obs;
  var averageEfficiency = 0.0.obs;
  var activeWorkers = 0.obs;
  var totalDamages = 0.obs;

  // --- REPORTING VARIABLES (New) ---
  var reportDate = DateTime.now().obs;
  var reportSection =
      'All'.obs; // Options: All, Orders, Cutting, Printing, Stitching, Packing
  RxList<ActivityItem> reportList = <ActivityItem>[].obs;
  var isReportLoading = false.obs;

  // --- Lists ---
  RxList<Map<String, dynamic>> pendingRequests = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> allApprovedWorkers =
      <Map<String, dynamic>>[].obs;

  RxList<OrderModel> recentOrders = <OrderModel>[].obs;
  RxList<Map<String, dynamic>> recentCuttingEntries =
      <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> recentPrintingEntries =
      <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> recentStitchingEntries =
      <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> recentPackingEntries =
      <Map<String, dynamic>>[].obs;
  RxList<ActivityItem> recentActivities = <ActivityItem>[].obs;

  var pendingApprovalsCount = 0.obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _bindPendingRequests();
    _bindApprovedWorkers();
    _bindTodaysOrders();
    _bindCuttingStream();
    _bindPrintingStream();
    _bindStitchingStream();
    _bindPackingStream();
    fetchRecentActivities();
  }

  // --- 1. WORKFORCE STREAMS ---
  void _bindApprovedWorkers() {
    _db
        .collection('id_requests')
        .where('status', isEqualTo: 'Approved')
        .snapshots()
        .listen((snapshot) {
          allApprovedWorkers.assignAll(
            snapshot.docs.map((doc) {
              var data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList(),
          );
          activeWorkers.value = allApprovedWorkers.length;
        });
  }

  void _bindPendingRequests() {
    _db
        .collection('id_requests')
        .where('status', isEqualTo: 'Pending')
        .snapshots()
        .listen((snapshot) {
          pendingRequests.assignAll(
            snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList(),
          );
          pendingApprovalsCount.value = pendingRequests.length;
        });
  }

  // --- 2. DEPARTMENT STREAMS (Dashboard) ---

  void _bindTodaysOrders() {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);

    _db
        .collection('orders')
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          recentOrders.assignAll(
            snapshot.docs.map((doc) => OrderModel.fromSnapshot(doc)).toList(),
          );
          _calculateProductionTotal();
        });
  }

  void _bindCuttingStream() {
    _db
        .collection('cutting_entries')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .listen((snapshot) {
          recentCuttingEntries.assignAll(
            snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList(),
          );
          _calculateGlobalStats();
        });
  }

  void _bindPrintingStream() {
    _db
        .collection('printing_entries')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .listen((snapshot) {
          recentPrintingEntries.assignAll(
            snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList(),
          );
          _calculateGlobalStats();
        });
  }

  void _bindStitchingStream() {
    _db
        .collection('stitching_entries')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .listen((snapshot) {
          recentStitchingEntries.assignAll(
            snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList(),
          );
          _calculateGlobalStats();
        });
  }

  void _bindPackingStream() {
    _db
        .collection('packing_entries')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .listen((snapshot) {
          recentPackingEntries.assignAll(
            snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList(),
          );
          _calculateGlobalStats();
        });
  }

  // --- 3. KPI CALCULATIONS ---
  void _calculateGlobalStats() {
    double totalScoreSum = 0.0;
    int activeDepartments = 0;

    // A. STITCHING
    if (recentStitchingEntries.isNotEmpty) {
      double stitchEff = 0.0;
      for (var entry in recentStitchingEntries) {
        stitchEff += (entry['efficiency'] as num? ?? 0.0).toDouble();
      }
      totalScoreSum += (stitchEff / recentStitchingEntries.length);
      activeDepartments++;
    }

    // B. PRINTING
    if (recentPrintingEntries.isNotEmpty) {
      double printQualityScore = 0.0;
      for (var entry in recentPrintingEntries) {
        double total = (entry['completedQty'] as num? ?? 1).toDouble();
        double damaged = (entry['totalDamaged'] as num? ?? 0).toDouble();
        if (total == 0) total = 1;

        double batchScore = ((total - damaged) / total) * 100;
        if (batchScore < 0) batchScore = 0;
        printQualityScore += batchScore;
      }
      totalScoreSum += (printQualityScore / recentPrintingEntries.length);
      activeDepartments++;
    }

    // C. CUTTING (Baseline)
    if (recentCuttingEntries.isNotEmpty) {
      totalScoreSum += 100.0;
      activeDepartments++;
    }

    // D. PACKING (Baseline)
    if (recentPackingEntries.isNotEmpty) {
      totalScoreSum += 100.0;
      activeDepartments++;
    }

    if (activeDepartments > 0) {
      averageEfficiency.value = totalScoreSum / activeDepartments;
    } else {
      averageEfficiency.value = 0.0;
    }

    // Damages
    int pDamages = recentPrintingEntries.fold(
      0,
      (sum, item) => sum + (item['totalDamaged'] as int? ?? 0),
    );
    int sDamages = recentStitchingEntries.fold(
      0,
      (sum, item) => sum + (item['rejectedQty'] as int? ?? 0),
    );
    totalDamages.value = pDamages + sDamages;
  }

  void _calculateProductionTotal() {
    double total = recentOrders.fold(0, (sum, item) => sum + item.totalAmount);
    totalDailyProduction.value = total;
  }

  // --- 4. LIVE FEED LOGIC (Dashboard) ---
  void fetchRecentActivities() async {
    isLoading.value = true;
    List<ActivityItem> allActivities = [];
    try {
      var orders = await _db
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(3)
          .get();
      for (var doc in orders.docs) {
        final data = doc.data();
        Timestamp? ts = data['createdAt'] as Timestamp?;
        allActivities.add(
          ActivityItem(
            title: "New Order: ${data['clientName'] ?? 'Unknown'}",
            subtitle: "${data['productName']} (${data['quantity']} pcs)",
            time: ts?.toDate() ?? DateTime.now(),
            icon: Icons.shopping_bag,
            color: TColors.marketing,
          ),
        );
      }
      await _fetchDeptLogs(
        allActivities,
        'cutting_entries',
        "Cutting",
        Icons.content_cut,
        TColors.cutting,
      );
      await _fetchDeptLogs(
        allActivities,
        'printing_entries',
        "Printing",
        Icons.print,
        TColors.printing,
      );
      await _fetchDeptLogs(
        allActivities,
        'stitching_entries',
        "Stitching",
        Icons.handyman,
        TColors.stitching,
      );
      await _fetchDeptLogs(
        allActivities,
        'packing_entries',
        "Packing",
        Icons.inventory_2,
        TColors.packing,
      );

      allActivities.sort((a, b) => b.time.compareTo(a.time));
      recentActivities.assignAll(allActivities);
    } catch (e) {
      print("Error fetching activities: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchDeptLogs(
    List<ActivityItem> list,
    String collection,
    String deptName,
    IconData icon,
    Color color,
  ) async {
    try {
      var snap = await _db
          .collection(collection)
          .orderBy('timestamp', descending: true)
          .limit(3)
          .get();
      for (var doc in snap.docs) {
        final data = doc.data();
        Timestamp? ts = data['timestamp'] as Timestamp?;
        String qty = (data['completedQty'] ?? data['totalQty'] ?? '0')
            .toString();
        list.add(
          ActivityItem(
            title: "$deptName Entry",
            subtitle: "Order #${data['orderId'] ?? '?'} - $qty pcs",
            time: ts?.toDate() ?? DateTime.now(),
            icon: icon,
            color: color,
          ),
        );
      }
    } catch (e) {
      print("Skipping $collection: $e");
    }
  }

  // --- 5. REPORTING LOGIC (New Screen) ---

  void setReportDate(DateTime date) {
    reportDate.value = date;
    fetchReportData();
  }

  void setReportSection(String section) {
    reportSection.value = section;
    fetchReportData();
  }

  void fetchReportData() async {
    isReportLoading.value = true;
    reportList.clear();
    List<ActivityItem> tempResults = [];

    // Calculate Start & End of selected day
    DateTime start = DateTime(
      reportDate.value.year,
      reportDate.value.month,
      reportDate.value.day,
    );
    DateTime end = start.add(const Duration(days: 1));

    try {
      // --- ORDERS ---
      if (reportSection.value == 'All' || reportSection.value == 'Orders') {
        var snap = await _db
            .collection('orders')
            .where(
              'createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start),
            )
            .where('createdAt', isLessThan: Timestamp.fromDate(end))
            .get();

        for (var doc in snap.docs) {
          var data = doc.data();
          tempResults.add(
            ActivityItem(
              title: "Order: ${data['clientName']}",
              subtitle: "${data['productName']} - ${data['quantity']} pcs",
              time: (data['createdAt'] as Timestamp).toDate(),
              icon: Icons.shopping_bag,
              color: TColors.marketing,
            ),
          );
        }
      }

      // --- DEPARTMENTS ---
      if (reportSection.value == 'All' || reportSection.value == 'Cutting') {
        await _fetchReportDept(
          tempResults,
          'cutting_entries',
          'Cutting',
          Icons.content_cut,
          TColors.cutting,
          start,
          end,
        );
      }
      if (reportSection.value == 'All' || reportSection.value == 'Printing') {
        await _fetchReportDept(
          tempResults,
          'printing_entries',
          'Printing',
          Icons.print,
          TColors.printing,
          start,
          end,
        );
      }
      if (reportSection.value == 'All' || reportSection.value == 'Stitching') {
        await _fetchReportDept(
          tempResults,
          'stitching_entries',
          'Stitching',
          Icons.handyman,
          TColors.stitching,
          start,
          end,
        );
      }
      if (reportSection.value == 'All' || reportSection.value == 'Packing') {
        await _fetchReportDept(
          tempResults,
          'packing_entries',
          'Packing',
          Icons.inventory_2,
          TColors.packing,
          start,
          end,
        );
      }

      // Sort by Time
      tempResults.sort((a, b) => b.time.compareTo(a.time));
      reportList.assignAll(tempResults);
    } catch (e) {
      print("Report Error: $e");
    } finally {
      isReportLoading.value = false;
    }
  }

  Future<void> _fetchReportDept(
    List<ActivityItem> list,
    String collection,
    String title,
    IconData icon,
    Color color,
    DateTime start,
    DateTime end,
  ) async {
    var snap = await _db
        .collection(collection)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThan: Timestamp.fromDate(end))
        .get();

    for (var doc in snap.docs) {
      var data = doc.data();
      String qty = (data['completedQty'] ?? data['totalQty'] ?? '0').toString();
      list.add(
        ActivityItem(
          title: "$title Entry",
          subtitle: "Order #${data['orderId'] ?? '?'} - $qty pcs",
          time: (data['timestamp'] as Timestamp).toDate(),
          icon: icon,
          color: color,
        ),
      );
    }
  }

  // --- 6. ACTIONS ---
  Future<void> approveNextStage(String docId, Map<String, dynamic> user) async {
    try {
      final docRef = _db.collection('id_requests').doc(docId);
      if (user['unitApproved'] == false) {
        await docRef.update({'unitApproved': true});
      } else if (user['shiftApproved'] == false) {
        await docRef.update({'shiftApproved': true});
      } else if (user['adminApproved'] == false) {
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
    fetchRecentActivities();
    await Future.delayed(const Duration(seconds: 1));
  }
}
