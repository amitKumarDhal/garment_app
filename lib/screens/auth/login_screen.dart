import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/login_controller.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/sizes.dart';
import '../../utils/widgets/custom_text_field.dart';
import '../../routes/route_names.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject the controller. Get.put() ensures it's created if not found.
    final controller = Get.put(LoginController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      // OPTIMIZATION: Dismiss keyboard when tapping background
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: isDark ? TColors.dark : TColors.light,
        body: SafeArea(
          // OPTIMIZATION: Avoid system notches
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(TSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // --- Header ---
                Text(
                  "Factory Manager",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: TColors.primary,
                  ),
                ),
                const SizedBox(height: TSizes.xs),
                Text(
                  "Select your role to access your dashboard",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                const SizedBox(height: TSizes.xl),

                // --- Role Selection Grid ---
                const Text(
                  "Login as:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: TSizes.sm),
                _buildRoleGrid(controller, isDark),

                const SizedBox(height: TSizes.xl),

                // --- Login Form ---
                _buildLoginForm(controller),

                const SizedBox(height: TSizes.xl),

                // --- Footer ---
                _buildSignUpFooter(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleGrid(LoginController controller, bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 85, // Fixed height for consistent look
      ),
      itemCount: controller.roles.length,
      itemBuilder: (context, index) {
        final role = controller.roles[index];
        return Obx(() {
          final isSelected = controller.selectedRole.value == role;
          return GestureDetector(
            onTap: () => controller.selectedRole.value = role,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected
                    ? TColors.primary
                    : (isDark ? Colors.white10 : Colors.white),
                borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
                border: Border.all(
                  color: isSelected
                      ? TColors.primary
                      : Colors.grey.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: TColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    controller.roleIcons[role],
                    color: isSelected ? Colors.white : TColors.primary,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    role,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
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

  Widget _buildLoginForm(LoginController controller) {
    return Form(
      key: controller.loginFormKey,
      child: Column(
        children: [
          TCustomTextField(
            label: "Email",
            controller: controller.email,
            prefixIcon: Icons.email_outlined,
            validator: (val) =>
                GetUtils.isEmail(val ?? "") ? null : "Invalid Email",
          ),
          const SizedBox(height: TSizes.md),
          Obx(
            () => TCustomTextField(
              label: "Password",
              controller: controller.password,
              prefixIcon: Icons.lock_outline,
              obscureText: controller.hidePassword.value,
              suffixIcon: IconButton(
                onPressed: () => controller.hidePassword.toggle(),
                icon: Icon(
                  controller.hidePassword.value
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
              ),
            ),
          ),
          const SizedBox(height: TSizes.lg),

          // --- Full Width Login Button ---
          SizedBox(
            width: double.infinity,
            height: 55,
            child: Obx(
              () => ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () => controller.login(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TSizes.sm),
                  ),
                ),
                child: controller.isLoading.value
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "LOGIN",
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
    );
  }

  Widget _buildSignUpFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Need an account? "),
        GestureDetector(
          onTap: () => Get.toNamed(AppRouteNames.signup),
          child: const Text(
            "Create ID Request",
            style: TextStyle(
              color: TColors.primary,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
