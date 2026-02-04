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

  // Stores the current user's role
  var currentUserRole = "Loading...".obs;

  @override
  void onInit() {
    super.onInit();
    _identifyUserRole();
    _bindInventoryStream();
  }

  /// Checks Local Storage first. If missing, checks Firebase.
  void _identifyUserRole() async {
    String? storedRole = _storage.read('role');

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

          await _storage.write('role', fetchedRole);
          currentUserRole.value = fetchedRole;
        }
      } catch (e) {
        print("Error fetching role: $e");
      }
    }
  }

  // ✅ FIXED & UPDATED: Real-time listener with Sorting
  void _bindInventoryStream() {
    _db
        .collection('inventory')
        .where('type', isEqualTo: 'Fabric')
        // ✅ RESTORED: Sort by newest updated first
        // NOTE: If this causes an error, check the Debug Console for the Index Link!
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            rawMaterials.value = snapshot.docs.map((doc) {
              var data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList();
            isLoading.value = false; // Stop loading on success
          },
          onError: (error) {
            print("Firestore Error: $error");
            isLoading.value = false;

            // ✅ Smarter Error Message
            String msg = "Could not load data.";
            if (error.toString().contains("failed-precondition")) {
              msg = "Missing Index. Check Debug Console for link!";
            } else if (error.toString().contains("permission-denied")) {
              msg = "Access Denied. Check Database Rules.";
            }

            Get.snackbar(
              "Database Error",
              msg,
              backgroundColor: Colors.red.withOpacity(0.1),
              colorText: Colors.red,
              duration: const Duration(seconds: 5),
            );
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
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return;
    }

    try {
      // ✅ IMPROVEMENT: Case-insensitive check (Cotton == cotton)
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

      // Log the Activity
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
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }
}
