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
    final preStitchingStatuses = ['approved', 'cutting', 'printing', 'printed'];
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

  // ✅ 7. DISPATCH ORDER LOGIC
  Future<void> dispatchOrder(String orderId, String courier, String trackingNo) async {
    try {
      await _db.collection('orders').doc(orderId).update({
        'status': 'Shipped',
        'courierPartner': courier,
        'trackingNumber': trackingNo,
        'dispatchedAt': FieldValue.serverTimestamp(),
      });
      Get.back(); // Close dialog
      Get.snackbar("Success", "Order marked as Shipped!", backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Dispatch failed: $e", backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  // GET PIPELINE STAGE BREAKDOWN
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
      {'name': 'Shipped', 'icon': Icons.local_shipping_outlined, 'color': Colors.teal},
      // ✅ ADDED DELIVERED STAGE
      {'name': 'Delivered', 'icon': Icons.task_alt_rounded, 'color': Colors.green},
    ];

    List<Map<String, dynamic>> breakdown = [];

    for (var stage in stages) {
      String stageName = stage['name'] as String;
      int count = 0;

      // ✅ SMART CHECK: 'Delivered' orders live in completedOrders, not activeOrders!
      if (stageName.toLowerCase() == 'delivered') {
        count = smController.completedOrders
            .where((o) => o.status.toLowerCase() == 'delivered')
            .fold(0, (sum, o) => sum + o.quantity);
      } else {
        count = smController.activeOrders
            .where((o) => o.status.toLowerCase() == stageName.toLowerCase())
            .fold(0, (sum, o) => sum + o.quantity);
      }

      breakdown.add({
        'name': stageName,
        'count': count,
        'icon': stage['icon'],
        'color': stage['color'],
      });
    }
    return breakdown;
  }
}