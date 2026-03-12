import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../data/models/order_model.dart';

class UnitSupervisorController extends GetxController {
  static UnitSupervisorController get instance => Get.find();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  var activeOrders = <OrderModel>[].obs;
  var supervisorName = 'Supervisor'.obs;
  var isLoading = true.obs;

  // ✅ FULL PIPELINE STAGES (Excluding Pending/Placed)
  final List<String> factoryStages = [
    'Approved', 'Cutting', 'Printing', 'Printed',
    'Stitching', 'Stitched', 'Packing', 'Packed',
    'Shipping', 'Shipped', 'Delivered'
  ];

  // Logic for filtering
  var selectedFilterStage = 'All'.obs; // Default to All

  // ✅ NEW: Logic for Search
  var searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSupervisorProfile();
    fetchActiveFactoryOrders();
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

    // Listen to orders that are currently in the active pipeline
    _db.collection('orders')
        .where('status', whereIn: factoryStages)
        .orderBy('deliveryDate', descending: false)
        .snapshots()
        .listen((snapshot) {
      final validDocs = snapshot.docs.where((doc) => doc.data()['isDeleted'] != true);
      activeOrders.value = validDocs.map((doc) => OrderModel.fromSnapshot(doc)).toList();
      isLoading.value = false;
    }, onError: (e) {
      debugPrint("Error fetching factory orders: $e");
      isLoading.value = false;
    });
  }

  // --- QUICK UPDATE STATUS ---
  Future<void> updateProductionStage(String orderId, String currentStatus, String newStatus) async {
    try {
      await _db.collection('orders').doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Notify the Sales Associate
      final doc = await _db.collection('orders').doc(orderId).get();
      final associateId = doc.data()?['marketingPersonId'] ?? '';
      final manualOrderNo = doc.data()?['manualOrderNo'] ?? orderId;

      if (associateId.isNotEmpty) {
        String emoji = newStatus == 'Packed' ? "📦" : "🏭";
        await _db.collection('notifications').add({
          'targetUserId': associateId,
          'title': 'Production Update $emoji',
          'message': 'Order $manualOrderNo moved to $newStatus.',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
      Get.snackbar("Success", "Moved to $newStatus", backgroundColor: Colors.green.withValues(alpha: 0.1), colorText: Colors.green);
    } catch (e) {
      Get.snackbar("Error", "Failed: $e", backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red);
    }
  }

  // =========================================================================
  // ✅ UPDATED: Filtered List Logic (Handles both Stage Tabs AND Search)
  // =========================================================================
  List<OrderModel> get filteredOrders {
    List<OrderModel> result = activeOrders;

    // 1. Filter by Stage first
    if (selectedFilterStage.value != 'All') {
      result = result.where((o) => o.status.toLowerCase() == selectedFilterStage.value.toLowerCase()).toList();
    }

    // 2. Then filter by Search Query (if user typed something)
    if (searchQuery.value.isNotEmpty) {
      String query = searchQuery.value.toLowerCase();
      result = result.where((o) {
        String orderNo = (o.manualOrderNo ?? o.id ?? "").toLowerCase();
        String client = o.clientName.toLowerCase();
        String product = o.productName.toLowerCase();

        // Checks if the typed text matches ID, Client, OR Product
        return orderNo.contains(query) || client.contains(query) || product.contains(query);
      }).toList();
    }

    return result;
  }

  void setFilterStage(String stage) => selectedFilterStage.value = stage;

  // ✅ NEW: Updates the search text from the UI
  void updateSearchQuery(String query) => searchQuery.value = query;

  List<Map<String, dynamic>> get stageUnitBreakdown {
    final stages = [
      {'name': 'Approved', 'icon': Icons.thumb_up_alt_outlined, 'color': Colors.blue},
      {'name': 'Cutting', 'icon': Icons.content_cut_rounded, 'color': Colors.orange},
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
      int count = activeOrders.where((o) => o.status.toLowerCase() == name.toLowerCase()).fold(0, (sum, o) => sum + o.quantity);
      return {...stage, 'count': count};
    }).toList();
  }
}