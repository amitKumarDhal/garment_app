import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InventoryController extends GetxController {
  static InventoryController get instance => Get.find();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- UI Observables ---
  var isLoading = true.obs;
  var searchQuery = ''.obs;
  var currentView = 'Stock'.obs;
  var currentUserRole = 'Admin'.obs;

  // --- Data Observables ---
  var inventoryLogs = <Map<String, dynamic>>[].obs;
  var aggregatedStock = <Map<String, dynamic>>[].obs;

  StreamSubscription? _logsSub;

  final List<String> fabricTypes = ['PC Matty', 'Dotknit', 'Spun Matty', 'Nokia', 'Collar', 'Cuff', 'Others'];
  final List<String> colors = ['Navy Blue', 'Red', 'Black', 'White', 'Royal Blue', 'Grey', 'Light grey', 'Maroon', 'Yellow', 'Green', 'Sky Blue', 'Neon Green', 'Others'];

  @override
  void onInit() {
    super.onInit();
    _fetchUserRole();
    _bindInventoryLogs();
  }

  @override
  void onClose() {
    _logsSub?.cancel();
    super.onClose();
  }

  double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val.replaceAll(RegExp(r'[^0-9.\-]'), '')) ?? 0.0;
    return 0.0;
  }

  void setView(String view) {
    currentView.value = view;
  }

  void updateSearch(String query) {
    searchQuery.value = query.toLowerCase();
  }

  Future<void> _fetchUserRole() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        // ✅ OPTIMIZED: Use serverAndCache to save reads on role fetching
        final doc = await _db.collection('users').doc(user.uid).get(const GetOptions(source: Source.serverAndCache));
        if (doc.exists) {
          currentUserRole.value = doc.data()?['Role'] ?? doc.data()?['role'] ?? 'Worker';
        }
      } catch (e) {
        debugPrint("Role Fetch Error: $e");
      }
    }
  }

  // --- FIRESTORE STREAM ---
  void _bindInventoryLogs() {
    isLoading.value = true;

    // ✅ OPTIMIZED: Added .limit(200)
    // Streaming the entire collection is what causes the "Resource Exhausted" error.
    // Capping this ensures your daily quota lasts 10x longer.
    _logsSub = _db.collection('inventory_logs')
        .orderBy('timestamp', descending: true)
        .limit(200)
        .snapshots()
        .listen((snapshot) {

      List<Map<String, dynamic>> safeLogs = [];
      for (var doc in snapshot.docs) {
        try {
          safeLogs.add({...doc.data(), 'id': doc.id});
        } catch (e) {
          debugPrint("Skipped corrupt log doc: ${doc.id}");
        }
      }

      inventoryLogs.value = safeLogs;
      _calculateAggregatedStock();
      isLoading.value = false;

    }, onError: (e) {
      debugPrint("Inventory Stream Error: $e");
      isLoading.value = false;
    });
  }

  Future<void> fetchInventoryData({bool showSpinner = true}) async {
    if (showSpinner) isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 600));
    _calculateAggregatedStock();
    if (showSpinner) isLoading.value = false;
  }

  void _calculateAggregatedStock() {
    Map<String, Map<String, dynamic>> stockMap = {};

    for (var log in inventoryLogs) {
      String type = (log['fabricType'] ?? log['fabricName'] ?? log['name'] ?? 'Unknown').toString().trim();
      String color = (log['color'] ?? log['colour'] ?? 'Unknown').toString().trim();
      String action = (log['action'] ?? log['type'] ?? 'IN').toString().toUpperCase().trim();
      double qty = _parseDouble(log['quantity'] ?? log['qty'] ?? log['amount']);
      String unit = (log['unit'] ?? log['unitType'] ?? 'KG').toString().toUpperCase().trim();

      String lookupKey = "${type.toLowerCase()}_${color.toLowerCase()}";

      if (!stockMap.containsKey(lookupKey)) {
        stockMap[lookupKey] = {
          'fabricType': type,
          'color': color,
          'lookupKey': lookupKey,
          'unit': unit,
          'quantity': 0.0,
          'lastUpdated': log['timestamp'],
        };
      }

      if (action == 'IN') {
        stockMap[lookupKey]!['quantity'] += qty;
      } else if (action == 'OUT') {
        stockMap[lookupKey]!['quantity'] -= qty;
      }
    }

    var stockList = stockMap.values.toList();
    stockList.sort((a, b) => (a['fabricType'] as String).compareTo(b['fabricType'] as String));
    aggregatedStock.value = stockList;
  }

  Future<void> addTransaction({
    required String type,
    required String color,
    required String action,
    required double quantity,
  }) async {
    try {
      final user = _auth.currentUser;
      String adminName = user?.displayName ?? 'Admin';

      if (user != null) {
        final doc = await _db.collection('users').doc(user.uid).get(const GetOptions(source: Source.serverAndCache));
        if (doc.exists) {
          adminName = doc.data()?['FullName'] ?? doc.data()?['name'] ?? adminName;
        }
      }

      String unit = (type.toLowerCase().contains('collar') || type.toLowerCase().contains('cuff')) ? 'PCS' : 'KG';

      if (action == 'OUT') {
        String lookupKey = "${type.toLowerCase()}_${color.toLowerCase()}";
        double currentStock = 0.0;

        try {
          var item = aggregatedStock.firstWhere((element) => element['lookupKey'] == lookupKey);
          currentStock = _parseDouble(item['quantity']);
        } catch (e) {
          currentStock = 0.0;
        }

        if (currentStock < quantity) {
          Get.snackbar(
            "Insufficient Stock",
            "Only $currentStock $unit available.",
            backgroundColor: Colors.red.withOpacity(0.1),
            colorText: Colors.red,
          );
          return;
        }
      }

      await _db.collection('inventory_logs').add({
        'fabricType': type,
        'color': color,
        'action': action,
        'quantity': quantity,
        'unit': unit,
        'timestamp': FieldValue.serverTimestamp(),
        'addedBy': adminName,
      });

      Get.back();
      Get.snackbar(
        "Transaction Saved",
        "Recorded $action for $quantity $unit",
        backgroundColor: action == 'IN' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        colorText: action == 'IN' ? Colors.green : Colors.orange,
      );

    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  List<Map<String, dynamic>> get filteredStock {
    if (searchQuery.value.isEmpty) return aggregatedStock;
    return aggregatedStock.where((item) {
      String t = (item['fabricType'] ?? '').toString().toLowerCase();
      String c = (item['color'] ?? '').toString().toLowerCase();
      return t.contains(searchQuery.value) || c.contains(searchQuery.value);
    }).toList();
  }

  List<Map<String, dynamic>> get filteredLogs {
    if (searchQuery.value.isEmpty) return inventoryLogs;
    return inventoryLogs.where((log) {
      String t = (log['fabricType'] ?? '').toString().toLowerCase();
      String c = (log['color'] ?? '').toString().toLowerCase();
      return t.contains(searchQuery.value) || c.contains(searchQuery.value);
    }).toList();
  }
}