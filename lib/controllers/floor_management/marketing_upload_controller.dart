import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/order_model.dart';
import '../../data/services/api_service.dart';

class ProductItemForm {
  final productDetails = TextEditingController(text: 'T-Shirt');
  final selectedNeckType = Rxn<String>('Round Neck');
  final selectedProductType = Rxn<String>('T-Shirt');
  final selectedFabric = Rxn<String>('PC Matty');
  final selectedColor = Rxn<String>('Black');
  final customColor = TextEditingController();
  final sizeDescription = TextEditingController();
  final productCode = TextEditingController();
  final quantity = TextEditingController(text: '10');
  final orderValue = TextEditingController(text: '250');
  final gstInfo = TextEditingController(text: '5');
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
  final subTotal = 0.0.obs;
  final taxAmount = 0.0.obs;
  final grandTotal = 0.0.obs;
  final balanceDue = 0.0.obs;

  RxBool get isLoading => isSubmitting;
  List<String> get neckTypes => ['Round Neck', 'Polo', 'V-Neck', 'Hoodie'];
  List<String> get productTypes => ['T-Shirt', 'Polo', 'Hoodie', 'Sweatshirt'];
  List<String> get fabricOptions => ['PC Matty', 'Spun Matty', 'Nokia', 'Dotknit'];
  List<String> get colorOptions => ['Black', 'White', 'Navy', 'Red', 'Royal Blue', 'Custom/Mixed'];

  void removeItem(int index) {
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
    }
  }

  void addNewItem() => addDefaultProductRow();

  var lastOrderSerial = 'ZBR001'.obs;
  var selectedState = Rxn<String>();
  List<String> get indianStates => ['Maharashtra', 'Delhi', 'Gujarat', 'Karnataka', 'Tamil Nadu'];

  void loadOrderData(dynamic order) {}
  void clearForm() {}
  Future<void> fetchLastOrderSerial() async {}
  Future<void> pickAndUploadMockup() async {}
  void removeMockup() {
    uploadedMockupUrl.value = '';
    mockupImage.value = null;
  }

  Future<void> chooseDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) selectedDeliveryDate.value = picked;
  }

  @override
  void onInit() {
    super.onInit();
    addDefaultProductRow();
  }

  void addDefaultProductRow() {
    items.add(ProductItemForm());
  }

  Future<void> submitOrder([dynamic existingOrderOrContext]) async {
    if (uploadFormKey.currentState != null && !uploadFormKey.currentState!.validate()) return;

    try {
      isSubmitting.value = true;
      final user = ApiService.currentUser;
      final marketingPersonName = user != null ? (user['name'] ?? user['FullName'] ?? 'Sales Associate') : 'Sales Associate';

      final Map<String, dynamic> orderPayload = {
        'client_name': clientName.text.trim(),
        'client_phone': phone.text.trim(),
        'organization': organization.text.trim(),
        'client_address': address.text.trim(),
        'client_gst_number': clientGstNumber.text.trim(),
        'pincode': pincode.text.trim(),
        'product_name': items.isNotEmpty ? items[0].productDetails.text.trim() : 'T-Shirt',
        'product_details': 'Dynamic Product Order',
        'quantity': items.fold<int>(0, (sum, p) => sum + (int.tryParse(p.quantity.text.trim()) ?? 0)),
        'priority': selectedPriority.value,
        'status': 'Pending',
        'total_amount': 5000.0,
        'shipping_charge': double.tryParse(shippingCharge.text.trim()) ?? 0.0,
        'advance_amount': double.tryParse(advanceAmount.text.trim()) ?? 0.0,
        'balance_due': 5000.0 - (double.tryParse(advanceAmount.text.trim()) ?? 0.0),
        'effective_revenue': 5000.0,
        'marketing_person_name': marketingPersonName,
        'delivery_date': (selectedDeliveryDate.value ?? DateTime.now().add(const Duration(days: 7))).toIso8601String(),
      };

      final response = await ApiService.post('/orders', orderPayload);

      if (response['success'] == true) {
        Get.snackbar("Order Submitted", "Order has been created successfully", backgroundColor: Colors.green, colorText: Colors.white);
        Get.back();
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to save order: $e", backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isSubmitting.value = false;
    }
  }
}