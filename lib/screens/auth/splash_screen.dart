import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/splash_controller.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the controller
    Get.put(SplashController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Center Logo and Title
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Placeholder for your Logo
                const Icon(
                  Icons.factory_rounded,
                  size: 100,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 20),
                const Text(
                  "YOOBBEL",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 5,
                    color: Colors.blueAccent,
                  ),
                ),
                const Text(
                  "Smart Factory Management",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Loading Indicator at the bottom
          const Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            ),
          ),
        ],
      ),
    );
  }
}
