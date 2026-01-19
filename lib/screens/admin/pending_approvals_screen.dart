import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/admin/admin_controller.dart';
import '../../utils/constants/sizes.dart';

class PendingApprovalsScreen extends StatelessWidget {
  const PendingApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("ID Approval Queue")),
      body: Obx(() {
        if (controller.pendingRequests.isEmpty) {
          return const Center(child: Text("No pending requests"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(TSizes.md),
          itemCount: controller.pendingRequests.length,
          itemBuilder: (context, index) {
            final user = controller.pendingRequests[index];
            return _buildRequestCard(controller, user, index, isDark);
          },
        );
      }),
    );
  }

  Widget _buildRequestCard(
    AdminController controller,
    Map<String, dynamic> user,
    int index,
    bool isDark,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Text(user['name'][0])),
              title: Text(
                user['name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text("${user['role']} • ${user['employeeId']}"),
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusCircle("Unit", user['unitApproved']),
                _buildLine(user['unitApproved']),
                _buildStatusCircle("Shift", user['shiftApproved']),
                _buildLine(user['shiftApproved']),
                _buildStatusCircle("Admin", user['adminApproved']),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => controller.rejectRequest(index),
                    child: const Text("Reject"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => controller.approveNextStage(index),
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
