import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/auth/status_check_controller.dart';
import '../../utils/constants/colors.dart';
import '../../utils/widgets/blur_extension.dart'; // ✅ Imports your new shared extension!
import 'login_screen.dart';

class StatusCheckScreen extends StatelessWidget {
  const StatusCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StatusCheckController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Premium Background Gradients
    final List<Color> bgGradient = isDark
        ? [const Color(0xFF0F0C29), const Color(0xFF302B63), const Color(0xFF121212)]
        : [const Color(0xFFE0EAFC), const Color(0xFFCFDEF3), const Color(0xFFF4F6F9)];

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87, size: 20),
            onPressed: () => Get.back(),
          ),
          systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Get.offAll(() => const LoginScreen());
              },
              child: const Text("Login", style: TextStyle(color: TColors.primary, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Stack(
          children: [
            // --- 1. ANIMATED/GLOWING BACKGROUND ---
            Container(decoration: BoxDecoration(gradient: LinearGradient(colors: bgGradient, begin: Alignment.topLeft, end: Alignment.bottomRight))),
            // Decorative Glowing Orbs
            Positioned(
              top: -50, right: -50,
              child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: TColors.primary.withValues(alpha:isDark ? 0.3 : 0.1))).applyBlur(sigma: 50),
            ),
            Positioned(
              bottom: -100, left: -50,
              child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withValues(alpha:isDark ? 0.2 : 0.05))).applyBlur(sigma: 60),
            ),

            // --- 2. MAIN CONTENT ---
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Column(
                  children: [
                    // --- 3. SEARCH CARD (GLASSMORPHIC) ---
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha:0.05) : Colors.white.withValues(alpha:0.6),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: isDark ? Colors.white.withValues(alpha:0.1) : Colors.white),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:isDark ? 0.2 : 0.05), blurRadius: 20, offset: const Offset(0, 10))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: TColors.primary.withValues(alpha:0.1), shape: BoxShape.circle),
                                  child: const Icon(Icons.radar_rounded, size: 40, color: TColors.primary),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Center(child: Text("Clearance Tracker", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: -0.5))),
                              const SizedBox(height: 8),
                              Center(
                                child: Text("Enter your registered email to check your hierarchy approval status.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Search Input
                              _buildGlassInput(controller: controller.emailController, hint: "Official Email Address", icon: Icons.alternate_email_rounded, isDark: isDark),
                              const SizedBox(height: 16),

                              // Check Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: Obx(
                                      () => Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [TColors.gradientStart, TColors.gradientEnd]),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [BoxShadow(color: TColors.primary.withValues(alpha:0.3), blurRadius: 15, offset: const Offset(0, 8))],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: controller.isLoading.value ? null : () {
                                        HapticFeedback.mediumImpact();
                                        controller.checkStatus();
                                        FocusManager.instance.primaryFocus?.unfocus();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                      child: controller.isLoading.value
                                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                          : const Text("SCAN STATUS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- 4. RESULTS SECTION (CLEARANCE TRACKER) ---
                    Obx(() {
                      if (!controller.hasSearched.value || controller.requestData.value == null) return const SizedBox.shrink();

                      final data = controller.requestData.value!;
                      final role = data['role'] ?? 'Worker';
                      final status = data['status'] ?? 'Pending';

                      Color statusBadgeColor = Colors.orange;
                      if (status == 'Approved') statusBadgeColor = Colors.green;
                      if (status == 'Rejected') statusBadgeColor = Colors.redAccent;

                      return AnimatedOpacity(
                        opacity: 1.0,
                        duration: const Duration(milliseconds: 500),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("CLEARANCE PATH: ${role.toUpperCase()}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.grey.shade500, letterSpacing: 1.5)),
                            const SizedBox(height: 16),

                            // Tracker Box
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha:0.03)),
                                boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withValues(alpha:0.03), blurRadius: 15, offset: const Offset(0, 5))],
                              ),
                              child: Column(
                                children: [
                                  // Always true if document exists
                                  _buildTrackerStep("Profile Generated", "Identity logged in system", true, isCurrent: false, isDark: isDark),

                                  // Final Admin Step
                                  _buildTrackerStep("System Authorization", data['adminApproved'] ? "Clearance Granted" : "Final Admin Review", data['adminApproved'] ?? false, isCurrent: !(data['adminApproved'] ?? false), isLast: true, isDark: isDark),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // --- STATUS BADGE ---
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: statusBadgeColor.withValues(alpha:0.15),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: statusBadgeColor.withValues(alpha:0.3), width: 2),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(status == 'Approved' ? Icons.check_circle_rounded : (status == 'Rejected' ? Icons.cancel_rounded : Icons.pending_rounded), color: statusBadgeColor, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      "ACCESS ${status.toUpperCase()}",
                                      style: TextStyle(color: statusBadgeColor, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- MODERN TRACKER STEP ---
  Widget _buildTrackerStep(String title, String subtitle, bool isCompleted, {bool isCurrent = false, bool isLast = false, required bool isDark}) {
    Color nodeColor = isCompleted ? Colors.green : (isCurrent ? Colors.orange : Colors.grey.withValues(alpha:0.3));
    IconData nodeIcon = isCompleted ? Icons.check_rounded : (isCurrent ? Icons.sync_rounded : Icons.lock_outline_rounded);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Node & Line
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green : (isCurrent ? Colors.orange.withValues(alpha:0.1) : Colors.transparent),
                    shape: BoxShape.circle,
                    border: Border.all(color: nodeColor, width: 2),
                  ),
                  child: Icon(nodeIcon, color: isCompleted ? Colors.white : nodeColor, size: 16),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isCompleted ? Colors.green : (isDark ? Colors.white10 : Colors.grey.shade300),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Right Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: isCompleted || isCurrent ? (isDark ? Colors.white : Colors.black87) : Colors.grey.shade500)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isCompleted ? Colors.green : (isCurrent ? Colors.orange : Colors.grey))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER FOR GLASS TEXT FIELDS ---
  Widget _buildGlassInput({required TextEditingController controller, required String hint, required IconData icon, required bool isDark}) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black38),
        prefixIcon: Icon(icon, color: isDark ? Colors.white70 : TColors.primary, size: 20),
        filled: true,
        fillColor: isDark ? Colors.black.withValues(alpha:0.3) : Colors.white.withValues(alpha:0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: TColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }
}