import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class StockSummaryController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  var isLoading = true.obs;
  var searchQuery = ''.obs;
  var selectedCategory = 'All'.obs;

  final List<String> categories = ['All', 'Cotton fab', 'Polyester fab', 'Collars'];
  var groupedStock = <Map<String, dynamic>>[].obs;
  List<Map<String, dynamic>> rawLogs = [];

  StreamSubscription? _inventorySubscription;

  @override
  void onInit() {
    super.onInit();
    fetchInventory();
  }

  @override
  void onClose() {
    _inventorySubscription?.cancel();
    super.onClose();
  }

  void fetchInventory() {
    isLoading.value = true;

    _inventorySubscription = _db
        .collection('inventory_logs')
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) {

      rawLogs = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'type': data['type'] ?? 'IN',
          'product': data['product'] ?? 'Unknown',
          'color': data['color'] ?? 'Unknown',
          'qty': (data['qty'] ?? 0).toDouble(),
          'unit': data['unit'] ?? 'kg',
          'style': data['style'] ?? 'N/A', // Fetches style if available
          'date': (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'supervisorName': data['supervisorName'] ?? 'Unknown',
        };
      }).toList();

      _processAndFilterData();
      isLoading.value = false;

    }, onError: (e) {
      if (_auth.currentUser == null) return;

      Get.snackbar("Error", "Could not load live inventory: $e",
          backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red);
      isLoading.value = false;
    });
  }

  void updateSearch(String query) {
    searchQuery.value = query;
    _processAndFilterData();
  }

  void updateCategory(String category) {
    selectedCategory.value = category;
    _processAndFilterData();
  }

  void _processAndFilterData() {
    // 1. First, apply Search and Category filters
    List<Map<String, dynamic>> filteredLogs = rawLogs.where((log) {
      String prod = log['product'].toString().toLowerCase();

      bool matchesCategory = true;
      if (selectedCategory.value == 'Cotton fab') {
        matchesCategory = prod.contains('spun matty') || prod.contains('pc matty');
      } else if (selectedCategory.value == 'Polyester fab') {
        matchesCategory = prod.contains('dotknit') || prod.contains('nokia');
      } else if (selectedCategory.value == 'Collars') {
        matchesCategory = prod.contains('collar') || prod.contains('rib');
      }

      bool matchesSearch = true;
      if (searchQuery.value.isNotEmpty) {
        matchesSearch = prod.contains(searchQuery.value.toLowerCase()) ||
            log['color'].toString().toLowerCase().contains(searchQuery.value.toLowerCase());
      }

      return matchesCategory && matchesSearch;
    }).toList();

    Map<String, Map<String, dynamic>> aggregated = {};

    // 2. Group the filtered data
    for (var log in filteredLogs) {
      String product = log['product'];
      String colorName = log['color'];
      String type = log['type'];
      double qty = log['qty'];

      // If product is "Others", group them into one card
      bool isOtherProduct = product == 'Others';
      String groupKey = isOtherProduct ? "Other Products" : product;

      if (!aggregated.containsKey(groupKey)) {
        aggregated[groupKey] = {
          'title': groupKey,
          'product': product,
          'totalGroupQty': 0.0,
          'colors': <String, Map<String, dynamic>>{}
        };
      }

      var colorMap = aggregated[groupKey]!['colors'] as Map<String, Map<String, dynamic>>;

      // Unique key for the color (Keeps 'Others' separated by their real color name)
      String colorKey = isOtherProduct ? "$colorName ($product)" : colorName;

      if (!colorMap.containsKey(colorKey)) {
        colorMap[colorKey] = {
          'color': colorName,
          'balance': 0.0,
          'history': <Map<String, dynamic>>[]
        };
      }

      if (type == 'IN') {
        colorMap[colorKey]!['balance'] += qty;
        aggregated[groupKey]!['totalGroupQty'] += qty;
      } else {
        colorMap[colorKey]!['balance'] -= qty;
        aggregated[groupKey]!['totalGroupQty'] -= qty;
      }

      (colorMap[colorKey]!['history'] as List).add(log);
    }

    // 3. ✅ THE FIX: Convert the 'colors' map into the 'colorsList' array the UI expects
    List<Map<String, dynamic>> finalData = [];

    aggregated.forEach((key, groupData) {
      var colorList = (groupData['colors'] as Map).values.toList();

      // Remove zero-balance items ONLY from the "Other Products" card to keep it clean
      if (key == "Other Products") {
        colorList.removeWhere((c) => c['balance'] <= 0);
        if (colorList.isEmpty) return; // Don't add the card if it's empty
      }

      // Sort history newest-first so the UI knows the exact last action
      for (var c in colorList) {
        (c['history'] as List).sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
      }

      groupData['colorsList'] = colorList;
      finalData.add(groupData);
    });

    // 4. Sort: Regular products alphabetically, "Other Products" card forced to the bottom
    finalData.sort((a, b) {
      if (a['title'] == "Other Products") return 1;
      if (b['title'] == "Other Products") return -1;
      return a['title'].compareTo(b['title']);
    });

    groupedStock.assignAll(finalData);
  }
}