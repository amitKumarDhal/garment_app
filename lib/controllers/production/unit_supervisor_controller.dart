import 'dart:async'; // ✅ 1. ADDED THIS IMPORT FOR STREAMS
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

  // ✅ 2. ADDED THIS VARIABLE TO TRACK THE LIVE STREAM
  StreamSubscription? _ordersSubscription;

  final List<String> factoryStages = [
    'Approved',
    'Fab Purchased',
    'Fab Ready',
    'Cutting',
    'Cutting Done',
    'Printing',
    'Printed',
    'Stitching',
    'Stitched',
    'Packing',
    'Packed',
    'Shipping',
    'Shipped',
    'Delivered'
  ];

  var selectedFilterStage = 'All'.obs;
  var searchQuery = ''.obs;
  var selectedDateRange = Rxn<DateTimeRange>();
  var selectedDeliverableDate = Rxn<DateTime>();

  @override
  void onInit() {
    super.onInit();
    fetchSupervisorProfile();
    fetchActiveFactoryOrders();
  }

  // ✅ 3. ADDED onClose TO KILL THE STREAM WHEN YOU LOG OUT
  @override
  void onClose() {
    _ordersSubscription?.cancel();
    super.onClose();
  }

  Future<void> fetchSupervisorProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await _db.collection('users').doc(user.uid).get();
        if (doc.exists) {
          String fullName = doc.data()?['FullName'] ?? doc.data()?['name'] ?? 'Supervisor';
          supervisorName.value = fullName.trim().split(' ').first;
        }
      } catch (e) {
        debugPrint("Error fetching supervisor profile: $e");
      }
    }
  }

  void fetchActiveFactoryOrders() {
    if (FirebaseAuth.instance.currentUser == null) return;
    isLoading.value = true;

    // ✅ 4. ATTACH THE LISTENER TO THE VARIABLE
    _ordersSubscription = _db.collection('orders')
        .where('status', whereIn: factoryStages)
        .orderBy('deliveryDate', descending: false)
        .snapshots()
        .listen((snapshot) {
      final validDocs = snapshot.docs.where((doc) => doc.data()['isDeleted'] != true);
      activeOrders.value = validDocs.map((doc) => OrderModel.fromSnapshot(doc)).toList();
      isLoading.value = false;
    }, onError: (e) {
      // Ignore errors if the user simply logged out
      if (FirebaseAuth.instance.currentUser == null) return;
      debugPrint("Error fetching factory orders: $e");
      isLoading.value = false;
    });
  }

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
        if (newStatus == 'Shipped') emoji = "🚚";

        await _db.collection('notifications').add({
          'targetUserId': associateId,
          'title': 'Production Update $emoji',
          'message': 'Order $manualOrderNo moved to $newStatus.',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
      Get.snackbar("Success", "Moved to $newStatus", backgroundColor: Colors.green.withValues(alpha:0.1), colorText: Colors.green);
    } catch (e) {
      Get.snackbar("Error", "Failed: $e", backgroundColor: Colors.red.withValues(alpha:0.1), colorText: Colors.red);
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
                ? ColorScheme.dark(primary: TColors.primary, onPrimary: Colors.white, surface: const Color(0xFF1E1E1E), onSurface: Colors.white)
                : ColorScheme.light(primary: TColors.primary, onPrimary: Colors.white, surface: Colors.white, onSurface: Colors.black87),
          ),
          child: child!,
        );
      },
    );

    if (newDateRange != null) {
      selectedDateRange.value = newDateRange;
    }
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
      {'name': 'Approved', 'icon': Icons.thumb_up_alt_outlined, 'color': Colors.blue},
      {'name': 'Fab Purchased', 'icon': Icons.shopping_cart_outlined, 'color': Colors.pink},
      {'name': 'Fab Ready', 'icon': Icons.inventory_outlined, 'color': Colors.lightGreen},
      {'name': 'Cutting', 'icon': Icons.content_cut_rounded, 'color': Colors.orange},
      {'name': 'Cutting Done', 'icon': Icons.cut_outlined, 'color': Colors.deepOrange},
      {'name': 'Printing', 'icon': Icons.print_outlined, 'color': Colors.indigo},
      {'name': 'Printed', 'icon': Icons.format_paint_outlined, 'color': Colors.cyan},
      {'name': 'Stitching', 'icon': Icons.precision_manufacturing_outlined, 'color': Colors.amber},
      {'name': 'Stitched', 'icon': Icons.checkroom_outlined, 'color': Colors.brown},
      {'name': 'Packing', 'icon': Icons.inventory_2_outlined, 'color': Colors.purple},
      {'name': 'Packed', 'icon': Icons.all_inbox_rounded, 'color': Colors.deepPurple},
      {'name': 'Shipping', 'icon': Icons.local_shipping_outlined, 'color': Colors.teal},
      {'name': 'Delivered', 'icon': Icons.task_alt_rounded, 'color': Colors.green},
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