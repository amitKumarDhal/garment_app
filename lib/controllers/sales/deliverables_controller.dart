import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Needed for updating DB
import '../../data/models/order_model.dart';
import 'sales_manager_controller.dart';

class DeliverablesController extends GetxController {
  final SalesManagerController smController = Get.find<SalesManagerController>();
  final FirebaseFirestore _db = FirebaseFirestore.instance; // ✅ Database reference

  // Currently selected date on the timeline
  var selectedDate = DateTime.now().obs;

  // Change the selected date
  void selectDate(DateTime date) {
    selectedDate.value = date;
  }

  // 1. GET ORDERS EXACTLY FOR SELECTED DATE
  List<OrderModel> get ordersForSelectedDate {
    return smController.activeOrders.where((order) {
      return order.deliveryDate.year == selectedDate.value.year &&
          order.deliveryDate.month == selectedDate.value.month &&
          order.deliveryDate.day == selectedDate.value.day;
    }).toList();
  }

  // 2. GET "AT RISK" ORDERS
  List<OrderModel> get atRiskOrders {
    List<String> safeStatuses = ['shipping', 'shipped', 'delivered', 'completed', 'rejected'];
    DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    var filtered = smController.activeOrders.where((order) {
      String status = (order.status).toLowerCase();
      if (safeStatuses.contains(status)) return false;

      DateTime cleanDeadline = DateTime(order.deliveryDate.year, order.deliveryDate.month, order.deliveryDate.day);
      int daysLeft = cleanDeadline.difference(today).inDays;

      return daysLeft <= 3;
    }).toList();

    filtered.sort((a, b) {
      DateTime aDeadline = DateTime(a.deliveryDate.year, a.deliveryDate.month, a.deliveryDate.day);
      DateTime bDeadline = DateTime(b.deliveryDate.year, b.deliveryDate.month, b.deliveryDate.day);

      int aDaysLeft = aDeadline.difference(today).inDays;
      int bDaysLeft = bDeadline.difference(today).inDays;

      return aDaysLeft.compareTo(bDaysLeft);
    });

    return filtered;
  }

  // 3. GET PRE-STITCHING QUEUE
  List<OrderModel> get notStitchedOrders {
    // ✅ UPDATED: Included the new pre-stitching stages
    final preStitchingStatuses = [
      'approved', 'fab purchased', 'fab ready',
      'cutting', 'cutting done',
      'printing', 'printed'
    ];
    return smController.activeOrders.where((order) {
      return preStitchingStatuses.contains(order.status.toLowerCase());
    }).toList();
  }

  // 4. GET TOTAL UNITS IN PRE-STITCHING QUEUE
  int get totalNotStitchedUnits {
    return notStitchedOrders.fold(0, (sum, order) => sum + order.quantity);
  }

  // ✅ 5. GET ORDERS READY FOR DISPATCH (Status: Packed)
  List<OrderModel> get readyForDispatchOrders {
    return smController.activeOrders.where((order) {
      return order.status.toLowerCase() == 'packed';
    }).toList();
  }

  // ✅ 6. GET TOTAL UNITS READY FOR DISPATCH
  int get totalReadyUnits {
    return readyForDispatchOrders.fold(0, (sum, order) => sum + order.quantity);
  }

  // ✅ 7. DISPATCH ORDER LOGIC (UPDATED WITH HISTORY LOGGING)
  Future<void> dispatchOrder(String orderId, String courier, String trackingNo) async {
    try {
      // 1. Create the History Event
      final historyEvent = {
        'stage': 'Shipped',
        'updatedBy': smController.managerName.value,
        'timestamp': Timestamp.now(),
      };

      // 2. Update DB with status, tracking, and history
      await _db.collection('orders').doc(orderId).update({
        'status': 'Shipped',
        'courierPartner': courier,
        'trackingNumber': trackingNo,
        'dispatchedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastUpdatedBy': smController.managerName.value,
        'stageHistory': FieldValue.arrayUnion([historyEvent]), // <-- Push to timeline
      });

      Get.back(); // Close dialog
      Get.snackbar("Success", "Order marked as Shipped!", backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Dispatch failed: $e", backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  // GET PIPELINE STAGE BREAKDOWN (UPDATED TO 14 STAGES)
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
      {'name': 'Shipped', 'icon': Icons.local_shipping_outlined, 'color': Colors.teal},
      {'name': 'Delivered', 'icon': Icons.task_alt_rounded, 'color': Colors.green},
    ];

    List<Map<String, dynamic>> breakdown = [];

    for (var stage in stages) {
      String stageName = stage['name'] as String;

      // ✅ SMART CHECK: 'Shipped' and 'Delivered' orders live in completedOrders!
      bool isCompletedStage = ['shipped', 'delivered'].contains(stageName.toLowerCase());
      var targetList = isCompletedStage ? smController.completedOrders : smController.activeOrders;

      var filteredOrders = targetList.where((o) => o.status.toLowerCase() == stageName.toLowerCase());

      int count = filteredOrders.fold(0, (sum, o) => sum + o.quantity);
      int orderCount = filteredOrders.length;

      breakdown.add({
        'name': stageName,
        'count': count,
        'orderCount': orderCount, // Added this so UI can show the badge if needed
        'icon': stage['icon'],
        'color': stage['color'],
      });
    }
    return breakdown;
  }
}