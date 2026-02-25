import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class AdminNotificationController extends GetxController {
  final _db = FirebaseFirestore.instance;

  var notifications = <Map<String, dynamic>>[].obs;
  var unreadCount = 0.obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchGlobalNotifications();
  }

  // ✅ Fetch ALL activity across the company for the Admin
  void fetchGlobalNotifications() {
    _db.collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(100) // Keep the app fast by loading the latest 100
        .snapshots()
        .listen((snapshot) {

      final docs = snapshot.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id; // Save the document ID to mark as read later
        return data;
      }).toList();

      notifications.value = docs;

      // Update the badge count for the Bell Icon
      unreadCount.value = docs.where((n) => n['isRead'] == false).length;
      isLoading.value = false;
    });
  }

  // ✅ Mark a specific notification as read when clicked
  void markAsRead(String docId) {
    _db.collection('notifications').doc(docId).update({'isRead': true});
  }

  // ✅ Mark all as read
  void markAllAsRead() async {
    final batch = _db.batch();
    for (var n in notifications) {
      if (n['isRead'] == false) {
        batch.update(_db.collection('notifications').doc(n['id']), {'isRead': true});
      }
    }
    await batch.commit();
  }
}