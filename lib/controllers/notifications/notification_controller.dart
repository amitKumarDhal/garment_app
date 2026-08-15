import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/order_model.dart';
import '../../data/services/api_service.dart';
import '../../screens/sales/manager/order_approval_screen.dart';
import '../../screens/floor_management/marketing_upload_screen.dart';
import '../../screens/sales/order_tracking_screen.dart';

class NotificationController extends GetxController {
  static NotificationController get instance => Get.find();

  var notifications = <Map<String, dynamic>>[].obs;
  var unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      final res = await ApiService.get('/notifications');
      if (res['success'] == true && res['notifications'] != null) {
        final list = List<Map<String, dynamic>>.from(res['notifications']);
        notifications.assignAll(list);
        unreadCount.value = res['unreadCount'] ?? list.where((n) => n['is_read'] == false).length;
      }
    } catch (e) {
      debugPrint("Notifications Fetch Error: $e");
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await ApiService.put('/notifications/$id/read', {});
      fetchNotifications();
    } catch (e) {
      debugPrint("Could not mark notification as read: $e");
    }
  }

  Future<void> handleNotificationTap(Map<String, dynamic> data) async {
    if (data['id'] != null) {
      await markAsRead(data['id']);
    }

    String title = data['title'] ?? "";
    String orderId = data['order_id'] ?? data['orderId'] ?? "";

    if (orderId.isNotEmpty) {
      try {
        final res = await ApiService.get('/orders/$orderId');
        if (res['success'] == true && res['order'] != null) {
          final order = OrderModel.fromJson(res['order']);
          if (title.contains("Approval") || title.contains("Alert") || title.contains("Deletion")) {
            Get.to(() => OrderApprovalScreen(order: order));
          } else if (title.contains("Approved") || title.contains("Rejected") || title.contains("Placed")) {
            Get.to(() => OrderTrackingScreen(searchKey: order.manualOrderNo ?? order.id));
          } else {
            Get.to(() => MarketingUploadScreen(existingOrder: order));
          }
        }
      } catch (e) {
        Get.snackbar("Error", "Could not load order details.");
      }
    }
  }

  static Future<void> sendNotification({
    required String targetUserId,
    required String title,
    required String message,
    required String type,
    String? orderId,
  }) async {
    try {
      await ApiService.post('/notifications', {
        'target_user_id': targetUserId,
        'title': title,
        'message': message,
        'type': type,
        'order_id': orderId ?? "",
      });
    } catch (e) {
      debugPrint("Failed to send notification: $e");
    }
  }
}