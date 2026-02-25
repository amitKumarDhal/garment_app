import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/admin/admin_notification_controller.dart';

class AdminNotificationScreen extends StatelessWidget {
  const AdminNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminNotificationController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("System Activity", style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          TextButton(
            onPressed: () => controller.markAllAsRead(),
            child: const Text("Mark all read", style: TextStyle(color: Colors.blueAccent)),
          )
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.notifications.isEmpty) {
          return const Center(child: Text("No system activity found."));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.notifications.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final note = controller.notifications[index];
            bool isRead = note['isRead'] ?? false;

            // Safe timestamp parsing
            DateTime time = DateTime.now();
            if (note['timestamp'] != null) {
              time = (note['timestamp'] as Timestamp).toDate();
            }

            return GestureDetector(
              onTap: () {
                if (!isRead) controller.markAsRead(note['id']);
                // Optional: You can navigate to the specific order here if you included orderId in the notification
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isRead
                      ? (isDark ? const Color(0xFF1E1E1E) : Colors.white)
                      : (isDark ? Colors.blue.withValues(alpha: 0.1) : Colors.blue.shade50),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isRead
                          ? Colors.transparent
                          : Colors.blueAccent.withValues(alpha: 0.3)
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                      child: Icon(
                        note['title'].toString().contains('Delete') ? Icons.delete_sweep : Icons.notifications_active,
                        color: note['title'].toString().contains('Delete') ? Colors.redAccent : Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              note['title'] ?? "Alert",
                              style: TextStyle(fontWeight: isRead ? FontWeight.w700 : FontWeight.w900, fontSize: 15)
                          ),
                          const SizedBox(height: 4),
                          Text(
                              note['message'] ?? "",
                              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13)
                          ),
                          const SizedBox(height: 8),
                          Text(
                              DateFormat('MMM dd, yyyy • hh:mm a').format(time),
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600)
                          ),
                        ],
                      ),
                    ),
                    if (!isRead)
                      Container(
                        width: 10, height: 10,
                        decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                      )
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}