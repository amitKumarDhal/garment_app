import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'marketing_controller.dart'; // Import to update the global list

class MarketingUploadController extends GetxController {
  final uploadFormKey = GlobalKey<FormState>();

  // --- Form Field Controllers ---
  final orderNo = TextEditingController();
  final clientName = TextEditingController();
  final organization = TextEditingController();
  final phone = TextEditingController();
  final productDetails = TextEditingController();
  final orderValue = TextEditingController();
  final quantity = TextEditingController();
  final gstInfo = TextEditingController();
  final deadline = TextEditingController();

  final isLoading = false.obs;

  // --- Date Picker Logic ---
  Future<void> chooseDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(), // Agents can't pick past dates
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      // Format: DD MMM YYYY (e.g., 17 Jan 2026)
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

  // --- Submit Logic ---
  void submitOrder() async {
    if (!uploadFormKey.currentState!.validate()) return;

    try {
      isLoading.value = true;
      await Future.delayed(
        const Duration(seconds: 1),
      ); // Simulate network delay

      // --- Connect to MarketingController (In-Memory Update) ---
      // This ensures the new order shows up in the Agent's list immediately
      final marketingCtrl = Get.find<MarketingController>();

      final newOrder = {
        "name": clientName.text.trim(),
        "org": organization.text.trim(),
        "phone": phone.text.trim(),
        "qty": int.tryParse(quantity.text) ?? 0,
        "value": "₹${orderValue.text.trim()}",
        "gst": "${gstInfo.text.trim()}%",
        "date": "Today",
        "targetDate": deadline.text.trim(),
        "status": "Processing",
      };

      // Add to the first agent (Amit Sharma) for now as a dummy test
      if (marketingCtrl.allAgents.isNotEmpty) {
        marketingCtrl.allAgents[0]['clients'].add(newOrder);
        marketingCtrl.allAgents.refresh(); // Tell GetX to update the UI
      }

      Get.snackbar(
        "Success",
        "Order ${orderNo.text} recorded for ${clientName.text}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );

      _clearForm();
      Get.back(); // Go back to the list screen after upload
    } catch (e) {
      Get.snackbar("Error", "Failed to upload order");
    } finally {
      isLoading.value = false;
    }
  }

  void _clearForm() {
    [
      orderNo,
      clientName,
      organization,
      phone,
      productDetails,
      orderValue,
      quantity,
      gstInfo,
      deadline,
    ].forEach((c) => c.clear());
  }

  @override
  void onClose() {
    [
      orderNo,
      clientName,
      organization,
      phone,
      productDetails,
      orderValue,
      quantity,
      gstInfo,
      deadline,
    ].forEach((c) => c.dispose());
    super.onClose();
  }
}
