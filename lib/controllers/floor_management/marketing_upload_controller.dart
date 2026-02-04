import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/order_model.dart';

class MarketingUploadController extends GetxController {
  static MarketingUploadController get instance => Get.find();

  final uploadFormKey = GlobalKey<FormState>();

  // --- Form Field Controllers ---
  final orderNo = TextEditingController();
  final productCode = TextEditingController();
  final clientName = TextEditingController();
  final organization = TextEditingController();
  final phone = TextEditingController();
  final productDetails = TextEditingController();
  final orderValue = TextEditingController();
  final quantity = TextEditingController();
  final gstInfo = TextEditingController();
  final deadline = TextEditingController();

  final isLoading = false.obs;
  DateTime? _selectedDeadline;

  // ✅ EDIT MODE VARIABLES
  final isEditing = false.obs;
  String? editingOrderId;

  final RxString selectedImagePath = ''.obs;
  final RxDouble grandTotal = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    // Auto-calculate total when these fields change
    quantity.addListener(_calculateTotal);
    orderValue.addListener(_calculateTotal);
    gstInfo.addListener(_calculateTotal);
  }

  // ✅ Load data from an existing order for Editing
  void loadOrderData(OrderModel order) {
    isEditing.value = true;
    editingOrderId = order.id;

    orderNo.text = order.manualOrderNo ?? "";
    clientName.text = order.clientName;
    organization.text = order.organization ?? "";
    phone.text = order.clientPhone ?? "";
    productCode.text = order.productCode ?? "";
    productDetails.text = order.productDetails ?? "";
    quantity.text = order.quantity.toString();

    // Calculate Unit Price approx: (Total / (1 + GST%)) / Qty
    double qty = order.quantity > 0 ? order.quantity.toDouble() : 1.0;
    double baseVal = order.totalAmount / (1 + (order.gstPercentage / 100));
    orderValue.text = (baseVal / qty).toStringAsFixed(2);

    gstInfo.text = order.gstPercentage.toString();

    _selectedDeadline = order.deliveryDate;
    deadline.text =
        "${_selectedDeadline!.day} ${_getMonthName(_selectedDeadline!.month)} ${_selectedDeadline!.year}";

    _calculateTotal();
  }

  void _calculateTotal() {
    double qty = double.tryParse(quantity.text.trim()) ?? 0.0;
    double unitPrice = double.tryParse(orderValue.text.trim()) ?? 0.0;
    double gstPercent = double.tryParse(gstInfo.text.trim()) ?? 0.0;

    double subTotal = qty * unitPrice;
    double gstAmount = (subTotal * gstPercent) / 100;

    grandTotal.value = subTotal + gstAmount;
  }

  Future<void> chooseDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      _selectedDeadline = pickedDate;
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

  void pickImage() => Get.snackbar("Mockup Upload", "Coming soon!");

  // ✅ SUBMIT ORDER (Create or Update)
  void submitOrder() async {
    if (!uploadFormKey.currentState!.validate()) return;
    if (_selectedDeadline == null) {
      Get.snackbar("Missing Date", "Please select a delivery deadline.");
      return;
    }

    try {
      isLoading.value = true;
      final firestore = FirebaseFirestore.instance;
      final user = FirebaseAuth.instance.currentUser;

      String agentName = "Agent";

      // ---------------- DEBUGGING / FETCH LOGIC ----------------
      if (user != null) {
        print("🔍 DEBUG: Searching for User UID: ${user.uid}");

        try {
          final userDoc = await firestore
              .collection('users')
              .doc(user.uid)
              .get();

          if (userDoc.exists) {
            final data = userDoc.data()!;
            print("📄 DEBUG: Found User Data: $data");

            // Robust fallback: Check all common naming conventions
            agentName =
                data['FullName'] ??
                data['Name'] ??
                data['full_name'] ??
                data['name'] ??
                user.displayName ??
                "Agent";

            print("✅ DEBUG: Using Name: $agentName");
          } else {
            print("❌ DEBUG: User document not found in 'users' collection.");
          }
        } catch (e) {
          print("❌ DEBUG Error fetching user: $e");
        }
      }
      // ---------------------------------------------------------

      // Prepare Data
      int qty = int.tryParse(quantity.text.trim()) ?? 0;
      double price = double.tryParse(orderValue.text.trim()) ?? 0.0;
      double total = grandTotal.value;

      final singleProductMap = {
        "productName": productDetails.text.trim(),
        "qty": qty,
        "price": price,
        "total": total,
      };

      final orderMap = {
        "manualOrderNo": orderNo.text.trim(),
        "clientName": clientName.text.trim(),
        "clientPhone": phone.text.trim(),
        "organization": organization.text.trim(),
        "productCode": productCode.text.trim(),
        "productDetails": productDetails.text.trim(),
        "productName": productDetails.text.trim(), // Legacy support
        "quantity": qty,
        "deliveryDate": _selectedDeadline,
        "gstPercentage": double.tryParse(gstInfo.text.trim()) ?? 0.0,
        "totalAmount": total,

        // ✅ REAL NAME
        "marketingPersonName": agentName,

        // ✅ LIST FORMAT (Required for new Details Screen)
        "products": [singleProductMap],

        "status": "Pending",
      };

      if (isEditing.value && editingOrderId != null) {
        // UPDATE
        await firestore
            .collection('orders')
            .doc(editingOrderId)
            .update(orderMap);
        Get.snackbar("Success", "Order updated successfully!");
      } else {
        // CREATE
        orderMap["orderDate"] = DateTime.now();
        await firestore.collection('orders').add(orderMap);
        Get.snackbar("Success", "New order saved!");
      }

      _clearForm();
      Get.back(); // Go back to history/dashboard
    } catch (e) {
      Get.snackbar("Error", "Action failed: $e");
      print("❌ CRITICAL ERROR: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _clearForm() {
    for (var c in [
      orderNo,
      productCode,
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
    selectedImagePath.value = '';
    grandTotal.value = 0.0;
    isEditing.value = false;
    editingOrderId = null;
  }
}
