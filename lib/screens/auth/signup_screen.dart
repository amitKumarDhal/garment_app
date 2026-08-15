import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/auth/signup_controller.dart';
import '../../utils/constants/colors.dart';
import '../../utils/widgets/blur_extension.dart'; // ✅ Imported shared extension!

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final controller = Get.put(SignupController());

  final Map<String, IconData> roleIcons = {
    'Unit Supervisor': Icons.manage_accounts_outlined,
    'Sales Associate': Icons.support_agent_rounded,
    'Sales Manager': Icons.domain_verification_rounded,
  };

  String selectedRole = 'Sales Associate';

  final List<String> roles = [
    'Sales Associate',
    'Unit Supervisor',
    'Sales Manager',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Premium Background Gradients (Matches Login Screen)
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
            // --- 1. ANIMATED/GLOWING BACKGROUND ---
            Container(decoration: BoxDecoration(gradient: LinearGradient(colors: bgGradient, begin: Alignment.topLeft, end: Alignment.bottomRight))),
            // Decorative Glowing Orbs
            Positioned(
              top: -50, right: -50,
              child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: TColors.primary.withValues(alpha:isDark ? 0.3 : 0.1))).applyBlur(sigma: 50),
            ),
            Positioned(
              bottom: -100, left: -50,
              child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: TColors.marketing.withValues(alpha:isDark ? 0.2 : 0.05))).applyBlur(sigma: 60),
            ),

            // --- 2. MAIN CONTENT ---
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Form(
                  key: controller.signupFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text("Request Access", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: -1)),
                      const SizedBox(height: 8),
                      Text("Submit your profile for hierarchy approval.", style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey.shade600, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 32),

                      // --- 3. GLASSMORPHIC FORM CARD ---
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
                                // Role Selector
                                Text("REQUESTED CLEARANCE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey.shade500, letterSpacing: 1.5)),
                                const SizedBox(height: 12),
                                _buildRoleGrid(isDark),
                                const SizedBox(height: 24),

                                // Dynamic Approval Info
                                _buildApprovalInfoBox(isDark),
                                const SizedBox(height: 32),

                                // Inputs
                                Text("IDENTITY DETAILS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey.shade500, letterSpacing: 1.5)),
                                const SizedBox(height: 12),
                                _buildGlassInput(controller: controller.fullName, hint: "Full Legal Name", icon: Icons.person_outline_rounded, isDark: isDark, validator: (val) => val!.isEmpty ? "Enter your full name" : null),
                                const SizedBox(height: 16),
                                _buildGlassInput(controller: controller.email, hint: "Official Email", icon: Icons.alternate_email_rounded, isDark: isDark, validator: (val) => val!.isEmpty ? "Enter email" : null),
                                const SizedBox(height: 16),
                                _buildGlassInput(controller: controller.employeeId, hint: "Employee ID (If assigned)", icon: Icons.badge_outlined, isDark: isDark),
                                const SizedBox(height: 16),
                                Obx(() => _buildGlassInput(
                                    controller: controller.password,
                                    hint: "Set Secure Password",
                                    icon: Icons.lock_outline_rounded,
                                    isDark: isDark,
                                    isPassword: true,
                                    obscure: controller.hidePassword.value,
                                    onToggleToggle: () => controller.hidePassword.toggle(),
                                    validator: (val) => val!.length < 6 ? "Password must be 6+ chars" : null
                                )),
                                const SizedBox(height: 40),

                                // --- SUBMIT BUTTON ---
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
                                          controller.submitIdRequest(selectedRole);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                        child: controller.isLoading.value
                                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                            : const Text("SUBMIT REQUEST", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5)),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
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

  // --- COMPACT ROLE GRID ---
  Widget _buildRoleGrid(bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: roles.length,
      itemBuilder: (context, index) {
        final role = roles[index];
        String shortName = role.replaceAll(" Supervisor", " Sup").replaceAll("Manager", "Mgr").replaceAll("Associate", "Assoc");
        final isSelected = selectedRole == role;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => selectedRole = role);
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
                Icon(roleIcons[role] ?? Icons.person_outline, color: isSelected ? Colors.white : (isDark ? Colors.white70 : TColors.primary), size: 24),
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
      },
    );
  }

  // --- DYNAMIC APPROVAL INFO BOX ---
  Widget _buildApprovalInfoBox(bool isDark) {
    String chain = "Admin Direct Verification";
    Color iconColor = TColors.primary;

    if (selectedRole == 'Unit Supervisor') {
      chain = "Floor Operations Approval (Admin)";
      iconColor = Colors.teal;
    } else if (selectedRole == 'Sales Associate') {
      chain = "Admin Verification (Direct Access)";
      iconColor = Colors.orange;
    } else if (selectedRole == 'Sales Manager') {
      chain = "Admin High-Level Verification";
      iconColor = Colors.purple;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withValues(alpha:0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.route_rounded, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("APPROVAL PATH", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: iconColor, letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(chain, style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w700)),
              ],
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
            ? IconButton(icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: isDark ? Colors.white54 : Colors.black38, size: 20), onPressed: onToggleToggle)
            : null,
        filled: true,
        fillColor: isDark ? Colors.black.withValues(alpha:0.3) : Colors.white.withValues(alpha:0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: TColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }
}