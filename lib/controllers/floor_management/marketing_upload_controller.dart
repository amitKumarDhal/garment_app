import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/order_model.dart';
import '../../services/stats_service.dart';

// =========================================================================
// ✅ 1. HELPER CLASS FOR DYNAMIC ITEMS
// =========================================================================
class OrderItemForm {
  final productCode = TextEditingController();
  final productDetails = TextEditingController();
  final sizeDescription = TextEditingController();
  final quantity = TextEditingController();
  final orderValue = TextEditingController();
  final gstInfo = TextEditingController();

  final customColor = TextEditingController();

  final selectedNeckType = Rx<String?>(null);
  final selectedProductType = Rx<String?>(null);
  final selectedColor = Rx<String?>(null);

  final selectedFabric = Rx<String?>(null);

  void dispose() {
    productCode.dispose();
    productDetails.dispose();
    sizeDescription.dispose();
    quantity.dispose();
    orderValue.dispose();
    gstInfo.dispose();
    customColor.dispose();
  }
}

// =========================================================================
// ✅ 2. THE CONTROLLER
// =========================================================================
class MarketingUploadController extends GetxController {
  static MarketingUploadController get instance => Get.find();

  final uploadFormKey = GlobalKey<FormState>();
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // --- Client Info Controllers ---
  final orderNo = TextEditingController();
  final clientName = TextEditingController();
  final organization = TextEditingController();
  final clientGstNumber = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  final deadline = TextEditingController();
  final pincode = TextEditingController();

  final Rx<String?> selectedState = Rx<String?>(null);

  final List<String> indianStates = [
    'Andaman and Nicobar Islands', 'Andhra Pradesh', 'Arunachal Pradesh', 'Assam',
    'Bihar', 'Chandigarh', 'Chhattisgarh', 'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi', 'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jammu and Kashmir',
    'Jharkhand', 'Karnataka', 'Kerala', 'Ladakh', 'Lakshadweep', 'Madhya Pradesh',
    'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha',
    'Puducherry', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana',
    'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal'
  ];

  // --- Financial Global Controllers ---
  final shippingCharge = TextEditingController();
  final advanceAmount = TextEditingController();

  // Dropdown Options
  final List<String> neckTypes = ['Round Neck', 'Collared Neck'];
  final List<String> productTypes = [
    'Sports Jersey',
    'Business Promotional',
    'Team/Staff Wear',
    'Specific Event Use'
  ];

  final List<String> fabricOptions = [
    'Dotknit (160 gsm)',
    'Nokia (120 gsm)',
    'Spun matty (220 gsm)',
    'Pc matty (240 gsm)',
    'Polyester collar',
    'Acrylic collar',
    'Others'
  ];

  final List<String> colorOptions = [
    'White', 'Off white', 'Beige', 'Light grey', 'Dark grey', 'Black',
    'Sky blue', 'Ocean blue', 'Royal blue', 'Navy blue', 'Neon green',
    'Green', 'Bottle green', 'Lemon yellow', 'Yellow', 'Mustard yellow',
    'Orange', 'Red', 'Maroon', 'Pink', 'Light pink', 'Brown', 'Purple',
    'Lavender', 'Custom/Mixed'
  ];

  final items = <OrderItemForm>[].obs;
  final isLoading = false.obs;
  DateTime? _selectedDeadline;

  final isEditing = false.obs;
  String? editingOrderId;

  String? originalMarketingPersonName;
  String? originalMarketingPersonId;

  final RxString uploadedMockupUrl = ''.obs;
  final RxBool isUploadingMockup = false.obs;

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

    originalMarketingPersonName = order.marketingPersonName;
    originalMarketingPersonId = order.marketingPersonId;

    orderNo.text = order.manualOrderNo ?? "";
    clientName.text = order.clientName;
    organization.text = order.organization ?? "";
    phone.text = order.clientPhone ?? "";
    address.text = order.clientAddress ?? "";
    shippingCharge.text = order.shippingCharge.toString();

    // ✅ FIX 1: Load the actual advance amount so the math doesn't break!
    advanceAmount.text = order.advanceAmount.toString();

    final orderJson = order.toJson();
    pincode.text = orderJson['pincode'] ?? "";

    String loadedState = orderJson['state'] ?? "";
    if (indianStates.contains(loadedState)) {
      selectedState.value = loadedState;
    } else {
      selectedState.value = null;
    }

    clientGstNumber.text = orderJson['clientGstNumber'] ?? "";
    uploadedMockupUrl.value = order.mockupUrl ?? orderJson['designMockupUrl'] ?? '';

    _selectedDeadline = order.deliveryDate;
    if (_selectedDeadline != null) {
      deadline.text = "${_selectedDeadline!.day} ${_getMonthName(_selectedDeadline!.month)} ${_selectedDeadline!.year}";
    }

    items.clear();
    for (var prod in order.products) {
      final itemForm = OrderItemForm();
      itemForm.productCode.text = prod['productCode'] ?? "";
      itemForm.productDetails.text = prod['productName'] ?? "";
      itemForm.sizeDescription.text = prod['sizeDescription'] ?? "";
      itemForm.quantity.text = (prod['qty'] ?? 0).toString();
      itemForm.orderValue.text = (prod['price'] ?? 0.0).toStringAsFixed(2);
      itemForm.gstInfo.text = (prod['gstPercentage'] ?? 0.0).toString();

      itemForm.selectedNeckType.value = prod['neckType'];
      itemForm.selectedProductType.value = prod['productType'];

      String loadedFabric = prod['fabricType'] ?? '';
      if (loadedFabric.isNotEmpty && loadedFabric != 'Not Specified' && fabricOptions.contains(loadedFabric)) {
        itemForm.selectedFabric.value = loadedFabric;
      }

      String loadedColor = prod['color'] ?? '';
      if (loadedColor.isNotEmpty && loadedColor != 'Not Specified') {
        if (!colorOptions.contains(loadedColor)) {
          itemForm.selectedColor.value = 'Custom/Mixed';
          itemForm.customColor.text = loadedColor;
        } else {
          itemForm.selectedColor.value = loadedColor;
        }
      }

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

  Future<void> pickAndUploadMockup() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;

    try {
      isUploadingMockup.value = true;
      const String cloudName = "dt2yfdelm";
      const String uploadPreset = "yoobbel_mockups";

      var uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");
      var request = http.MultipartRequest("POST", uri);
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.toBytes();
        var result = json.decode(String.fromCharCodes(responseData));
        uploadedMockupUrl.value = result['secure_url'];
        Get.snackbar("Success", "Mockup uploaded successfully!", backgroundColor: Colors.green.withValues(alpha: 0.1), colorText: Colors.green);
      } else {
        Get.snackbar("Upload Failed", "Could not upload to Cloudinary.", backgroundColor: Colors.redAccent.withValues(alpha: 0.1), colorText: Colors.redAccent);
      }
    } catch (e) {
      Get.snackbar("Error", "Something went wrong: $e", backgroundColor: Colors.redAccent.withValues(alpha: 0.1), colorText: Colors.redAccent);
    } finally {
      isUploadingMockup.value = false;
    }
  }

  void removeMockup() {
    uploadedMockupUrl.value = '';
  }

  void submitOrder() async {
    if (!uploadFormKey.currentState!.validate()) return;

    if (pincode.text.trim().length < 6) {
      Get.snackbar("Missing Pincode", "Please enter a valid 6-digit Pincode.", backgroundColor: Colors.redAccent.withValues(alpha: 0.1), colorText: Colors.redAccent, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    if (selectedState.value == null || selectedState.value!.isEmpty) {
      Get.snackbar("Missing State", "Please select a state from the dropdown.", backgroundColor: Colors.redAccent.withValues(alpha: 0.1), colorText: Colors.redAccent, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    if (_selectedDeadline == null) {
      Get.snackbar("Missing Date", "Please select a delivery deadline.", backgroundColor: Colors.redAccent.withValues(alpha: 0.1), colorText: Colors.redAccent, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.selectedProductType.value == null || item.selectedProductType.value!.isEmpty) {
        Get.snackbar("Missing Category", "Please select a Category (Product Type) for Item ${i + 1}.", backgroundColor: Colors.redAccent.withValues(alpha: 0.1), colorText: Colors.redAccent, snackPosition: SnackPosition.BOTTOM);
        return;
      }
      if (item.selectedFabric.value == null || item.selectedFabric.value!.isEmpty) {
        Get.snackbar("Missing Fabric", "Please select a Fabric Type for Item ${i + 1}.", backgroundColor: Colors.redAccent.withValues(alpha: 0.1), colorText: Colors.redAccent, snackPosition: SnackPosition.BOTTOM);
        return;
      }
    }

    try {
      isLoading.value = true;
      final user = _auth.currentUser;

      String agentName = originalMarketingPersonName ?? "Agent";
      String userId = originalMarketingPersonId ?? user?.uid ?? "";

      if (!isEditing.value && user != null) {
        try {
          final userDoc = await _db.collection('id_requests').doc(user.uid).get();
          if (userDoc.exists) {
            agentName = userDoc.data()?['name'] ?? user.displayName ?? "Agent";
          }
        } catch (e) {}
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

        String finalColor = item.selectedColor.value ?? 'Not Specified';
        if (finalColor == 'Custom/Mixed' && item.customColor.text.trim().isNotEmpty) {
          finalColor = item.customColor.text.trim();
        }

        productsList.add({
          "productCode": item.productCode.text.trim(),
          "productName": item.productDetails.text.trim(),
          "sizeDescription": item.sizeDescription.text.trim(),
          "qty": qty,
          "price": price,
          "gstPercentage": gst,
          "total": itemTotal,
          "neckType": item.selectedNeckType.value ?? 'Not Specified',
          "productType": item.selectedProductType.value ?? 'Not Specified',
          "color": finalColor,
          "fabricType": item.selectedFabric.value ?? 'Not Specified',
        });
      }

      String rootProductName = items.length > 1 ? "$firstProductName + ${items.length - 1} more" : firstProductName;
      double advance = double.tryParse(advanceAmount.text.trim()) ?? 0.0;

      final orderMap = {
        "clientName": clientName.text.trim(),
        "clientPhone": phone.text.trim(),
        "organization": organization.text.trim(),
        "clientAddress": address.text.trim(),
        "pincode": pincode.text.trim(),
        "state": selectedState.value,
        "clientGstNumber": clientGstNumber.text.trim(),
        "productCode": items.first.productCode.text.trim(),
        "productDetails": rootProductName,
        "productName": rootProductName,
        "quantity": totalQty,
        "gstPercentage": avgGst,
        "priority": "Medium",
        "deliveryDate": Timestamp.fromDate(_selectedDeadline!),
        "shippingCharge": double.tryParse(shippingCharge.text.trim()) ?? 0.0,
        "totalAmount": grandTotal.value,
        "balanceDue": balanceDue.value,
        "effectiveRevenue": grandTotal.value,
        "marketingPersonName": agentName,
        "marketingPersonId": userId,
        "products": productsList,
        "mockupUrl": uploadedMockupUrl.value.isEmpty ? null : uploadedMockupUrl.value,
      };

      if (isEditing.value && editingOrderId != null) {
        orderMap['manualOrderNo'] = orderNo.text.trim();
        orderMap['status'] = 'Pending';
        orderMap['isEdited'] = true;

        // Ensure advance is saved accurately on edit
        orderMap['advanceAmount'] = advance;

        await _db.collection('orders').doc(editingOrderId).update(orderMap);

        // ✅ FIX 2: Generate an explicit approval request for the Sales Manager
        await _db.collection('payment_requests').add({
          'orderId': editingOrderId,
          'manualOrderNo': orderNo.text.trim(),
          'clientName': clientName.text.trim(),
          'agentName': agentName,
          'amount': advance,
          'status': 'pending',
          'isEditRequest': true, // Helps manager know it's an edit
          'requestedAt': FieldValue.serverTimestamp(),
        });

        try {
          final managerSnapshot = await _db.collection('users').where('Role', isEqualTo: 'Sales Manager').get();
          for (var managerDoc in managerSnapshot.docs) {
            await _db.collection('notifications').add({
              'targetUserId': managerDoc.id,
              'title': 'Order Updated 🔄',
              'message': '$agentName modified the details for Order ${orderNo.text.trim()}. It requires re-approval.',
              'orderId': editingOrderId,
              'timestamp': FieldValue.serverTimestamp(),
              'isRead': false,
            });
          }
        } catch (e) {}

        Get.snackbar("Success", "Order updated and sent for re-approval!", backgroundColor: Colors.green, colorText: Colors.white);
      }
      else {
        String newOrderId = "";
        String generatedDocId = "";

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

          orderMap['advanceAmount'] = 0.0;
          orderMap['balanceDue'] = grandTotal.value;
          orderMap['status'] = advance > 0 ? "Pending" : "Placed";

          DocumentReference newOrderRef = _db.collection('orders').doc();
          generatedDocId = newOrderRef.id;
          transaction.set(newOrderRef, orderMap);
        });

        await StatsService.updateMonthlyStats(
          agentName: agentName,
          orderDate: DateTime.now(),
          amountChange: grandTotal.value,
          countChange: 1,
        );

        if (advance > 0 && generatedDocId.isNotEmpty) {
          await _db.collection('payment_requests').add({
            'orderId': generatedDocId,
            'manualOrderNo': newOrderId,
            'clientName': clientName.text.trim(),
            'agentName': agentName,
            'amount': advance,
            'status': 'pending',
            'requestedAt': FieldValue.serverTimestamp(),
          });

          final managerSnapshot = await _db.collection('users').where('Role', isEqualTo: 'Sales Manager').get();
          for (var managerDoc in managerSnapshot.docs) {
            await _db.collection('notifications').add({
              'targetUserId': managerDoc.id,
              'title': 'New Order + Payment 💰',
              'message': '$agentName created Order $newOrderId and collected ₹$advance.',
              'orderId': generatedDocId,
              'timestamp': FieldValue.serverTimestamp(),
              'isRead': false,
            });
          }
        } else {
          final managerSnapshot = await _db.collection('users').where('Role', isEqualTo: 'Sales Manager').get();
          for (var managerDoc in managerSnapshot.docs) {
            await _db.collection('notifications').add({
              'targetUserId': managerDoc.id,
              'title': 'New Order Alert 🚨',
              'message': '$agentName just placed Order $newOrderId.',
              'orderId': generatedDocId,
              'timestamp': FieldValue.serverTimestamp(),
              'isRead': false,
            });
          }
        }

        Get.snackbar("Success", advance > 0 ? "Order saved! Advance payment sent for approval." : "Order saved securely!", backgroundColor: Colors.green, colorText: Colors.white);
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
    pincode.clear();

    selectedState.value = null;

    clientGstNumber.clear();

    items.clear();
    addNewItem();

    _selectedDeadline = null;
    uploadedMockupUrl.value = '';
    isUploadingMockup.value = false;

    subTotal.value = 0.0;
    taxAmount.value = 0.0;
    grandTotal.value = 0.0;
    balanceDue.value = 0.0;
    isEditing.value = false;
    editingOrderId = null;

    originalMarketingPersonName = null;
    originalMarketingPersonId = null;

    fetchLastOrderSerial();
  }
}