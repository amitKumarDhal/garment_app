import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // ✅ NEW
import 'package:image_picker/image_picker.dart'; // ✅ NEW
import '../../data/models/order_model.dart';

// ✅ Helper Class for Dynamic Items
class OrderItemForm {
  final productCode = TextEditingController();
  final productDetails = TextEditingController();
  final sizeDescription = TextEditingController();
  final quantity = TextEditingController();
  final orderValue = TextEditingController();
  final gstInfo = TextEditingController();

  void dispose() {
    productCode.dispose();
    productDetails.dispose();
    sizeDescription.dispose();
    quantity.dispose();
    orderValue.dispose();
    gstInfo.dispose();
  }
}

class MarketingUploadController extends GetxController {
  static MarketingUploadController get instance => Get.find();

  final uploadFormKey = GlobalKey<FormState>();
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // --- Client Info Controllers ---
  final orderNo = TextEditingController();
  final clientName = TextEditingController();
  final organization = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  final deadline = TextEditingController();

  // --- Financial Global Controllers ---
  final shippingCharge = TextEditingController();
  final advanceAmount = TextEditingController();

  // ✅ DYNAMIC ITEM LIST
  final items = <OrderItemForm>[].obs;

  final isLoading = false.obs;
  DateTime? _selectedDeadline;

  final isEditing = false.obs;
  String? editingOrderId;

  // ✅ IMAGE OBSERVABLES
  final RxString selectedImagePath = ''.obs; // Local file path
  final RxString existingImageUrl = ''.obs;  // Cloud URL if editing

  // Observables for Financials
  final RxDouble subTotal = 0.0.obs;
  final RxDouble taxAmount = 0.0.obs;
  final RxDouble grandTotal = 0.0.obs;
  final RxDouble balanceDue = 0.0.obs;

  final RxString lastOrderSerial = "Fetching...".obs;

  @override
  void onInit() {
    super.onInit();
    addNewItem();
    shippingCharge.addListener(_calculateTotal);
    advanceAmount.addListener(_calculateTotal);
  }

  // ✅ DYNAMIC ITEM MANAGEMENT
  void addNewItem() {
    final newItem = OrderItemForm();
    newItem.quantity.addListener(_calculateTotal);
    newItem.orderValue.addListener(_calculateTotal);
    newItem.gstInfo.addListener(_calculateTotal);
    items.add(newItem);
  }

  void removeItem(int index) {
    if (items.length > 1) {
      items[index].dispose();
      items.removeAt(index);
      _calculateTotal();
    } else {
      Get.snackbar("Warning", "An order must have at least one item.", backgroundColor: Colors.orange, colorText: Colors.white);
    }
  }

  // --- Serial Logic ---
  Future<void> fetchLastOrderSerial() async {
    if (_auth.currentUser == null) return;
    isLoading.value = true;
    try {
      final snapshot = await _db.collection('orders').orderBy('createdAt', descending: true).limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        String lastSerial = snapshot.docs.first.data()['manualOrderNo'] ?? "ORD-000";
        lastOrderSerial.value = lastSerial;
        _generateNextSerial(lastSerial);
      } else {
        orderNo.text = "YB001";
      }
    } catch (e) {
      orderNo.text = "YB001";
    } finally {
      isLoading.value = false;
    }
  }

  void _generateNextSerial(String lastSerial) {
    try {
      final match = RegExp(r'^([A-Za-z]+)(\d+)$').firstMatch(lastSerial);
      if (match != null) {
        int nextNumber = int.parse(match.group(2)!) + 1;
        orderNo.text = "YB${nextNumber.toString().padLeft(3, '0')}";
      } else {
        orderNo.text = "YB001";
      }
    } catch (e) {
      orderNo.text = "YB001";
    }
  }

  // ✅ LOAD DATA (Edit Mode)
  void loadOrderData(OrderModel order) {
    final lockedStatuses = ['shipping', 'shipped', 'delivered', 'rejected'];
    if (lockedStatuses.contains(order.status.toLowerCase())) {
      Get.snackbar(
        "Edit Locked",
        "Orders marked as '${order.status}' cannot be modified.",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.back();
      return;
    }

    isEditing.value = true;
    editingOrderId = order.id;

    orderNo.text = order.manualOrderNo ?? "";
    clientName.text = order.clientName;
    organization.text = order.organization ?? "";
    phone.text = order.clientPhone ?? "";
    address.text = order.clientAddress ?? "";
    shippingCharge.text = order.shippingCharge.toString();
    advanceAmount.text = order.advanceAmount.toString();

    // ✅ Load existing image URL if present
    existingImageUrl.value = order.toJson()['designMockupUrl'] ?? '';

    _selectedDeadline = order.deliveryDate;
    if (_selectedDeadline != null) {
      deadline.text = "${_selectedDeadline!.day} ${_getMonthName(_selectedDeadline!.month)} ${_selectedDeadline!.year}";
    }

    // Load Items into Form
    items.clear();
    for (var prod in order.products) {
      final itemForm = OrderItemForm();
      itemForm.productCode.text = prod['productCode'] ?? "";
      itemForm.productDetails.text = prod['productName'] ?? "";
      itemForm.sizeDescription.text = prod['sizeDescription'] ?? "";
      itemForm.quantity.text = (prod['qty'] ?? 0).toString();
      itemForm.orderValue.text = (prod['price'] ?? 0.0).toStringAsFixed(2);
      itemForm.gstInfo.text = (prod['gstPercentage'] ?? 0.0).toString();

      itemForm.quantity.addListener(_calculateTotal);
      itemForm.orderValue.addListener(_calculateTotal);
      itemForm.gstInfo.addListener(_calculateTotal);

      items.add(itemForm);
    }

    if (items.isEmpty) addNewItem();
    _calculateTotal();
  }

  void _calculateTotal() {
    double tempSubTotal = 0.0;
    double tempTaxAmount = 0.0;

    for (var item in items) {
      double qty = double.tryParse(item.quantity.text.trim()) ?? 0.0;
      double unitPrice = double.tryParse(item.orderValue.text.trim()) ?? 0.0;
      double gstPercent = double.tryParse(item.gstInfo.text.trim()) ?? 0.0;

      double base = qty * unitPrice;
      double tax = base * (gstPercent / 100);

      tempSubTotal += base;
      tempTaxAmount += tax;
    }

    double shipping = double.tryParse(shippingCharge.text.trim()) ?? 0.0;
    double advance = double.tryParse(advanceAmount.text.trim()) ?? 0.0;

    subTotal.value = tempSubTotal;
    taxAmount.value = tempTaxAmount;
    grandTotal.value = tempSubTotal + tempTaxAmount + shipping;
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
      deadline.text = "${pickedDate.day} ${_getMonthName(pickedDate.month)} ${pickedDate.year}";
    }
  }

  String _getMonthName(int month) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[month - 1];
  }

  // ✅ NEW: IMAGE PICKER LOGIC
  Future<void> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);

      if (image != null) {
        selectedImagePath.value = image.path;
        existingImageUrl.value = '';
      }
    } catch (e) {
      Get.snackbar("Error", "Could not pick image: $e", backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  // ✅ NEW: Clear selected image
  void removeImage() {
    selectedImagePath.value = '';
    existingImageUrl.value = '';
  }

  // ✅ NEW: FIREBASE STORAGE UPLOAD FUNCTION
  Future<String?> _uploadImageToStorage() async {
    if (selectedImagePath.value.isEmpty) return null;

    try {
      File file = File(selectedImagePath.value);
      String fileName = 'mockups/${DateTime.now().millisecondsSinceEpoch}_${orderNo.text}.jpg';
      Reference ref = FirebaseStorage.instance.ref().child(fileName);

      await ref.putFile(file);
      String downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception("Image upload failed: $e");
    }
  }

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
        } catch (e) {}
      }

      // ✅ UPLOAD IMAGE BEFORE SAVING ORDER
      String? finalImageUrl = existingImageUrl.value;
      if (selectedImagePath.value.isNotEmpty) {
        finalImageUrl = await _uploadImageToStorage();
      }

      List<Map<String, dynamic>> productsList = [];
      int totalQty = 0;
      String firstProductName = "";
      double avgGst = 0.0;

      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        int qty = int.tryParse(item.quantity.text.trim()) ?? 0;
        double price = double.tryParse(item.orderValue.text.trim()) ?? 0.0;
        double gst = double.tryParse(item.gstInfo.text.trim()) ?? 0.0;
        double itemBase = qty * price;
        double itemTotal = itemBase + (itemBase * (gst / 100));

        totalQty += qty;
        avgGst = gst;
        if (i == 0) firstProductName = item.productDetails.text.trim();

        productsList.add({
          "productCode": item.productCode.text.trim(),
          "productName": item.productDetails.text.trim(),
          "sizeDescription": item.sizeDescription.text.trim(),
          "qty": qty,
          "price": price,
          "gstPercentage": gst,
          "total": itemTotal,
        });
      }

      String rootProductName = items.length > 1 ? "$firstProductName + ${items.length - 1} more" : firstProductName;

      final orderMap = {
        "clientName": clientName.text.trim(),
        "clientPhone": phone.text.trim(),
        "organization": organization.text.trim(),
        "clientAddress": address.text.trim(),

        "productCode": items.first.productCode.text.trim(),
        "productDetails": rootProductName,
        "productName": rootProductName,
        "quantity": totalQty,
        "gstPercentage": avgGst,

        "priority": "Medium",
        "deliveryDate": Timestamp.fromDate(_selectedDeadline!),
        "shippingCharge": double.tryParse(shippingCharge.text.trim()) ?? 0.0,
        "totalAmount": grandTotal.value,
        "advanceAmount": double.tryParse(advanceAmount.text.trim()) ?? 0.0,
        "balanceDue": balanceDue.value,
        "marketingPersonName": agentName,
        "marketingPersonId": userId,
        "status": "Pending",
        "products": productsList,

        // ✅ SAVE THE CLOUD URL IN FIRESTORE
        if (finalImageUrl != null && finalImageUrl.isNotEmpty) "designMockupUrl": finalImageUrl,
      };

      if (isEditing.value && editingOrderId != null) {
        orderMap['manualOrderNo'] = orderNo.text.trim();
        await _db.collection('orders').doc(editingOrderId).update(orderMap);
        Get.snackbar("Success", "Order updated successfully!", backgroundColor: Colors.green, colorText: Colors.white);
      }
      else {
        // ✅ 1. Declare this outside so the notification can access it
        String newOrderId = "";

        await _db.runTransaction((transaction) async {
          DocumentReference counterRef = _db.collection('counters').doc('order_counter');
          DocumentSnapshot counterSnapshot = await transaction.get(counterRef);
          int nextSerialInt = 1;
          if (counterSnapshot.exists) nextSerialInt = (counterSnapshot.get('current_serial') ?? 0) + 1;

          newOrderId = "YB${nextSerialInt.toString().padLeft(3, '0')}";
          transaction.set(counterRef, {'current_serial': nextSerialInt});

          orderMap['manualOrderNo'] = newOrderId;
          orderMap['createdAt'] = FieldValue.serverTimestamp();
          orderMap['orderDate'] = DateTime.now();

          DocumentReference newOrderRef = _db.collection('orders').doc();
          transaction.set(newOrderRef, orderMap);
        });

        // ✅ 2. NOTIFY MANAGERS
        try {
          // Finds all users marked as "Sales Manager"
          final managerSnapshot = await _db.collection('users').where('Role', isEqualTo: 'Sales Manager').get();

          for (var managerDoc in managerSnapshot.docs) {
            await _db.collection('notifications').add({
              'targetUserId': managerDoc.id,
              'title': 'New Order Alert 🚨',
              'message': '$agentName just placed Order $newOrderId.',
              'timestamp': FieldValue.serverTimestamp(),
              'isRead': false,
            });
          }
        } catch (e) {
          debugPrint("Could not notify manager: $e");
        }

        // ✅ 3. NOTIFY THE ASSOCIATE (Confirmation)
        await _db.collection('notifications').add({
          'targetUserId': userId,
          'title': 'Order Placed ✅',
          'message': 'Your order $newOrderId has been sent to the Manager for approval.',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });

        Get.snackbar("Success", "Order saved securely!", backgroundColor: Colors.green, colorText: Colors.white);
      }
      clearForm();

    } catch (e) {
      Get.snackbar("Error", "Action failed: $e", backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  void clearForm() {
    orderNo.clear();
    clientName.clear();
    organization.clear();
    phone.clear();
    address.clear();
    deadline.clear();
    shippingCharge.clear();
    advanceAmount.clear();

    items.clear();
    addNewItem();

    _selectedDeadline = null;
    selectedImagePath.value = '';
    existingImageUrl.value = ''; // ✅ Clear
    subTotal.value = 0.0;
    taxAmount.value = 0.0;
    grandTotal.value = 0.0;
    balanceDue.value = 0.0;
    isEditing.value = false;
    editingOrderId = null;

    fetchLastOrderSerial();
  }
}