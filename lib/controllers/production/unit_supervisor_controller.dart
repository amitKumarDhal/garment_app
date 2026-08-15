import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/order_model.dart';
import '../../data/services/api_service.dart';
import '../../utils/constants/colors.dart';

class UnitSupervisorController extends GetxController {
  static UnitSupervisorController get instance => Get.find();

  var activeOrders = <OrderModel>[].obs;
  var supervisorName = 'Supervisor'.obs;
  var isLoading = true.obs;

  var visibleOrdersCount = 10.obs;
  final RxInt visibleMockupDoneCount = 10.obs;

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
    fetchInventoryLogs();
  }

  void loadMoreMockupDone() {
    HapticFeedback.lightImpact();
    visibleMockupDoneCount.value += 10;
  }

  void loadMoreOrders() {
    HapticFeedback.lightImpact();
    visibleOrdersCount.value += 10;
  }

  Future<void> fetchSupervisorProfile() async {
    try {
      final user = ApiService.currentUser;
      if (user != null) {
        String fullName = user['name'] ?? user['FullName'] ?? 'Supervisor';
        supervisorName.value = fullName.trim().split(' ').first;
      }
    } catch (e) {
      debugPrint("Error fetching supervisor profile: $e");
    }
  }

  Future<void> fetchActiveOrders() async {
    try {
      isLoading.value = true;
      final res = await ApiService.get('/orders');
      if (res['success'] == true && res['orders'] != null) {
        final list = List<Map<String, dynamic>>.from(res['orders']);
        List<OrderModel> ordersList = list.map((doc) => OrderModel.fromJson(doc)).toList();
        ordersList.sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));
        activeOrders.value = ordersList;

        pendingMockupOrders.value = ordersList.where((o) => o.mockupUrl == null || o.mockupUrl!.isEmpty).toList();
        doneMockupOrders.value = ordersList.where((o) => o.mockupUrl != null && o.mockupUrl!.isNotEmpty).toList();
      }
    } catch (e) {
      debugPrint("Fetch Orders Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchInventoryLogs() async {
    try {
      final res = await ApiService.get('/inventory');
      if (res['success'] == true && res['inventory'] != null) {
        final items = List<Map<String, dynamic>>.from(res['inventory']);
        Map<String, double> stock = {};
        for (var item in items) {
          String key = "${item['fabric_type']}_${item['color']}".toLowerCase();
          stock[key] = double.tryParse(item['quantity']?.toString() ?? '0') ?? 0.0;
        }
        inventoryStock.value = stock;
      }
    } catch (e) {
      debugPrint("Fetch inventory error: $e");
    }
  }

  Future<void> updateProductionStage(String orderId, String currentStatus, String newStatus, {String remark = ""}) async {
    try {
      final res = await ApiService.put('/orders/$orderId', {
        'status': newStatus,
        'last_updated_by': supervisorName.value,
      });

      if (res['success'] == true) {
        fetchActiveOrders();
      }
    } catch (e) {
      Get.snackbar("Error", "Failed: $e", backgroundColor: TColors.error.withValues(alpha:0.1), colorText: TColors.error);
    }
  }

  Future<void> markMockupDone(OrderModel order) async {
    if (order.id != null) {
      await updateProductionStage(order.id!, order.status, 'Fab Purchased');
    }
  }

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
    return "${(kgRequired * 1.02).toStringAsFixed(1)} KG";
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

  List<Map<String, dynamic>> get stageUnitBreakdown {
    final Map<String, int> counts = {};
    final Map<String, int> orderCounts = {};
    for (var o in activeOrders) {
      final s = o.status.trim().toLowerCase();
      final qty = int.tryParse(o.quantity.toString()) ?? 0;
      counts[s] = (counts[s] ?? 0) + qty;
      orderCounts[s] = (orderCounts[s] ?? 0) + 1;
    }
    return [
      {
        'name': 'Cutting',
        'count': (counts['cutting'] ?? 0) + (counts['cutting done'] ?? 0),
        'orderCount': (orderCounts['cutting'] ?? 0) + (orderCounts['cutting done'] ?? 0),
        'color': Colors.orange,
        'icon': Icons.content_cut_rounded,
      },
      {
        'name': 'Printing',
        'count': (counts['printing'] ?? 0) + (counts['printed'] ?? 0),
        'orderCount': (orderCounts['printing'] ?? 0) + (orderCounts['printed'] ?? 0),
        'color': Colors.indigo,
        'icon': Icons.print_rounded,
      },
      {
        'name': 'Stitching',
        'count': (counts['stitching'] ?? 0) + (counts['stitched'] ?? 0),
        'orderCount': (orderCounts['stitching'] ?? 0) + (orderCounts['stitched'] ?? 0),
        'color': Colors.amber,
        'icon': Icons.precision_manufacturing_rounded,
      },
      {
        'name': 'Packing',
        'count': (counts['packing'] ?? 0) + (counts['packed'] ?? 0),
        'orderCount': (orderCounts['packing'] ?? 0) + (orderCounts['packed'] ?? 0),
        'color': Colors.purple,
        'icon': Icons.inventory_2_rounded,
      },
    ];
  }

  void setFilterStage(String stage) {
    selectedFilterStage.value = stage;
    visibleOrdersCount.value = 10;
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
    visibleOrdersCount.value = 10;
  }
}