import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yoobbel/controllers/auth/profile_controller.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/sizes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the controller
    final controller = Get.put(ProfileController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "My Profile",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              Get.snackbar("Digital ID", "Show this QR code at the gate.");
            },
            tooltip: "Show Gate Pass",
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.fetchUserProfile(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.md),
        child: Column(
          children: [
            // 1. DIGITAL ID CARD (Visual & Practical)
            _buildDigitalIdCard(context, controller),

            const SizedBox(height: TSizes.lg),

            // 2. PERFORMANCE DASHBOARD (Data driven)
            _buildPerformanceStats(context),

            const SizedBox(height: TSizes.lg),

            // 3. SHIFT DETAILS (Practical Info)
            _buildShiftInfo(context),

            const SizedBox(height: TSizes.lg),

            // 4. MENU ITEMS
            _buildSectionHeader(context, "Account & Security"),
            _buildProfileTile(
              context,
              icon: Icons.person_outline,
              title: "Personal Information",
              subtitle: "Update name, phone, address",
              onTap: () {},
            ),
            _buildProfileTile(
              context,
              icon: Icons.lock_outline,
              title: "Change Password",
              subtitle: "Last changed 30 days ago",
              onTap: () {},
            ),

            const SizedBox(height: TSizes.md),
            _buildSectionHeader(context, "App Preferences"),
            _buildThemeTile(context),
            _buildProfileTile(
              context,
              icon: Icons.help_outline,
              title: "Support & Help",
              subtitle: "Report issues or contact HR",
              onTap: () {},
            ),

            const SizedBox(height: TSizes.xl),

            // 5. LOGOUT
            _buildLogoutButton(controller),

            const SizedBox(height: TSizes.xl),

            // Version Info
            Text(
              "Version 1.0.2 (Build 240)",
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            const SizedBox(height: TSizes.lg),
          ],
        ),
      ),
    );
  }

  // ===================== WIDGETS =====================

  Widget _buildDigitalIdCard(
    BuildContext context,
    ProfileController controller,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [TColors.primary, TColors.primary.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: TColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Align items vertically
        children: [
          // 1. Profile Image
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: Colors.white24,
              child: Obx(
                () => Text(
                  controller.name.value.isNotEmpty
                      ? controller.name.value[0].toUpperCase()
                      : "U",
                  style: const TextStyle(
                    fontSize: 30,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),

          // 2. User Info (Expanded allows text to take available space)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- FULL NAME FIX (Wraps text instead of cutting off) ---
                Obx(
                  () => Text(
                    controller.name.value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2, // Adds space between lines
                    ),
                    maxLines: 2, // Allow up to 2 lines
                    softWrap: true, // Enable wrapping
                    overflow: TextOverflow.visible,
                  ),
                ),
                const SizedBox(height: 4),

                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Obx(
                    () => Text(
                      controller.role.value.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        letterSpacing: 1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // ID
                Obx(
                  () => Text(
                    "ID: ${controller.employeeId.value}",
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // 3. QR Code Icon (Visual Only)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.qr_code_2, color: Colors.black, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceStats(BuildContext context) {
    return Row(
      children: [
        _buildStatBox(context, "Efficiency", "94%", Colors.green),
        const SizedBox(width: 12),
        _buildStatBox(context, "Attendance", "26/30", Colors.orange),
        const SizedBox(width: 12),
        _buildStatBox(context, "Tasks", "128", Colors.blue),
      ],
    );
  }

  Widget _buildStatBox(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftInfo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.access_time_filled, color: Colors.purple),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Current Shift",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const Text(
                "Morning Shift (08:00 - 16:00)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDark ? Colors.white : Colors.black87,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }

  Widget _buildThemeTile(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.brightness_6,
            color: isDark ? Colors.white : Colors.black87,
            size: 20,
          ),
        ),
        title: const Text(
          "Dark Mode",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          isDark ? "Easy on the eyes" : "Classic light theme",
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: Switch(
          value: isDark,
          activeThumbColor: TColors.primary,
          onChanged: (value) =>
              Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(ProfileController controller) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () {
          Get.defaultDialog(
            title: "Logout",
            middleText: "Are you sure?",
            textConfirm: "Yes",
            textCancel: "No",
            confirmTextColor: Colors.white,
            buttonColor: Colors.red,
            onConfirm: () => controller.logout(),
          );
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          "Log Out",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
