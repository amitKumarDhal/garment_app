import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yoobbel/controllers/auth/status_check_controller.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/sizes.dart';
import 'login_screen.dart'; // ✅ Import your Login Screen here

class StatusCheckScreen extends StatelessWidget {
  const StatusCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StatusCheckController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : TColors.light,
      appBar: AppBar(
        title: const Text("Check Application Status"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
        // ✅ Option 1: Add a Login button in the AppBar (Optional)
        actions: [
          TextButton(
            onPressed: () => Get.offAll(() => const LoginScreen()),
            child: const Text("Login"),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.lg),
        child: Column(
          children: [
            // --- Search Section ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.manage_search,
                    size: 50,
                    color: TColors.primary,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Track Your ID Request",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Enter your email to see approval progress",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: controller.emailController,
                    decoration: InputDecoration(
                      hintText: "Enter Email Address",
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Obx(
                      () => ElevatedButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : () => controller.checkStatus(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: controller.isLoading.value
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "CHECK STATUS",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- Results Section ---
            Obx(() {
              if (!controller.hasSearched.value) return const SizedBox.shrink();
              if (controller.requestData.value == null) {
                return const SizedBox.shrink();
              }

              final data = controller.requestData.value!;
              final role = data['role'] ?? 'Worker';
              final status = data['status'] ?? 'Pending';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Application for: $role",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 1. Submitted Step (Always True if data exists)
                  _buildStep(
                    title: "Request Submitted",
                    subtitle: "Profile created in system",
                    isCompleted: true,
                    isDark: isDark,
                  ),

                  // 2. Unit Approval (Only for Workers)
                  if (role == 'Worker')
                    _buildStep(
                      title: "Unit Supervisor Approval",
                      subtitle: data['unitApproved']
                          ? "Approved"
                          : "Waiting for Unit Head",
                      isCompleted: data['unitApproved'],
                      isCurrent: !data['unitApproved'],
                      isDark: isDark,
                    ),

                  // 3. Shift Approval (Workers & Unit Supervisors)
                  if (role == 'Worker' || role == 'Unit Supervisor')
                    _buildStep(
                      title: "Shift Supervisor Approval",
                      subtitle: data['shiftApproved']
                          ? "Approved"
                          : "Waiting for Shift Manager",
                      isCompleted: data['shiftApproved'],
                      isCurrent:
                          (data['unitApproved'] ?? true) &&
                          !data['shiftApproved'],
                      isDark: isDark,
                    ),

                  // 4. Admin Approval (Everyone)
                  _buildStep(
                    title: "System Admin Verification",
                    subtitle: data['adminApproved']
                        ? "Access Granted"
                        : "Final Verification Pending",
                    isCompleted: data['adminApproved'],
                    isCurrent:
                        (data['shiftApproved'] ?? true) &&
                        !data['adminApproved'],
                    isLast: true,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 20),

                  // Status Badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: status == 'Approved'
                            ? Colors.green
                            : (status == 'Rejected'
                                  ? Colors.red
                                  : Colors.orange),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Current Status: ${status.toUpperCase()}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),

            // ✅ Option 2: Clear "Go to Login" Section at the bottom
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Already approved?",
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                TextButton(
                  onPressed: () => Get.offAll(() => const LoginScreen()),
                  child: const Text(
                    "Login Here",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: TColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- Visual Step Builder ---
  Widget _buildStep({
    required String title,
    required String subtitle,
    required bool isCompleted,
    bool isCurrent = false,
    bool isLast = false,
    required bool isDark,
  }) {
    Color color = isCompleted
        ? Colors.green
        : (isCurrent ? Colors.orange : Colors.grey);
    IconData icon = isCompleted
        ? Icons.check_circle
        : (isCurrent ? Icons.access_time_filled : Icons.circle_outlined);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(icon, color: color, size: 28),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted
                    ? Colors.green.withOpacity(0.5)
                    : Colors.grey.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isCompleted || isCurrent
                      ? (isDark ? Colors.white : Colors.black)
                      : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isCompleted ? Colors.green : Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}
