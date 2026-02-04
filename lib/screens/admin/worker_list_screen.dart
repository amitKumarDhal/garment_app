import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/admin/admin_controller.dart';
import '../../utils/constants/colors.dart';

class WorkerListScreen extends StatelessWidget {
  const WorkerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Reuse the existing controller
    final controller = Get.find<AdminController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : TColors.light,
      appBar: AppBar(
        title: const Text("Active Workforce"),
        backgroundColor: isDark ? TColors.dark : TColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.allApprovedWorkers.isEmpty) {
          return const Center(child: Text("No approved workers found."));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.allApprovedWorkers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final worker = controller.allApprovedWorkers[index];
            final String name = worker['name'] ?? 'Unknown';
            final String role = worker['role'] ?? 'Worker';
            final String dept = worker['department'] ?? 'General';

            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getRoleColor(role).withValues(alpha: 0.1),
                  child: Text(
                    name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: _getRoleColor(role),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  role, // e.g., "Shift Supervisor"
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                trailing: Chip(
                  label: Text(
                    dept,
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  backgroundColor: _getRoleColor(dept),
                  padding: const EdgeInsets.all(0),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Color _getRoleColor(String text) {
    String lower = text.toLowerCase();
    if (lower.contains('sales') || lower.contains('agent'))
      return TColors.marketing;
    if (lower.contains('cutting')) return TColors.cutting;
    if (lower.contains('print')) return TColors.printing;
    if (lower.contains('stitch')) return TColors.stitching;
    if (lower.contains('pack')) return TColors.packing;
    if (lower.contains('admin')) return Colors.blue;
    return Colors.grey;
  }
}
