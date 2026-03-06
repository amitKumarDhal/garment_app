import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ✅ Ensure these paths match your folder structure exactly
import '../../data/models/order_model.dart';
import '../../screens/sales/manager/order_approval_screen.dart';
import '../../screens/floor_management/marketing_upload_screen.dart';
import '../../screens/sales/order_tracking_screen.dart';

class NotificationController extends GetxController {
  static NotificationController get instance => Get.find();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  var notifications = <Map<String, dynamic>>[].obs;
  var unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    listenToNotifications();
  }

  void listenToNotifications() {
    final user = _auth.currentUser;
    if (user == null) return;

    _db.collection('notifications')
        .where('targetUserId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      final docs = snapshot.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      notifications.assignAll(docs);
      unreadCount.value = docs.where((n) => n['isRead'] == false).length;
    });
  }

  Future<void> markAsRead(String docId) async {
    try {
      await _db.collection('notifications').doc(docId).update({'isRead': true});
    } catch (e) {
      debugPrint("Could not mark as read: $e");
    }
  }

  // ✅ HANDLES DUAL ROUTING (Manager vs Associate)
  Future<void> handleNotificationTap(Map<String, dynamic> data) async {
    if (data['id'] != null) {
      await markAsRead(data['id']);
    }

    String title = data['title'] ?? "";
    String orderId = data['orderId'] ?? "";

    if (orderId.isNotEmpty) {
      try {
        final doc = await _db.collection('orders').doc(orderId).get();

        if (doc.exists) {
          final order = OrderModel.fromSnapshot(doc);

          // 🚨 ROUTE FOR MANAGER (Now catches Updates and New Orders!)
          if (title.contains("Approval") || title.contains("Alert") || title.contains("Deletion") || title.contains("Updated") || title.contains("New Order")) {
            Get.to(() => OrderApprovalScreen(order: order));
          }
          // 👨‍💼 ROUTE FOR ASSOCIATE
          else if (title.contains("Approved") || title.contains("Rejected") || title.contains("Placed")) {
            // Passing the manual order number to trigger the auto-search on the Tracking Screen
            Get.to(() => OrderTrackingScreen(searchKey: order.manualOrderNo ?? order.id));
          }
          // Default Fallback
          else {
            Get.to(() => MarketingUploadScreen(existingOrder: order));
          }

        } else {
          Get.snackbar(
            "Order Not Found",
            "This order might have been deleted.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
            colorText: Colors.red,
          );
        }
      } catch (e) {
        Get.snackbar("Error", "Could not load order details: $e");
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
      await FirebaseFirestore.instance.collection('notifications').add({
        'targetUserId': targetUserId,
        'title': title,
        'message': message,
        'type': type,
        'orderId': orderId ?? "",
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Failed to send notification: $e");
    }
  }
}