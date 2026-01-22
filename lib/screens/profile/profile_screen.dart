import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yoobbel/controllers/auth/profile_controller.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/sizes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the Production Controller
    final controller = Get.put(ProfileController());

    // Note: We removed PopScope because MainWrapper already handles
    // the "Back to Home" logic for the Bottom Navigation Bar.

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("My Profile"),
        centerTitle: true,
        backgroundColor: TColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        // Optional: Add refresh button to reload data manually
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.fetchUserProfile(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- Header Section ---
            _buildHeader(context, controller),

            const SizedBox(height: TSizes.xl),

            // --- Settings Section ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel(context, "Account Settings"),
                  _buildProfileMenuItem(
                    context,
                    icon: Icons.edit_outlined,
                    title: "Edit Profile",
                    onTap: () {
                      // TODO: Add Edit Profile Logic
                      Get.snackbar(
                        "Coming Soon",
                        "Edit Profile feature is in progress",
                      );
                    },
                  ),
                  _buildProfileMenuItem(
                    context,
                    icon: Icons.notifications_none,
                    title: "Notifications",
                    onTap: () {},
                  ),
                  _buildProfileMenuItem(
                    context,
                    icon: Icons.security_outlined,
                    title: "Security",
                    onTap: () {},
                  ),

                  const SizedBox(height: TSizes.lg),
                  _buildSectionLabel(context, "App System"),
                  _buildThemeToggleItem(context),

                  _buildProfileMenuItem(
                    context,
                    icon: Icons.language_outlined,
                    title: "Language",
                    onTap: () {},
                  ),
                  _buildProfileMenuItem(
                    context,
                    icon: Icons.help_outline,
                    title: "Help Center",
                    onTap: () {},
                  ),

                  const SizedBox(height: TSizes.xl),

                  // --- Logout Button ---
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _showLogoutDialog(controller),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(
                          vertical: TSizes.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(TSizes.sm),
                        ),
                      ),
                      child: const Text(
                        "LOGOUT",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: TSizes.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildHeader(BuildContext context, ProfileController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TSizes.xl),
      decoration: const BoxDecoration(
        color: TColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(TSizes.cardRadiusLg),
          bottomRight: Radius.circular(TSizes.cardRadiusLg),
        ),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 4),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white10,
              // Show first letter of name if available
              child: Obx(
                () => Text(
                  controller.name.value.isNotEmpty
                      ? controller.name.value[0].toUpperCase()
                      : "U",
                  style: const TextStyle(
                    fontSize: 40,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: TSizes.md),

          // FIX: Variable names now match the Real ProfileController
          Obx(
            () => Text(
              controller.name.value, // Was userName
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Obx(
            () => Text(
              controller.email.value, // Was userEmail
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 4),
          Obx(
            () => Text(
              "ID: ${controller.employeeId.value}", // Was supervisorId
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: TSizes.xs, bottom: TSizes.sm),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.grey[400] : Colors.black54,
        ),
      ),
    );
  }

  Widget _buildProfileMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: TSizes.sm),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TSizes.sm),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: TColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: TColors.primary, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildThemeToggleItem(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: TSizes.sm),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TSizes.sm),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: TColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
            color: TColors.primary,
            size: 22,
          ),
        ),
        title: Text(isDark ? "Dark Mode On" : "Dark Mode Off"),
        trailing: Switch(
          value: isDark,
          onChanged: (value) =>
              Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light),
          activeColor: TColors.primary,
        ),
      ),
    );
  }

  void _showLogoutDialog(ProfileController controller) {
    Get.defaultDialog(
      title: "Logout",
      middleText: "Are you sure you want to logout?",
      textConfirm: "Yes, Logout",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        controller.logout();
        // Note: The controller handles the navigation to login
      },
    );
  }
}
