import 'package:cloud_firestore/cloud_firestore.dart' as default_firebase;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/notifications/notification_controller.dart';
import '../../utils/constants/colors.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject the controller
    final controller = Get.put(NotificationController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        title: Text(
          "Notifications",
          style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87),
        ),
      ),
      body: Obx(() {
        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off_outlined, size: 64, color: isDark ? Colors.white24 : Colors.black12),
                const SizedBox(height: 16),
                Text("All caught up!", style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey.shade500)),
              ],
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: controller.notifications.length,
          itemBuilder: (context, index) {
            final note = controller.notifications[index];
            final bool isRead = note['isRead'] ?? true;

            // Format Timestamp
            String timeText = "Just now";
            if (note['timestamp'] != null) {
              DateTime dt = (note['timestamp'] as default_firebase.Timestamp).toDate();
              timeText = DateFormat('MMM dd, hh:mm a').format(dt);
            }

            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                if (!isRead) controller.markAsRead(note['id']);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isRead
                      ? (isDark ? const Color(0xFF1E1E1E) : Colors.white)
                      : (isDark ? TColors.primary.withValues(alpha:0.15) : TColors.primary.withValues(alpha:0.05)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isRead
                        ? (isDark ? Colors.white10 : Colors.black.withValues(alpha:0.05))
                        : TColors.primary.withValues(alpha:0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isRead ? Colors.grey.withValues(alpha:0.1) : TColors.primary.withValues(alpha:0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                          _getIconForType(note['type']),
                          color: isRead ? Colors.grey : TColors.primary,
                          size: 20
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  note['title'] ?? "Notification",
                                  style: TextStyle(fontWeight: isRead ? FontWeight.w700 : FontWeight.w900, fontSize: 15, color: isDark ? Colors.white : Colors.black87),
                                ),
                              ),
                              if (!isRead)
                                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle))
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            note['message'] ?? "",
                            style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87, fontWeight: isRead ? FontWeight.w500 : FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            timeText,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'OrderApproved': return Icons.check_circle_rounded;
      case 'OrderRejected': return Icons.cancel_rounded;
      case 'System': return Icons.info_rounded;
      default: return Icons.notifications_rounded;
    }
  }
}