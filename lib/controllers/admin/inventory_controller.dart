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
  var currentView = 'Stock'.obs; // 'Stock' or 'Ledger'
  var currentUserRole = 'Admin'.obs;

  // --- Data Observables ---
  var inventoryLogs = <Map<String, dynamic>>[].obs;
  var aggregatedStock = <Map<String, dynamic>>[].obs;

  // 🛡️ Stream Subscription for Memory Leak Protection
  StreamSubscription? _logsSub;

  // --- Dropdown Options ---
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
    // 🛡️ CRITICAL: Kills the real-time stream when the controller is destroyed
    _logsSub?.cancel();
    super.onClose();
  }

  // 🛡️ Bulletproof Number Parser
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
        final doc = await _db.collection('users').doc(user.uid).get();
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
    _logsSub = _db.collection('inventory_logs')
        .orderBy('timestamp', descending: true)
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

  // ✅ Compatibility Method: Connects to UI Pull-to-Refresh without crashing
  Future<void> fetchInventoryData({bool showSpinner = true}) async {
    if (showSpinner) isLoading.value = true;
    // The stream is already listening, so we just add a tiny delay to satisfy the refresh indicator UX
    await Future.delayed(const Duration(milliseconds: 600));
    _calculateAggregatedStock();
    if (showSpinner) isLoading.value = false;
  }

  // --- THE LEDGER MATH (WITH DATA NORMALIZATION) ---
  void _calculateAggregatedStock() {
    Map<String, Map<String, dynamic>> stockMap = {};

    for (var log in inventoryLogs) {
      // 🛡️ Data Normalization: Checks multiple keys just in case
      String type = (log['fabricType'] ?? log['fabricName'] ?? log['name'] ?? 'Unknown').toString().trim();
      String color = (log['color'] ?? log['colour'] ?? 'Unknown').toString().trim();
      String action = (log['action'] ?? log['type'] ?? 'IN').toString().toUpperCase().trim();
      double qty = _parseDouble(log['quantity'] ?? log['qty'] ?? log['amount']);
      String unit = (log['unit'] ?? log['unitType'] ?? 'KG').toString().toUpperCase().trim();

      // Generate the exact lookup key the Unit Supervisor uses
      String lookupKey = "${type.toLowerCase()}_${color.toLowerCase()}";

      if (!stockMap.containsKey(lookupKey)) {
        stockMap[lookupKey] = {
          'fabricType': type,
          'color': color,
          'lookupKey': lookupKey,
          'unit': unit,
          'quantity': 0.0, // Start at zero
          'lastUpdated': log['timestamp'],
        };
      }

      // Add if IN, Subtract if OUT
      if (action == 'IN') {
        stockMap[lookupKey]!['quantity'] += qty;
      } else if (action == 'OUT') {
        stockMap[lookupKey]!['quantity'] -= qty;
      }
    }

    // Convert map to list and sort alphabetically
    var stockList = stockMap.values.toList();
    stockList.sort((a, b) => (a['fabricType'] as String).compareTo(b['fabricType'] as String));
    aggregatedStock.value = stockList;
  }

  // --- ADD TRANSACTION ---
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
        final doc = await _db.collection('users').doc(user.uid).get();
        if (doc.exists) {
          adminName = doc.data()?['FullName'] ?? doc.data()?['name'] ?? adminName;
        }
      }

      // Auto-assign unit based on fabric type
      String unit = (type.toLowerCase().contains('collar') || type.toLowerCase().contains('cuff')) ? 'PCS' : 'KG';

      // 🛡️ Negative Stock Check
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
              "You only have $currentStock $unit available. Cannot consume $quantity.",
              backgroundColor: Colors.red.withValues(alpha: 0.1),
              colorText: Colors.red,
              duration: const Duration(seconds: 4)
          );
          return; // Stop the transaction
        }
      }

      await _db.collection('inventory_logs').add({
        'fabricType': type,
        'color': color,
        'action': action, // 'IN' or 'OUT'
        'quantity': quantity,
        'unit': unit,
        'timestamp': FieldValue.serverTimestamp(),
        'addedBy': adminName,
      });

      Get.back(); // Close Bottom Sheet/Dialog
      Get.snackbar(
        "Transaction Saved",
        "Successfully recorded $action for $quantity $unit of $type ($color)",
        backgroundColor: action == 'IN' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
        colorText: action == 'IN' ? Colors.green : Colors.orange,
      );

    } catch (e) {
      Get.snackbar("Error", "Failed to save transaction: $e", backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red);
    }
  }

  // --- FILTERS ---

  // 🛡️ Safe List Access for the UI
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