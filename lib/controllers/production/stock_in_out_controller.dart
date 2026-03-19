import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/constants/inventory_constants.dart'; // ✅ Import your new constants file

class StockInOutController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Configuration ---
  final List<String> transactionTypes = ['Stock In', 'Stock Out'];
  var selectedTransactionType = 'Stock In'.obs;

  // ✅ Use Master Lists from Constants File
  final List<String> products = InventoryConstants.products;
  final List<Map<String, dynamic>> allColors = InventoryConstants.allColors;
  final List<String> collarStyles = InventoryConstants.collarStyles;

  // --- Observables ---
  var selectedProduct = ''.obs;
  var selectedColor = ''.obs;
  var selectedCollarStyle = 'Solid color'.obs;

  var recentHistory = <Map<String, dynamic>>[].obs;
  var currentBalance = 0.0.obs;
  var isFetchingBalance = false.obs;
  var isLoading = false.obs;
  var selectedDate = DateTime.now().obs;

  // --- Rib Logic States ---
  var hasRib = false.obs;
  var selectedRibColor = ''.obs;
  var selectedRibStyle = 'Solid color'.obs;

  // --- Text Controllers ---
  final qtyController = TextEditingController();
  final vendorController = TextEditingController();
  final ribQtyController = TextEditingController();

  StreamSubscription? _historySubscription;

  @override
  void onInit() {
    super.onInit();
    ever(selectedProduct, (_) => fetchBalance());
    ever(selectedColor, (_) => fetchBalance());
    fetchRecentHistory();
  }

  @override
  void onClose() {
    _historySubscription?.cancel();
    qtyController.dispose();
    vendorController.dispose();
    ribQtyController.dispose();
    super.onClose();
  }

  void fetchRecentHistory() {
    _historySubscription = _db
        .collection('inventory_logs')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      recentHistory.value = snapshot.docs.map((doc) => doc.data()).toList();
    }, onError: (e) {
      if (_auth.currentUser == null) return;
      debugPrint("Error fetching recent history: $e");
    });
  }

  Future<void> fetchBalance() async {
    String prod = selectedProduct.value;
    String color = selectedColor.value;

    if (prod.isEmpty || color.isEmpty) {
      currentBalance.value = 0.0;
      return;
    }

    isFetchingBalance.value = true;
    try {
      final snapshot = await _db
          .collection('inventory_logs')
          .where('product', isEqualTo: prod)
          .where('color', isEqualTo: color)
          .get();

      double balance = 0.0;
      for (var doc in snapshot.docs) {
        double qty = (doc.data()['qty'] as num).toDouble();
        String type = doc.data()['type'] ?? 'IN';
        if (type == 'IN') balance += qty;
        else balance -= qty;
      }
      currentBalance.value = balance;
    } catch (e) {
      debugPrint("Error fetching balance: $e");
      currentBalance.value = 0.0;
    } finally {
      isFetchingBalance.value = false;
    }
  }

  Future<void> submitStock() async {
    if (!_validateForm()) return;

    try {
      isLoading.value = true;

      // ✅ 1. BULLETPROOF NAME FETCHING
      String supName = _auth.currentUser?.displayName ?? '';

      // If Firebase Auth name is blank, fetch it directly from the Firestore database
      if (supName.isEmpty && _auth.currentUser != null) {
        try {
          // NOTE: If your users are stored in a collection called 'employees' or 'id_requests', change 'users' below to match your database.
          var userDoc = await _db.collection('users').doc(_auth.currentUser!.uid).get();

          if (userDoc.exists) {
            // Grab the name from the database document
            supName = userDoc.data()?['name'] ?? userDoc.data()?['fullName'] ?? 'Unit Supervisor';

            // Permanently fix their Firebase Auth profile so it's instant next time!
            await _auth.currentUser!.updateDisplayName(supName);
            await _auth.currentUser!.reload();
          } else {
            supName = 'Unit Supervisor';
          }
        } catch (e) {
          debugPrint("Could not fetch user name from database: $e");
          supName = 'Unit Supervisor';
        }
      } else if (supName.isEmpty) {
        supName = 'Unit Supervisor';
      }

      // ✅ 2. PROCEED WITH STOCK SAVE
      String type = selectedTransactionType.value == 'Stock In' ? 'IN' : 'OUT';
      WriteBatch batch = _db.batch();

      // Prepare Main Product
      var docRef1 = _db.collection('inventory_logs').doc();
      batch.set(docRef1, {
        'type': type,
        'product': selectedProduct.value,
        'color': selectedColor.value,
        'qty': double.tryParse(qtyController.text) ?? 0.0,
        'unit': isPcs ? 'pcs' : 'kg',
        'style': isPcs ? selectedCollarStyle.value : 'N/A',
        'vendor': type == 'IN' ? vendorController.text.trim() : 'N/A',
        'date': Timestamp.fromDate(selectedDate.value),
        'supervisorName': supName, // <--- NOW SAVES REAL NAME
        'supervisorId': _auth.currentUser?.uid ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Prepare Rib (If applicable)
      if (isPcs && hasRib.value) {
        var docRef2 = _db.collection('inventory_logs').doc();
        batch.set(docRef2, {
          'type': type,
          'product': 'Rib',
          'color': selectedRibColor.value,
          'qty': double.tryParse(ribQtyController.text) ?? 0.0,
          'unit': 'pcs',
          'style': selectedRibStyle.value,
          'vendor': type == 'IN' ? vendorController.text.trim() : 'N/A',
          'date': Timestamp.fromDate(selectedDate.value),
          'supervisorName': supName, // <--- NOW SAVES REAL NAME
          'supervisorId': _auth.currentUser?.uid ?? '',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      Get.snackbar("Success", "${selectedTransactionType.value} recorded by $supName!",
          backgroundColor: Colors.green.withValues(alpha: 0.1), colorText: Colors.green);

      resetFields();
      selectedProduct.value = '';
    } catch (e) {
      _showError("Failed to save: $e");
    } finally {
      isLoading.value = false;
    }
  }

  bool _validateForm() {
    if (selectedProduct.value.isEmpty) { _showError("Select a product."); return false; }
    if (selectedColor.value.isEmpty) { _showError("Select a color."); return false; }
    if (qtyController.text.isEmpty) { _showError("Enter quantity."); return false; }

    if (isPcs && hasRib.value) {
      if (selectedRibColor.value.isEmpty) { _showError("Select Rib color."); return false; }
      if (ribQtyController.text.isEmpty) { _showError("Enter Rib quantity."); return false; }
    }

    if (selectedTransactionType.value == 'Stock In' && vendorController.text.trim().isEmpty) {
      _showError("Enter vendor name."); return false;
    }
    return true;
  }

  // Helper to check if item uses "pcs"
  bool get isPcs => selectedProduct.value.toLowerCase().contains('collar') || selectedProduct.value == 'Others';

  void resetFields() {
    selectedColor.value = '';
    selectedCollarStyle.value = 'Solid color';
    qtyController.clear();
    vendorController.clear();

    hasRib.value = false;
    selectedRibColor.value = '';
    selectedRibStyle.value = 'Solid color';
    ribQtyController.clear();
    currentBalance.value = 0.0;
  }

  Future<void> pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) selectedDate.value = picked;
  }

  void _showError(String msg) {
    Get.snackbar("Error", msg, backgroundColor: Colors.redAccent.withValues(alpha: 0.1), colorText: Colors.red);
  }
}