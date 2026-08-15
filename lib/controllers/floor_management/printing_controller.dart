import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/api_service.dart';

class PrintingController extends GetxController {
  final styleNo = TextEditingController();
  final receivedQty = TextEditingController();
  final isLoading = false.obs;

  Future<void> submitPrintingEntry(String? orderId) async {
    if (styleNo.text.trim().isEmpty) {
      Get.snackbar("Error", "Please enter style number");
      return;
    }

    try {
      isLoading.value = true;
      final recv = int.tryParse(receivedQty.text.trim()) ?? 0;

      final res = await ApiService.post('/production/printing', {
        'order_id': orderId,
        'style_no': styleNo.text.trim(),
        'received_from_cutting': recv,
        'damaged_quantities': {},
        'total_damaged': 0,
        'net_good_pieces': recv,
      });

      if (res['success'] == true) {
        Get.snackbar("Success", "Printing entry saved", backgroundColor: Colors.green.withValues(alpha: 0.1));
        Get.back();
      }
    } catch (e) {
      Get.snackbar("Error", "Failed: $e");
    } finally {
      isLoading.value = false;
    }
  }

  final printingFormKey = GlobalKey<FormState>();
  List<String> get printingTypes => ['Screen Printing', 'DTF', 'Sublimation', 'Embroidery'];
  final selectedPrintingType = Rxn<String>('Screen Printing');
  final damagedQuantities = <String, TextEditingController>{
    'S': TextEditingController(),
    'M': TextEditingController(),
    'L': TextEditingController(),
    'XL': TextEditingController(),
    'XXL': TextEditingController(),
  };

  void calculatePrintingTotals() {}
  TextEditingController get receivedFromCutting => receivedQty;
  var totalDamaged = 0.obs;
  var netGoodPieces = 0.obs;
  Future<void> submitPrintingData() async => await submitPrintingEntry(null);
}
