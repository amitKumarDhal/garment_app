import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/admin/admin_controller.dart';

class PendingApprovalsScreen extends StatelessWidget {
  const PendingApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),

      // ✅ 1. SLEEK TRANSPARENT APP BAR
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        title: Text(
          "ID Approval Queue",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
      ),

      body: Obx(() {
        if (controller.pendingRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha:0.05) : Colors.black.withValues(alpha:0.03),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.verified_user_rounded, size: 56, color: Colors.grey.shade400),
                ),
                const SizedBox(height: 24),
                Text(
                  "All Caught Up!",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  "No pending ID requests require attention.",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 40),
          itemCount: controller.pendingRequests.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final user = controller.pendingRequests[index];
            return _buildRequestCard(controller, user, isDark);
          },
        );
      }),
    );
  }
  // --- 2. PREMIUM SECURITY CLEARANCE TICKET ---
  Widget _buildRequestCard(AdminController controller, Map<String, dynamic> user, bool isDark) {
    final String docId = user['id']?.toString() ?? '';
    final String role = (user['role'] ?? 'SALES_ASSOCIATE').toString().replaceAll('_', ' ').toUpperCase();
    final String employeeId = user['employee_id']?.toString() ?? user['employeeId']?.toString() ?? '---';
    final String email = user['email']?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.orange.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Glowing Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      user['name'] != null && user['name'].toString().isNotEmpty
                          ? user['name'][0].toUpperCase()
                          : 'U',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // User Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name']?.toString() ?? 'Unknown User',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isDark ? Colors.white : Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                            child: Text(role, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.orange.shade700, letterSpacing: 0.5)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "ID: $employeeId",
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(height: 1, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03)),

          // Actions
          Padding(
            padding: const EdgeInsets.all(20),
            child: Obx(() {
              final isProcessing = controller.processingUserIds.contains(docId);

              if (isProcessing) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.orange)),
                    ),
                  ),
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _confirmAction(
                          "Reject Request",
                          "Are you sure you want to reject and delete this ID request?",
                          Colors.redAccent,
                          () => controller.rejectRequest(docId),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text("Reject", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          controller.approveNextStage(docId, user);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text("Approve Clearance", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // --- 3. SAFETY DIALOG ---
  void _confirmAction(String title, String message, Color color, VoidCallback onConfirm) {
    Get.defaultDialog(
      title: title,
      titleStyle: const TextStyle(fontWeight: FontWeight.w900),
      middleText: message,
      radius: 16,
      confirm: ElevatedButton(
        onPressed: () {
          onConfirm();
          Get.back(); // Close dialog
        },
        style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: const Text("Confirm", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      cancel: OutlinedButton(
        onPressed: () => Get.back(),
        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: const Text("Cancel"),
      ),
    );
  }
}