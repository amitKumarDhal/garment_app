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
    final controller = Get.put(LoginController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              Text(
                "Factory Manager",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text("Select your role to access your dashboard"),
              const SizedBox(height: TSizes.xl),

              const Text(
                "Login as:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: TSizes.sm),

              _buildRoleGrid(controller, isDark),

              const SizedBox(height: TSizes.xl),
              _buildLoginForm(controller),

              const SizedBox(height: TSizes.xl),
              _buildSignUpFooter(),
            ],
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
        mainAxisExtent: 85,
      ),
      itemCount: controller.roles.length,
      itemBuilder: (context, index) {
        final role = controller.roles[index];
        return Obx(() {
          final isSelected = controller.selectedRole.value == role;
          return GestureDetector(
            onTap: () => controller.selectedRole.value = role,
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? TColors.primary
                    : (isDark ? Colors.white10 : Colors.white),
                borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
                border: Border.all(
                  color: isSelected
                      ? TColors.primary
                      : Colors.grey.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    controller.roleIcons[role],
                    color: isSelected ? Colors.white : TColors.primary,
                  ),
                  Text(
                    role,
                    style: TextStyle(
                      fontSize: 12,
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
          Obx(
            () => ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : () => controller.login(),
              child: controller.isLoading.value
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("LOGIN"),
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
