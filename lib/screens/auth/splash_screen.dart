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
    // Starting at 0.0 (invisible) and growing to 1.0 (full massive size)
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        // easeOutBack gives it that premium "opening/expanding" snap at the end
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
    return Scaffold(
      backgroundColor: Colors.white, // ✅ Always strictly white
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: const Text(
            "Y",
            style: TextStyle(
              fontSize: 220, // ✅ Massive "Y" dominating the center of the screen
              fontWeight: FontWeight.w900,
              color: Colors.red, // Use TColors.primary if you prefer your brand color
              height: 1.0, // Keeps the text perfectly centered vertically
            ),
          ),
        ),
      ),
    );
  }
}