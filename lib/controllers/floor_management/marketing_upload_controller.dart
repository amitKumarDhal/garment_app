import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/order_model.dart';
import '../../data/services/api_service.dart';
import '../../utils/constants/app_constants.dart';

class ProductItemForm {
  final productDetails = TextEditingController(text: 'Polo T-Shirt');
  final selectedNeckType = Rxn<String>('Polo');
  final selectedProductType = Rxn<String>('Polo');
  final selectedFabric = Rxn<String>('Spun Matty');
  final selectedColor = Rxn<String>('Black');
  final customColor = TextEditingController();
  final sizeDescription = TextEditingController();
  final productCode = TextEditingController();
  final quantity = TextEditingController(text: '10');
  final orderValue = TextEditingController(text: '250');
  final gstInfo = TextEditingController(text: '5');

  VoidCallback? _listener;

  void attachListener(VoidCallback listener) {
    _listener = listener;
    quantity.addListener(listener);
    orderValue.addListener(listener);
    gstInfo.addListener(listener);
  }

  void dispose() {
    if (_listener != null) {
      quantity.removeListener(_listener!);
      orderValue.removeListener(_listener!);
      gstInfo.removeListener(_listener!);
    }
    productDetails.dispose();
    customColor.dispose();
    sizeDescription.dispose();
    productCode.dispose();
    quantity.dispose();
    orderValue.dispose();
    gstInfo.dispose();
  }
}

class MarketingUploadController extends GetxController {
  static MarketingUploadController get instance => Get.find();

  final uploadFormKey = GlobalKey<FormState>();

  final orderNo = TextEditingController();
  final clientName = TextEditingController();
  final organization = TextEditingController();
  final clientGstNumber = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  final deadline = TextEditingController();
  final pincode = TextEditingController();

  final shippingCharge = TextEditingController(text: "0");
  final advanceAmount = TextEditingController(text: "0");

  final isSubmitting = false.obs;
  final selectedPriority = 'Medium'.obs;
  final Rx<DateTime?> selectedDeliveryDate = Rx<DateTime?>(null);
  final Rx<File?> mockupImage = Rx<File?>(null);

  final items = <ProductItemForm>[].obs;

  final isUploadingMockup = false.obs;
  final uploadedMockupUrl = ''.obs;
  final isEditing = false.obs;
  String? editingOrderId;

  // Live financial observable totals
  final subTotal = 0.0.obs;
  final taxAmount = 0.0.obs;
  final grandTotal = 0.0.obs;
  final balanceDue = 0.0.obs;

  RxBool get isLoading => isSubmitting;

  // Centralized option lists
  List<String> get neckTypes => AppConstants.neckTypes;
  List<String> get productTypes => AppConstants.productTypes;
  List<String> get fabricOptions => AppConstants.materialOptions;
  List<String> get colorOptions => AppConstants.colorOptions;
  List<String> get indianStates => AppConstants.indianStates;

  var lastOrderSerial = 'ZBR001'.obs;
  var selectedState = Rxn<String>('Odisha');
  var selectedDistrict = Rxn<String>();

  List<String> get availableDistricts => AppConstants.getDistrictsForState(selectedState.value);

  @override
  void onInit() {
    super.onInit();
    shippingCharge.addListener(calculateTotals);
    advanceAmount.addListener(calculateTotals);

    addDefaultProductRow();
    fetchLastOrderSerial();
  }

  void onStateChanged(String? newState) {
    selectedState.value = newState;
    selectedDistrict.value = null;
  }

  void addDefaultProductRow() {
    final newItem = ProductItemForm();
    newItem.attachListener(calculateTotals);
    items.add(newItem);
    calculateTotals();
  }

  void addNewItem() {
    addDefaultProductRow();
  }

  void removeItem(int index) {
    if (items.length > 1 && index >= 0 && index < items.length) {
      final itemToRemove = items[index];
      items.removeAt(index);
      itemToRemove.dispose();
      calculateTotals();
    } else if (items.length <= 1) {
      Get.snackbar("Notice", "An order must contain at least one product item.",
          backgroundColor: Colors.orange, colorText: Colors.white);
    }
  }

  // ===========================================================================
  // LIVE FINANCIAL CALCULATION
  // ===========================================================================
  void calculateTotals() {
    double runningSubTotal = 0.0;
    double runningTaxAmount = 0.0;

    for (final item in items) {
      final double price = double.tryParse(item.orderValue.text.trim()) ?? 0.0;
      final double qty = double.tryParse(item.quantity.text.trim()) ?? 0.0;
      final double gstPct = double.tryParse(item.gstInfo.text.trim()) ?? 0.0;

      final double itemBase = price * qty;
      final double itemGst = itemBase * (gstPct / 100.0);

      runningSubTotal += itemBase;
      runningTaxAmount += itemGst;
    }

    final double shipping = double.tryParse(shippingCharge.text.trim()) ?? 0.0;
    final double advance = double.tryParse(advanceAmount.text.trim()) ?? 0.0;

    final double computedGrandTotal = runningSubTotal + runningTaxAmount + shipping;
    final double computedBalanceDue = computedGrandTotal - advance;

    subTotal.value = runningSubTotal;
    taxAmount.value = runningTaxAmount;
    grandTotal.value = computedGrandTotal;
    balanceDue.value = computedBalanceDue;
  }

  // ===========================================================================
  // CLOUDINARY MOCKUP UPLOAD (END-TO-END)
  // ===========================================================================
  Future<void> pickAndUploadMockup() async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      if (!await file.exists()) {
        Get.snackbar("File Error", "Selected file could not be read.",
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      mockupImage.value = file;
      isUploadingMockup.value = true;

      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      final extension = pickedFile.name.split('.').last.toLowerCase();
      final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';
      final dataUri = 'data:$mimeType;base64,$base64String';

      final response = await ApiService.post('/media/upload', {
        'file': dataUri,
        'folder': 'yoobbel_mockups',
      });

      if (response['success'] == true && response['data'] != null) {
        final url = response['data']['url']?.toString() ?? '';
        if (url.isNotEmpty) {
          uploadedMockupUrl.value = url;
          Get.snackbar("Success", "Mockup image uploaded to Cloudinary successfully",
              backgroundColor: Colors.green, colorText: Colors.white);
        } else {
          throw Exception("No secure URL returned from upload");
        }
      } else {
        throw Exception(response['message'] ?? 'Mockup upload failed');
      }
    } catch (e) {
      Get.snackbar("Upload Error", "Failed to upload mockup: $e",
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isUploadingMockup.value = false;
    }
  }

  void removeMockup() {
    uploadedMockupUrl.value = '';
    mockupImage.value = null;
  }

  Future<void> fetchLastOrderSerial() async {
    try {
      final res = await ApiService.get('/orders');
      if (res['success'] == true && res['data'] != null) {
        final list = res['data'] as List;
        if (list.isNotEmpty) {
          final first = list.first;
          final serial = first['manual_order_no'] ?? first['manualOrderNo'];
          if (serial != null && serial.toString().isNotEmpty) {
            lastOrderSerial.value = serial.toString();
          }
        }
      }
    } catch (_) {}
  }

  Future<void> chooseDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDeliveryDate.value ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      selectedDeliveryDate.value = picked;
      deadline.text = "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
    }
  }

  void loadOrderData(OrderModel order) {
    isEditing.value = true;
    editingOrderId = order.id;
    clientName.text = order.clientName;
    phone.text = order.clientPhone ?? '';
    organization.text = order.organization ?? '';
    address.text = order.clientAddress ?? '';
    clientGstNumber.text = order.clientGstNumber ?? '';
    pincode.text = order.pincode ?? '';
    if (order.state != null && order.state!.isNotEmpty) {
      selectedState.value = order.state;
    }
    selectedDeliveryDate.value = order.deliveryDate;
    deadline.text = "${order.deliveryDate.day.toString().padLeft(2, '0')}-${order.deliveryDate.month.toString().padLeft(2, '0')}-${order.deliveryDate.year}";
    shippingCharge.text = order.shippingCharge.toStringAsFixed(2);
    advanceAmount.text = order.advanceAmount.toStringAsFixed(2);

    if (order.mockupUrl != null && order.mockupUrl!.isNotEmpty) {
      uploadedMockupUrl.value = order.mockupUrl!;
    }

    // Populate products
    for (final item in items) {
      item.dispose();
    }
    items.clear();

    if (order.products.isNotEmpty) {
      for (final p in order.products) {
        final form = ProductItemForm();
        form.productDetails.text = p['productName'] ?? p['product_name'] ?? 'T-Shirt';
        form.selectedNeckType.value = p['neckType'] ?? p['neck_type'] ?? 'Polo';
        form.selectedProductType.value = p['productType'] ?? p['product_type'] ?? 'Polo';
        form.selectedFabric.value = p['fabricType'] ?? p['fabric_type'] ?? 'Spun Matty';

        final colorVal = p['color'] ?? 'Black';
        if (AppConstants.colorOptions.contains(colorVal)) {
          form.selectedColor.value = colorVal;
        } else {
          form.selectedColor.value = 'Other';
          form.customColor.text = colorVal;
        }

        form.sizeDescription.text = p['sizeDescription'] ?? p['size_description'] ?? '';
        form.productCode.text = p['productCode'] ?? p['product_code'] ?? '';
        form.quantity.text = (p['qty'] ?? p['quantity'] ?? 10).toString();
        form.orderValue.text = (p['price'] ?? 250).toString();
        form.gstInfo.text = (p['gstPercentage'] ?? p['gst_percentage'] ?? 5).toString();

        form.attachListener(calculateTotals);
        items.add(form);
      }
    } else {
      addDefaultProductRow();
    }

    calculateTotals();
  }

  void clearForm() {
    clientName.clear();
    phone.clear();
    organization.clear();
    address.clear();
    clientGstNumber.clear();
    pincode.clear();
    deadline.clear();
    shippingCharge.text = "0";
    advanceAmount.text = "0";
    selectedDeliveryDate.value = null;
    uploadedMockupUrl.value = '';
    mockupImage.value = null;
    isEditing.value = false;
    editingOrderId = null;

    for (final item in items) {
      item.dispose();
    }
    items.clear();
    addDefaultProductRow();
  }

  // ===========================================================================
  // SUBMIT ORDER
  // ===========================================================================
  Future<void> submitOrder([dynamic existingOrderOrContext]) async {
    if (uploadFormKey.currentState != null && !uploadFormKey.currentState!.validate()) {
      Get.snackbar("Validation Error", "Please fill all required fields correctly.",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    if (items.isEmpty) {
      Get.snackbar("Validation Error", "Please add at least one product item.",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    try {
      isSubmitting.value = true;
      calculateTotals();

      final pin = pincode.text.trim();
      final formattedPincode = pin.length == 6 ? pin : (pin.padRight(6, '0').substring(0, 6));

      // Build product items
      final List<Map<String, dynamic>> productsPayload = items.map((item) {
        final String effectiveColor = item.selectedColor.value == 'Other' && item.customColor.text.trim().isNotEmpty
            ? item.customColor.text.trim()
            : (item.selectedColor.value ?? 'Black');

        final int itemQty = int.tryParse(item.quantity.text.trim()) ?? 1;
        final double itemPrice = double.tryParse(item.orderValue.text.trim()) ?? 0.0;
        final double itemGst = double.tryParse(item.gstInfo.text.trim()) ?? 0.0;

        return {
          'productCode': item.productCode.text.trim().isNotEmpty ? item.productCode.text.trim() : null,
          'productName': item.productDetails.text.trim().isNotEmpty ? item.productDetails.text.trim() : 'Garment',
          'sizeDescription': item.sizeDescription.text.trim().isNotEmpty ? item.sizeDescription.text.trim() : null,
          'qty': itemQty > 0 ? itemQty : 1,
          'price': itemPrice >= 0 ? itemPrice : 0.0,
          'gstPercentage': itemGst >= 0 ? itemGst : 0.0,
          'neckType': item.selectedNeckType.value ?? 'Not Specified',
          'productType': item.selectedProductType.value ?? 'Polo',
          'color': effectiveColor,
          'fabricType': item.selectedFabric.value ?? 'Spun Matty',
        };
      }).toList();

      final deliveryIso = (selectedDeliveryDate.value ?? DateTime.now().add(const Duration(days: 7))).toUtc().toIso8601String();

      final Map<String, dynamic> orderPayload = {
        'clientName': clientName.text.trim(),
        'clientPhone': phone.text.trim().isNotEmpty ? phone.text.trim() : null,
        'organization': organization.text.trim().isNotEmpty ? organization.text.trim() : null,
        'clientAddress': address.text.trim().isNotEmpty ? address.text.trim() : null,
        'clientGstNumber': clientGstNumber.text.trim().isNotEmpty ? clientGstNumber.text.trim() : null,
        'pincode': formattedPincode.isNotEmpty ? formattedPincode : '751001',
        'state': selectedState.value ?? 'Odisha',
        'deliveryDate': deliveryIso,
        'shippingCharge': double.tryParse(shippingCharge.text.trim()) ?? 0.0,
        'advanceAmount': double.tryParse(advanceAmount.text.trim()) ?? 0.0,
        'mockupUrl': uploadedMockupUrl.value.isNotEmpty ? uploadedMockupUrl.value : null,
        'products': productsPayload,
      };

      Map<String, dynamic> response;
      if (isEditing.value && editingOrderId != null) {
        response = await ApiService.put('/orders/$editingOrderId', orderPayload);
      } else {
        response = await ApiService.post('/orders', orderPayload);
      }

      if (response['success'] == true) {
        Get.snackbar(
          isEditing.value ? "Order Updated" : "Order Submitted",
          isEditing.value ? "Order updated successfully" : "Order has been created successfully",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        clearForm();
        Get.back();
      } else {
        throw Exception(response['message'] ?? 'Failed to submit order');
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to save order: $e",
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    shippingCharge.removeListener(calculateTotals);
    advanceAmount.removeListener(calculateTotals);
    orderNo.dispose();
    clientName.dispose();
    organization.dispose();
    clientGstNumber.dispose();
    phone.dispose();
    address.dispose();
    deadline.dispose();
    pincode.dispose();
    shippingCharge.dispose();
    advanceAmount.dispose();

    for (final item in items) {
      item.dispose();
    }
    super.onClose();
  }
}