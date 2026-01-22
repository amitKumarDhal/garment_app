import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/admin/admin_controller.dart';
import '../../utils/constants/sizes.dart';

class PendingApprovalsScreen extends StatelessWidget {
  const PendingApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Accessing the AdminController which now uses real-time Firestore streams
    final controller = Get.find<AdminController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("ID Approval Queue")),
      body: Obx(() {
        // Obx listens to the reactive pendingRequests list from Firestore
        if (controller.pendingRequests.isEmpty) {
          return const Center(child: Text("No pending requests found"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(TSizes.md),
          itemCount: controller.pendingRequests.length,
          itemBuilder: (context, index) {
            final user = controller.pendingRequests[index];
            // Pass the user map directly to the card builder
            return _buildRequestCard(controller, user, isDark);
          },
        );
      }),
    );
  }

  Widget _buildRequestCard(
    AdminController controller,
    Map<String, dynamic> user,
    bool isDark,
  ) {
    // FIX: Extract the String docId to resolve the 'int' vs 'String' type error
    final String docId = user['id'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Colors.blue.withOpacity(0.1),
                child: Text(user['name']?[0] ?? 'U'),
              ),
              title: Text(
                user['name'] ?? 'Unknown User',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text("${user['role']} • ${user['employeeId']}"),
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Approval Path Visualizer using boolean flags from Firestore
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusCircle("Unit", user['unitApproved'] ?? false),
                _buildLine(user['unitApproved'] ?? false),
                _buildStatusCircle("Shift", user['shiftApproved'] ?? false),
                _buildLine(user['shiftApproved'] ?? false),
                _buildStatusCircle("Admin", user['adminApproved'] ?? false),
              ],
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    // FIX: Passing String docId to match the updated AdminController
                    onPressed: () => controller.rejectRequest(docId),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text("Reject"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    // FIX: Passing both String docId and the user Map to approveNextStage
                    onPressed: () => controller.approveNextStage(docId, user),
                    child: const Text("Approve Stage"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCircle(String label, bool active) {
    return Column(
      children: [
        Icon(
          active ? Icons.check_circle : Icons.radio_button_unchecked,
          color: active ? Colors.green : Colors.grey,
          size: 20,
        ),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildLine(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        color: active ? Colors.green : Colors.grey.withOpacity(0.3),
      ),
    );
  }
}
