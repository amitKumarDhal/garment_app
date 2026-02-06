import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:image_picker/image_picker.dart'; // Commented out for now
// import 'package:firebase_storage/firebase_storage.dart'; // Commented out for now
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
  final sizeDescription = TextEditingController(); // ✅ Size Controller
  final orderValue = TextEditingController();
  final quantity = TextEditingController();
  final gstInfo = TextEditingController();
  final deadline = TextEditingController();
  final shippingCharge = TextEditingController(); // ✅ Shipping Controller

  final isLoading = false.obs;
  DateTime? _selectedDeadline;

  // Edit Mode Variables
  final isEditing = false.obs;
  String? editingOrderId;

  final RxString selectedImagePath = ''.obs;
  final RxDouble grandTotal = 0.0.obs;

  // ✅ Last Order Serial Observable
  final RxString lastOrderSerial = "Fetching...".obs;

  // ✅ Loading state for the refresh button (Prevents Crash)
  final RxBool isFetchingSerial = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Auto-calculate total when these fields change
    quantity.addListener(_calculateTotal);
    orderValue.addListener(_calculateTotal);
    gstInfo.addListener(_calculateTotal);
    shippingCharge.addListener(_calculateTotal);

    // ✅ Fetch immediately when screen loads
    fetchLastOrderSerial();
  }

  // ✅ FETCH LAST ORDER
  Future<void> fetchLastOrderSerial() async {
    try {
      isFetchingSerial.value = true; // 🔄 Start Spinner

      final querySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        lastOrderSerial.value = data['manualOrderNo'] ?? "None";
      } else {
        lastOrderSerial.value = "No orders yet";
      }
    } catch (e) {
      lastOrderSerial.value = "Error";
      print("Error fetching last order: $e");
    } finally {
      isFetchingSerial.value = false; // 🛑 Stop Spinner
    }
  }

  // ✅ LOAD DATA (Edit Mode)
  void loadOrderData(OrderModel order) {
    isEditing.value = true;
    editingOrderId = order.id;

    orderNo.text = order.manualOrderNo ?? "";
    clientName.text = order.clientName;
    organization.text = order.organization ?? "";
    phone.text = order.clientPhone ?? "";
    productCode.text = order.productCode ?? "";
    productDetails.text = order.productDetails ?? "";
    sizeDescription.text = order.sizeDescription ?? "";
    quantity.text = order.quantity.toString();

    // Load Shipping
    shippingCharge.text = order.shippingCharge.toString();

    // Calculate Base Unit Price (Reverse Engineering Total)
    double qty = order.quantity > 0 ? order.quantity.toDouble() : 1.0;
    double gstMultiplier = 1 + (order.gstPercentage / 100);
    double baseVal = (gstMultiplier > 0)
        ? (order.totalAmount / gstMultiplier)
        : order.totalAmount;

    orderValue.text = (baseVal / qty).toStringAsFixed(2);
    gstInfo.text = order.gstPercentage.toString();

    _selectedDeadline = order.deliveryDate;
    if (_selectedDeadline != null) {
      deadline.text =
          "${_selectedDeadline!.day} ${_getMonthName(_selectedDeadline!.month)} ${_selectedDeadline!.year}";
    }
    _calculateTotal();
  }

  void _calculateTotal() {
    double qty = double.tryParse(quantity.text.trim()) ?? 0.0;
    double unitPrice = double.tryParse(orderValue.text.trim()) ?? 0.0;
    double gstPercent = double.tryParse(gstInfo.text.trim()) ?? 0.0;
    double shipping = double.tryParse(shippingCharge.text.trim()) ?? 0.0;

    double subTotal = qty * unitPrice;
    double gstAmount = (subTotal * gstPercent) / 100;

    grandTotal.value = subTotal + gstAmount + shipping;
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

  // ✅ DISABLED: Shows Snackbar instead of opening gallery
  void pickImage() {
    Get.snackbar(
      "Coming Soon",
      "Image upload is currently disabled.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange.withOpacity(0.1),
      colorText: Colors.orange,
      margin: const EdgeInsets.all(10),
    );
  }

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

      if (user != null) {
        try {
          final userDoc = await firestore
              .collection('users')
              .doc(user.uid)
              .get();
          if (userDoc.exists) {
            final data = userDoc.data()!;
            agentName =
                data['FullName'] ?? data['Name'] ?? user.displayName ?? "Agent";
          }
        } catch (e) {
          print("Error fetching user: $e");
        }
      }

      int qty = int.tryParse(quantity.text.trim()) ?? 0;
      double price = double.tryParse(orderValue.text.trim()) ?? 0.0;
      double shipping = double.tryParse(shippingCharge.text.trim()) ?? 0.0;
      double total = grandTotal.value;

      // ✅ FIXED: Define imageUrl as empty string so code compiles
      String imageUrl = '';

      /* --- IMAGE UPLOAD LOGIC (Commented Out) ---
      if (selectedImagePath.value.isNotEmpty) {
         // ... existing upload code ...
         imageUrl = await ref.getDownloadURL();
      }
      */

      final singleProductMap = {
        "productName": productDetails.text.trim(),
        "sizeDescription": sizeDescription.text.trim(),
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
        "productName": productDetails.text.trim(),
        "sizeDescription": sizeDescription.text.trim(),
        "quantity": qty,
        "deliveryDate": _selectedDeadline,
        "gstPercentage": double.tryParse(gstInfo.text.trim()) ?? 0.0,
        "shippingCharge": shipping,
        "totalAmount": total,
        "marketingPersonName": agentName,
        "products": [singleProductMap],
        "status": "Pending",

        // ✅ CRITICAL: Save 'createdAt' for sorting
        "createdAt": FieldValue.serverTimestamp(),

        if (imageUrl.isNotEmpty) "imageUrl": imageUrl,
      };

      if (isEditing.value && editingOrderId != null) {
        await firestore
            .collection('orders')
            .doc(editingOrderId)
            .update(orderMap);
        Get.snackbar("Success", "Order updated successfully!");
      } else {
        orderMap["orderDate"] = DateTime.now();
        await firestore.collection('orders').add(orderMap);
        Get.snackbar("Success", "New order saved!");
      }

      _clearForm();
      Get.back();
    } catch (e) {
      Get.snackbar("Error", "Action failed: $e");
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
      sizeDescription,
      orderValue,
      quantity,
      gstInfo,
      deadline,
      shippingCharge,
    ]) {
      c.clear();
    }
    _selectedDeadline = null;
    selectedImagePath.value = '';
    grandTotal.value = 0.0;
    isEditing.value = false;
    editingOrderId = null;

    // Refresh the last serial after submission
    fetchLastOrderSerial();
  }
}
