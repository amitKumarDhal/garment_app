import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/auth/forgot_password_controller.dart';
import '../../utils/constants/colors.dart';
import '../../utils/widgets/blur_extension.dart'; // ✅ Using your shared extension

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ForgotPasswordController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        ),
        body: Stack(
          children: [
            // Background & Orbs
            Container(decoration: BoxDecoration(gradient: LinearGradient(colors: bgGradient, begin: Alignment.topLeft, end: Alignment.bottomRight))),
            Positioned(
              top: -50, right: -50,
              child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: TColors.primary.withValues(alpha:isDark ? 0.3 : 0.1))).applyBlur(sigma: 50),
            ),
            Positioned(
              bottom: -100, left: -50,
              child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.orange.withValues(alpha:isDark ? 0.2 : 0.05))).applyBlur(sigma: 60), // Orange tint for recovery
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha:0.05) : Colors.black.withValues(alpha:0.03), shape: BoxShape.circle),
                        child: Icon(Icons.lock_reset_rounded, size: 48, color: isDark ? Colors.white : TColors.primary),
                      ),
                      const SizedBox(height: 20),
                      Text("Credential Recovery", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: -1)),
                      const SizedBox(height: 8),
                      Text(
                        "Enter your official email address and we will dispatch a secure link to reset your password.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey.shade600, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 40),

                      // Glassmorphic Card
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
                            child: Form(
                              key: controller.resetFormKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("ACCOUNT IDENTIFIER", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey.shade500, letterSpacing: 1.5)),
                                  const SizedBox(height: 12),

                                  // Input Field
                                  TextFormField(
                                    controller: controller.emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (val) => GetUtils.isEmail(val ?? "") ? null : "Invalid Email format",
                                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                                    decoration: InputDecoration(
                                      hintText: "Email Address",
                                      hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black38),
                                      prefixIcon: Icon(Icons.alternate_email_rounded, color: isDark ? Colors.white70 : TColors.primary, size: 20),
                                      filled: true,
                                      fillColor: isDark ? Colors.black.withValues(alpha:0.3) : Colors.white.withValues(alpha:0.5),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: TColors.primary, width: 1.5)),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  // Glowing Send Button
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
                                            controller.sendPasswordResetEmail();
                                            FocusManager.instance.primaryFocus?.unfocus();
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          ),
                                          child: controller.isLoading.value
                                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                              : const Text("DISPATCH LINK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}