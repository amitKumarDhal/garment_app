import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class NotificationController extends GetxController {
  static NotificationController get instance => Get.find();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // The list of notifications
  var notifications = <Map<String, dynamic>>[].obs;
  // The red badge number
  var unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    listenToNotifications();
  }

  void listenToNotifications() {
    final user = _auth.currentUser;
    if (user == null) return;

    // Listen to notifications specifically for this user
    _db.collection('notifications')
        .where('targetUserId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {

      final docs = snapshot.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id; // Save the document ID to mark it as read later
        return data;
      }).toList();

      notifications.assignAll(docs);

      // Calculate how many are unread
      unreadCount.value = docs.where((n) => n['isRead'] == false).length;
    });
  }

  // Call this when the user taps a notification
  Future<void> markAsRead(String docId) async {
    try {
      await _db.collection('notifications').doc(docId).update({'isRead': true});
    } catch (e) {
      print("Could not mark as read: $e");
    }
  }

  // --- Helper to SEND notifications (You can call this from anywhere!) ---
  static Future<void> sendNotification({
    required String targetUserId,
    required String title,
    required String message,
    required String type, // e.g., 'OrderApproved', 'Alert'
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'targetUserId': targetUserId,
        'title': title,
        'message': message,
        'type': type,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Failed to send notification: $e");
    }
  }
}