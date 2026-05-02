// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';

import '../../controllers/production/unit_supervisor_controller.dart';
import '../../utils/constants/colors.dart';

class MockupDesignScreen extends StatelessWidget {
  const MockupDesignScreen({super.key, required this.order, required this.isMockupDone});

  final dynamic order;
  final bool isMockupDone;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = UnitSupervisorController.instance;

    // =========================================================================
    // ✅ 1. EXTRACT EXACT DATABASE DETAILS (Product, Fabric, Sizes)
    // =========================================================================
    String productDetail = order.productDetails ?? "Not specified";
    String fabricDetail = "Not specified";
    String sizesDetail = "Not specified";

    if (order.products != null && order.products.isNotEmpty) {
      var firstProduct = order.products[0];

      // Product Name
      if (productDetail == "Not specified" || productDetail.isEmpty) {
        productDetail = firstProduct['productName'] ?? "Not specified";
      }
      if (order.products.length > 1) {
        productDetail += " (+${order.products.length - 1} more)";
      }

      // Fabric
      fabricDetail = firstProduct['fabricType'] ?? "Not specified";

      // ✅ Safe Size Extraction (Removes ugly brackets if stored as a Map)
      sizesDetail = _extractSizes(firstProduct);
    }

    // =========================================================================
    // ✅ 2. EXTRACT EXACT MOCKUP URL
    // =========================================================================
    String? finalImageUrl;

    try {
      if (order.mockupUrl != null && order.mockupUrl.toString().isNotEmpty) {
        finalImageUrl = order.mockupUrl;
      } else if (order.designUrl != null && order.designUrl.toString().isNotEmpty) {
        finalImageUrl = order.designUrl;
      } else if (order.imageUrl != null && order.imageUrl.toString().isNotEmpty) {
        finalImageUrl = order.imageUrl;
      }
    } catch (e) {
      // Ignore if getters fail
    }

    if (finalImageUrl == null && order.products != null && order.products.isNotEmpty) {
      var firstProduct = order.products[0];
      finalImageUrl = firstProduct['mockupUrl'] ?? firstProduct['designUrl'] ?? firstProduct['imageUrl'];
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 1,
        centerTitle: true,
        title: Text(
            "Order #${order.manualOrderNo ?? order.id}",
            style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, fontSize: 18)
        ),
        leading: IconButton(
            onPressed: () => Get.back(),
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: isDark ? Colors.white : Colors.black87)
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ✅ 3. THE MOCKUP IMAGE VIEWER
            GestureDetector(
              onTap: () {
                if (finalImageUrl != null && finalImageUrl.isNotEmpty) {
                  _showFullScreenImage(context, finalImageUrl, order.manualOrderNo ?? "Unknown", isDark);
                }
              },
              child: Container(
                width: double.infinity,
                height: 280,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                  boxShadow: [
                    if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: finalImageUrl != null && finalImageUrl.isNotEmpty
                      ? CachedNetworkImage(
                    imageUrl: finalImageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: TColors.primary)),
                    errorWidget: (context, url, error) => _buildImagePlaceholder(isDark),
                  )
                      : _buildImagePlaceholder(isDark),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Center(
              child: Text(
                "Tap image to view full screen & download",
                style: TextStyle(
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // --- SPECIFICATIONS SECTION ---
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 20, color: TColors.primary),
                const SizedBox(width: 8),
                Text("Material Requirements", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
              ],
            ),
            const SizedBox(height: 12),

            // ✅ Display Product Details, Fabric, AND Sizes
            _buildInfoCard(isDark, productDetail, fabricDetail, sizesDetail),

            const SizedBox(height: 40),

            // ✅ 4. THE LARGE DONE BUTTON
            if (!isMockupDone)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    controller.markMockupDone(order);
                    Get.back();
                  },
                  icon: const Icon(Icons.check_circle_rounded, size: 22, color: Colors.white),
                  label: const Text("Approve Mockup & Set to Done", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3))
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text("Mockup Completed", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // ✅ HELPER: SAFE SIZE EXTRACTION
  // ===========================================================================
  String _extractSizes(dynamic item) {
    if (item['sizeDescription'] != null && item['sizeDescription'].toString().trim().isNotEmpty) {
      return item['sizeDescription'].toString();
    }

    if (item['sizes'] != null && item['sizes'] is Map) {
      final Map sizesMap = item['sizes'];
      if (sizesMap.isNotEmpty) {
        final validSizes = sizesMap.entries
            .where((e) => e.value.toString() != "0" && e.value.toString().isNotEmpty)
            .map((e) => "${e.key}: ${e.value}")
            .join(", ");
        if (validSizes.isNotEmpty) return validSizes;
      }
    }

    return "Not specified";
  }

  // ===========================================================================
  // ✅ FULL SCREEN & DOWNLOAD LOGIC
  // ===========================================================================
  void _showFullScreenImage(BuildContext context, String imageUrl, String orderNo, bool isDark) {
    Get.to(
          () => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          title: Text("Mockup $orderNo", style: const TextStyle(color: Colors.white, fontSize: 16)),
          actions: [
            IconButton(
              icon: const Icon(Icons.download_rounded, color: Colors.white),
              tooltip: 'Save to Gallery',
              onPressed: () => _downloadAndSaveImage(imageUrl, orderNo),
            ),
          ],
        ),
        body: Center(
          child: InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 1,
            maxScale: 4,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white),
              errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white, size: 50),
            ),
          ),
        ),
      ),
      transition: Transition.fadeIn,
    );
  }

  Future<void> _downloadAndSaveImage(String url, String orderNo) async {
    try {
      Get.snackbar("Downloading...", "Saving mockup to your gallery.", backgroundColor: Colors.black87, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);

      final response = await http.get(Uri.parse(url));
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/mockup_$orderNo.jpg');
      await file.writeAsBytes(response.bodyBytes);

      await Gal.putImage(file.path);

      Get.snackbar("Success!", "Image saved to your photo gallery.", backgroundColor: Colors.green.shade800, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar("Error", "Could not save image: $e", backgroundColor: Colors.red.shade800, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    }
  }

  // --- Helper Widgets ---
  Widget _buildImagePlaceholder(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text("No Image Provided", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInfoCard(bool isDark, String productDetail, String fabric, String sizes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF2A2A2A) : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailText("Product Details:", productDetail, isDark),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1, color: Colors.white10),
          ),
          _buildDetailText("Fabric:", fabric, isDark),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1, color: Colors.white10),
          ),
          _buildDetailText("Sizes:", sizes, isDark),
        ],
      ),
    );
  }

  Widget _buildDetailText(String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
        ),
        Expanded(
          child: Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
        ),
      ],
    );
  }
}