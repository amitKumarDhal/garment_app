import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/auth/profile_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(
          "My Profile",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -0.5,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: false,
        titleSpacing: 24,
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        actions: [
          _buildAppBarAction(Icons.qr_code_scanner_rounded, isDark, () {
            Get.snackbar("Digital ID", "Show this QR code at the gate.");
          }),
          const SizedBox(width: 8),
          _buildAppBarAction(Icons.refresh_rounded, isDark, () => controller.fetchUserProfile()),
          const SizedBox(width: 20),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            // 1. PREMIUM DIGITAL ID CARD
            _buildDigitalIdCard(context, controller),

            const SizedBox(height: 32),

            // 2. PERFORMANCE STATS
            _buildSectionHeader("Performance Metrics"),
            _buildPerformanceStats(context),

            const SizedBox(height: 28),

            // 3. SHIFT INFO
            _buildShiftInfo(context),

            const SizedBox(height: 32),

            // 4. MENU ITEMS
            _buildSectionHeader("Account & Security"),
            _buildProfileTile(
              icon: Icons.person_outline_rounded,
              title: "Personal Information",
              subtitle: "Update name, phone, address",
              isDark: isDark,
              onTap: () {},
            ),
            _buildProfileTile(
              icon: Icons.lock_outline_rounded,
              title: "Change Password",
              subtitle: "Last changed 30 days ago",
              isDark: isDark,
              onTap: () {},
            ),

            const SizedBox(height: 24),
            _buildSectionHeader("App Preferences"),
            _buildThemeTile(context, isDark),
            _buildProfileTile(
              icon: Icons.help_outline_rounded,
              title: "Support & Help",
              subtitle: "Report issues or contact HR",
              isDark: isDark,
              onTap: () {},
            ),

            const SizedBox(height: 40),

            // 5. LOGOUT
            _buildLogoutButton(controller),

            const SizedBox(height: 24),

            Text(
              "Version 1.0.2 (Build 240)",
              style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ===================== MODERN WIDGETS =====================

  Widget _buildAppBarAction(IconData icon, bool isDark, VoidCallback onTap) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? Colors.white.withValues(alpha:0.08) : Colors.black.withValues(alpha:0.04),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: isDark ? Colors.white : Colors.black87),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildDigitalIdCard(BuildContext context, ProfileController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A1B9A).withValues(alpha:0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Avatar (Fixed size)
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Icon(Icons.person_rounded, size: 32, color: const Color(0xFF6A1B9A)),
            ),
          ),
          const SizedBox(width: 16),

          // 2. Info Section (Takes remaining space)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(() => Text(
                  controller.name.value,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5
                  ),
                  maxLines: 1, // ✅ Prevents name from breaking layout
                  overflow: TextOverflow.ellipsis, // ✅ Adds "..." if too long
                )),
                const SizedBox(height: 4),

                // ✅ THE FIX: Wrap the sub-row to prevent overflow on small screens
                FittedBox(
                  fit: BoxFit.scaleDown, // ✅ Automatically shrinks the text if it overflows
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha:0.2),
                            borderRadius: BorderRadius.circular(6)
                        ),
                        child: Obx(() => Text(
                          controller.role.value.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5
                          ),
                        )),
                      ),
                      const SizedBox(width: 8),
                      Obx(() => Text(
                        "E-ID: ${controller.employeeId.value}",
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha:0.7),
                            fontWeight: FontWeight.w600
                        ),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // 3. QR Code Icon (Fixed size)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }
  Widget _buildPerformanceStats(BuildContext context) {
    return Row(
      children: [
        _buildStatBox("Efficiency", "94%", Colors.green, context),
        const SizedBox(width: 12),
        _buildStatBox("Attendance", "26/30", Colors.orange, context),
        const SizedBox(width: 12),
        _buildStatBox("Tasks", "128", Colors.blue, context),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, Color color, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8), // ✅ Added slight horizontal padding
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha:0.05) : Colors.black.withValues(alpha:0.03)),
          boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withValues(alpha:0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            // ✅ Wrapped in FittedBox to automatically shrink if the value (e.g. "100%") is too wide
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            ),
            const SizedBox(height: 4),
            // ✅ Wrapped in FittedBox to prevent long words like "Efficiency" from breaking
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildShiftInfo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.withValues(alpha:0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.purple.withValues(alpha:0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.access_time_filled_rounded, color: Colors.purple),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Current Shift", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
              const SizedBox(height: 2),
              const Text("Morning Shift (08:00 - 16:00)", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5),
        ),
      ),
    );
  }

  Widget _buildProfileTile({required IconData icon, required String title, required String subtitle, required bool isDark, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha:0.05) : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: isDark ? Colors.white : Colors.black87, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
      ),
    );
  }

  Widget _buildThemeTile(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha:0.05) : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.dark_mode_rounded, color: isDark ? Colors.amber : Colors.indigo, size: 22),
        ),
        title: const Text("Dark Mode", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        subtitle: Text(isDark ? "Easy on the eyes" : "Classic light theme", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        trailing: Switch.adaptive(
          value: isDark,
          activeColor: Colors.purple,
          onChanged: (value) => Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light),
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
            titleStyle: const TextStyle(fontWeight: FontWeight.w900),
            middleText: "Are you sure you want to exit?",
            textConfirm: "Logout",
            textCancel: "Cancel",
            confirmTextColor: Colors.white,
            buttonColor: Colors.redAccent,
            radius: 16,
            onConfirm: () => controller.logout(),
          );
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: Colors.red.withValues(alpha:0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: const Text("Log Out", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 16)),
      ),
    );
  }
}