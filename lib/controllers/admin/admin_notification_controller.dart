import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/api_service.dart';

class AdminNotificationController extends GetxController {
  var notifications = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      isLoading.value = true;
      final res = await ApiService.get('/notifications');
      if (res['success'] == true && res['notifications'] != null) {
        notifications.assignAll(List<Map<String, dynamic>>.from(res['notifications']));
      }
    } catch (e) {
      debugPrint("Fetch Notifications Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  RxInt get unreadCount => notifications.where((n) => n['isRead'] != true).length.obs;

  Future<void> markAllAsRead() async {
    for (var n in notifications) {
      n['isRead'] = true;
    }
    notifications.refresh();
  }

  Future<void> markAsRead(String id) async {
    final note = notifications.firstWhereOrNull((n) => n['id'] == id);
    if (note != null) {
      note['isRead'] = true;
      notifications.refresh();
    }
  }
}