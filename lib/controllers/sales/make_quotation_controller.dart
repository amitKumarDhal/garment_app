import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// ✅ IMPORT THE PDF SERVICE
import '../../services/pdf_invoice_service.dart';

// A simple model to hold the text controllers for each dynamic item row
class QuotationItemModel {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController priceCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController(text: '1');
  final TextEditingController gstCtrl = TextEditingController(text: '0'); // GST %
}

class MakeQuotationController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Static Fields ---
  final quotationNoCtrl = TextEditingController();
  final clientNameCtrl = TextEditingController();
  final clientAddressCtrl = TextEditingController();
  final clientGstCtrl = TextEditingController();
  final shippingCtrl = TextEditingController(text: '0');

  // --- Dynamic Items List ---
  var items = <QuotationItemModel>[].obs;

  // --- Calculated Totals ---
  var subTotal = 0.0.obs;
  var totalGst = 0.0.obs;
  var shippingCharge = 0.0.obs;
  var grandTotal = 0.0.obs;

  var isSaving = false.obs;
  var isLoadingInitialData = true.obs;

  @override
  void onInit() {
    super.onInit();
    _fetchNextQuotationNumber();

    // Start with one empty item
    addNewItem();

    // Listen to shipping changes
    shippingCtrl.addListener(_calculateTotals);
  }

  // ===========================================================================
  // ✅ AUTO-FETCH SEQUENTIAL QUOTATION NUMBER (YBL + YY + 001)
  // ===========================================================================
  Future<void> _fetchNextQuotationNumber() async {
    try {
      // 1. Generate the prefix based on current Year (e.g., "26" for 2026)
      String year = DateFormat('yy').format(DateTime.now());
      String prefix = "YBL$year"; // Result: YBL26

      // 2. Query the database for the highest quotation number THAT STARTS WITH this prefix
      // This automatically limits the search to the current year!
      final querySnapshot = await _db.collection('quotations')
          .where('quotationNo', isGreaterThanOrEqualTo: prefix)
          .where('quotationNo', isLessThan: '$prefix\uf8ff')
          .orderBy('quotationNo', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // 3. A quotation exists for this year! Get the string (e.g., "YBL26004")
        String lastQtnString = querySnapshot.docs.first.data()['quotationNo'] ?? "";

        // 4. Extract the last 3 characters (the serial number) and increment
        if (lastQtnString.length >= 3) {
          String serialPart = lastQtnString.substring(lastQtnString.length - 3);
          int lastNumber = int.tryParse(serialPart) ?? 0;
          int nextNumber = lastNumber + 1;

          // 5. Format back to 3 digits (e.g., 5 becomes "005")
          String nextSerial = nextNumber.toString().padLeft(3, '0');
          quotationNoCtrl.text = "$prefix$nextSerial";
        } else {
          quotationNoCtrl.text = "${prefix}001";
        }
      } else {
        // 6. Database has no quotations for this year yet. Start at 001!
        quotationNoCtrl.text = "${prefix}001";
      }
    } catch (e) {
      debugPrint("Error fetching next QTN number: $e");
      // Fallback if the database read fails
      String year = DateFormat('yy').format(DateTime.now());
      quotationNoCtrl.text = "YBL${year}001";
    } finally {
      isLoadingInitialData.value = false;
    }
  }

  void addNewItem() {
    final newItem = QuotationItemModel();
    // Add listeners so totals update automatically when the user types
    newItem.priceCtrl.addListener(_calculateTotals);
    newItem.qtyCtrl.addListener(_calculateTotals);
    newItem.gstCtrl.addListener(_calculateTotals);
    items.add(newItem);
    _calculateTotals();
  }

  void removeItem(int index) {
    if (items.length > 1) {
      items[index].priceCtrl.dispose();
      items[index].qtyCtrl.dispose();
      items[index].gstCtrl.dispose();
      items.removeAt(index);
      _calculateTotals();
    } else {
      Get.snackbar("Hold on", "You must have at least one item in the quotation.");
    }
  }

  void _calculateTotals() {
    double tempSubTotal = 0.0;
    double tempGst = 0.0;

    for (var item in items) {
      double price = double.tryParse(item.priceCtrl.text) ?? 0.0;
      double qty = double.tryParse(item.qtyCtrl.text) ?? 0.0;
      double gstPercent = double.tryParse(item.gstCtrl.text) ?? 0.0;

      double itemTotal = price * qty;
      double itemGst = itemTotal * (gstPercent / 100);

      tempSubTotal += itemTotal;
      tempGst += itemGst;
    }

    subTotal.value = tempSubTotal;
    totalGst.value = tempGst;
    shippingCharge.value = double.tryParse(shippingCtrl.text) ?? 0.0;
    grandTotal.value = subTotal.value + totalGst.value + shippingCharge.value;
  }

  Future<void> saveAndGenerateQuotation() async {
    if (clientNameCtrl.text.trim().isEmpty) {
      Get.snackbar("Missing Info", "Please enter a Client Name.", backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    isSaving.value = true;

    try {
      // 1. Prepare Item Data
      List<Map<String, dynamic>> itemsData = items.map((item) => {
        'name': item.nameCtrl.text.trim(),
        'price': double.tryParse(item.priceCtrl.text) ?? 0.0,
        'quantity': int.tryParse(item.qtyCtrl.text) ?? 1,
        'gstPercent': double.tryParse(item.gstCtrl.text) ?? 0.0,
      }).toList();

      // 2. Prepare Final Document
      Map<String, dynamic> quotationData = {
        'quotationNo': quotationNoCtrl.text.trim(),
        'clientName': clientNameCtrl.text.trim(),
        'clientAddress': clientAddressCtrl.text.trim(),
        'clientGst': clientGstCtrl.text.trim(),
        'items': itemsData,
        'subTotal': subTotal.value,
        'totalGst': totalGst.value,
        'shipping': shippingCharge.value,
        'grandTotal': grandTotal.value,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'Draft',
      };

      // 3. Save to Firebase
      await _db.collection('quotations').doc(quotationNoCtrl.text.trim()).set(quotationData);

      Get.snackbar("Success", "Quotation saved to database!", backgroundColor: Colors.green, colorText: Colors.white);

      // ✅ 4. GENERATE AND DOWNLOAD PDF
      await PdfInvoiceService.generateQuotationPdf(quotationData);

    } catch (e) {
      Get.snackbar("Error", "Failed to save quotation: $e");
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    quotationNoCtrl.dispose();
    clientNameCtrl.dispose();
    clientAddressCtrl.dispose();
    clientGstCtrl.dispose();
    shippingCtrl.dispose();
    for (var item in items) {
      item.nameCtrl.dispose();
      item.priceCtrl.dispose();
      item.qtyCtrl.dispose();
      item.gstCtrl.dispose();
    }
    super.onClose();
  }
}