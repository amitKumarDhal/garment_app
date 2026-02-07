import 'dart:async'; // ✅ Import this for StreamSubscription
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class InventoryController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _storage = GetStorage();

  // Observables
  var rawMaterials = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;
  var currentUserRole = "Loading...".obs;

  // ✅ 1. CREATE SUBSCRIPTION VARIABLE
  StreamSubscription? _inventoryStream;

  @override
  void onInit() {
    super.onInit();
    _identifyUserRole();
    _bindInventoryStream();
  }

  // ✅ 2. CANCEL THE STREAM WHEN CONTROLLER DIES
  @override
  void onClose() {
    _inventoryStream?.cancel(); // <--- THIS KILLS THE ZOMBIE LISTENER
    super.onClose();
  }

  void _identifyUserRole() async {
    // ✅ FIX: Use 'user_role' to match AuthenticationRepository
    String? storedRole = _storage.read('user_role');

    if (storedRole != null && storedRole.isNotEmpty) {
      currentUserRole.value = storedRole;
    } else {
      await _fetchRoleFromFirestore();
    }
  }

  Future<void> _fetchRoleFromFirestore() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc = await _db
            .collection('id_requests')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          String fetchedRole = data['role'] ?? "Worker";

          // ✅ FIX: Use 'user_role'
          await _storage.write('user_role', fetchedRole);
          currentUserRole.value = fetchedRole;
        }
      } catch (e) {
        print("Error fetching role: $e");
      }
    }
  }

  void _bindInventoryStream() {
    // ✅ 3. ASSIGN THE LISTENER TO THE VARIABLE
    _inventoryStream = _db
        .collection('inventory')
        .where('type', isEqualTo: 'Fabric')
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            rawMaterials.value = snapshot.docs.map((doc) {
              var data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList();
            isLoading.value = false;
          },
          onError: (error) {
            print("Firestore Error: $error");
            isLoading.value = false;

            // Only show snackbar if we are NOT logging out
            if (!error.toString().contains("permission-denied")) {
              Get.snackbar("Database Error", error.toString());
            }
          },
        );
  }

  // --- Add New Stock (Inward) ---
  Future<void> addStock(String name, double quantity, String unit) async {
    // 🔒 SECURITY CHECK
    bool isAllowed =
        currentUserRole.value.contains('Supervisor') ||
        currentUserRole.value == 'Admin';

    if (!isAllowed) {
      Get.snackbar(
        "Restricted",
        "Only Supervisors can add stock.",
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
      return;
    }

    try {
      String searchName = name.trim();
      var existing = rawMaterials.firstWhereOrNull(
        (item) =>
            (item['name'] as String).toLowerCase() == searchName.toLowerCase(),
      );

      if (existing != null) {
        double currentQty = (existing['quantity'] as num).toDouble();
        await _db.collection('inventory').doc(existing['id']).update({
          'quantity': currentQty + quantity,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        await _db.collection('inventory').add({
          'name': searchName,
          'type': 'Fabric',
          'quantity': quantity,
          'unit': unit,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      await _db.collection('activities').add({
        'title': "Stock Inward",
        'subtitle': "+$quantity $unit of $searchName",
        'time': FieldValue.serverTimestamp(),
        'iconCode': Icons.move_to_inbox.codePoint,
        'colorValue': Colors.green.value,
      });

      Get.back();
      Get.snackbar(
        "Success",
        "Stock Added Successfully",
        backgroundColor: Colors.green.withValues(alpha: 0.1),
        colorText: Colors.green,
      );
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }
}
