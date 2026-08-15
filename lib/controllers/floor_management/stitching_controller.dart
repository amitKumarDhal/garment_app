import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/api_service.dart';

class StitchingController extends GetxController {
  final operatorName = TextEditingController();
  final styleNo = TextEditingController();
  final operationType = TextEditingController();
  final assignedQty = TextEditingController();
  final completedQty = TextEditingController();
  final rejectedQty = TextEditingController();
  final isLoading = false.obs;

  Future<void> submitStitchingEntry([dynamic orderId]) async {
    final String? oId = orderId?.toString();
    try {
      isLoading.value = true;
      final assigned = int.tryParse(assignedQty.text.trim()) ?? 0;
      final completed = int.tryParse(completedQty.text.trim()) ?? 0;
      final rejected = int.tryParse(rejectedQty.text.trim()) ?? 0;
      final eff = assigned > 0 ? ((completed / assigned) * 100) : 0.0;

      final res = await ApiService.post('/production/stitching', {
        'order_id': orderId,
        'operator': operatorName.text.trim(),
        'style_no': styleNo.text.trim(),
        'operation_type': operationType.text.trim(),
        'assigned_qty': assigned,
        'completed_qty': completed,
        'rejected_qty': rejected,
        'efficiency': eff,
      });

      if (res['success'] == true) {
        Get.snackbar("Success", "Stitching entry saved", backgroundColor: Colors.green.withValues(alpha: 0.1));
        Get.back();
      }
    } catch (e) {
      Get.snackbar("Error", "Failed: $e");
    } finally {
      isLoading.value = false;
    }
  }

  final stitchingFormKey = GlobalKey<FormState>();
  List<String> get availableOperators => ['Operator A', 'Operator B', 'Operator C'];
  void calculateStitchingStats() {}
  var balanceQty = 0.obs;
  var efficiency = 0.0.obs;
}
