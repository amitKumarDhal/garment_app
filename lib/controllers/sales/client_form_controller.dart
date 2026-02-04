import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ClientFormController extends GetxController {
  // Form Keys & Controllers
  final clientFormKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final businessNameController = TextEditingController();

  void submitClientData() {
    if (clientFormKey.currentState!.validate()) {
      // For now, we show a snackbar. Later, we'll connect Firestore.
      Get.snackbar(
        "Success",
        "Client ${nameController.text} added to database",
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );
      _clearForm();
    }
  }

  void _clearForm() {
    nameController.clear();
    phoneController.clear();
    addressController.clear();
    businessNameController.clear();
  }
}
