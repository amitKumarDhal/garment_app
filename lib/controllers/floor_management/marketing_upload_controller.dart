import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/order_model.dart';

class MarketingUploadController extends GetxController {
  static MarketingUploadController get instance => Get.find();

  final uploadFormKey = GlobalKey<FormState>();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // --- Form Field Controllers ---
  final orderNo = TextEditingController();
  final productCode = TextEditingController();
  final clientName = TextEditingController();
  final organization = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  final productDetails = TextEditingController();
  final sizeDescription = TextEditingController();

  // ✅ Just the Selling Price (No Standard Price)
  final orderValue = TextEditingController();

  final quantity = TextEditingController();
  final gstInfo = TextEditingController();
  final deadline = TextEditingController();
  final shippingCharge = TextEditingController();
  final advanceAmount = TextEditingController();

  final isLoading = false.obs;
  DateTime? _selectedDeadline;

  // Edit Mode Variables
  final isEditing = false.obs;
  String? editingOrderId;

  final RxString selectedImagePath = ''.obs;

  // Observables for Financials
  final RxDouble subTotal = 0.0.obs;
  final RxDouble taxAmount = 0.0.obs;
  final RxDouble grandTotal = 0.0.obs;
  final RxDouble balanceDue = 0.0.obs;

  final RxString lastOrderSerial = "Fetching...".obs;
  final RxBool isFetchingSerial = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Listen to inputs to trigger calculation
    quantity.addListener(_calculateTotal);
    orderValue.addListener(_calculateTotal);
    gstInfo.addListener(_calculateTotal);
    shippingCharge.addListener(_calculateTotal);
    advanceAmount.addListener(_calculateTotal);

    // Call this manually in UI to avoid initial build crashes
  }

  // ✅ Logic to Fetch & Increment Serial
  Future<void> fetchLastOrderSerial() async {
    if (_auth.currentUser == null) return;

    isLoading.value = true;
    try {
      final snapshot = await _db
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        String lastSerial =
            snapshot.docs.first.data()['manualOrderNo'] ?? "ORD-000";
        lastOrderSerial.value = lastSerial;
        _generateNextSerial(lastSerial);
      } else {
        orderNo.text = "YB001"; // Default start
      }
    } catch (e) {
      print("Error fetching serial: $e");
      orderNo.text = "YB001"; // Fallback
    } finally {
      isLoading.value = false;
    }
  }

  // --- Logic to increment string (Format: YB001) ---
  void _generateNextSerial(String lastSerial) {
    try {
      final match = RegExp(r'^([A-Za-z]+)(\d+)$').firstMatch(lastSerial);

      if (match != null) {
        String numberPart = match.group(2)!;
        int nextNumber = int.parse(numberPart) + 1;
        orderNo.text = "YB${nextNumber.toString().padLeft(3, '0')}";
      } else {
        print("⚠️ Format mismatch. Resetting sequence.");
        orderNo.text = "YB001";
      }
    } catch (e) {
      print("❌ Serial Generation Error: $e");
      orderNo.text = "YB001";
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
    address.text = order.clientAddress ?? "";

    productCode.text = order.productCode ?? "";
    productDetails.text = order.productDetails ?? "";
    sizeDescription.text = order.sizeDescription ?? "";
    quantity.text = order.quantity.toString();
    shippingCharge.text = order.shippingCharge.toString();
    advanceAmount.text = order.advanceAmount.toString();

    // Reverse Engineering Unit Price
    // Price = Total / Quantity
    double qty = order.quantity > 0 ? order.quantity.toDouble() : 1.0;

    // We calculate base value before tax to show correct unit price
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

  // ✅ CLEAN CALCULATION (Standard Logic Only)
  void _calculateTotal() {
    double qty = double.tryParse(quantity.text.trim()) ?? 0.0;
    double unitPrice = double.tryParse(orderValue.text.trim()) ?? 0.0;
    double gstPercent = double.tryParse(gstInfo.text.trim()) ?? 0.0;
    double shipping = double.tryParse(shippingCharge.text.trim()) ?? 0.0;
    double advance = double.tryParse(advanceAmount.text.trim()) ?? 0.0;

    // Simple Math: Total = Qty * Price
    double base = qty * unitPrice;
    double tax = base * (gstPercent / 100);

    subTotal.value = base;
    taxAmount.value = tax;
    grandTotal.value = base + tax + shipping;
    balanceDue.value = grandTotal.value - advance;
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
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    ];
    return months[month - 1];
  }

  void pickImage() {
    Get.snackbar("Coming Soon", "Image upload disabled.");
  }

  // ✅ Safe Submit Order
  void submitOrder() async {
    if (!uploadFormKey.currentState!.validate()) return;
    if (_selectedDeadline == null) {
      Get.snackbar("Missing Date", "Please select a delivery deadline.");
      return;
    }

    try {
      isLoading.value = true;

      final user = _auth.currentUser;
      String agentName = "Agent";
      String userId = user?.uid ?? "";

      if (userId.isNotEmpty) {
        try {
          final userDoc = await _db.collection('users').doc(userId).get();
          if (userDoc.exists) {
            final data = userDoc.data()!;
            agentName = data['FullName'] ?? data['Name'] ?? user?.displayName ?? "Agent";
          }
        } catch (e) {
          print("Error fetching user profile: $e");
        }
      }

      double finalTotal = grandTotal.value;
      double finalBalance = balanceDue.value;
      double finalAdvance = double.tryParse(advanceAmount.text.trim()) ?? 0.0;

      int qty = int.tryParse(quantity.text.trim()) ?? 0;
      double price = double.tryParse(orderValue.text.trim()) ?? 0.0;
      double shipping = double.tryParse(shippingCharge.text.trim()) ?? 0.0;
      double gst = double.tryParse(gstInfo.text.trim()) ?? 0.0;

      final singleProductMap = {
        "productName": productDetails.text.trim(),
        "sizeDescription": sizeDescription.text.trim(),
        "qty": qty,
        "price": price,
        "total": finalTotal,
      };

      final orderMap = {
        "clientName": clientName.text.trim(),
        "clientPhone": phone.text.trim(),
        "organization": organization.text.trim(),
        "clientAddress": address.text.trim(),
        "productCode": productCode.text.trim(),
        "productDetails": productDetails.text.trim(),
        "productName": productDetails.text.trim(),
        "sizeDescription": sizeDescription.text.trim(),
        "quantity": qty,
        "priority": "Medium",
        "deliveryDate": Timestamp.fromDate(_selectedDeadline!),
        "gstPercentage": gst,
        "shippingCharge": shipping,

        // ✅ Standard Total Calculation
        "totalAmount": finalTotal,

        "advanceAmount": finalAdvance,
        "balanceDue": finalBalance,
        "marketingPersonName": agentName,
        "marketingPersonId": userId,
        "products": [singleProductMap],
        "status": "Pending",
      };

      if (selectedImagePath.value.isNotEmpty) {
        orderMap['localImagePath'] = selectedImagePath.value;
      }

      if (isEditing.value && editingOrderId != null) {
        orderMap['manualOrderNo'] = orderNo.text.trim();
        await _db.collection('orders').doc(editingOrderId).update(orderMap);
        Get.snackbar("Success", "Order updated successfully!", backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        // --- NEW ORDER (Transaction Mode) ---
        await _db.runTransaction((transaction) async {
          DocumentReference counterRef = _db.collection('counters').doc('order_counter');
          DocumentSnapshot counterSnapshot = await transaction.get(counterRef);

          int nextSerialInt = 1;
          if (counterSnapshot.exists) {
            nextSerialInt = (counterSnapshot.get('current_serial') ?? 0) + 1;
          }

          String newOrderId = "YB${nextSerialInt.toString().padLeft(3, '0')}";
          transaction.set(counterRef, {'current_serial': nextSerialInt});

          orderMap['manualOrderNo'] = newOrderId;
          orderMap['createdAt'] = FieldValue.serverTimestamp();
          orderMap['orderDate'] = DateTime.now();

          DocumentReference newOrderRef = _db.collection('orders').doc();
          transaction.set(newOrderRef, orderMap);
        });

        Get.snackbar("Success", "Order saved securely!", backgroundColor: Colors.green, colorText: Colors.white);
      }

      _clearForm();
    } catch (e) {
      Get.snackbar("Error", "Action failed: $e", backgroundColor: Colors.red, colorText: Colors.white);
      print("Transaction Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _clearForm() {
    for (var c in [
      orderNo, productCode, clientName, organization, phone, address,
      productDetails, sizeDescription, orderValue, quantity, gstInfo,
      deadline, shippingCharge, advanceAmount,
    ]) {
      c.clear();
    }
    _selectedDeadline = null;
    selectedImagePath.value = '';

    subTotal.value = 0.0;
    taxAmount.value = 0.0;
    grandTotal.value = 0.0;
    balanceDue.value = 0.0;

    isEditing.value = false;
    editingOrderId = null;

    fetchLastOrderSerial();
  }
}