import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/order_model.dart';
import '../../data/services/api_service.dart';
import 'sales_manager_controller.dart';

class DeliverablesController extends GetxController {
  final deliverables = <OrderModel>[].obs;
  final isLoading = true.obs;
  final selectedDate = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    fetchDeliverables();
  }

  Future<void> fetchDeliverables() async {
    try {
      isLoading.value = true;
      final res = await ApiService.get('/orders');
      if (res['success'] == true) {
        final raw = res['data'] ?? res['orders'] ?? [];
        if (raw is List) {
          final list = List<Map<String, dynamic>>.from(raw);
          final orders = list.map((e) => OrderModel.fromJson(e)).toList();
          deliverables.assignAll(orders);
        }
      }
    } catch (e) {
      debugPrint("Fetch Deliverables Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  SalesManagerController? get smController {
    if (Get.isRegistered<SalesManagerController>()) {
      return Get.find<SalesManagerController>();
    }
    return null;
  }

  void selectDate(DateTime date) => selectedDate.value = date;

  List<OrderModel> get ordersForSelectedDate {
    final sel = selectedDate.value;
    return deliverables.where((o) =>
      o.deliveryDate.year == sel.year &&
      o.deliveryDate.month == sel.month &&
      o.deliveryDate.day == sel.day
    ).toList();
  }

  List<OrderModel> get notStitchedOrders {
    const preStitch = [
      'approved',
      'fab purchased',
      'fab ready',
      'cutting',
      'cutting done',
      'printing',
      'printed',
      'pending',
    ];
    return deliverables.where((o) => preStitch.contains(o.status.toLowerCase().trim())).toList();
  }

  int get totalNotStitchedUnits {
    return notStitchedOrders.fold<int>(0, (sum, o) => sum + (int.tryParse(o.quantity.toString()) ?? 0));
  }

  List<OrderModel> get readyForDispatchOrders {
    const readyStages = [
      'stitching',
      'stitched',
      'packing',
      'packed',
      'out src',
      'shipping',
      'shipped',
    ];
    return deliverables.where((o) => readyStages.contains(o.status.toLowerCase().trim())).toList();
  }

  int get totalReadyUnits {
    return readyForDispatchOrders.fold<int>(0, (sum, o) => sum + (int.tryParse(o.quantity.toString()) ?? 0));
  }

  List<OrderModel> get atRiskOrders {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return deliverables.where((o) {
      final s = o.status.toLowerCase().trim();
      if (s == 'delivered' || s == 'completed' || s == 'rejected') return false;
      final deadline = DateTime(o.deliveryDate.year, o.deliveryDate.month, o.deliveryDate.day);
      final daysLeft = deadline.difference(today).inDays;
      return daysLeft <= 3;
    }).toList();
  }

  List<Map<String, dynamic>> get stageUnitBreakdown {
    final Map<String, int> counts = {};
    for (var o in deliverables) {
      final s = o.status.trim().toLowerCase();
      final qty = int.tryParse(o.quantity.toString()) ?? 0;
      counts[s] = (counts[s] ?? 0) + qty;
    }
    return [
      {'name': 'Approved', 'count': counts['approved'] ?? 0, 'color': Colors.blue},
      {'name': 'Fab Purchased', 'count': counts['fab purchased'] ?? 0, 'color': Colors.pink},
      {'name': 'Fab Ready', 'count': counts['fab ready'] ?? 0, 'color': Colors.lightGreen},
      {'name': 'Cutting', 'count': counts['cutting'] ?? 0, 'color': Colors.orange},
      {'name': 'Cutting Done', 'count': counts['cutting done'] ?? 0, 'color': Colors.deepOrange},
      {'name': 'Printing', 'count': counts['printing'] ?? 0, 'color': Colors.indigo},
      {'name': 'Printed', 'count': counts['printed'] ?? 0, 'color': Colors.cyan},
      {'name': 'Stitching', 'count': counts['stitching'] ?? 0, 'color': Colors.amber},
      {'name': 'Stitched', 'count': counts['stitched'] ?? 0, 'color': Colors.brown},
      {'name': 'Packing', 'count': counts['packing'] ?? 0, 'color': Colors.purple},
      {'name': 'Packed', 'count': counts['packed'] ?? 0, 'color': Colors.deepPurple},
      {'name': 'Out SRC', 'count': counts['out src'] ?? 0, 'color': Colors.indigoAccent},
    ];
  }
}