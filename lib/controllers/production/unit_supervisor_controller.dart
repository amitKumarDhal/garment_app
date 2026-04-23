import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../data/models/order_model.dart';
import '../../utils/constants/colors.dart';

class UnitSupervisorController extends GetxController {
  static UnitSupervisorController get instance => Get.find();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  var activeOrders = <OrderModel>[].obs;
  var supervisorName = 'Supervisor'.obs;
  var isLoading = true.obs;
  var visibleOrdersCount = 10.obs;

  StreamSubscription? _ordersSubscription;
  StreamSubscription? _inventorySubscription;
  StreamSubscription? _mockupSubscription;

  final RxMap<String, double> inventoryStock = <String, double>{}.obs;

  var pendingMockupOrders = <OrderModel>[].obs;
  var doneMockupOrders = <OrderModel>[].obs;

  final List<String> factoryStages = [
    'Approved', 'Fab Purchased', 'Fab Ready', 'Cutting', 'Cutting Done',
    'Printing', 'Printed', 'Stitching', 'Stitched', 'Packing', 'Packed',
    'Out SRC', 'Shipping', 'Shipped', 'Delivered'
  ];

  var selectedFilterStage = 'All'.obs;
  var searchQuery = ''.obs;
  var selectedDateRange = Rxn<DateTimeRange>();
  var selectedDeliverableDate = Rxn<DateTime>();

  @override
  void onInit() {
    super.onInit();
    fetchSupervisorProfile();
    fetchActiveOrders();
    listenToInventoryLogs();
    listenToMockupOrders();
  }

  @override
  void onClose() {
    _ordersSubscription?.cancel();
    _inventorySubscription?.cancel();
    _mockupSubscription?.cancel();
    super.onClose();
  }

  // ===========================================================================
  // ✅ MOCKUP LOGIC
  // ===========================================================================
  void listenToMockupOrders() {
    _mockupSubscription?.cancel();
    _mockupSubscription = _db.collection('orders')
        .where('status', whereIn: ['Approved', 'Fab Purchased', 'Fab Ready', 'Cutting', 'Cutting Done'])
        .limit(50) // ✅ OPTIMIZED: Hard cap prevents quota burn
        .snapshots()
        .listen((snapshot) {

      pendingMockupOrders.clear();
      doneMockupOrders.clear();

      for (var doc in snapshot.docs) {
        OrderModel order = OrderModel.fromSnapshot(doc);
        bool isMockupDone = doc.data().containsKey('mockupDone') ? doc.data()['mockupDone'] : false;

        if (isMockupDone) {
          doneMockupOrders.add(order);
        } else {
          pendingMockupOrders.add(order);
        }
      }
    }, onError: (e) => debugPrint("Error fetching mockups: $e"));
  }

  Future<void> markMockupDone(dynamic order) async {
    try {
      String approverName = supervisorName.value.trim().isEmpty ? "Unit Supervisor" : supervisorName.value;

      Get.dialog(const Center(child: CircularProgressIndicator(color: TColors.primary)), barrierDismissible: false);

      await _db.collection('orders').doc(order.id).update({
        'mockupDone': true,
        'mockupApprovedBy': approverName,
        'mockupDoneAt': FieldValue.serverTimestamp(),
        'lastUpdatedBy': approverName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.back();
      Get.snackbar(
        "Mockup Approved", "Design set to DONE by $approverName",
        backgroundColor: Colors.green, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      if (Get.isDialogOpen!) Get.back();
      Get.snackbar("Update Failed", "Could not save approval: $e", backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  // ===========================================================================
  // ✅ FABRIC YIELD CALCULATOR
  // ===========================================================================
  String getFabricRequiredText(int totalPieces, String fabricOrProductName) {
    String normalized = fabricOrProductName.toLowerCase().trim();
    double yieldPerKg = 0.0;

    if (normalized.contains('pc matty')) yieldPerKg = 3.2;
    else if (normalized.contains('spun') || normalized.contains('spun matty')) yieldPerKg = 3.5;
    else if (normalized.contains('nokia')) yieldPerKg = 6.0;
    else if (normalized.contains('dotknit') || normalized.contains('dot')) yieldPerKg = 4.0;
    else if (normalized.contains('matty')) yieldPerKg = 3.5;

    if (yieldPerKg == 0.0) return "Not Specified";

    double kgRequired = totalPieces / yieldPerKg;
    double finalRequirement = kgRequired * 1.02;

    return "${finalRequirement.toStringAsFixed(1)} KG";
  }

  // ===========================================================================
  // ✅ REAL-TIME INVENTORY
  // ===========================================================================
  void listenToInventoryLogs() {
    _inventorySubscription?.cancel();
    _inventorySubscription = _db.collection('inventory_logs')
        .limit(300) // ✅ OPTIMIZED: Prevents downloading thousands of old logs
        .snapshots().listen((snapshot) {
      Map<String, double> calculatedStock = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        String rawProduct = (data['product'] ?? '').toString().toLowerCase().trim();
        String rawColor = (data['color'] ?? 'Not Specified').toString().toLowerCase().trim();
        String type = (data['type'] ?? 'IN').toString().toUpperCase();
        double qty = double.tryParse(data['qty']?.toString() ?? '0') ?? 0.0;

        String baseFabric = rawProduct;
        if (rawProduct.contains('collar')) baseFabric = "collar";

        String key = "${baseFabric}_$rawColor";

        if (type == 'IN') calculatedStock[key] = (calculatedStock[key] ?? 0.0) + qty;
        else if (type == 'OUT') calculatedStock[key] = (calculatedStock[key] ?? 0.0) - qty;
      }
      inventoryStock.value = calculatedStock;
    }, onError: (e) => debugPrint("Error fetching inventory logs: $e"));
  }

  // ===========================================================================
  // ✅ DATA FETCHING
  // ===========================================================================
  Future<void> fetchSupervisorProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await _db.collection('users').doc(user.uid).get(const GetOptions(source: Source.serverAndCache));
        if (doc.exists) {
          String fullName = doc.data()?['FullName'] ?? doc.data()?['name'] ?? 'Supervisor';
          supervisorName.value = fullName.trim().split(' ').first;
        }
      } catch (e) {
        debugPrint("Error fetching supervisor profile: $e");
      }
    }
  }

  Future<void> fetchActiveOrders() async {
    if (FirebaseAuth.instance.currentUser == null) return;

    await _ordersSubscription?.cancel();
    isLoading.value = true;
    Completer<void> completer = Completer<void>();

    _ordersSubscription = _db.collection('orders')
        .where('status', whereIn: factoryStages)
    // ❌ REMOVED: .orderBy('deliveryDate') to prevent Firebase Index Crash
        .limit(100) // ✅ OPTIMIZED: Hard cap on active items
        .snapshots()
        .listen((snapshot) {

      final validDocs = snapshot.docs.where((doc) => doc.data()['isDeleted'] != true);

      // Convert to list of OrderModels
      List<OrderModel> ordersList = validDocs.map((doc) => OrderModel.fromSnapshot(doc)).toList();

      // ✅ LOCAL SORT: Sorts by delivery date perfectly without needing Firebase Indexes!
      ordersList.sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));

      activeOrders.value = ordersList;
      isLoading.value = false;

      if (!completer.isCompleted) completer.complete();
    }, onError: (e) {
      debugPrint("Fetch Orders Error: $e");
      isLoading.value = false;
      if (!completer.isCompleted) completer.complete();
    });

    return completer.future;
  }

  // ===========================================================================
  // ✅ UPDATES & FILTERS
  // ===========================================================================
  Future<void> updateProductionStage(String orderId, String currentStatus, String newStatus, {String remark = ""}) async {
    try {
      final historyEvent = {
        'stage': newStatus,
        'updatedBy': supervisorName.value,
        'timestamp': Timestamp.now(),
        'remark': remark,
      };

      await _db.collection('orders').doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastUpdatedBy': supervisorName.value,
        'stageHistory': FieldValue.arrayUnion([historyEvent]),
      });

      final doc = await _db.collection('orders').doc(orderId).get();
      final associateId = doc.data()?['marketingPersonId'] ?? '';
      final manualOrderNo = doc.data()?['manualOrderNo'] ?? orderId;

      if (associateId.isNotEmpty) {
        String emoji = "🏭";
        if (newStatus == 'Packed') emoji = "📦";
        if (newStatus == 'Fab Ready') emoji = "👕";
        if (newStatus == 'Out SRC') emoji = "🏢";
        if (newStatus == 'Shipped') emoji = "🚚";

        await _db.collection('notifications').add({
          'targetUserId': associateId,
          'title': 'Production Update $emoji',
          'message': 'Order $manualOrderNo moved to $newStatus.',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }

      Get.snackbar("Success", "Moved to $newStatus", backgroundColor: TColors.success.withValues(alpha:0.1), colorText: TColors.success);
    } catch (e) {
      Get.snackbar("Error", "Failed: $e", backgroundColor: TColors.error.withValues(alpha:0.1), colorText: TColors.error);
    }
  }

  void clearDateFilter() => selectedDateRange.value = null;

  Future<void> pickDateRange(BuildContext context) async {
    final initialDateRange = selectedDateRange.value ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 7)),
          end: DateTime.now().add(const Duration(days: 30)),
        );

    final newDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(primary: TColors.primary, onPrimary: Colors.white, surface: TColors.darkCard, onSurface: Colors.white)
                : const ColorScheme.light(primary: TColors.primary, onPrimary: Colors.white, surface: Colors.white, onSurface: TColors.textPrimary),
          ),
          child: child!,
        );
      },
    );

    if (newDateRange != null) selectedDateRange.value = newDateRange;
  }

  List<OrderModel> get filteredOrders {
    List<OrderModel> result = activeOrders;

    if (selectedDateRange.value != null) {
      DateTime start = selectedDateRange.value!.start;
      DateTime end = selectedDateRange.value!.end;
      end = DateTime(end.year, end.month, end.day, 23, 59, 59);

      result = result.where((o) {
        return o.deliveryDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
            o.deliveryDate.isBefore(end.add(const Duration(seconds: 1)));
      }).toList();
    }

    if (selectedFilterStage.value == 'All NSO') {
      result = result.where((o) {
        String s = o.status.toLowerCase();
        return s != 'shipped' && s != 'delivered' && s != 'completed';
      }).toList();
    } else if (selectedFilterStage.value != 'All') {
      result = result.where((o) => o.status.toLowerCase() == selectedFilterStage.value.toLowerCase()).toList();
    }

    if (searchQuery.value.isNotEmpty) {
      String query = searchQuery.value.toLowerCase();
      result = result.where((o) {
        String orderNo = (o.manualOrderNo ?? o.id ?? "").toLowerCase();
        String client = o.clientName.toLowerCase();
        String product = o.productName.toLowerCase();

        return orderNo.contains(query) || client.contains(query) || product.contains(query);
      }).toList();
    }

    return result;
  }

  void setFilterStage(String stage) => selectedFilterStage.value = stage;
  void updateSearchQuery(String query) => searchQuery.value = query;

  List<Map<String, dynamic>> get stageUnitBreakdown {
    final stages = [
      {'name': 'Approved', 'icon': Icons.thumb_up_alt_outlined, 'color': TColors.electricBlue},
      {'name': 'Fab Purchased', 'icon': Icons.shopping_cart_outlined, 'color': TColors.neonPink},
      {'name': 'Fab Ready', 'icon': Icons.inventory_outlined, 'color': TColors.brightMint},
      {'name': 'Cutting', 'icon': Icons.content_cut_rounded, 'color': TColors.cutting},
      {'name': 'Cutting Done', 'icon': Icons.cut_outlined, 'color': Colors.deepOrange},
      {'name': 'Printing', 'icon': Icons.print_outlined, 'color': TColors.printing},
      {'name': 'Printed', 'icon': Icons.format_paint_outlined, 'color': Colors.cyan},
      {'name': 'Stitching', 'icon': Icons.precision_manufacturing_outlined, 'color': TColors.stitching},
      {'name': 'Stitched', 'icon': Icons.checkroom_outlined, 'color': Colors.brown},
      {'name': 'Packing', 'icon': Icons.inventory_2_outlined, 'color': TColors.packing},
      {'name': 'Packed', 'icon': Icons.all_inbox_rounded, 'color': Colors.deepPurple},
      {'name': 'Out SRC', 'icon': Icons.business_rounded, 'color': Colors.indigoAccent},
      {'name': 'Shipping', 'icon': Icons.local_shipping_outlined, 'color': TColors.shipping},
      {'name': 'Delivered', 'icon': Icons.task_alt_rounded, 'color': TColors.delivered},
    ];

    return stages.map((stage) {
      String name = stage['name'] as String;
      var stageOrders = activeOrders.where((o) => o.status.toLowerCase() == name.toLowerCase());

      int count = stageOrders.fold(0, (sum, o) => sum + o.quantity);
      int orderCount = stageOrders.length;

      return {...stage, 'count': count, 'orderCount': orderCount};
    }).toList();
  }
}