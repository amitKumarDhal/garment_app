import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/sizes.dart';
import '../../utils/widgets/custom_text_field.dart';
import '../../controllers/auth/signup_controller.dart'; // IMPORTED

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // Initialize the Controller
  final controller = Get.put(SignupController());

  final Map<String, IconData> roleIcons = {
    'Worker': Icons.engineering_outlined,
    'Unit Supervisor': Icons.manage_accounts_outlined,
    'Shift Supervisor': Icons.supervisor_account_outlined,
    'Admin': Icons.admin_panel_settings_outlined,
  };

  String selectedRole = 'Worker';
  final List<String> roles = [
    'Worker',
    'Unit Supervisor',
    'Shift Supervisor',
    'Admin',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : TColors.light,
      appBar: AppBar(
        title: const Text("Request Employee ID"),
        backgroundColor: TColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.lg),
        child: Form(
          // ADDED FORM WRAPPER
          key: controller.signupFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Create Your Profile",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: TSizes.sm),
              const Text(
                "Your account will be activated after hierarchy approval.",
              ),

              const SizedBox(height: TSizes.xl),

              // --- ROLE SELECTION ---
              const Text(
                "Select Your Designation:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: TSizes.sm),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 items per row
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 80, // Height of the card
                ),
                itemCount: roles.length,
                itemBuilder: (context, index) {
                  final role = roles[index];
                  final isSelected = selectedRole == role;
                  // Use the icon from your map, fallback to a default if not found
                  final icon = roleIcons[role] ?? Icons.person_outline;

                  return GestureDetector(
                    onTap: () => setState(() => selectedRole = role),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? TColors.primary
                            : (isDark ? Colors.white10 : Colors.white),
                        borderRadius: BorderRadius.circular(
                          TSizes.cardRadiusMd,
                        ),
                        border: Border.all(
                          color: isSelected
                              ? TColors.primary
                              : Colors.grey.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: TColors.primary.withOpacity(0.3),
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
                            icon,
                            color: isSelected ? Colors.white : TColors.primary,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            role,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.black87),
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: TSizes.xl),

              // --- INPUT FIELDS (CONNECTED TO CONTROLLER) ---
              TCustomTextField(
                label: "Full Name",
                controller: controller.fullName, // CONNECTED
                prefixIcon: Icons.person_outline,
                validator: (val) =>
                    val!.isEmpty ? "Enter your full name" : null,
              ),
              const SizedBox(height: TSizes.md),
              TCustomTextField(
                label: "Official Email / Phone",
                controller: controller.email, // CONNECTED
                prefixIcon: Icons.contact_mail_outlined,
                validator: (val) =>
                    val!.isEmpty ? "Enter email or phone" : null,
              ),
              const SizedBox(height: TSizes.md),
              TCustomTextField(
                label: "Employee ID (If assigned)",
                controller: controller.employeeId, // CONNECTED
                prefixIcon: Icons.badge_outlined,
              ),
              const SizedBox(height: TSizes.md),
              TCustomTextField(
                label: "Set Password",
                controller: controller.password, // CONNECTED
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                validator: (val) =>
                    val!.length < 6 ? "Password too short" : null,
              ),

              const SizedBox(height: TSizes.xl),

              _buildApprovalInfoBox(isDark),

              const SizedBox(height: TSizes.xl),

              // --- SUBMIT BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: Obx(
                  () => ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () => controller.submitIdRequest(
                            selectedRole,
                          ), // CALLS CONTROLLER
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(TSizes.sm),
                      ),
                    ),
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "SUBMIT FOR APPROVAL",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: TSizes.md),

              Center(
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: const Text("Already have an account? Login"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Visual guide helper (Unchanged logic)
  Widget _buildApprovalInfoBox(bool isDark) {
    String chain = "";
    if (selectedRole == 'Worker') {
      chain = "Unit Supervisor ➔ Shift Supervisor ➔ Admin";
    }
    if (selectedRole == 'Unit Supervisor') chain = "Shift Supervisor ➔ Admin";
    if (selectedRole == 'Shift Supervisor') chain = "Admin Final Approval";
    if (selectedRole == 'Admin') chain = "System Owner Verification";

    return Container(
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.blue.withOpacity(0.1)
            : Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
        border: Border.all(color: TColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_tree_outlined,
                size: 18,
                color: TColors.primary,
              ),
              SizedBox(width: 8),
              Text(
                "Required Approval Chain:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            chain,
            style: const TextStyle(
              fontSize: 13,
              color: TColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
