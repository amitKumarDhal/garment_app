import 'package:cloud_firestore/cloud_firestore.dart'; // REQUIRED
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yoobbel/data/models/order_model.dart';

class MarketingUploadController extends GetxController {
  final uploadFormKey = GlobalKey<FormState>();

  // --- Form Field Controllers ---
  final orderNo = TextEditingController();
  final clientName = TextEditingController();
  final organization = TextEditingController();
  final phone = TextEditingController();
  final productDetails = TextEditingController();
  final orderValue = TextEditingController();
  final quantity = TextEditingController();
  final gstInfo = TextEditingController();
  final deadline = TextEditingController();

  final isLoading = false.obs;
  DateTime? _selectedDeadline; // Store raw DateTime for Firestore

  // --- Date Picker Logic ---
  Future<void> chooseDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      _selectedDeadline = pickedDate; // Keep track of the actual date object
      deadline.text =
          "${pickedDate.day} ${_getMonthName(pickedDate.month)} ${pickedDate.year}";
    }
  }

  String _getMonthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[month - 1];
  }

  // --- Submit Logic (NOW WITH FIRESTORE) ---
  void submitOrder() async {
    if (!uploadFormKey.currentState!.validate()) return;
    if (_selectedDeadline == null) {
      Get.snackbar("Error", "Please select a deadline date");
      return;
    }

    try {
      isLoading.value = true;

      // 1. Create the OrderModel using your form data
      final newOrder = OrderModel(
        clientName: clientName.text.trim(),
        productName: productDetails.text.trim(), // From productDetails field
        quantity: int.tryParse(quantity.text.trim()) ?? 0,
        priority: "Medium", // You can add a priority picker later
        orderDate: DateTime.now(),
        deliveryDate: _selectedDeadline!,
        marketingPersonName:
            "Amit शर्मा", // Ideally get this from current user profile
        totalAmount: double.tryParse(orderValue.text.trim()) ?? 0.0,
      );

      // 2. Save to Cloud Firestore 'orders' collection
      await FirebaseFirestore.instance
          .collection('orders')
          .add(newOrder.toJson());

      Get.snackbar(
        "Success",
        "Order ${orderNo.text} for ${clientName.text} saved to Cloud",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.1),
        colorText: Colors.green,
      );

      _clearForm();
      Get.back();
    } catch (e) {
      Get.snackbar("Error", "Failed to upload to database: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _clearForm() {
    for (var c in [
      orderNo,
      clientName,
      organization,
      phone,
      productDetails,
      orderValue,
      quantity,
      gstInfo,
      deadline,
    ]) {
      c.clear();
    }
    _selectedDeadline = null;
  }

  @override
  void onClose() {
    // Crucial for 8GB RAM: Dispose all controllers properly
    for (var c in [
      orderNo,
      clientName,
      organization,
      phone,
      productDetails,
      orderValue,
      quantity,
      gstInfo,
      deadline,
    ]) {
      c.dispose();
    }
    super.onClose();
  }
}
