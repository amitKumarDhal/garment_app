import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/order_model.dart';
import '../../utils/constants/colors.dart';
import '../../utils/widgets/custom_text_field.dart';

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

  // ✅ NEW: Added GST Controller
  final clientGstNumber = TextEditingController();

  final phone = TextEditingController();
  final address = TextEditingController();
  final deadline = TextEditingController();

  final pincode = TextEditingController();
  final selectedState = "".obs;

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

    pincode.addListener(() {
      String pin = pincode.text.trim();
      if (pin.length == 6) {
        _fetchStateFromPincode(pin);
      } else if (pin.length < 6) {
        selectedState.value = "";
      }
    });
  }

  Future<void> _fetchStateFromPincode(String pin) async {
    try {
      final response = await GetConnect().get('https://api.postalpincode.in/pincode/$pin');

      if (response.body != null &&
          response.body is List &&
          response.body[0]['Status'] == 'Success') {
        final String fetchedState = response.body[0]['PostOffice'][0]['State'];
        selectedState.value = fetchedState;
      } else {
        selectedState.value = "";
      }
    } catch (e) {
      debugPrint("PIN fetch error: $e");
    }
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
    advanceAmount.text = "0";

    final orderJson = order.toJson();
    pincode.text = orderJson['pincode'] ?? "";
    selectedState.value = orderJson['state'] ?? "";

    // ✅ NEW: Load the GST Number safely from the database
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
    if (_selectedDeadline == null) {
      Get.snackbar("Missing Date", "Please select a delivery deadline.", backgroundColor: Colors.redAccent.withValues(alpha: 0.1), colorText: Colors.redAccent);
      return;
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

        // ✅ NEW: Saves the GST Number into the database map
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
        "marketingPersonName": agentName,
        "marketingPersonId": userId,
        "products": productsList,
        "mockupUrl": uploadedMockupUrl.value.isEmpty ? null : uploadedMockupUrl.value,
      };

      if (isEditing.value && editingOrderId != null) {
        orderMap['manualOrderNo'] = orderNo.text.trim();
        await _db.collection('orders').doc(editingOrderId).update(orderMap);

        try {
          final managerSnapshot = await _db.collection('users').where('Role', isEqualTo: 'Sales Manager').get();
          for (var managerDoc in managerSnapshot.docs) {
            await _db.collection('notifications').add({
              'targetUserId': managerDoc.id,
              'title': 'Order Updated 🔄',
              'message': '$agentName modified the details for Order ${orderNo.text.trim()}.',
              'orderId': editingOrderId,
              'timestamp': FieldValue.serverTimestamp(),
              'isRead': false,
            });
          }
        } catch (e) {}

        Get.snackbar("Success", "Order updated successfully!", backgroundColor: Colors.green, colorText: Colors.white);
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
    selectedState.value = "";

    // ✅ NEW: Clears GST field
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