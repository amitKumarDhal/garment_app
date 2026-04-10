import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:yoobbel/data/models/order_model.dart';
import '../../utils/constants/colors.dart';
import '../../data/models/activity_item_model.dart';

class AdminController extends GetxController {
  static AdminController get instance => Get.find();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Observables ---
  var totalDailyProduction = 0.0.obs;
  var averageEfficiency = 0.0.obs;
  var activeWorkers = 0.obs;
  var totalDamages = 0.obs;
  var adminName = "".obs;

  // --- Monthly Revenue Observables ---
  var totalMonthlyRevenue = 0.0.obs;
  var selectedMonth = DateTime.now().obs;

  // 🛡️ Memory Leak Protection (All Streams)
  StreamSubscription? _monthlyRevenueSubscription;
  StreamSubscription? _requestsSub;
  StreamSubscription? _workersSub;
  StreamSubscription? _staffSub;
  StreamSubscription? _ordersSub;
  StreamSubscription? _cuttingSub;
  StreamSubscription? _printingSub;
  StreamSubscription? _stitchingSub;
  StreamSubscription? _packingSub;

  // --- REPORTING VARIABLES ---
  var reportDate = DateTime.now().obs;
  var reportSection = 'All'.obs;
  RxList<ActivityItem> reportList = <ActivityItem>[].obs;
  var isReportLoading = false.obs;

  // --- Lists ---
  RxList<Map<String, dynamic>> pendingRequests = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> allApprovedWorkers = <Map<String, dynamic>>[].obs;

  // REAL DATA LISTS FOR SUPERVISORS & MANAGERS
  RxList<Map<String, dynamic>> unitSupervisors = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> shiftSupervisors = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> salesManagers = <Map<String, dynamic>>[].obs;

  RxList<OrderModel> recentOrders = <OrderModel>[].obs;
  RxList<Map<String, dynamic>> recentCuttingEntries = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> recentPrintingEntries = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> recentStitchingEntries = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> recentPackingEntries = <Map<String, dynamic>>[].obs;
  RxList<ActivityItem> recentActivities = <ActivityItem>[].obs;

  var pendingApprovalsCount = 0.obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAdminIdentity();
    startAdminListeners();
  }

  @override
  void onClose() {
    // 🛡️ CRITICAL: Kill all active listeners to save battery and Firebase costs
    _monthlyRevenueSubscription?.cancel();
    _requestsSub?.cancel();
    _workersSub?.cancel();
    _staffSub?.cancel();
    _ordersSub?.cancel();
    _cuttingSub?.cancel();
    _printingSub?.cancel();
    _stitchingSub?.cancel();
    _packingSub?.cancel();
    super.onClose();
  }

  Future<void> fetchAdminIdentity() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _db.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          String dbName = userDoc.data()?['FullName'] ?? userDoc.data()?['Name'] ?? userDoc.data()?['name'] ?? '';
          if (dbName.isNotEmpty) {
            adminName.value = dbName;
            return;
          }
        }

        final idDoc = await _db.collection('id_requests').doc(user.uid).get();
        if (idDoc.exists) {
          String reqName = idDoc.data()?['name'] ?? idDoc.data()?['FullName'] ?? '';
          if (reqName.isNotEmpty) {
            adminName.value = reqName;
            return;
          }
        }

        adminName.value = user.displayName ?? "Super Admin";
      }
    } catch (e) {
      debugPrint("Error fetching admin name: $e");
      adminName.value = "Super Admin";
    }
  }

  void startAdminListeners() {
    if (_auth.currentUser == null) return;

    _bindPendingRequests();
    _bindApprovedWorkers();
    _bindStaffDirectory();
    _bindTodayOrders();
    _bindCuttingStream();
    _bindPrintingStream();
    _bindStitchingStream();
    _bindPackingStream();
    fetchRecentActivities();
    _bindMonthlyRevenue();
  }

  // --- MONTH SELECTION & REVENUE LOGIC ---
  Future<void> selectMonthYear(BuildContext context) async {
    int tempYear = selectedMonth.value.year;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              contentPadding: const EdgeInsets.all(20),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left_rounded, color: isDark ? Colors.white : Colors.black87),
                    onPressed: () => setState(() => tempYear--),
                  ),
                  Text(
                      tempYear.toString(),
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: isDark ? Colors.white : Colors.black87)
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white : Colors.black87),
                    onPressed: tempYear < DateTime.now().year
                        ? () => setState(() => tempYear++)
                        : null,
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    DateTime monthDate = DateTime(tempYear, index + 1, 1);
                    String monthName = DateFormat('MMM').format(monthDate);

                    bool isSelected = selectedMonth.value.year == tempYear && selectedMonth.value.month == index + 1;
                    bool isFuture = monthDate.isAfter(DateTime.now());

                    return GestureDetector(
                      onTap: isFuture ? null : () {
                        selectedMonth.value = monthDate;
                        Get.back();
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? TColors.primary
                              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? TColors.primary : Colors.transparent),
                        ),
                        child: Text(
                          monthName,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isFuture
                                ? Colors.grey
                                : (isDark ? Colors.white70 : Colors.black87)),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _bindMonthlyRevenue() {
    if (_auth.currentUser == null) return;
    ever(selectedMonth, (_) => _updateMonthlyStream());
    _updateMonthlyStream();
  }

  Future<void> _updateMonthlyStream() async {
    await _monthlyRevenueSubscription?.cancel();

    DateTime startOfMonth = DateTime(selectedMonth.value.year, selectedMonth.value.month, 1);
    DateTime endOfMonth = DateTime(selectedMonth.value.year, selectedMonth.value.month + 1, 0, 23, 59, 59);

    _monthlyRevenueSubscription = _db.collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .snapshots()
        .listen((snapshot) {

      double monthlySum = 0.0;
      List<String> ignoredStatuses = ['pending', 'placed', 'rejected', 'deleted', 'cancelled'];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        String status = (data['status'] ?? '').toString().toLowerCase();

        if (data['isDeleted'] == true || ignoredStatuses.contains(status)) continue;

        double totalAmt = 0.0;
        if (data['totalAmount'] is num) {
          totalAmt = (data['totalAmount'] as num).toDouble();
        } else if (data['totalAmount'] is String) {
          totalAmt = double.tryParse(data['totalAmount'].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
        }

        double effRev = 0.0;
        if (data['effectiveRevenue'] is num) {
          effRev = (data['effectiveRevenue'] as num).toDouble();
        } else if (data['effectiveRevenue'] is String) {
          effRev = double.tryParse(data['effectiveRevenue'].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
        }

        double finalAmount = (effRev > 0) ? effRev : totalAmt;
        monthlySum += finalAmount;
      }

      totalMonthlyRevenue.value = monthlySum;
    });
  }

  // --- 1. WORKFORCE & STAFF STREAMS ---

  void _bindStaffDirectory() {
    if (_auth.currentUser == null) return;
    _staffSub = _db.collection('users').where('status', isEqualTo: 'Approved').snapshots().listen((snapshot) {
      var uSupervisors = <Map<String, dynamic>>[];
      var sSupervisors = <Map<String, dynamic>>[];
      var sManagers = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        var data = doc.data();
        data['id'] = doc.id;

        // 🛡️ SAFE ROLE CHECK: Trim spaces and convert to lowercase
        String role = (data['role'] ?? data['Role'] ?? '').toString().trim().toLowerCase();

        if (role.contains('unit supervisor')) uSupervisors.add(data);
        else if (role.contains('shift supervisor')) sSupervisors.add(data);
        else if (role.contains('sales manager')) sManagers.add(data);
      }

      unitSupervisors.assignAll(uSupervisors);
      shiftSupervisors.assignAll(sSupervisors);
      salesManagers.assignAll(sManagers);
    });
  }

  void _bindApprovedWorkers() {
    if (_auth.currentUser == null) return;
    _workersSub = _db.collection('id_requests')
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
    if (_auth.currentUser == null) return;
    _requestsSub = _db.collection('id_requests')
        .where('status', isEqualTo: 'Pending')
        .snapshots()
        .listen((snapshot) {
      pendingRequests.assignAll(
        snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList(),
      );
      pendingApprovalsCount.value = pendingRequests.length;
    });
  }

  // --- 2. DEPARTMENT STREAMS ---

  void _bindTodayOrders() {
    if (_auth.currentUser == null) return;
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);

    _ordersSub = _db.collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {

      List<OrderModel> validOrders = [];
      for (var doc in snapshot.docs) {
        // 🛡️ CRITICAL TRY/CATCH: Prevents a single corrupt order from crashing the entire feed
        try {
          final order = OrderModel.fromSnapshot(doc);
          if (order.toJson()['isDeleted'] != true) {
            validOrders.add(order);
          }
        } catch (e) {
          debugPrint("Skipped corrupt daily order doc: ${doc.id}");
        }
      }

      recentOrders.assignAll(validOrders);
      _calculateProductionTotal();
    });
  }

  void _bindCuttingStream() {
    if (_auth.currentUser == null) return;
    _cuttingSub = _db.collection('cutting_entries').orderBy('timestamp', descending: true).limit(10).snapshots().listen((snapshot) {
      recentCuttingEntries.assignAll(snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
      _calculateGlobalStats();
    });
  }

  void _bindPrintingStream() {
    if (_auth.currentUser == null) return;
    _printingSub = _db.collection('printing_entries').orderBy('timestamp', descending: true).limit(10).snapshots().listen((snapshot) {
      recentPrintingEntries.assignAll(snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
      _calculateGlobalStats();
    });
  }

  void _bindStitchingStream() {
    if (_auth.currentUser == null) return;
    _stitchingSub = _db.collection('stitching_entries').orderBy('timestamp', descending: true).limit(10).snapshots().listen((snapshot) {
      recentStitchingEntries.assignAll(snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
      _calculateGlobalStats();
    });
  }

  void _bindPackingStream() {
    if (_auth.currentUser == null) return;
    _packingSub = _db.collection('packing_entries').orderBy('timestamp', descending: true).limit(10).snapshots().listen((snapshot) {
      recentPackingEntries.assignAll(snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
      _calculateGlobalStats();
    });
  }

  // --- 3. KPI CALCULATIONS ---
  void _calculateGlobalStats() {
    double totalScoreSum = 0.0;
    int activeDepartments = 0;

    if (recentStitchingEntries.isNotEmpty) {
      double stitchEff = 0.0;
      for (var entry in recentStitchingEntries) {
        stitchEff += (entry['efficiency'] as num? ?? 0.0).toDouble();
      }
      totalScoreSum += (stitchEff / recentStitchingEntries.length);
      activeDepartments++;
    }

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

    if (recentCuttingEntries.isNotEmpty) {
      totalScoreSum += 100.0;
      activeDepartments++;
    }

    if (recentPackingEntries.isNotEmpty) {
      totalScoreSum += 100.0;
      activeDepartments++;
    }

    if (activeDepartments > 0) {
      averageEfficiency.value = totalScoreSum / activeDepartments;
    } else {
      averageEfficiency.value = 0.0;
    }

    int pDamages = recentPrintingEntries.fold(0, (acc, item) => acc + (item['totalDamaged'] as int? ?? 0));
    int sDamages = recentStitchingEntries.fold(0, (acc, item) => acc + (item['rejectedQty'] as int? ?? 0));
    totalDamages.value = pDamages + sDamages;
  }

  void _calculateProductionTotal() {
    List<String> ignoredStatuses = ['pending', 'placed', 'rejected', 'deleted', 'cancelled'];

    double total = recentOrders.fold(0.0, (acc, item) {
      if (ignoredStatuses.contains(item.status.toLowerCase())) {
        return acc;
      }
      double effRev = item.effectiveRevenue;
      double amount = (effRev > 0) ? effRev : item.totalAmount;
      return acc + amount;
    });

    totalDailyProduction.value = total;
  }

  // --- 4. LIVE FEED LOGIC ---
  void fetchRecentActivities() async {
    if (_auth.currentUser == null) return;
    isLoading.value = true;
    List<ActivityItem> allActivities = [];
    try {
      var orders = await _db.collection('orders').orderBy('createdAt', descending: true).limit(10).get();

      int orderCount = 0;
      for (var doc in orders.docs) {
        final data = doc.data();
        if (data['isDeleted'] == true) continue;
        if (orderCount >= 3) break;
        orderCount++;

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

      await _fetchDeptLogs(allActivities, 'cutting_entries', "Cutting", Icons.content_cut, TColors.cutting);
      await _fetchDeptLogs(allActivities, 'printing_entries', "Printing", Icons.print, TColors.printing);
      await _fetchDeptLogs(allActivities, 'stitching_entries', "Stitching", Icons.handyman, TColors.stitching);
      await _fetchDeptLogs(allActivities, 'packing_entries', "Packing", Icons.inventory_2, TColors.packing);

      allActivities.sort((a, b) => b.time.compareTo(a.time));
      recentActivities.assignAll(allActivities);
    } catch (e) {
      debugPrint("Error fetching activities: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchDeptLogs(
      List<ActivityItem> list, String collection, String deptName, IconData icon, Color color,
      ) async {
    try {
      var snap = await _db.collection(collection).orderBy('timestamp', descending: true).limit(3).get();
      for (var doc in snap.docs) {
        final data = doc.data();
        Timestamp? ts = data['timestamp'] as Timestamp?;
        String qty = (data['completedQty'] ?? data['totalQty'] ?? '0').toString();
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
      debugPrint("Skipping $collection: $e");
    }
  }

  // --- 5. REPORTING LOGIC ---
  void setReportDate(DateTime date) {
    reportDate.value = date;
    fetchReportData();
  }

  void setReportSection(String section) {
    reportSection.value = section;
    fetchReportData();
  }

  void fetchReportData() async {
    if (_auth.currentUser == null) return;
    isReportLoading.value = true;
    reportList.clear();
    List<ActivityItem> tempResults = [];

    DateTime start = DateTime(reportDate.value.year, reportDate.value.month, reportDate.value.day);
    DateTime end = start.add(const Duration(days: 1));

    try {
      if (reportSection.value == 'All' || reportSection.value == 'Orders') {
        var snap = await _db.collection('orders')
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .where('createdAt', isLessThan: Timestamp.fromDate(end))
            .get();

        for (var doc in snap.docs) {
          var data = doc.data();
          if (data['isDeleted'] == true) continue;

          // 🛡️ SAFE FALLBACK: Prevents crash if 'createdAt' is randomly missing
          Timestamp? ts = data['createdAt'] as Timestamp?;
          DateTime time = ts?.toDate() ?? DateTime.now();

          tempResults.add(
            ActivityItem(
              title: "Order: ${data['clientName'] ?? 'Unknown'}",
              subtitle: "${data['productName'] ?? 'Item'} - ${data['quantity'] ?? 0} pcs",
              time: time,
              icon: Icons.shopping_bag,
              color: TColors.marketing,
            ),
          );
        }
      }

      if (reportSection.value == 'All' || reportSection.value == 'Cutting') {
        await _fetchReportDept(tempResults, 'cutting_entries', 'Cutting', Icons.content_cut, TColors.cutting, start, end);
      }
      if (reportSection.value == 'All' || reportSection.value == 'Printing') {
        await _fetchReportDept(tempResults, 'printing_entries', 'Printing', Icons.print, TColors.printing, start, end);
      }
      if (reportSection.value == 'All' || reportSection.value == 'Stitching') {
        await _fetchReportDept(tempResults, 'stitching_entries', 'Stitching', Icons.handyman, TColors.stitching, start, end);
      }
      if (reportSection.value == 'All' || reportSection.value == 'Packing') {
        await _fetchReportDept(tempResults, 'packing_entries', 'Packing', Icons.inventory_2, TColors.packing, start, end);
      }

      tempResults.sort((a, b) => b.time.compareTo(a.time));
      reportList.assignAll(tempResults);
    } catch (e) {
      debugPrint("Report Error: $e");
    } finally {
      isReportLoading.value = false;
    }
  }

  Future<void> _fetchReportDept(
      List<ActivityItem> list, String collection, String title, IconData icon, Color color, DateTime start, DateTime end,
      ) async {
    var snap = await _db.collection(collection)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThan: Timestamp.fromDate(end))
        .get();

    for (var doc in snap.docs) {
      var data = doc.data();
      String qty = (data['completedQty'] ?? data['totalQty'] ?? '0').toString();

      Timestamp? ts = data['timestamp'] as Timestamp?;
      DateTime time = ts?.toDate() ?? DateTime.now();

      list.add(
        ActivityItem(
          title: "$title Entry",
          subtitle: "Order #${data['orderId'] ?? '?'} - $qty pcs",
          time: time,
          icon: icon,
          color: color,
        ),
      );
    }
  }

  // --- 6. ACTIONS ---

  Future<void> approveNextStage(String docId, Map<String, dynamic> user, {String? assignedSupervisorId, String? assignedSupervisorName}) async {
    try {
      final docRef = _db.collection('id_requests').doc(docId);

      Map<String, dynamic> updates = {};
      if (assignedSupervisorId != null) updates['assignedSupervisorId'] = assignedSupervisorId;
      if (assignedSupervisorName != null) updates['assignedSupervisorName'] = assignedSupervisorName;

      if (user['unitApproved'] == false) {
        updates['unitApproved'] = true;
        await docRef.update(updates);
      } else if (user['shiftApproved'] == false) {
        updates['shiftApproved'] = true;
        await docRef.update(updates);
      } else if (user['adminApproved'] == false) {
        // 1. Update id_requests
        updates['adminApproved'] = true;
        updates['status'] = 'Approved';
        await docRef.update(updates);

        // 2. Create/Update the official 'users' document
        await _db.collection('users').doc(docId).set({
          'name': user['name'] ?? user['FullName'] ?? 'Unknown',
          'email': user['email'] ?? user['Email'] ?? '',
          'role': user['role'] ?? user['Role'] ?? 'Worker',
          'status': 'Approved',
          'assignedSupervisorId': assignedSupervisorId ?? user['assignedSupervisorId'] ?? '',
          'assignedSupervisorName': assignedSupervisorName ?? user['assignedSupervisorName'] ?? '',
          'FullName': user['name'] ?? user['FullName'] ?? 'Unknown',
          'Role': user['role'] ?? user['Role'] ?? 'Worker',
          'Status': 'Approved',
          'updatedAt': FieldValue.serverTimestamp(),
          'approvedByAdmin': adminName.value,
        }, SetOptions(merge: true));

        Get.snackbar("Approved", "${user['name'] ?? 'User'} access granted", backgroundColor: Colors.green, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> rejectRequest(String docId) async {
    try {
      await _db.collection('id_requests').doc(docId).delete();
      Get.snackbar("Deleted", "Request removed", backgroundColor: Colors.orange, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  Future<void> removeApprovedWorker(String uid) async {
    try {
      await _db.collection('users').doc(uid).delete();
      await _db.collection('id_requests').doc(uid).delete();
      Get.snackbar("Worker Removed", "User has been successfully removed from the system.", backgroundColor: Colors.orange, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Could not remove worker: $e", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> refreshStats() async {
    _calculateProductionTotal();
    _calculateGlobalStats();
    fetchRecentActivities();
    await Future.delayed(const Duration(seconds: 1));
  }
}