import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/auth/login_controller.dart';
import '../../utils/constants/colors.dart';
import '../../routes/route_names.dart';
import '../../screens/auth/status_check_screen.dart';
import '../../utils/widgets/blur_extension.dart';
import 'forgot_password_screen.dart'; // ✅ Imported your shared extension here!

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());
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
          systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        ),
        body: Stack(
          children: [
            // --- 1. ANIMATED/GLOWING BACKGROUND ---
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: bgGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
            ),
            // Decorative Glowing Orbs
            Positioned(
              top: -50,
              left: -50,
              child: Container(
                width: 200, height: 200,
                decoration: BoxDecoration(shape: BoxShape.circle, color: TColors.primary.withValues(alpha:isDark ? 0.3 : 0.1)),
              ).applyBlur(sigma: 50),
            ),
            Positioned(
              bottom: -100,
              right: -50,
              child: Container(
                width: 300, height: 300,
                decoration: BoxDecoration(shape: BoxShape.circle, color: TColors.marketing.withValues(alpha:isDark ? 0.2 : 0.05)),
              ).applyBlur(sigma: 60),
            ),

            // --- 2. MAIN CONTENT ---
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Header
                      // Container(
                      //   padding: const EdgeInsets.all(16),
                      //   decoration: BoxDecoration(
                      //     color: isDark ? Colors.white.withValues(alpha:0.05) : Colors.black.withValues(alpha:0.03),
                      //     shape: BoxShape.circle,
                      //   ),
                      //   child: Icon(Icons.fingerprint_rounded, size: 48, color: isDark ? Colors.white : TColors.primary),
                      // ),
                      const SizedBox(height: 20),
                      Text(
                        "Secure Portal",
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: -1),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Authenticate to access your dashboard",
                        style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey.shade600, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 40),

                      // --- 3. GLASSMORPHIC LOGIN CARD ---
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
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha:isDark ? 0.2 : 0.05), blurRadius: 20, offset: const Offset(0, 10))
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Role Selector
                                Text("CLEARANCE LEVEL", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey.shade500, letterSpacing: 1.5)),
                                const SizedBox(height: 12),
                                _buildRoleGrid(controller, isDark),
                                const SizedBox(height: 32),

                                // Inputs
                                Text("CREDENTIALS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey.shade500, letterSpacing: 1.5)),
                                const SizedBox(height: 12),
                                _buildLoginForm(controller, isDark),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // --- 4. FOOTER ---
                      _buildSignUpFooter(isDark),
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

  // --- COMPACT 3-COLUMN ROLE GRID ---
  Widget _buildRoleGrid(LoginController controller, bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: controller.roles.length,
      itemBuilder: (context, index) {
        final role = controller.roles[index];

        String shortName = role.replaceAll(" Supervisor", " Sup").replaceAll("Manager", "Mgr").replaceAll("Associate", "Assoc");

        return Obx(() {
          final isSelected = controller.selectedRole.value == role;
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              controller.selectedRole.value = role;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: isSelected ? TColors.primary : (isDark ? Colors.black.withValues(alpha:0.3) : Colors.white.withValues(alpha:0.5)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? TColors.primary : (isDark ? Colors.white10 : Colors.white), width: 1.5),
                boxShadow: isSelected ? [BoxShadow(color: TColors.primary.withValues(alpha:0.4), blurRadius: 12, offset: const Offset(0, 4))] : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(controller.roleIcons[role] ?? Icons.person_outline, color: isSelected ? Colors.white : (isDark ? Colors.white70 : TColors.primary), size: 24),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        shortName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                          color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.black87),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  // --- SLEEK INPUT FORM ---
// --- SLEEK INPUT FORM ---
  Widget _buildLoginForm(LoginController controller, bool isDark) {
    return Form(
      key: controller.loginFormKey,
      child: Column(
        children: [
          _buildGlassInput(
            controller: controller.email,
            hint: "Email Address",
            icon: Icons.alternate_email_rounded,
            isDark: isDark,
            validator: (val) => GetUtils.isEmail(val ?? "") ? null : "Invalid Email",
          ),
          const SizedBox(height: 16),
          Obx(
                () => _buildGlassInput(
              controller: controller.password,
              hint: "Password",
              icon: Icons.lock_outline_rounded,
              isDark: isDark,
              isPassword: true,
              obscure: controller.hidePassword.value,
              onToggleToggle: () => controller.hidePassword.toggle(),
            ),
          ),

          // ✅ ADDED: Forgot Password Link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                // We will create this screen in Step 3!
                Get.to(() => const ForgotPasswordScreen());
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                "Forgot Password?",
                style: TextStyle(color: TColors.primary, fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // --- GLOWING LOGIN BUTTON ---
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
                  onPressed: controller.isLoading.value
                      ? null
                      : () {
                    HapticFeedback.mediumImpact();
                    controller.login();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text("AUTHENTICATE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  // --- HELPER FOR GLASS TEXT FIELDS ---
  Widget _buildGlassInput({required TextEditingController controller, required String hint, required IconData icon, required bool isDark, bool isPassword = false, bool obscure = false, VoidCallback? onToggleToggle, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black38),
        prefixIcon: Icon(icon, color: isDark ? Colors.white70 : TColors.primary, size: 20),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: isDark ? Colors.white54 : Colors.black38, size: 20),
          onPressed: onToggleToggle,
        )
            : null,
        filled: true,
        fillColor: isDark ? Colors.black.withValues(alpha:0.3) : Colors.white.withValues(alpha:0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: TColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }

  // --- FOOTER LINKS ---
  Widget _buildSignUpFooter(bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("No assigned clearance? ", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w500)),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Get.toNamed(AppRouteNames.signup);
              },
              child: const Text("Request ID", style: TextStyle(color: TColors.primary, fontWeight: FontWeight.w900, decoration: TextDecoration.underline)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () {
            HapticFeedback.lightImpact();
            Get.to(() => const StatusCheckScreen());
          },
          icon: Icon(Icons.radar_rounded, size: 18, color: isDark ? Colors.white54 : Colors.grey),
          label: Text("Check ID Status", style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white54 : Colors.grey)),
        ),
      ],
    );
  }
}