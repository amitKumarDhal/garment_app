import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/order_model.dart';

class MarketingUploadController extends GetxController {
  static MarketingUploadController get instance => Get.find();

  final uploadFormKey = GlobalKey<FormState>();

  // ✅ ADD THESE TWO LINES HERE
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // --- Form Field Controllers ---
  final orderNo = TextEditingController();
  final productCode = TextEditingController();
  final clientName = TextEditingController();
  final organization = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController(); // ✅ Address
  final productDetails = TextEditingController();
  final sizeDescription = TextEditingController();
  final orderValue = TextEditingController();
  final quantity = TextEditingController();
  final gstInfo = TextEditingController();
  final deadline = TextEditingController();
  final shippingCharge = TextEditingController();
  final advanceAmount = TextEditingController(); // ✅ Advance

  final isLoading = false.obs;
  DateTime? _selectedDeadline;

  // Edit Mode Variables
  final isEditing = false.obs;
  String? editingOrderId;

  final RxString selectedImagePath = ''.obs;

  // ✅ NEW: Observables for Financials (UI listens to these)
  final RxDouble subTotal = 0.0.obs;
  final RxDouble taxAmount = 0.0.obs;
  final RxDouble grandTotal = 0.0.obs;
  final RxDouble balanceDue = 0.0.obs;

  final RxString lastOrderSerial = "Fetching...".obs;
  final RxBool isFetchingSerial = false.obs;

  @override
  void onInit() {
    super.onInit();
    // ✅ Listen to all input fields to trigger calculation
    quantity.addListener(_calculateTotal);
    orderValue.addListener(_calculateTotal);
    gstInfo.addListener(_calculateTotal);
    shippingCharge.addListener(_calculateTotal);
    advanceAmount.addListener(_calculateTotal);

    fetchLastOrderSerial();
  }

  // ✅ Logic to Fetch & Increment Serial
  Future<void> fetchLastOrderSerial() async {
    isLoading.value = true;
    final snapshot = await _db
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      String lastSerial =
          snapshot.docs.first.data()['manualOrderNo'] ?? "ORD-000";
      lastOrderSerial.value = lastSerial;
      _generateNextSerial(lastSerial); // <--- Calls the math logic below
    } else {
      orderNo.text = "ORD-001";
    }
    isLoading.value = false;
  }

  // --- 2. Logic to increment string (Optimized for YB- prefix) ---
  // --- 2. Logic to increment string (Format: YB001) ---
  void _generateNextSerial(String lastSerial) {
    try {
      // Logic: Separate Letters from Numbers
      // Regex ^([A-Za-z]+) matches "YB" or "YBOO" at start
      // Regex (\d+)$ matches "008" or "8" at the end
      final match = RegExp(r'^([A-Za-z]+)(\d+)$').firstMatch(lastSerial);

      if (match != null) {
        // We ignore the old prefix (match.group(1)) to enforce "YB"
        // We grab the number part (match.group(2))
        String numberPart = match.group(2)!;

        int nextNumber = int.parse(numberPart) + 1;

        // Format: Prefix "YB" + 3-digit padding
        orderNo.text = "YB${nextNumber.toString().padLeft(3, '0')}";
      } else {
        // If the regex fails (e.g. data is empty or totally weird), reset.
        print("⚠️ Format mismatch. Resetting sequence.");
        orderNo.text = "YB001";
      }
    } catch (e) {
      print("❌ Serial Generation Error: $e");
      orderNo.text = "YB001"; // Fallback
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

  // ✅ Logic to Calculate Totals automatically
  void _calculateTotal() {
    double qty = double.tryParse(quantity.text.trim()) ?? 0.0;
    double unitPrice = double.tryParse(orderValue.text.trim()) ?? 0.0;
    double gstPercent = double.tryParse(gstInfo.text.trim()) ?? 0.0;
    double shipping = double.tryParse(shippingCharge.text.trim()) ?? 0.0;
    double advance = double.tryParse(advanceAmount.text.trim()) ?? 0.0;

    double base = qty * unitPrice;
    double tax = base * (gstPercent / 100);

    // Update Observables so UI changes instantly
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

  void pickImage() {
    Get.snackbar("Coming Soon", "Image upload disabled.");
  }

  // ✅ 6. Submit Order (Fully Updated)
  // ✅ 6. Safe Submit Order (Concurrency Proof)
  void submitOrder() async {
    // 1. Validate Form & Date
    if (!uploadFormKey.currentState!.validate()) return;
    if (_selectedDeadline == null) {
      Get.snackbar("Missing Date", "Please select a delivery deadline.");
      return;
    }

    try {
      isLoading.value = true;

      // 2. Identify the Agent (Logged-in User)
      final user = _auth.currentUser;
      String agentName = "Agent";
      String userId = user?.uid ?? "";

      if (userId.isNotEmpty) {
        try {
          final userDoc = await _db.collection('users').doc(userId).get();
          if (userDoc.exists) {
            final data = userDoc.data()!;
            agentName =
                data['FullName'] ??
                data['Name'] ??
                user?.displayName ??
                "Agent";
          }
        } catch (e) {
          print("Error fetching user profile: $e");
        }
      }

      // 3. Prepare Financial Values
      double finalTotal = grandTotal.value;
      double finalBalance = balanceDue.value;
      double finalAdvance = double.tryParse(advanceAmount.text.trim()) ?? 0.0;

      int qty = int.tryParse(quantity.text.trim()) ?? 0;
      double price = double.tryParse(orderValue.text.trim()) ?? 0.0;
      double shipping = double.tryParse(shippingCharge.text.trim()) ?? 0.0;
      double gst = double.tryParse(gstInfo.text.trim()) ?? 0.0;

      // 4. Product Data
      final singleProductMap = {
        "productName": productDetails.text.trim(),
        "sizeDescription": sizeDescription.text.trim(),
        "qty": qty,
        "price": price,
        "total": finalTotal,
      };

      // 5. Build Base Order Map (Without ID yet)
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
        "totalAmount": finalTotal,
        "advanceAmount": finalAdvance,
        "balanceDue": finalBalance,

        "marketingPersonName": agentName,
        "marketingPersonId": userId,
        "products": [singleProductMap],
        "status": "Pending",
      };

      // 6. Handle Image Path
      if (selectedImagePath.value.isNotEmpty) {
        orderMap['localImagePath'] = selectedImagePath.value;
      }

      // 7. Save to Firestore
      if (isEditing.value && editingOrderId != null) {
        // --- EDIT MODE (Standard Update) ---
        // Use the ID currently in the text box
        orderMap['manualOrderNo'] = orderNo.text.trim();

        await _db.collection('orders').doc(editingOrderId).update(orderMap);

        Get.snackbar(
          "Success",
          "Order updated successfully!",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        // --- NEW ORDER (Transaction Mode) ---
        await _db.runTransaction((transaction) async {
          // A. Lock & Read Counter
          DocumentReference counterRef = _db
              .collection('counters')
              .doc('order_counter');
          DocumentSnapshot counterSnapshot = await transaction.get(counterRef);

          int nextSerialInt = 1;
          if (counterSnapshot.exists) {
            nextSerialInt = (counterSnapshot.get('current_serial') ?? 0) + 1;
          }

          // B. Generate Format "YB001"
          String newOrderId = "YB${nextSerialInt.toString().padLeft(3, '0')}";

          // C. Update Counter
          transaction.set(counterRef, {'current_serial': nextSerialInt});

          // D. Finalize Order Data
          orderMap['manualOrderNo'] = newOrderId;
          orderMap['createdAt'] = FieldValue.serverTimestamp();
          orderMap['orderDate'] = DateTime.now();

          // E. Create Document
          DocumentReference newOrderRef = _db.collection('orders').doc();
          transaction.set(newOrderRef, orderMap);
        });

        Get.snackbar(
          "Success",
          "Order saved securely!",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }

      // 8. Cleanup
      _clearForm();
    } catch (e) {
      Get.snackbar(
        "Error",
        "Action failed: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      print("Transaction Error: $e");
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
      address,
      productDetails,
      sizeDescription,
      orderValue,
      quantity,
      gstInfo,
      deadline,
      shippingCharge,
      advanceAmount,
    ]) {
      c.clear();
    }
    _selectedDeadline = null;
    selectedImagePath.value = '';

    // Reset Observables
    subTotal.value = 0.0;
    taxAmount.value = 0.0;
    grandTotal.value = 0.0;
    balanceDue.value = 0.0;

    isEditing.value = false;
    editingOrderId = null;
    fetchLastOrderSerial();
  }
}
