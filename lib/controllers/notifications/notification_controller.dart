import 'dart:async'; // ✅ Added for StreamSubscription
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/order_model.dart';
import '../../screens/sales/manager/order_approval_screen.dart';
import '../../screens/floor_management/marketing_upload_screen.dart';
import '../../screens/sales/order_tracking_screen.dart';

class NotificationController extends GetxController {
  static NotificationController get instance => Get.find();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ✅ Keep track of the listener to cancel it
  StreamSubscription? _notificationSub;

  var notifications = <Map<String, dynamic>>[].obs;
  var unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    listenToNotifications();
    updateUnreadCount(); // Initial count
  }

  @override
  void onClose() {
    _notificationSub?.cancel(); // ✅ Stop listening when app/controller closes
    super.onClose();
  }

  void listenToNotifications() {
    final user = _auth.currentUser;
    if (user == null) return;

    // ✅ OPTIMIZED: Added .limit(30)
    // Workers/Managers only need to see recent notifications.
    // Loading the entire history burns thousands of reads for no reason.
    _notificationSub = _db.collection('notifications')
        .where('targetUserId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .limit(30)
        .snapshots()
        .listen((snapshot) {
      final docs = snapshot.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      notifications.assignAll(docs);

      // Update badge count whenever a change occurs
      updateUnreadCount();
    });
  }

  // ✅ OPTIMIZED: Use Aggregation for the badge count
  // This calculates the number on the server and costs only 1 read total,
  // instead of 1 read per unread document.
  Future<void> updateUnreadCount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final aggregateQuery = await _db.collection('notifications')
          .where('targetUserId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      unreadCount.value = aggregateQuery.count ?? 0;
    } catch (e) {
      debugPrint("Count aggregation error: $e");
    }
  }

  Future<void> markAsRead(String docId) async {
    try {
      await _db.collection('notifications').doc(docId).update({'isRead': true});
      // unreadCount will auto-update via the listener triggering updateUnreadCount
    } catch (e) {
      debugPrint("Could not mark as read: $e");
    }
  }

  Future<void> handleNotificationTap(Map<String, dynamic> data) async {
    if (data['id'] != null) {
      await markAsRead(data['id']);
    }

    String title = data['title'] ?? "";
    String orderId = data['orderId'] ?? "";

    if (orderId.isNotEmpty) {
      try {
        // ✅ OPTIMIZED: serverAndCache ensures we don't re-read the order
        // if it's already sitting in the phone's memory.
        final doc = await _db.collection('orders').doc(orderId).get(
            const GetOptions(source: Source.serverAndCache)
        );

        if (doc.exists) {
          final order = OrderModel.fromSnapshot(doc);

          if (title.contains("Approval") || title.contains("Alert") || title.contains("Deletion") || title.contains("Updated") || title.contains("New Order")) {
            Get.to(() => OrderApprovalScreen(order: order));
          }
          else if (title.contains("Approved") || title.contains("Rejected") || title.contains("Placed")) {
            Get.to(() => OrderTrackingScreen(searchKey: order.manualOrderNo ?? order.id));
          }
          else {
            Get.to(() => MarketingUploadScreen(existingOrder: order));
          }

        } else {
          Get.snackbar("Order Not Found", "This order might have been deleted.");
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