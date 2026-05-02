import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/splash_controller.dart';
// Ensure your TColors path is correct

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize your lightweight controller for routing
    Get.put(SplashController());

    // 1. Set the duration to match the delay in your AuthenticationRepository
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // 2 seconds
    );

    // 2. Define the "Smaller to Bigger" scaling effect
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    // Start the animation immediately when the screen loads
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 1. Detect if the device/app is in Dark Mode
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // ✅ 2. Adapt the background color so the logo matches seamlessly
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Image.asset(
            // ✅ 3. Swap the exact file path based on the theme
            isDark
                ? 'assets/logos/Yoobbel-onblack-cup.png'
                : 'assets/logos/Yoobbel-onwhite-cup.png',
            width: 250,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}