import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/api_service.dart';

class FinishingController extends GetxController {
  final checkerName = TextEditingController();
  final styleNo = TextEditingController();
  final receivedQty = TextEditingController();
  final ironedQty = TextEditingController();
  final packedQty = TextEditingController();
  final defectiveQty = TextEditingController();
  final isLoading = false.obs;
  final finishingFormKey = GlobalKey<FormState>();
  GlobalKey<FormState> get formKey => finishingFormKey;

  Future<void> submitFinishingEntry([dynamic orderId]) async {
    try {
      isLoading.value = true;
      final res = await ApiService.post('/production/finishing', {
        'order_id': orderId?.toString(),
        'checker_name': checkerName.text.trim(),
        'style_no': styleNo.text.trim(),
        'received_qty': int.tryParse(receivedQty.text.trim()) ?? 0,
        'ironed_qty': int.tryParse(ironedQty.text.trim()) ?? 0,
        'packed_qty': int.tryParse(packedQty.text.trim()) ?? 0,
        'defective_qty': int.tryParse(defectiveQty.text.trim()) ?? 0,
      });

      if (res['success'] == true) {
        Get.snackbar("Success", "Finishing entry saved", backgroundColor: Colors.green.withValues(alpha: 0.1));
        Get.back();
      }
    } catch (e) {
      Get.snackbar("Error", "Failed: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
