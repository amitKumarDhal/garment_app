import 'package:get/get.dart';
import 'package:flutter/material.dart';

class AdminController extends GetxController {
  // --- Stats ---
  var totalDailyProduction = 2450.obs;
  var averageEfficiency = 84.5.obs;
  var activeWorkers = 42.obs;
  var totalDamages = 12.obs;

  // --- DUMMY APPROVAL DATA ---
  var pendingRequests = <Map<String, dynamic>>[
    {
      "id": "USR001",
      "name": "Amit Das",
      "role": "Worker",
      "employeeId": "EMP-101",
      "email": "amit@factory.com",
      "unitApproved": true,
      "shiftApproved": false,
      "adminApproved": false,
    },
    {
      "id": "USR002",
      "name": "Rajesh Kumar",
      "role": "Unit Supervisor",
      "employeeId": "EMP-102",
      "email": "rajesh@factory.com",
      "unitApproved": true,
      "shiftApproved": true,
      "adminApproved": false,
    },
  ].obs;

  var pendingApprovalsCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    updateBadgeCount();
  }

  void updateBadgeCount() {
    pendingApprovalsCount.value = pendingRequests.length;
  }

  void approveNextStage(int index) {
    var user = pendingRequests[index];

    if (!user['unitApproved']) {
      user['unitApproved'] = true;
    } else if (!user['shiftApproved']) {
      user['shiftApproved'] = true;
    } else if (!user['adminApproved']) {
      user['adminApproved'] = true;
    }

    // Check if fully approved
    if (user['unitApproved'] &&
        user['shiftApproved'] &&
        user['adminApproved']) {
      pendingRequests.removeAt(index);
      Get.snackbar(
        "Account Active",
        "${user['name']} can now login!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      pendingRequests[index] = user;
      pendingRequests.refresh(); // Crucial for nested UI updates
    }
    updateBadgeCount();
  }

  void rejectRequest(int index) {
    pendingRequests.removeAt(index);
    updateBadgeCount();
    Get.snackbar(
      "Rejected",
      "ID Request deleted",
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  Future<void> refreshStats() async {
    await Future.delayed(const Duration(seconds: 1));
    updateBadgeCount();
  }
}
