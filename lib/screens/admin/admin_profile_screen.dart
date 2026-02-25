import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/admin/admin_profile_controller.dart';
import '../../utils/constants/colors.dart'; // Ensure this points to your TColors

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject the controller
    final controller = Get.put(AdminProfileController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Admin Profile",
          style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // --- PROFILE HEADER ---
            Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: TColors.primary.withValues(alpha: 0.3), width: 3),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: TColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.admin_panel_settings_rounded, size: 50, color: TColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- ADMIN NAME & BADGE ---
            Obx(() => Text(
              controller.adminName.value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: -0.5),
            )),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: const Text("MASTER ADMIN", style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
            const SizedBox(height: 8),

            // --- ADMIN EMAIL ---
            Obx(() => Text(
              controller.adminEmail.value,
              style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w600),
            )),

            const SizedBox(height: 40),

            // --- MANAGEMENT OPTIONS ---
            _buildProfileMenuRow(
                title: "Manage Users",
                icon: Icons.manage_accounts_rounded,
                isDark: isDark,
                onTap: () {
                  // Get.to(() => const ManageUsersScreen());
                  Get.snackbar("Coming Soon", "User management will be available here.");
                }
            ),
            _buildProfileMenuRow(
                title: "Global Counter Settings",
                icon: Icons.pin_rounded,
                isDark: isDark,
                onTap: () {
                  // Get.to(() => const CounterSettingsScreen());
                  Get.snackbar("Coming Soon", "Counter settings will be available here.");
                }
            ),
            _buildProfileMenuRow(
                title: "System Settings",
                icon: Icons.settings_rounded,
                isDark: isDark,
                onTap: () {
                  Get.snackbar("Coming Soon", "System settings will be available here.");
                }
            ),

            const SizedBox(height: 40),

            // --- LOGOUT BUTTON ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: controller.confirmLogout,
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                label: const Text("Secure Logout", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGET FOR MENU ROWS ---
  Widget _buildProfileMenuRow({
    required String title,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: TColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: TColors.primary, size: 20),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: isDark ? Colors.white38 : Colors.black38),
      ),
    );
  }
}